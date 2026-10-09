import 'dart:async';

// Общие заглушки для тестов: ассеты с диска, «сервер» с расписанием, запись уведомлений.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raspisanie/data/attachments/attachment_store.dart';
import 'package:raspisanie/data/remote/shared_api.dart';
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
    if (picked.path != null) {
      File(picked.path!).copySync(target);
    } else {
      File(target).writeAsBytesSync(await picked.readBytes!());
    }
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
  Future<Uint8List?> readBytes(Attachment a) async => exists(a) ? File(a.path).readAsBytesSync() : null;

  @override
  Future<String?> open(Attachment a) async {
    opened.add(a.name);
    return null;
  }

  @override
  Widget image(Attachment a, {double? width, double? height, BoxFit? fit, int? cacheWidth}) => SizedBox(width: width, height: height);
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


/// Поддельный сервер старост в памяти: те же вызовы, что у настоящего (get_group_data, redeem_code, put_/delete_…).
/// Позволяет проверять сквозные сценарии без интернета.
class FakeBackend {
  FakeBackend({this.hash = 'h-test'});

  /// Хеш расписания группы, к которому относятся правки (как в index.json).
  final String hash;
  final overrides = <String, Map<String, dynamic>>{};
  final homework = <String, Map<String, dynamic>>{};
  final files = <String, ({String name, List<int> bytes})>{}; // загруженные файлы группы
  final calls = <String>[];
  var _clock = 0;
  final validCodes = {'GOODCODE': 'ofo-1-bi-25'};
  final usedCodes = <String>{};

  String _stamp() => DateTime.utc(2026, 10, 9, 12, 0, _clock++).toIso8601String();

  Map<String, dynamic> override({String id = 'o1', int pair = 4, String type = 'replace', String? room = '3-33', String? hash, String date = '2026-10-07', String? note}) => {
        'id': id, 'base_hash': hash ?? this.hash, 'date': date, 'pair': pair, 'type': type,
        'subject': null, 'room': room, 'teacher': null, 'note': note, 'kind': null, 'repeat_weekly': false, 'match_subject': null,
        'deleted': false, 'updated_at': _stamp(),
      };

  Map<String, dynamic> hw({String id = 'h1', String subject = 'Философия', String text = 'Читать главу 3', String due = '2026-10-14', List<Map<String, dynamic>> files = const []}) =>
      {'id': id, 'subject': subject, 'body': text, 'due_date': due, 'kind': null, 'files': files, 'deleted': false, 'updated_at': _stamp()};

  SharedApi api() => SharedApi('https://fake.test', 'key', client: MockClient((request) async {
        final fn = request.url.pathSegments.last;
        final args = request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;
        calls.add(fn);
        http.Response ok(Object? body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
        http.Response fail(String message) => http.Response.bytes(utf8.encode(jsonEncode({'message': message})), 400);

        switch (fn) {
          case 'get_group_data':
            final since = args['p_since'] as String?;
            bool wanted(Map<String, dynamic> r) =>
                since == null ? r['deleted'] != true : DateTime.parse(r['updated_at'] as String).isAfter(DateTime.parse(since));
            return ok({
              'server_time': DateTime.utc(2026, 10, 9, 12, 5).toIso8601String(),
              'overrides': overrides.values.where(wanted).toList(),
              'homework': homework.values.where(wanted).toList(),
            });
          case 'redeem_code':
            final code = (args['p_code'] as String).trim().toUpperCase();
            if (!validCodes.containsKey(code)) return fail('bad_code');
            if (!usedCodes.add(code)) return fail('code_used');
            return ok({'group_id': validCodes[code], 'token': 'tok-$code'});
          case 'put_group_override':
            final row = Map<String, dynamic>.from(args['p_row'] as Map)..['deleted'] = false..['updated_at'] = '2026-10-09T13:00:${(_clock++).toString().padLeft(2, '0')}+00:00';
            overrides[row['id'] as String] = row;
            return ok(row['id']);
          case 'delete_group_override':
            overrides[args['p_id']]?['deleted'] = true;
            overrides[args['p_id']]?['updated_at'] = '2026-10-09T13:30:${(_clock++).toString().padLeft(2, '0')}+00:00';
            return http.Response('', 204);
          case 'put_group_homework':
            final row = Map<String, dynamic>.from(args['p_row'] as Map)..['deleted'] = false..['updated_at'] = '2026-10-09T13:00:${(_clock++).toString().padLeft(2, '0')}+00:00';
            homework[row['id'] as String] = row;
            return ok(row['id']);
          case 'delete_group_homework':
            homework[args['p_id']]?['deleted'] = true;
            homework[args['p_id']]?['updated_at'] = '2026-10-09T13:30:${(_clock++).toString().padLeft(2, '0')}+00:00';
            return http.Response('', 204);
          case 'put_group_file':
            if (args['p_token'] == null) return fail('bad_token');
            files[args['p_id'] as String] = (name: args['p_name'] as String, bytes: base64Decode(args['p_data'] as String));
            return http.Response('', 204);
          case 'get_group_file':
            final f = files[args['p_id']];
            if (f == null) return fail('no_file');
            return ok({'name': f.name, 'data': base64Encode(f.bytes)});
          case 'clear_stale_group_overrides':
            var n = 0;
            for (final o in overrides.values) {
              if (o['deleted'] != true && o['base_hash'] != args['p_keep_hash']) {
                o['deleted'] = true;
                o['updated_at'] = '2026-10-09T13:40:${(_clock++).toString().padLeft(2, '0')}+00:00';
                n++;
              }
            }
            return ok(n);
        }
        return fail('unknown $fn');
      }));
}
