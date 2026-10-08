// Мост с виджетами: отправка снимка и разбор ссылок «+ ДЗ».

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/domain/models.dart';
import 'package:raspisanie/widget_bridge/deep_links.dart';
import 'package:raspisanie/widget_bridge/widget_sync.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ссылки', () {
    test('«+ ДЗ» с предметом (в том числе с пробелами и кириллицей)', () {
      final link = parseLink('raspisanie://homework/new?subject=${Uri.encodeQueryComponent('Аккаунтинг и аудит')}');
      expect(link?.subject, 'Аккаунтинг и аудит');
    });
    test('«+ ДЗ» без предмета', () {
      expect(parseLink('raspisanie://homework/new'), isNotNull);
      expect(parseLink('raspisanie://homework/new')?.subject, isNull);
      expect(parseLink('raspisanie://homework/new?subject=')?.subject, isNull);
    });
    test('чужие и неправильные ссылки игнорируются', () {
      expect(parseLink(null), isNull);
      expect(parseLink('https://example.com/homework/new'), isNull);
      expect(parseLink('raspisanie://settings'), isNull);
      expect(parseLink('не ссылка'), isNull);
    });
  });

  group('Передача снимка виджетам', () {
    final index = ScheduleIndex.fromJson(_fixture('index.json'));
    final schedule = GroupSchedule.fromJson(_fixture('ofo-1-bi-25.json'));
    const profile = UserProfile(formCode: 'ofo', groupId: 'ofo-1-bi-25', subgroup: 1, pe: PeChoice.male);
    const channel = MethodChannel('raspisanie/widget');

    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    test('снимок уходит в нативную часть одной строкой JSON', () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return null;
      });

      await const WidgetBridge().push(
        now: DateTime.utc(2026, 10, 7, 5, 0),
        index: index,
        schedule: schedule,
        profile: profile,
        homework: const [],
      );

      expect(received?.method, 'saveSnapshot');
      final snapshot = jsonDecode(received!.arguments as String) as Map<String, dynamic>;
      expect(snapshot['weekLabel'], '2 неделя');
      expect((snapshot['days'] as List), hasLength(7));
      final first = ((snapshot['days'] as List).first as Map)['lessons'] as List;
      expect(first.first['start'], '2026-10-07T13:00+03:00');
    });

    test('не Android (канала нет) — молча, без ошибок', () async {
      await const WidgetBridge().push(
        now: DateTime.utc(2026, 10, 7, 5, 0), index: index, schedule: schedule, profile: profile, homework: const [],
      );
    });

    test('нативная сторона отказала — не падаем', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'boom'));
      await const WidgetBridge().push(
        now: DateTime.utc(2026, 10, 7, 5, 0), index: index, schedule: schedule, profile: profile, homework: const [],
      );
    });
  });
}
