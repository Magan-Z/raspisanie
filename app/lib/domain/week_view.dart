// Расписание «по шаблону недели» — для экрана «Неделя» (без конкретных дат).

import 'models.dart';

/// Подходит ли занятие пользователю: своя подгруппа и нужная физ-ра.
bool lessonFitsProfile(Lesson lesson, UserProfile profile) {
  if (!lesson.subgroups.contains(profile.subgroup)) return false;
  if (profile.pe == PeChoice.male && lesson.tags.contains('female')) return false;
  if (profile.pe == PeChoice.female && lesson.tags.contains('male')) return false;
  return true;
}

/// Пары по дням недели (1–6) для недели [week] (1 или 2).
Map<int, List<Lesson>> weekTemplate(GroupSchedule schedule, UserProfile profile, int week) {
  final result = {for (var d = 1; d <= 6; d++) d: <Lesson>[]};
  for (final lesson in schedule.lessons) {
    if (lesson.week != 0 && lesson.week != week) continue;
    if (!lessonFitsProfile(lesson, profile)) continue;
    result[lesson.weekday]!.add(lesson);
  }
  for (final list in result.values) {
    list.sort((a, b) => a.pair.compareTo(b.pair));
  }
  return result;
}

/// Названия предметов группы (для выбора при добавлении ДЗ), по алфавиту. Без кураторского часа и физ-ры.
List<String> subjectsOf(GroupSchedule schedule, UserProfile profile) {
  final names = {
    for (final l in schedule.lessons)
      if (lessonFitsProfile(l, profile) && l.kind != LessonKind.curator && l.kind != LessonKind.pe) l.subject,
  };
  return names.toList()..sort();
}

/// Делится ли предмет по подгруппам (иностранный язык, лабораторные): хотя бы одно занятие только для части подгрупп.
/// Тогда староста может задать ДЗ одной подгруппе.
bool subjectSplitsBySubgroup(GroupSchedule schedule, String subject) =>
    schedule.subgroups.length > 1 && schedule.lessons.any((l) => l.subject == subject && l.subgroups.length < schedule.subgroups.length);
