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
  test('Праздник из настроек → 0 пар (в самих настройках праздников сейчас нет — задаём в тесте)', () {
    expect(on(11, 4), isNotEmpty); // без праздника в среду пары есть
    final withHoliday = ScheduleIndex.fromJson({
      ..._fixture('index.json'),
      'holidays': ['2026-11-04'],
    });
    expect(resolve(DateTime.utc(2026, 11, 4), withHoliday, schedule, profile), isEmpty);
  });
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

  group('Правки «каждую неделю» и переносы', () {
    // Среда 07.10 (2 неделя): 3 пара — Технологическое предпринимательство 2-05; 4 пара — ЧТК и этика (практика 2-15)
    final wed = DateTime.utc(2026, 10, 7);

    List<ResolvedLesson> day(DateTime d, List<Override> o) => resolve(d, index, schedule, profile, overrides: o);

    test('отмена каждую неделю: действует с этой даты и дальше по средам, раньше — нет', () {
      final rule = Override(date: wed, pair: 3, type: OverrideType.cancel, repeatWeekly: true, matchSubject: 'Технологическое предпринимательство');
      expect(day(wed, [rule]).map((l) => l.pair), [4]);
      expect(day(DateTime.utc(2026, 10, 14), [rule]).map((l) => l.pair), [4, 5]); // следующая среда: пары 4 и кураторский час
      expect(day(DateTime.utc(2026, 10, 21), [rule]).any((l) => l.pair == 3), isFalse);
      expect(day(DateTime.utc(2026, 9, 30), [rule]).any((l) => l.pair == 3), isTrue); // до даты правка не действует
      expect(day(DateTime.utc(2026, 10, 8), [rule]).isNotEmpty, isTrue); // другой день недели не затронут
    });

    test('правило привязано к предмету: на той же паре другой предмет остаётся', () {
      // 4 пара по средам: ЧТК и этика (и на 1-й, и на 2-й неделе), правило про другой предмет её не трогает
      final rule = Override(date: wed, pair: 4, type: OverrideType.cancel, repeatWeekly: true, matchSubject: 'Философия');
      expect(day(wed, [rule]).any((l) => l.pair == 4), isTrue);
    });

    test('замена каждую неделю меняет аудиторию во все следующие среды', () {
      final rule = Override(date: wed, pair: 4, type: OverrideType.replace, room: '3-33', repeatWeekly: true, matchSubject: 'ЧТК и этика');
      expect(day(wed, [rule]).firstWhere((l) => l.pair == 4).room, '3-33');
      final next = day(DateTime.utc(2026, 10, 14), [rule]).firstWhere((l) => l.pair == 4);
      expect(next.room, '3-33');
      expect(next.kind, LessonKind.lecture); // тип занятия остался как в расписании
      expect(next.isPersonal, isTrue);
    });

    test('правка на конкретный день главнее правила «каждую неделю»', () {
      final rule = Override(date: wed, pair: 4, type: OverrideType.replace, room: '3-33', repeatWeekly: true, matchSubject: 'ЧТК и этика');
      final once = Override(date: DateTime.utc(2026, 10, 14), pair: 4, type: OverrideType.replace, room: '1-01');
      expect(day(DateTime.utc(2026, 10, 14), [rule, once]).firstWhere((l) => l.pair == 4).room, '1-01');
      expect(day(DateTime.utc(2026, 10, 21), [rule, once]).firstWhere((l) => l.pair == 4).room, '3-33');
    });

    test('перенос: пара исчезает со старого места и появляется на новом с тем же типом и данными', () {
      final overrides = [
        Override(date: wed, pair: 4, type: OverrideType.cancel),
        Override(date: wed, pair: 5, type: OverrideType.add, subject: 'ЧТК и этика', teacher: 'Ахмадова М.П.', room: '2-15', kind: LessonKind.practice, note: 'перенесено'),
      ];
      final lessons = day(wed, overrides);
      expect(lessons.map((l) => l.pair), [3, 5]);
      final moved = lessons.last;
      expect((moved.subject, moved.room, moved.kind, moved.note), ('ЧТК и этика', '2-15', LessonKind.practice, 'перенесено'));
      expect(moved.isPersonal, isTrue);
    });

    test('перенос на ту же пару другого дня не отменяет сам себя (отмена и добавление на одной паре)', () {
      // Пятница 09.10: переносим сюда ТП 3 пары из среды; отмена в среде, добавление в пятницу
      final overrides = [
        Override(date: wed, pair: 3, type: OverrideType.cancel),
        Override(date: DateTime.utc(2026, 10, 9), pair: 3, type: OverrideType.add, subject: 'Технологическое предпринимательство', room: '2-05', kind: LessonKind.lecture),
      ];
      expect(day(DateTime.utc(2026, 10, 9), overrides).map((l) => l.pair), [3]);
      expect(day(wed, overrides).any((l) => l.pair == 3), isFalse);
    });

    test('перенос каждую неделю: в следующую среду пара тоже уходит, а в следующую пятницу появляется', () {
      final overrides = [
        Override(date: wed, pair: 3, type: OverrideType.cancel, repeatWeekly: true, matchSubject: 'Технологическое предпринимательство'),
        Override(date: DateTime.utc(2026, 10, 9), pair: 5, type: OverrideType.add, subject: 'Технологическое предпринимательство', room: '2-05', kind: LessonKind.lecture, repeatWeekly: true),
      ];
      expect(day(DateTime.utc(2026, 10, 14), overrides).any((l) => l.pair == 3), isFalse);
      expect(day(DateTime.utc(2026, 10, 16), overrides).map((l) => l.pair), [5]); // пятница через неделю
      expect(day(DateTime.utc(2026, 10, 2), overrides), isEmpty); // до даты правила в пятницу ничего нет
    });
  });
}
