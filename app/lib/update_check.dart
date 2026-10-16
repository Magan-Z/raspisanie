// Проверка новой версии приложения: сайт отдаёт apk.json ({"version": "0.3.5", "size": …, "min": "0.3.0"}).
// Если на сайте версия новее — показываем мягкую плашку «Вышла новая версия» (её можно закрыть до следующей версии).
// Если версия приложения ниже «min» (минимально допустимой) — показываем экран «Нужно обновить» без возможности продолжить.
// Работает только в APK для Android: веб-версия обновляется сама, а в локальных сборках версия не задана.
//
// Защита от ошибок: нет связи, непонятный ответ или min выше последней версии — ничего не показываем и не блокируем.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'app_state.dart';
import 'config.dart';
import 'usage_ping.dart' show appVersion;

class UpdateInfo {
  const UpdateInfo({required this.latest, this.min = '0.0.0'});

  /// Последняя выпущенная версия.
  final String latest;

  /// Самая старая версия, которой ещё можно пользоваться.
  final String min;

  /// Разбирает apk.json; при любой странности возвращает null.
  static UpdateInfo? parse(Object? json) {
    if (json is! Map) return null;
    final latest = json['version'];
    if (latest is! String || _parts(latest) == null) return null;
    final min = json['min'];
    return UpdateInfo(latest: latest, min: min is String && _parts(min) != null ? min : '0.0.0');
  }
}

List<int>? _parts(String version) {
  final text = version.trim().replaceFirst(RegExp('^v'), '');
  if (text.isEmpty) return null;
  final result = <int>[];
  for (final piece in text.split('.')) {
    final match = RegExp(r'^\d+').firstMatch(piece);
    if (match == null) return null;
    result.add(int.parse(match.group(0)!));
  }
  return result;
}

/// Сравнение версий вида 0.3.4: отрицательное — [a] старее [b]; null — версию не удалось разобрать.
int? compareVersions(String a, String b) {
  final x = _parts(a), y = _parts(b);
  if (x == null || y == null) return null;
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final p = i < x.length ? x[i] : 0, q = i < y.length ? y[i] : 0;
    if (p != q) return p < q ? -1 : 1;
  }
  return 0;
}

enum UpdateStatus { none, available, required }

/// Что показать человеку. [dismissed] — версия, про которую он уже нажал «Позже».
UpdateStatus computeUpdateStatus({required String current, required UpdateInfo? info, String? dismissed}) {
  if (info == null || current.isEmpty) return UpdateStatus.none;
  final latestCmp = compareVersions(current, info.latest);
  if (latestCmp == null) return UpdateStatus.none;
  // min выше последней версии — это ошибка настройки; чтобы не запереть всех, её игнорируем
  final minOk = (compareVersions(info.min, info.latest) ?? 1) <= 0;
  final minCmp = compareVersions(current, info.min);
  if (minOk && minCmp != null && minCmp < 0) return UpdateStatus.required;
  if (latestCmp < 0) return dismissed == info.latest ? UpdateStatus.none : UpdateStatus.available;
  return UpdateStatus.none;
}

/// Скачивает apk.json с сайта; при любой ошибке возвращает null.
Future<UpdateInfo?> fetchUpdateInfo(String baseUrl, {http.Client? client}) async {
  try {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final response = await (client ?? http.Client()).get(Uri.parse('${base}apk.json')).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    return UpdateInfo.parse(jsonDecode(utf8.decode(response.bodyBytes)));
  } catch (_) {
    return null;
  }
}

/// Адрес файла приложения на сайте.
String get apkDownloadUrl => '${scheduleBaseUrl.endsWith('/') ? scheduleBaseUrl : '$scheduleBaseUrl/'}unigraf.apk';

// ---------- состояние (в тестах подменяется) ----------

final appVersionProvider = Provider<String>((ref) => appVersion);

/// Проверка включена только в APK для Android с известной версией.
final updateEnabledProvider = Provider<bool>((ref) => !kIsWeb && appVersion.isNotEmpty && scheduleBaseUrl.isNotEmpty);

final updateFetcherProvider = Provider<Future<UpdateInfo?> Function()>((ref) => () => fetchUpdateInfo(scheduleBaseUrl));

/// Открывает загрузку нового APK в браузере телефона. Возвращает false, если не вышло.
final updateOpenerProvider = Provider<Future<bool> Function()>((ref) => () async {
      try {
        return await const MethodChannel('unigraf/system').invokeMethod<bool>('openUrl', {'url': apkDownloadUrl}) ?? false;
      } on PlatformException {
        return false;
      }
    });

class UpdateInfoNotifier extends Notifier<UpdateInfo?> {
  DateTime? _last;

  @override
  UpdateInfo? build() => null;

  /// Спрашивает сайт, не чаще раза в 6 часов. Нет связи — остаётся прежний ответ.
  Future<void> check({bool force = false}) async {
    if (!ref.read(updateEnabledProvider)) return;
    final now = ref.read(clockProvider).now();
    if (!force && _last != null && now.difference(_last!) < const Duration(hours: 6)) return;
    _last = now;
    final info = await ref.read(updateFetcherProvider)();
    if (info != null) state = info;
  }
}

final updateInfoProvider = NotifierProvider<UpdateInfoNotifier, UpdateInfo?>(UpdateInfoNotifier.new);

/// Версия, про которую человек нажал «Позже».
class DismissedUpdateNotifier extends Notifier<String?> {
  static const _key = 'update.dismissed';

  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);

  void dismiss(String version) {
    ref.read(sharedPreferencesProvider).setString(_key, version);
    state = version;
  }
}

final dismissedUpdateProvider = NotifierProvider<DismissedUpdateNotifier, String?>(DismissedUpdateNotifier.new);

final updateStatusProvider = Provider<UpdateStatus>((ref) => computeUpdateStatus(
      current: ref.watch(appVersionProvider),
      info: ref.watch(updateInfoProvider),
      dismissed: ref.watch(dismissedUpdateProvider),
    ));
