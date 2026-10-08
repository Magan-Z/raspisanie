// «К какому дню ДЗ?» — к следующему занятию этого предмета (АРХИТЕКТУРА.md, §7.3, §8).

import '../core/week.dart';
import 'models.dart';
import 'schedule_resolver.dart';

/// Ближайшая дата после [after], когда есть занятие по [subject] (и, если указан, нужного типа).
/// Ищем не дальше 28 дней вперёд. Если не нашли — null.
DateTime? nextOccurrence(
  String subject,
  DateTime after,
  ScheduleIndex index,
  GroupSchedule schedule,
  UserProfile profile, {
  LessonKind? kind,
  List<Override> overrides = const [],
}) {
  var day = dayOnly(after);
  for (var i = 0; i < 28; i++) {
    day = day.add(const Duration(days: 1));
    final lessons = resolve(day, index, schedule, profile, overrides: overrides);
    if (lessons.any((l) => l.subject == subject && (kind == null || l.kind == kind))) return day;
  }
  return null;
}
