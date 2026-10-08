// ЯДРО приложения: «какие у меня пары в этот день?» (АРХИТЕКТУРА.md, §7.3).
// Чистая функция: не ходит в сеть, не трогает экран и не смотрит на часы —
// всё нужное передаётся параметрами. Поэтому её легко проверять тестами.

import '../core/bells.dart';
import '../core/week.dart';
import 'models.dart';
import 'week_view.dart';

List<ResolvedLesson> resolve(
  DateTime date,
  ScheduleIndex index,
  GroupSchedule schedule,
  UserProfile profile, {
  List<Override> overrides = const [],
  int? forcedWeek, // ручной переключатель недели из настроек (на случай сбоя чередования)
}) {
  final day = dayOnly(date);

  // 1. Воскресенье, праздник или день вне семестра — пар нет
  if (day.weekday == DateTime.sunday ||
      index.holidays.contains(day) ||
      day.isBefore(index.semesterStart) ||
      day.isAfter(index.semesterEnd)) {
    return [];
  }

  final week = forcedWeek ?? weekNumber(day, index.weekAnchor);
  final result = <ResolvedLesson>[];

  for (final lesson in schedule.lessons) {
    // 2. Нужный день недели и неделя (0 = каждая неделя)
    if (lesson.weekday != day.weekday) continue;
    if (lesson.week != 0 && lesson.week != week) continue;
    // 3–4. Своя подгруппа; физ-ра «чужого» пола убирается
    if (!lessonFitsProfile(lesson, profile)) continue;

    result.add(_toResolved(day, lesson.pair, index.bells, week,
        subject: lesson.subject, teacher: lesson.teacher, room: lesson.room, kind: lesson.kind, tags: lesson.tags));
  }

  // 5. Личные правки на эту дату
  for (final o in overrides.where((o) => o.date == day)) {
    switch (o.type) {
      case OverrideType.cancel:
        result.removeWhere((l) => l.pair == o.pair);
      case OverrideType.replace:
        for (var i = 0; i < result.length; i++) {
          if (result[i].pair == o.pair) {
            result[i] = result[i].copyWith(
                subject: o.subject, teacher: o.teacher, room: o.room, note: o.note, isPersonal: true);
          }
        }
      case OverrideType.add:
        result.add(_toResolved(day, o.pair, index.bells, week,
            subject: o.subject ?? 'Занятие',
            teacher: o.teacher,
            room: o.room,
            kind: LessonKind.practice,
            tags: const [],
            note: o.note,
            isPersonal: true));
    }
  }

  // 6. По порядку пар (время уже проставлено в _toResolved)
  result.sort((a, b) => a.pair.compareTo(b.pair));
  return result;
}

ResolvedLesson _toResolved(
  DateTime day,
  int pair,
  List<Bell> bells,
  int week, {
  required String subject,
  required String? teacher,
  required String? room,
  required LessonKind kind,
  required List<String> tags,
  String? note,
  bool isPersonal = false,
}) {
  final (start, end) = pairTimes(day, pair, bells);
  return ResolvedLesson(
    date: day,
    pair: pair,
    startAt: start,
    endAt: end,
    subject: subject,
    teacher: teacher,
    room: room,
    kind: kind,
    tags: tags,
    week: week,
    note: note,
    isPersonal: isPersonal,
  );
}

/// Ближайший учебный день начиная с [from] (включительно), в который есть пары. Не дальше 14 дней.
DateTime? nextStudyDay(
  DateTime from,
  ScheduleIndex index,
  GroupSchedule schedule,
  UserProfile profile, {
  List<Override> overrides = const [],
  int? forcedWeek,
}) {
  var day = dayOnly(from);
  for (var i = 0; i < 14; i++) {
    if (resolve(day, index, schedule, profile, overrides: overrides, forcedWeek: forcedWeek).isNotEmpty) return day;
    day = day.add(const Duration(days: 1));
  }
  return null;
}
