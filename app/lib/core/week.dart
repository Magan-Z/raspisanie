// Номер недели — та же формула, что в парсере (АРХИТЕКТУРА.md, §1.6):
// неделя = ((дата − weekAnchor).days // 7) % 2 + 1

/// Отбрасывает время: оставляет только день (в UTC, чтобы не мешали переводы часов).
DateTime dayOnly(DateTime moment) => DateTime.utc(moment.year, moment.month, moment.day);

/// Номер недели (1 или 2) для даты. anchor — понедельник первой «1 недели».
int weekNumber(DateTime date, DateTime anchor) {
  final days = dayOnly(date).difference(dayOnly(anchor)).inDays;
  // Деление с округлением вниз, чтобы даты до anchor тоже считались правильно
  final weeks = (days / 7).floor();
  return weeks % 2 + 1;
}
