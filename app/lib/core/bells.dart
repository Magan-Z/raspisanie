import '../domain/models.dart';

/// Смещение московского времени от UTC. В России нет перехода на летнее время,
/// поэтому смещение постоянное (АРХИТЕКТУРА.md, §1.6).
const moscowOffset = Duration(hours: 3);

/// Начало и конец пары в конкретный день — как моменты времени (в UTC).
(DateTime, DateTime) pairTimes(DateTime day, int pair, List<Bell> bells) {
  final bell = bells[pair - 1];
  final start = DateTime.utc(day.year, day.month, day.day, bell.startHour, bell.startMinute).subtract(moscowOffset);
  final end = DateTime.utc(day.year, day.month, day.day, bell.endHour, bell.endMinute).subtract(moscowOffset);
  return (start, end);
}

/// Текущий день по Москве (без времени) — независимо от часового пояса телефона.
DateTime moscowToday(DateTime now) {
  final moscow = now.toUtc().add(moscowOffset);
  return DateTime.utc(moscow.year, moscow.month, moscow.day);
}

/// Время «чч:мм» по Москве для момента времени.
String moscowTimeText(DateTime moment) {
  final m = moment.toUtc().add(moscowOffset);
  return '${m.hour.toString().padLeft(2, '0')}:${m.minute.toString().padLeft(2, '0')}';
}
