// Откуда берётся расписание (АРХИТЕКТУРА.md, §7.5):
//   1) локальный кэш (база на телефоне) — показывается сразу;
//   2) встроенная копия в приложении (assets/schedule) — если кэша ещё нет;
//   3) сеть — только чтобы обновить кэш. Ошибки сети не мешают работе.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show AssetBundle;

import '../../domain/models.dart';
import '../local/database.dart';
import '../remote/schedule_api.dart';

/// Итог синхронизации.
class SyncResult {
  const SyncResult({this.indexChanged = false, this.groupChanged = false, this.error});
  final bool indexChanged;
  final bool groupChanged;
  final Object? error;
}

class ScheduleRepository {
  ScheduleRepository({required this.db, required this.assets, this.api});

  final AppDatabase db;
  final AssetBundle assets;
  final ScheduleApi? api; // null — адрес сайта не задан, работаем только офлайн

  static const _assetDir = 'assets/schedule';

  // ---------- index.json ----------

  /// Список групп: из кэша или из встроенной копии (берём ту, что новее).
  Future<ScheduleIndex> loadIndex() async {
    final cached = await (db.select(db.indexCache)..where((t) => t.id.equals(1))).getSingleOrNull();
    final bundledJson = await _bundled('index.json');
    final bundled = bundledJson == null ? null : ScheduleIndex.fromJson(_decode(bundledJson));

    if (cached != null) {
      final fromCache = ScheduleIndex.fromJson(_decode(cached.json));
      // Версия начинается с даты сборки, поэтому строки можно сравнивать как текст
      if (bundled == null || fromCache.version.compareTo(bundled.version) >= 0) return fromCache;
    }
    if (bundled == null) throw StateError('Нет ни кэша, ни встроенного расписания');
    return bundled;
  }

  /// Когда последний раз удалось получить расписание из сети (null — ни разу).
  Future<DateTime?> lastFetchedAt() async {
    final cached = await (db.select(db.indexCache)..where((t) => t.id.equals(1))).getSingleOrNull();
    return cached?.fetchedAt;
  }

  // ---------- groups/<id>.json ----------

  Future<GroupSchedule> loadGroup(String groupId) async {
    final index = await loadIndex();
    final expectedHash = index.findGroup(groupId)?.hash;
    final cached = await (db.select(db.scheduleCache)..where((t) => t.groupId.equals(groupId))).getSingleOrNull();

    if (cached != null && cached.hash == expectedHash) return GroupSchedule.fromJson(_decode(cached.json));

    final bundledJson = await _bundled('groups/$groupId.json');
    if (bundledJson != null) {
      final bundled = GroupSchedule.fromJson(_decode(bundledJson));
      // Встроенная копия подходит, если она той же версии, что и список групп
      if (bundled.version == index.version || cached == null) return bundled;
    }
    if (cached != null) return GroupSchedule.fromJson(_decode(cached.json)); // последняя хорошая версия
    throw StateError('Нет расписания группы $groupId');
  }

  /// Расписания всех групп института — для поиска преподавателей и аудиторий.
  Future<List<GroupSchedule>> loadAllGroups() async {
    final index = await loadIndex();
    return [
      for (final form in index.forms)
        for (final group in form.groups) await loadGroup(group.id),
    ];
  }

  // ---------- синхронизация ----------

  /// Проверяет обновления на сайте. Никогда не бросает исключений: ошибка возвращается в результате.
  Future<SyncResult> sync({String? groupId}) async {
    final api = this.api;
    if (api == null) return const SyncResult();
    try {
      final cachedIndex = await (db.select(db.indexCache)..where((t) => t.id.equals(1))).getSingleOrNull();
      final indexResult = await api.fetch('index.json', etag: cachedIndex?.etag);

      var indexChanged = false;
      if (indexResult.notModified) {
        await (db.update(db.indexCache)..where((t) => t.id.equals(1)))
            .write(IndexCacheCompanion(fetchedAt: Value(DateTime.now())));
      } else {
        final index = ScheduleIndex.fromJson(_decode(indexResult.body!)); // битый JSON → исключение, кэш не трогаем
        final oldIndex = cachedIndex == null ? null : ScheduleIndex.fromJson(_decode(cachedIndex.json));
        if (oldIndex != null && oldIndex.semesterId != index.semesterId) {
          await db.delete(db.scheduleCache).go(); // новый семестр — старые расписания не нужны
        }
        indexChanged = oldIndex?.version != index.version;
        await db.into(db.indexCache).insertOnConflictUpdate(IndexCacheCompanion.insert(
              id: const Value(1),
              version: index.version,
              json: indexResult.body!,
              etag: Value(indexResult.etag),
              fetchedAt: DateTime.now(),
            ));
      }

      var groupChanged = false;
      if (groupId != null) groupChanged = await _syncGroup(api, groupId);
      await _syncOtherGroups(api, except: groupId);
      return SyncResult(indexChanged: indexChanged, groupChanged: groupChanged);
    } catch (error) {
      return SyncResult(error: error);
    }
  }

  /// Скачивает файл группы, если его хеш в index.json изменился. true — расписание обновилось.
  Future<bool> _syncGroup(ScheduleApi api, String groupId) async {
    final index = await loadIndex();
    final info = index.findGroup(groupId);
    if (info == null) return false;

    final cached = await (db.select(db.scheduleCache)..where((t) => t.groupId.equals(groupId))).getSingleOrNull();
    if (cached != null && cached.hash == info.hash) return false;

    final result = await api.fetch('groups/$groupId.json', etag: cached?.etag);
    if (result.notModified) return false;
    final schedule = GroupSchedule.fromJson(_decode(result.body!));
    await db.into(db.scheduleCache).insertOnConflictUpdate(ScheduleCacheCompanion.insert(
          groupId: groupId,
          version: schedule.version,
          hash: info.hash,
          json: result.body!,
          etag: Value(result.etag),
          fetchedAt: DateTime.now(),
        ));
    return cached != null; // первая загрузка — не «изменение»
  }

  /// Остальные группы (для поиска) обновляем по хешу; ошибка одной группы не мешает другим.
  Future<void> _syncOtherGroups(ScheduleApi api, {String? except}) async {
    final index = await loadIndex();
    for (final form in index.forms) {
      for (final group in form.groups) {
        if (group.id == except) continue;
        final cached = await (db.select(db.scheduleCache)..where((t) => t.groupId.equals(group.id))).getSingleOrNull();
        if (cached?.hash == group.hash) continue;
        if (cached == null) {
          // Встроенная копия той же версии — скачивать нечего
          final bundledJson = await _bundled('groups/${group.id}.json');
          if (bundledJson != null && GroupSchedule.fromJson(_decode(bundledJson)).version == index.version) continue;
        }
        try {
          await _syncGroup(api, group.id);
        } catch (_) {
          // Не получилось — попробуем при следующей синхронизации
        }
      }
    }
  }

  // ---------- вспомогательное ----------

  Future<String?> _bundled(String path) async {
    try {
      return await assets.loadString('$_assetDir/$path');
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decode(String json) => jsonDecode(json) as Map<String, dynamic>;
}
