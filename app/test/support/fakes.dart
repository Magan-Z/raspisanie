import 'dart:async';

// Общие заглушки для тестов: ассеты с диска, «сервер» с расписанием, запись уведомлений.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raspisanie/domain/notification_plan.dart';
import 'package:raspisanie/notifications/notification_gateway.dart';

/// Ассеты читаются прямо с диска и без ожидания — в тестах так надёжнее, чем настоящий rootBundle.
class DiskAssets extends AssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(Uint8List.fromList(File(key).readAsBytesSync()));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => utf8.decode(File(key).readAsBytesSync());

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) async => parser(await loadString(key));
}

/// Сервер, который отдаёт файлы из словаря и считает запросы.
class FakeSite {
  FakeSite(this.files);
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

/// Вместо настоящих уведомлений — запись того, что приложение собиралось показать.
class FakeGateway implements NotificationGateway {
  final plans = <List<PlannedNotification>>[];
  final shown = <String>[];
  int permissionRequests = 0;
  final tapController = StreamController<String>.broadcast();
  String? startPayload;

  @override
  Stream<String> get taps => tapController.stream;

  @override
  Future<String?> launchPayload() async => startPayload;

  List<PlannedNotification> get lastPlan => plans.isEmpty ? const [] : plans.last;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<bool> areEnabled() async => true;

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async => plans.add(plan);

  @override
  Future<void> showNow({required int id, required String title, required String body, NotificationChannel channel = NotificationChannel.updates}) async =>
      shown.add(title);
}
