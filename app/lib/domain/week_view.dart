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
