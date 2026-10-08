// Данные для виджетов (§7.6) и план уведомлений (§7.7) на контрольных фактах из §11.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/domain/homework.dart';
import 'package:raspisanie/domain/models.dart';
import 'package:raspisanie/domain/notification_plan.dart';
import 'package:raspisanie/domain/widget_snapshot.dart';
import 'package:raspisanie/core/formatting.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final index = ScheduleIndex.fromJson(_fixture('index.json'));
  final schedule = GroupSchedule.fromJson(_fixture('ofo-1-bi-25.json'));
  const profile = UserProfile(formCode: 'ofo', groupId: 'ofo-1-bi-25', subgroup: 1, pe: PeChoice.male);

  // Среда 7 октября 2026, 08:00 по Москве (05:00 UTC), 2 неделя
  final morning = DateTime.utc(2026, 10, 7, 5, 0);

  HomeworkItem hw(String subject, DateTime due) =>
      HomeworkItem(subject: subject, text: 'задание', dueDate: due, createdAt: DateTime.utc(2026, 10, 1));

  group('Снимок для виджетов', () {
    final snapshot = buildWidgetSnapshot(
      now: morning,
      index: index,
      schedule: schedule,
      profile: profile,
      homework: [hw('ЧТК и этика', DateTime.utc(2026, 10, 7))],
    );
    final days = snapshot['days'] as List;

    test('7 дней, подпись недели', () {
      expect(days, hasLength(7));
      expect(snapshot['weekLabel'], '2 неделя');
      expect((days.first as Map)['date'], '2026-10-07');
      expect((days.last as Map)['date'], '2026-10-13');
    });

    test('среда 7 октября: 2 пары со временем по Москве и значком ДЗ', () {
      final lessons = (days.first as Map)['lessons'] as List;
      expect(lessons, hasLength(2));
      expect(lessons[0]['start'], '2026-10-07T13:00+03:00');
      expect(lessons[0]['end'], '2026-10-07T14:30+03:00');
      expect(lessons[0]['hasHomework'], isFalse);
      expect(lessons[1]['subject'], 'ЧТК и этика');
      expect(lessons[1]['room'], '2-15');
      expect(lessons[1]['start'], '2026-10-07T14:40+03:00');
      expect(lessons[1]['hasHomework'], isTrue);
    });

    test('воскресенье — день без пар', () {
      final sunday = days.firstWhere((d) => (d as Map)['date'] == '2026-10-11') as Map;
      expect(sunday['lessons'], isEmpty);
    });

    test('короткие названия не длиннее лимита и читаются', () {
      expect(shortSubject('Физика'), 'Физика');
      expect(shortSubject('Технологическое предпринимательство').length, lessThanOrEqualTo(24));
      expect(shortSubject('Технологическое предпринимательство'), isNot(contains('Технологическое предпринимательство')));
    });

    test('снимок кодируется в JSON и читается обратно', () {
      expect(jsonDecode(encodeWidgetSnapshot(snapshot)), snapshot);
    });
  });

  group('План уведомлений', () {
    List<PlannedNotification> plan({DateTime? now, int before = 10, bool evening = true, List<HomeworkItem> homework = const []}) =>
        planNotifications(
          now: now ?? morning,
          index: index,
          schedule: schedule,
          profile: profile,
          homework: homework,
          notifyBeforeMin: before,
          eveningReminder: evening,
        );

    test('перед парой: за 10 минут, текст «предмет → аудитория»', () {
      final first = plan().first;
      expect(first.title, 'Технологическое предпринимательство → 2-05');
      expect(first.fireAt, DateTime.utc(2026, 10, 7, 9, 50)); // 12:50 МСК, пара в 13:00
      expect(first.body, 'Халиев М.С-У. · через 10 мин');
    });

    test('прошедшие пары не планируются', () {
      // 14:00 по Москве: пара в 13:00 уже идёт, уведомление за 10 мин до неё в прошлом
      final afterFirst = plan(now: DateTime.utc(2026, 10, 7, 11, 0));
      expect(afterFirst.first.title, startsWith('ЧТК и этика'));
    });

    test('0 минут — уведомления перед парой выключены', () {
      expect(plan(before: 0), isEmpty);
    });

    test('вечером в 19:00 — напоминание о ДЗ на завтра', () {
      final notes = plan(before: 0, homework: [
        hw('Аккаунтинг и аудит', DateTime.utc(2026, 10, 8)),
        hw('Графический дизайн', DateTime.utc(2026, 10, 8)),
        hw('Философия', DateTime.utc(2026, 10, 9)),
      ]);
      expect(notes.first.title, 'На завтра 2 ДЗ');
      expect(notes.first.body, 'Аккаунтинг и аудит, Графический дизайн');
      expect(notes.first.fireAt, DateTime.utc(2026, 10, 7, 16, 0)); // 19:00 МСК
      expect(notes[1].title, 'На завтра 1 ДЗ'); // 8 октября вечером — про 9-е
    });

    test('выполненное ДЗ не напоминается; напоминание можно выключить', () {
      final done = hw('Философия', DateTime.utc(2026, 10, 8)).copyWith(done: true);
      expect(plan(before: 0, homework: [done]), isEmpty);
      expect(plan(before: 0, evening: false, homework: [hw('Философия', DateTime.utc(2026, 10, 8))]), isEmpty);
    });

    test('номера уникальны и стабильны, список по времени', () {
      final a = plan(homework: [hw('Философия', DateTime.utc(2026, 10, 8))]);
      final b = plan(homework: [hw('Философия', DateTime.utc(2026, 10, 8))]);
      expect(a.map((n) => n.id).toList(), b.map((n) => n.id).toList());
      expect(a.map((n) => n.id).toSet().length, a.length);
      for (var i = 1; i < a.length; i++) {
        expect(a[i].fireAt.isBefore(a[i - 1].fireAt), isFalse);
      }
      expect(a.every((n) => n.id < 2147483647), isTrue);
    });
  });
}
