// Русские названия дней и месяцев, склонения — без лишних библиотек.

const weekdayNames = ['', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];
const weekdayTitles = ['', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
const weekdayShort = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _monthsGenitive = [
  '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

/// «четверг, 8 октября»
String dayTitle(DateTime day) => '${weekdayNames[day.weekday]}, ${day.day} ${_monthsGenitive[day.month]}';

/// «8 октября»
String dateText(DateTime day) => '${day.day} ${_monthsGenitive[day.month]}';

/// Склонение: plural(5, 'минута', 'минуты', 'минут') → «минут».
String plural(int n, String one, String few, String many) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/// «1 ч 30 мин», «45 мин»
String durationText(Duration d) {
  final hours = d.inHours, minutes = d.inMinutes % 60;
  if (hours == 0) return '$minutes мин';
  if (minutes == 0) return '$hours ч';
  return '$hours ч $minutes мин';
}

/// «обновлено 2 дня назад»
String agoText(DateTime moment, DateTime now) {
  final d = now.difference(moment);
  if (d.inMinutes < 1) return 'только что';
  if (d.inMinutes < 60) return '${d.inMinutes} ${plural(d.inMinutes, 'минуту', 'минуты', 'минут')} назад';
  if (d.inHours < 24) return '${d.inHours} ${plural(d.inHours, 'час', 'часа', 'часов')} назад';
  return '${d.inDays} ${plural(d.inDays, 'день', 'дня', 'дней')} назад';
}

/// Короткое название предмета для виджета: «Технологическое предпринимательство» → «Технол. предпр.».
String shortSubject(String subject, {int maxLength = 18}) {
  if (subject.length <= maxLength) return subject;
  final words = subject.split(' ');
  final short = words.map((w) {
    if (w.length <= 4 || w == w.toUpperCase()) return w; // короткие слова и аббревиатуры не трогаем
    // обрезаем после согласной, чтобы не получилось «Техноло.»
    var cut = 6;
    while (cut > 3 && 'аеёиоуыэюяй'.contains(w[cut - 1].toLowerCase())) {
      cut--;
    }
    return '${w.substring(0, cut)}.';
  }).where((w) => !const {'и', 'в', 'на', 'для', 'по'}.contains(w));
  final result = short.join(' ');
  return result.length <= maxLength + 4 ? result : '${result.substring(0, maxLength + 3)}…';
}
