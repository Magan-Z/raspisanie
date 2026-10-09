import 'dart:async';

// Общие заглушки для тестов: ассеты с диска, «сервер» с расписанием, запись уведомлений.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raspisanie/data/attachments/attachment_store.dart';
import 'package:raspisanie/domain/attachment.dart';
import 'package:raspisanie/domain/notification_plan.dart';
import 'package:raspisanie/notifications/notification_gateway.dart';
import 'package:raspisanie/widget_bridge/deep_links.dart';

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

/// Поддельное хранилище вложений: файлы копируются во временную папку теста.
class FakeAttachmentStore implements AttachmentStore {
  FakeAttachmentStore() : dir = Directory.systemTemp.createTempSync('attachments_test');
  final Directory dir;
  final deleted = <String>[];
  final opened = <String>[];

  @override
  Future<Attachment> save(PickedFileInfo picked) async {
    final target = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}_${picked.name}';
    File(picked.path).copySync(target);
    return Attachment(name: picked.name, path: target, sizeBytes: picked.sizeBytes);
  }

  @override
  Future<void> delete(Attachment a) async {
    deleted.add(a.name);
    final f = File(a.path);
    if (f.existsSync()) f.deleteSync();
  }

  @override
  bool exists(Attachment a) => File(a.path).existsSync();

  @override
  Future<String?> open(Attachment a) async {
    opened.add(a.name);
    return null;
  }
}

/// Поддельное окно выбора: возвращает заранее заданные файлы.
class FakeAttachmentPicker implements AttachmentPicker {
  FakeAttachmentPicker(this.files);
  final List<PickedFileInfo> files;

  @override
  Future<List<PickedFileInfo>> pickFiles() async => files;

  @override
  Future<List<PickedFileInfo>> pickImages() async => files;

  @override
  Future<PickedFileInfo?> takePhoto() async => files.isEmpty ? null : files.first;
}

/// Поддельный канал ссылок: тест сам «присылает» ссылку, как будто нажали быстрое действие на значке.
class FakeLinks extends LinkChannel {
  FakeLinks() : super(channel: const MethodChannel('raspisanie/links_test'));
  void Function(String link)? _listener;

  @override
  Future<String?> initialLink() async => null;

  @override
  void listen(void Function(String link) onLink) => _listener = onLink;

  void send(String link) => _listener?.call(link);
}
