// Контрольные факты для ScheduleResolver (АРХИТЕКТУРА.md, §11).
// Данные — настоящий результат парсера: test/fixtures/*.json.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/core/bells.dart';
import 'package:raspisanie/core/week.dart';
import 'package:raspisanie/domain/homework_due.dart';
import 'package:raspisanie/domain/models.dart';
import 'package:raspisanie/domain/schedule_resolver.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final index = ScheduleIndex.fromJson(_fixture('index.json'));
  final schedule = GroupSchedule.fromJson(_fixture('ofo-1-bi-25.json'));
  const profile = UserProfile(formCode: 'ofo', groupId: 'ofo-1-bi-25', subgroup: 1, pe: PeChoice.male);

  List<ResolvedLesson> on(int month, int day, [UserProfile p = profile, List<Override> o = const []]) =>
      resolve(DateTime.utc(2026, month, day), index, schedule, p, overrides: o);

  group('Номер недели (§1.6)', () {
    final anchor = DateTime.utc(2026, 8, 31);
    for (final d in ['2026-08-31', '2026-09-05', '2026-09-14', '2026-10-12', '2027-01-04', '2027-07-05']) {
      test('$d → 1', () => expect(weekNumber(parseDay(d), anchor), 1));
    }
    for (final d in ['2026-09-07', '2026-10-05', '2026-10-08', '2026-12-28', '2027-01-02', '2027-07-12']) {
      test('$d → 2', () => expect(weekNumber(parseDay(d), anchor), 2));
    }
  });

  test('07.10.2026 (ср, 2 неделя): ТП в 13:00 и ЧТК практика 2-15, без кураторского часа', () {
    final lessons = on(10, 7);
    expect(lessons, hasLength(2));
    expect(lessons[0].subject, 'Технологическое предпринимательство');
    expect(moscowTimeText(lessons[0].startAt), '13:00');
    expect(lessons[1].subject, 'ЧТК и этика');
    expect(lessons[1].kind, LessonKind.practice);
    expect(lessons[1].room, '2-15');
    expect(moscowTimeText(lessons[1].startAt), '14:40');
    expect(lessons[1].startAt, DateTime.utc(2026, 10, 7, 11, 40)); // как в .ics
  });

  test('14.10.2026 (ср, 1 неделя): ТП, ЧТК лекция 2-07, кураторский час 16:20 в 2-05', () {
    final lessons = on(10, 14);
    expect(lessons, hasLength(3));
    expect(lessons[1].subject, 'ЧТК и этика');
    expect(lessons[1].kind, LessonKind.lecture);
    expect(lessons[1].room, '2-07');
    expect(lessons[2].subject, 'Кураторский час');
    expect(moscowTimeText(lessons[2].startAt), '16:20');
    expect(lessons[2].room, '2-05');
  });

  test('09.10.2026 (пт): физ-ра девушек отфильтрована → 0 пар', () {
    expect(on(10, 9), isEmpty);
    // А с профилем «девушки» пара есть
    expect(on(10, 9, profile.copyWith(pe: PeChoice.female)), hasLength(1));
  });

  test('11.10.2026 (вс) → 0 пар', () => expect(on(10, 11), isEmpty));
  test('04.11.2026 (праздник) → 0 пар', () => expect(on(11, 4), isEmpty));
  test('Вне семестра → 0 пар', () => expect(on(8, 31), isEmpty));

  test('Понедельник: у п/г 2 в 4 пару иностранный язык, у п/г 1 — ТБК', () {
    final p1 = on(10, 5).firstWhere((l) => l.pair == 4);
    final p2 = on(10, 5, profile.copyWith(subgroup: 2)).firstWhere((l) => l.pair == 4);
    expect(p1.subject, 'Технологии бизнес-коммуникаций');
    expect(p2.subject, 'Иностранный язык');
    expect(p2.room, '2-16');
  });

  test('Личные правки: отмена, замена, добавление', () {
    final day = DateTime.utc(2026, 10, 7);
    final lessons = on(10, 7, profile, [
      Override(date: day, pair: 3, type: OverrideType.cancel),
      Override(date: day, pair: 4, type: OverrideType.replace, room: '3-01'),
      Override(date: day, pair: 1, type: OverrideType.add, subject: 'Консультация'),
    ]);
    expect(lessons.map((l) => l.pair), [1, 4]);
    expect(lessons[0].subject, 'Консультация');
    expect(lessons[1].room, '3-01');
    expect(lessons[1].subject, 'ЧТК и этика');
    expect(lessons[1].isPersonal, isTrue);
  });

  test('Ручной выбор недели меняет набор пар', () {
    final forced = resolve(DateTime.utc(2026, 10, 7), index, schedule, profile, forcedWeek: 1);
    expect(forced, hasLength(3));
  });

  test('ДЗ по «Аккаунтингу» от вторника → четверг (§9, этап 4)', () {
    final due = nextOccurrence('Аккаунтинг и аудит', DateTime.utc(2026, 10, 6), index, schedule, profile);
    expect(due, DateTime.utc(2026, 10, 8));
    // «к лекции» — следующий вторник
    final dueLecture = nextOccurrence('Аккаунтинг и аудит', DateTime.utc(2026, 10, 6), index, schedule, profile,
        kind: LessonKind.lecture);
    expect(dueLecture, DateTime.utc(2026, 10, 13));
  });

  test('Ближайший учебный день после воскресенья — понедельник', () {
    expect(nextStudyDay(DateTime.utc(2026, 10, 11), index, schedule, profile), DateTime.utc(2026, 10, 12));
  });
}
