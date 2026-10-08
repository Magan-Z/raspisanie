// Синхронизация с сайтом: ETag, хеши, кэш, офлайн — на поддельном сервере (без интернета).

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/remote/schedule_api.dart';
import 'package:raspisanie/data/repositories/schedule_repository.dart';

class _DiskAssets extends AssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async => utf8.decode(File(key).readAsBytesSync());

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) async => parser(await loadString(key));
}

/// Сервер, который отдаёт файлы из папки и считает запросы.
class _FakeSite {
  _FakeSite(this.files);
  Map<String, String> files; // путь → содержимое
  final requests = <String>[];
  bool offline = false;
  int get groupRequests => requests.where((r) => r.startsWith('groups/')).length;

  late final client = MockClient((request) async {
    if (offline) throw const SocketException('нет сети');
    final path = request.url.path.replaceFirst('/site/', '');
    requests.add(path);
    final body = files[path];
    if (body == null) return http.Response('not found', 404);
    final etag = '"${body.hashCode}"';
    if (request.headers['If-None-Match'] == etag) return http.Response('', 304);
    return http.Response.bytes(utf8.encode(body), 200, headers: {'etag': etag});
  });
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Map<String, String> siteFiles({String version = '2099-01-01T00:00:00Z-new'}) {
    final index = jsonDecode(File('test/fixtures/index.json').readAsStringSync()) as Map<String, dynamic>;
    index['version'] = version;
    // «Новое» расписание: у 1 БИ-25 другой хеш
    for (final form in index['forms']) {
      for (final g in form['groups']) {
        if (g['id'] == 'ofo-1-bi-25') g['hash'] = 'newhash';
      }
    }
    final files = {
      'index.json': jsonEncode(index),
      'diff/latest.json': '{"groups": {}}',
    };
    for (final f in Directory('test/fixtures/all').listSync().whereType<File>()) {
      final name = f.path.split('/').last;
      final group = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      group['version'] = version;
      if (name == 'ofo-1-bi-25.json') (group['lessons'] as List).removeLast(); // в новой версии на одну пару меньше
      files['groups/$name'] = jsonEncode(group);
    }
    return files;
  }

  ScheduleRepository repo(_FakeSite? site) => ScheduleRepository(
        db: db,
        assets: _DiskAssets(),
        api: site == null ? null : ScheduleApi('https://example.test/site/', client: site.client),
      );

  test('без сети и без кэша работает встроенная копия', () async {
    final r = repo(null);
    final index = await r.loadIndex();
    expect(index.forms.expand((f) => f.groups), hasLength(50));
    final group = await r.loadGroup('ofo-1-bi-25');
    expect(group.lessons, hasLength(23));
    expect(await r.lastFetchedAt(), isNull);
  });

  test('синхронизация подтягивает новую версию, и она показывается вместо встроенной', () async {
    final site = _FakeSite(siteFiles());
    final r = repo(site);

    final result = await r.sync(groupId: 'ofo-1-bi-25');
    expect(result.error, isNull);
    expect(result.indexChanged, isTrue);

    expect((await r.loadIndex()).version, '2099-01-01T00:00:00Z-new');
    final group = await r.loadGroup('ofo-1-bi-25');
    expect(group.lessons, hasLength(22)); // свежая версия, а не встроенная (23)
    expect(await r.lastFetchedAt(), isNotNull);
  });

  test('если расписание группы изменилось — вместе с ним приходит diff для баннера', () async {
    final site = _FakeSite(siteFiles());
    final r = repo(site);
    await r.sync(groupId: 'ofo-1-bi-25'); // первая загрузка: «изменением» не считается
    site.files = siteFiles(version: '2099-03-03T00:00:00Z-n2')..['groups/ofo-1-bi-25.json'] = jsonEncode({
      ...jsonDecode(site.files['groups/ofo-1-bi-25.json']!) as Map<String, dynamic>,
      'version': '2099-03-03T00:00:00Z-n2',
    });
    final index = jsonDecode(site.files['index.json']!) as Map<String, dynamic>;
    for (final form in index['forms']) {
      for (final g in form['groups']) {
        if (g['id'] == 'ofo-1-bi-25') g['hash'] = 'hash-2';
      }
    }
    site.files['index.json'] = jsonEncode(index);

    final result = await r.sync(groupId: 'ofo-1-bi-25');
    expect(result.groupChanged, isTrue);
    expect(result.diffJson, '{"groups": {}}');
  });

  test('повторная синхронизация: ETag → 304, группы заново не скачиваются', () async {
    final site = _FakeSite(siteFiles());
    final r = repo(site);
    await r.sync(groupId: 'ofo-1-bi-25');
    final groupRequestsAfterFirst = site.groupRequests;
    expect(groupRequestsAfterFirst, greaterThan(0));

    site.requests.clear();
    final second = await r.sync(groupId: 'ofo-1-bi-25');
    expect(second.error, isNull);
    expect(second.indexChanged, isFalse);
    expect(second.groupChanged, isFalse);
    expect(site.requests, ['index.json']); // один запрос, ответ 304
  });

  test('меняется только одна группа → скачивается только она', () async {
    final site = _FakeSite(siteFiles());
    final r = repo(site);
    await r.sync(groupId: 'ofo-1-bi-25');

    // Следующая версия сайта: изменилась только 2 БИ-25
    final next = siteFiles(version: '2099-02-02T00:00:00Z-next');
    final index = jsonDecode(next['index.json']!) as Map<String, dynamic>;
    for (final form in index['forms']) {
      for (final g in form['groups']) {
        if (g['id'] == 'ofo-2-bi-25') g['hash'] = 'changed';
      }
    }
    next['index.json'] = jsonEncode(index);
    site.files = next;
    site.requests.clear();

    final result = await r.sync(groupId: 'ofo-1-bi-25');
    expect(result.indexChanged, isTrue);
    expect(site.requests.where((p) => p.startsWith('groups/')), ['groups/ofo-2-bi-25.json']);
  });

  test('сервер недоступен: ошибка не бросается, кэш остаётся', () async {
    final site = _FakeSite(siteFiles());
    final r = repo(site);
    await r.sync(groupId: 'ofo-1-bi-25');

    site.offline = true;
    final result = await r.sync(groupId: 'ofo-1-bi-25');
    expect(result.error, isNotNull); // сообщаем, но не падаем
    expect((await r.loadGroup('ofo-1-bi-25')).lessons, hasLength(22)); // последняя хорошая версия
  });

  test('битый ответ сервера не портит кэш', () async {
    final site = _FakeSite({'index.json': '{это не json'});
    final r = repo(site);
    final result = await r.sync();
    expect(result.error, isNotNull);
    expect((await r.loadIndex()).version, startsWith('2026-')); // встроенная копия
  });

  test('новый семестр сбрасывает кэш групп', () async {
    final site = _FakeSite(siteFiles());
    final r = repo(site);
    await r.sync(groupId: 'ofo-1-bi-25');

    final next = siteFiles(version: '2100-01-01T00:00:00Z-spring');
    final index = jsonDecode(next['index.json']!) as Map<String, dynamic>;
    (index['semester'] as Map)['id'] = '2027-spring';
    next['index.json'] = jsonEncode(index);
    site.files = next;
    // вместо групп — 404: убедимся, что старый кэш групп очищен и приложение откатилось на встроенную копию
    next.removeWhere((k, _) => k.startsWith('groups/'));

    await r.sync(groupId: 'ofo-1-bi-25');
    expect(await db.select(db.scheduleCache).get(), isEmpty);
  });

  test('loadAllGroups отдаёт все 50 групп', () async {
    expect(await repo(null).loadAllGroups(), hasLength(50));
  });
}
