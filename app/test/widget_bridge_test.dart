// Мост с виджетами: отправка снимка и разбор ссылок «+ ДЗ».

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/domain/attachment.dart';
import 'package:raspisanie/domain/homework.dart';
import 'package:raspisanie/domain/models.dart';
import 'package:raspisanie/domain/widget_snapshot.dart';
import 'package:raspisanie/theme/brand_colors.dart';
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
    test('ссылка «открыть ДЗ» (виджет «Домашка»)', () {
      expect(parseAnyLink('raspisanie://homework'), isA<OpenHomeworkLink>());
      expect(parseAnyLink('raspisanie://homework/'), isA<OpenHomeworkLink>());
      expect(parseAnyLink('raspisanie://homework/new?subject=X'), isA<AddHomeworkLink>());
      expect(parseAnyLink('raspisanie://settings'), isNull);
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
    const channel = MethodChannel('home_widget');

    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    test('снимок уходит в нативную часть одной строкой JSON, затем оба виджета обновляются', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      await const WidgetBridge().push(
        now: DateTime.utc(2026, 10, 7, 5, 0),
        index: index,
        schedule: schedule,
        profile: profile,
        homework: const [],
      );

      expect(calls.map((c) => c.method), ['saveWidgetData', ...List.filled(7, 'updateWidget')]);
      expect(calls.first.arguments['id'], 'snapshot');
      expect((calls[1].arguments as Map)['qualifiedAndroidName'], 'ru.raspisanie.raspisanie.widget.NowNextWidget');
      expect((calls[2].arguments as Map)['qualifiedAndroidName'], 'ru.raspisanie.raspisanie.widget.TodayWidget');
      final snapshot = jsonDecode(calls.first.arguments['data'] as String) as Map<String, dynamic>;
      expect(snapshot['weekLabel'], '2 неделя');
      expect((snapshot['days'] as List), hasLength(7));
      final first = ((snapshot['days'] as List).first as Map)['lessons'] as List;
      expect(first.first['start'], '2026-10-07T13:00+03:00');
    });

    test('в снимке: ближайшие невыполненные ДЗ по срокам и цвета выбранной темы', () {
      HomeworkItem hw(String subject, int day, {bool done = false, int files = 0}) => HomeworkItem(
            subject: subject,
            text: 'Задание $subject',
            dueDate: DateTime.utc(2026, 10, day),
            createdAt: DateTime.utc(2026, 10, 1),
            done: done,
            attachments: [for (var i = 0; i < files; i++) Attachment(name: 'f$i.pdf', path: '/x')],
          );
      final snapshot = buildWidgetSnapshot(
        now: DateTime.utc(2026, 10, 7, 5, 0),
        index: index,
        schedule: schedule,
        profile: profile,
        homework: [hw('Философия', 14), hw('Физика', 8, files: 2), hw('Сделано', 9, done: true)],
        palette: AppPalette.ocean,
        amoled: true,
      );
      expect(snapshot['homeworkCount'], 2);
      final list = snapshot['homework'] as List;
      expect(list.map((h) => h['subject']), ['Физика', 'Философия']); // по сроку, без выполненных
      expect(list.first['due'], '2026-10-08');
      expect(list.first['files'], 2);

      final colors = snapshot['colors'] as Map;
      expect(colors['light']['bg'], matches(RegExp(r'^#[0-9A-F]{6}$')));
      expect(colors['dark']['bg'], '#121314'); // чёрный фон: карточка виджета — тёмно-серая, не цвет темы
      expect(colors['light']['accent'], isNot(colors['dark']['accent']));
    });

    test('без выбранной темы цветов в снимке нет (виджет остаётся в стандартных)', () {
      final snapshot = buildWidgetSnapshot(
          now: DateTime.utc(2026, 10, 7, 5, 0), index: index, schedule: schedule, profile: profile, homework: const []);
      expect(snapshot.containsKey('colors'), isFalse);
      expect(snapshot['homework'], isEmpty);
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
