// Поиск по всему институту (АРХИТЕКТУРА.md, §8): преподаватель, аудитория, свободные аудитории.
// Работает по файлам всех групп, поэтому не зависит от выбранной вами группы.

import '../core/week.dart';
import 'models.dart';

/// Занятие «глазами института»: одна пара в одной аудитории; общая лекция — одна запись на несколько групп.
class CampusLesson {
  const CampusLesson({
    required this.pair,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.kind,
    required this.groups,
  });

  final int pair;
  final String subject;
  final String? teacher;
  final String? room;
  final LessonKind kind;
  final List<String> groups; // названия групп, у которых это занятие
}

/// Аудитория в формате «корпус-номер»: 2-05, 3-120, 4-02а. («3 корпус», «читальный зал» — не считаем.)
final _roomPattern = RegExp(r'^\d-\d{2,3}[а-я]?$');

bool isNumberedRoom(String room) => _roomPattern.hasMatch(room);

/// Все занятия института в конкретный день. Общие лекции объединяются в одну запись.
List<CampusLesson> campusLessons(DateTime date, ScheduleIndex index, List<GroupSchedule> schedules, {int? forcedWeek}) {
  final day = dayOnly(date);
  if (day.weekday == DateTime.sunday ||
      index.holidays.contains(day) ||
      day.isBefore(index.semesterStart) ||
      day.isAfter(index.semesterEnd)) {
    return [];
  }
  final week = forcedWeek ?? weekNumber(day, index.weekAnchor);

  // (пара, предмет, преподаватель, аудитория) → группы
  final merged = <String, (Lesson, Set<String>)>{};
  for (final schedule in schedules) {
    for (final lesson in schedule.lessons) {
      if (lesson.weekday != day.weekday) continue;
      if (lesson.week != 0 && lesson.week != week) continue;
      final key = '${lesson.pair}|${lesson.subject}|${lesson.teacher}|${lesson.room}';
      merged.putIfAbsent(key, () => (lesson, <String>{})).$2.add(schedule.title);
    }
  }

  final result = [
    for (final (lesson, groups) in merged.values)
      CampusLesson(
        pair: lesson.pair,
        subject: lesson.subject,
        teacher: lesson.teacher,
        room: lesson.room,
        kind: lesson.kind,
        groups: groups.toList()..sort(),
      ),
  ];
  result.sort((a, b) => a.pair != b.pair ? a.pair.compareTo(b.pair) : a.subject.compareTo(b.subject));
  return result;
}

// ---------- преподаватели ----------

/// Ключ для сравнения имён: в таблице один человек бывает записан по-разному
/// («Батаева П.С», «Батаева П.С.», «Аюбов. С-М.»). Берём фамилию и первую букву инициалов.
String teacherKey(String name) {
  final parts = name.split(RegExp(r'\s+'));
  final surname = parts.first.replaceAll('.', '').toLowerCase();
  final initial = parts.length > 1 ? parts[1].replaceAll('.', '').toLowerCase() : '';
  return '$surname ${initial.isEmpty ? '' : initial[0]}';
}

/// Список преподавателей института (по алфавиту). Из нескольких написаний выбирается самое полное.
List<String> teacherNames(Iterable<GroupSchedule> schedules) {
  final best = <String, String>{};
  for (final schedule in schedules) {
    for (final lesson in schedule.lessons) {
      final name = lesson.teacher;
      if (name == null) continue;
      final key = teacherKey(name);
      final current = best[key];
      if (current == null || name.length > current.length) best[key] = name;
    }
  }
  return best.values.toList()..sort();
}

/// Занятия преподавателя в день [lessons] (результат [campusLessons]).
List<CampusLesson> lessonsOfTeacher(String teacher, List<CampusLesson> lessons) {
  final key = teacherKey(teacher);
  return [for (final l in lessons) if (l.teacher != null && teacherKey(l.teacher!) == key) l];
}

// ---------- аудитории ----------

/// Все аудитории института с номером в формате «корпус-номер», по порядку.
List<String> allRooms(Iterable<GroupSchedule> schedules) {
  final rooms = {
    for (final s in schedules)
      for (final l in s.lessons)
        if (l.room != null && isNumberedRoom(l.room!)) l.room!,
  };
  return rooms.toList()..sort();
}

/// Занятия в аудитории [room] в день [lessons].
List<CampusLesson> lessonsInRoom(String room, List<CampusLesson> lessons) =>
    [for (final l in lessons) if (l.room == room) l];

/// Аудитории, где в эту пару никто не занимается. Список «всех аудиторий» — те, что встречаются в расписании.
List<String> freeRooms(int pair, List<CampusLesson> dayLessons, List<String> rooms) {
  final busy = {for (final l in dayLessons) if (l.pair == pair && l.room != null) l.room!};
  return [for (final r in rooms) if (!busy.contains(r)) r];
}
