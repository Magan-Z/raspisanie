// Общие данные группы: разбор ответов сервера, дельта-обновление, ошибки и кэш.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/remote/shared_api.dart';
import 'package:raspisanie/data/repositories/group_shared_repository.dart';
import 'package:raspisanie/domain/group_shared.dart';
import 'package:raspisanie/domain/models.dart';

/// Поддельный сервер: запоминает вызовы и отвечает заранее заданным.
class FakeServer {
  final calls = <String, List<Map<String, dynamic>>>{};
  final responses = <String, Object Function(Map<String, dynamic> args)>{};
  int failWith = 0; // HTTP-код ошибки (0 — без ошибки)
  String failMessage = '';

  http.Client get client => MockClient((request) async {
        final fn = request.url.pathSegments.last;
        final args = request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;
        calls.putIfAbsent(fn, () => []).add(args);
        expect(request.headers['apikey'], 'test-key');
        expect(request.url.path, startsWith('/rest/v1/rpc/'));
        if (failWith != 0) return http.Response.bytes(utf8.encode(jsonEncode({'message': failMessage})), failWith);
        final response = responses[fn];
        if (response == null) return http.Response('', 204);
        return http.Response.bytes(utf8.encode(jsonEncode(response(args))), 200);
      });
}

Map<String, dynamic> _override(String id, {String hash = 'h1', String room = '3-33', bool deleted = false, int pair = 4}) => {
      'id': id,
      'base_hash': hash,
      'date': '2026-10-14',
      'pair': pair,
      'type': 'replace',
      'subject': null,
      'room': room,
      'teacher': null,
      'note': 'староста',
      'kind': null,
      'repeat_weekly': false,
      'match_subject': null,
      'deleted': deleted,
      'updated_at': '2026-10-09T12:00:00+00:00',
    };

Map<String, dynamic> _homework(String id, {String text = 'Читать главу 3', bool deleted = false}) => {
      'id': id,
      'subject': 'Философия',
      'body': text,
      'due_date': '2026-10-14',
      'kind': null,
      'deleted': deleted,
      'updated_at': '2026-10-09T12:00:00+00:00',
    };

void main() {
  group('Разбор и слияние (GroupSharedState)', () {
    test('полная загрузка: правки и ДЗ читаются, дата — день без времени', () {
      final state = GroupSharedState.empty.replaceWith({
        'server_time': '2026-10-09T12:00:00.5+00:00',
        'overrides': [_override('a')],
        'homework': [_homework('h')],
      });
      expect(state.overrides['a']!.room, '3-33');
      expect(state.overrides['a']!.date, DateTime.utc(2026, 10, 14));
      expect(state.overrides['a']!.type, OverrideType.replace);
      expect(state.homeworkList.single.text, 'Читать главу 3');
      expect(state.since, '2026-10-09T12:00:00.5+00:00');
    });

    test('дельта: изменённая строка заменяется, удалённая пропадает, новая добавляется', () {
      var state = GroupSharedState.empty.replaceWith({
        'server_time': 't1',
        'overrides': [_override('a'), _override('b', pair: 3)],
        'homework': [_homework('h')],
      });
      state = state.merge({
        'server_time': 't2',
        'overrides': [_override('a', room: '1-11'), _override('b', deleted: true), _override('c', pair: 2)],
        'homework': [_homework('h', deleted: true)],
      });
      expect(state.overrides.keys.toSet(), {'a', 'c'});
      expect(state.overrides['a']!.room, '1-11');
      expect(state.homework, isEmpty);
      expect(state.since, 't2');
    });

    test('правки к старому расписанию (другой хеш) не действуют', () {
      final state = GroupSharedState.empty.replaceWith({
        'overrides': [_override('a', hash: 'старый'), _override('b', hash: 'новый')],
        'homework': [],
      });
      expect(state.activeOverrides('новый').map((o) => o.id), ['b']);
      expect(state.staleOverrides('новый').map((o) => o.id), ['a']);
      expect(state.activeOverrides(null), hasLength(2)); // хеш неизвестен — ничего не прячем
    });

    test('преобразование в Override помечает правку как правку старосты', () {
      final o = GroupSharedState.empty.replaceWith({'overrides': [_override('a')], 'homework': []}).overrides['a']!.toOverride();
      expect(o.fromGroup, isTrue);
      expect(o.remoteId, 'a');
      expect(o.room, '3-33');
    });

    test('кэш: сохранить и прочитать без потерь', () {
      final state = GroupSharedState.empty.replaceWith({
        'server_time': 't1',
        'overrides': [_override('a')],
        'homework': [_homework('h')],
      }, now: DateTime.utc(2026, 10, 9, 12));
      final back = GroupSharedState.decode(state.encode());
      expect(back.overrides['a']!.room, '3-33');
      expect(back.homework['h']!.text, 'Читать главу 3');
      expect(back.since, 't1');
      expect(back.syncedAt, DateTime.utc(2026, 10, 9, 12));
    });
  });

  group('SharedApi', () {
    late FakeServer server;
    late SharedApi api;
    setUp(() {
      server = FakeServer();
      api = SharedApi('https://example.test/', 'test-key', client: server.client);
    });

    test('ввод кода: возвращает группу и токен', () async {
      server.responses['redeem_code'] = (_) => {'group_id': 'ofo-1-bi-25', 'token': 'секрет'};
      final session = await api.redeem('ABCD123456');
      expect(session.groupId, 'ofo-1-bi-25');
      expect(session.token, 'секрет');
      expect(server.calls['redeem_code']!.single['p_code'], 'ABCD123456');
    });

    test('ошибки сервера превращаются в понятные сообщения', () async {
      for (final (message, text) in [
        ('bad_code', 'Код не подошёл'),
        ('code_used', 'уже использован'),
        ('bad_token', 'отозван'),
        ('too_many', 'Слишком много'),
      ]) {
        server.failWith = 400;
        server.failMessage = message;
        await expectLater(
          api.redeem('x'),
          throwsA(isA<SharedApiException>().having((e) => e.code, 'code', message).having((e) => e.message, 'message', contains(text))),
        );
      }
    });

    test('неизвестная ошибка — «ошибка сервера» с подробностью', () async {
      server.failWith = 500;
      server.failMessage = 'что-то сломалось';
      await expectLater(api.getGroupData('ofo-1-bi-25'), throwsA(isA<SharedApiException>().having((e) => e.message, 'message', contains('что-то сломалось'))));
    });

    test('нет сети — «нет связи»', () async {
      final offline = SharedApi('https://example.test', 'k', client: MockClient((_) async => throw http.ClientException('нет сети')));
      await expectLater(offline.getGroupData('ofo-1-bi-25'), throwsA(isA<SharedApiException>().having((e) => e.code, 'code', 'network')));
    });

    test('запись правки и ДЗ отправляет токен и строку', () async {
      final row = GroupOverrideRow.fromJson(_override('a'));
      await api.putOverride('tok', row);
      await api.putHomework('tok', GroupHomeworkRow.fromJson(_homework('h')));
      await api.deleteOverride('tok', 'a');
      await api.deleteHomework('tok', 'h');
      expect(server.calls['put_group_override']!.single['p_token'], 'tok');
      expect((server.calls['put_group_override']!.single['p_row'] as Map)['room'], '3-33');
      expect((server.calls['put_group_homework']!.single['p_row'] as Map)['body'], 'Читать главу 3');
      expect(server.calls['delete_group_override']!.single['p_id'], 'a');
      expect(server.calls['delete_group_homework']!.single['p_id'], 'h');
    });

    test('адрес склеивается правильно с / на конце и без него', () async {
      server.responses['get_group_data'] = (_) => {'server_time': 't', 'overrides': [], 'homework': []};
      await SharedApi('https://example.test', 'test-key', client: server.client).getGroupData('ofo-1-bi-25');
      await api.getGroupData('ofo-1-bi-25');
      expect(server.calls['get_group_data'], hasLength(2));
    });
  });

  group('GroupSharedRepository', () {
    late AppDatabase db;
    late FakeServer server;
    late GroupSharedRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      server = FakeServer();
      repo = GroupSharedRepository(db, SharedApi('https://example.test', 'test-key', client: server.client));
    });
    tearDown(() => db.close());

    test('первый раз грузит всё (без p_since), потом — только изменения с запасом в минуту', () async {
      server.responses['get_group_data'] = (args) => args.containsKey('p_since')
          ? {'server_time': '2026-10-09T12:10:00+00:00', 'overrides': [_override('a', room: '1-11')], 'homework': []}
          : {'server_time': '2026-10-09T12:00:00+00:00', 'overrides': [_override('a')], 'homework': [_homework('h')]};

      final first = await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 12));
      expect(server.calls['get_group_data']!.first.containsKey('p_since'), isFalse);
      expect(first.state.overrides['a']!.room, '3-33');
      expect(first.newHomework.single.id, 'h');

      final second = await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 12, 10));
      final since = server.calls['get_group_data']!.last['p_since'] as String;
      expect(DateTime.parse(since), DateTime.utc(2026, 10, 9, 11, 59)); // 12:00 минус минута запаса
      expect(second.state.overrides['a']!.room, '1-11'); // изменилось
      expect(second.state.homework, hasLength(1)); // ДЗ не потерялось
      expect(second.newHomework, isEmpty);
    });

    test('новое ДЗ в дельте попадает в newHomework (для уведомления)', () async {
      server.responses['get_group_data'] = (args) => args.containsKey('p_since')
          ? {'server_time': 't2', 'overrides': [], 'homework': [_homework('h2', text: 'Новое')]}
          : {'server_time': '2026-10-09T12:00:00+00:00', 'overrides': [], 'homework': [_homework('h')]};
      await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 12));
      final r = await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 13));
      expect(r.newHomework.map((h) => h.id), ['h2']);
    });

    test('кэш живёт между запусками, ошибка сети его не стирает', () async {
      server.responses['get_group_data'] = (_) => {'server_time': '2026-10-09T12:00:00+00:00', 'overrides': [_override('a')], 'homework': []};
      await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 12));

      server.failWith = 500;
      server.failMessage = 'упало';
      await expectLater(repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 13)), throwsA(isA<SharedApiException>()));
      expect((await repo.cached('ofo-1-bi-25')).overrides.keys, ['a']);
      expect((await repo.cached('другая-группа')).overrides, isEmpty);
    });

    test('если телефон давно не обновлялся (> 20 дней) — загрузка заново целиком', () async {
      server.responses['get_group_data'] = (_) => {'server_time': '2026-10-09T12:00:00+00:00', 'overrides': [_override('a')], 'homework': []};
      await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 10, 9, 12));
      await repo.sync('ofo-1-bi-25', now: DateTime.utc(2026, 11, 20));
      expect(server.calls['get_group_data']!.last.containsKey('p_since'), isFalse);
    });

    test('повреждённый кэш не ломает приложение', () async {
      await db.customStatement("INSERT INTO group_shared_cache (group_id, json) VALUES ('ofo-1-bi-25', 'не json')");
      expect((await repo.cached('ofo-1-bi-25')).overrides, isEmpty);
    });

    test('newUuid: формат UUID v4, значения не повторяются', () {
      final a = newUuid(), b = newUuid();
      expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(a, isNot(b));
    });
  });
}
