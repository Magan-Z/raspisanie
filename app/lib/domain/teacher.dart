// Режим преподавателя: «расписание преподавателя» собирается из файлов всех групп.
//
// Хитрость, чтобы не переписывать приложение: из пар преподавателя строится обычное `GroupSchedule`
// (одна «группа» с одной подгруппой), а в поле `teacher` каждой пары вместо фамилии кладутся группы
// («1 БИ-24, 2 БИ-24»). Всё остальное (экраны «Сегодня» и «Неделя», виджеты, напоминания, чётные и нечётные
// недели) работает без изменений. Кроме расписания считаем, каким группам преподаватель может задать ДЗ.

import 'models.dart';
import 'search.dart' show sameTeacher;

/// Кто пользуется приложением.
enum UserRole { student, teacher }

/// Служебный номер «группы» преподавателя в профиле (настоящей группы с таким номером нет).
const teacherScheduleId = 'teacher';

/// Профиль, под которым расписание преподавателя проходит через общую логику (подгруппа 1, физкультура любая).
const teacherProfile = UserProfile(formCode: '', groupId: teacherScheduleId, subgroup: 1);

/// Кому можно задать ДЗ: вся группа или только одна подгруппа (если у преподавателя пары только у неё).
class TeacherTarget {
  const TeacherTarget({required this.groupId, required this.title, this.subgroup, this.subgroupLabel});

  final String groupId;
  final String title; // «1 БИ-24»
  final int? subgroup; // null — вся группа
  final String? subgroupLabel; // «БИ-24-1»

  /// Как показывать на кнопке: «1 БИ-24» или «БИ-24-1».
  String get label => subgroup == null ? title : (subgroupLabel ?? '$title, подгруппа $subgroup');

  @override
  bool operator ==(Object other) => other is TeacherTarget && other.groupId == groupId && other.subgroup == subgroup;

  @override
  int get hashCode => Object.hash(groupId, subgroup);
}

/// Всё, что экранам нужно знать о преподавателе.
class TeacherView {
  const TeacherView({required this.schedule, required this.targetsBySubject});

  /// Пары преподавателя в виде обычного расписания (в `teacher` — группы).
  final GroupSchedule schedule;

  /// Предмет → кому можно задать ДЗ (у каждого предмета свои группы).
  final Map<String, List<TeacherTarget>> targetsBySubject;

  /// Нет ни одной пары: имя не нашлось в расписании.
  bool get isEmpty => schedule.lessons.isEmpty;

  /// Предметы по алфавиту (для окна «Отправить ДЗ»). Здесь есть и физкультура, и кураторский час.
  List<String> get subjects => targetsBySubject.keys.toList()..sort();

  /// Группы, у которых есть любой предмет преподавателя: с ними сверяется список из кода.
  List<TeacherTarget> get allTargets {
    final seen = <String>{};
    final result = <TeacherTarget>[];
    for (final list in targetsBySubject.values) {
      for (final t in list) {
        if (seen.add(t.groupId)) result.add(TeacherTarget(groupId: t.groupId, title: t.title));
      }
    }
    return result..sort((a, b) => a.title.compareTo(b.title));
  }
}

/// Собирает расписание и список адресатов преподавателя [teacher] (так, как имя записано в списке:
/// полное ФИО или с инициалами) из расписаний всех групп.
TeacherView buildTeacherView(String teacher, List<GroupSchedule> schedules) {
  // (день, неделя, пара, предмет, аудитория, тип, пол) → группы, у которых это занятие
  final merged = <String, (Lesson, Set<String>)>{};
  // предмет → группа → кому именно (вся группа или подгруппы)
  final wholeGroup = <String, Map<String, TeacherTarget>>{};
  final subgroupTargets = <String, Map<String, List<TeacherTarget>>>{};

  for (final schedule in schedules) {
    final allSubgroups = [for (final s in schedule.subgroups) s.n];
    for (final lesson in schedule.lessons) {
      final name = lesson.teacher;
      if (name == null || !sameTeacher(teacher, name)) continue;

      // Занятие для всей группы или только для части подгрупп
      final whole = schedule.subgroups.length <= 1 || allSubgroups.every(lesson.subgroups.contains);
      final suffix = lesson.tags.contains('female') ? ' (девушки)' : (lesson.tags.contains('male') ? ' (юноши)' : '');
      final labels = whole
          ? [schedule.title]
          : [for (final s in schedule.subgroups) if (lesson.subgroups.contains(s.n)) s.label];

      final key = '${lesson.weekday}|${lesson.week}|${lesson.pair}|${lesson.subject}|${lesson.room}|${lesson.kind.name}|$suffix';
      final entry = merged.putIfAbsent(key, () => (lesson, <String>{}));
      for (final label in labels) {
        entry.$2.add('$label$suffix');
      }

      if (whole) {
        wholeGroup.putIfAbsent(lesson.subject, () => {})[schedule.groupId] = TeacherTarget(groupId: schedule.groupId, title: schedule.title);
      } else {
        final bySubgroup = subgroupTargets.putIfAbsent(lesson.subject, () => {}).putIfAbsent(schedule.groupId, () => []);
        for (final s in schedule.subgroups) {
          if (lesson.subgroups.contains(s.n) && !bySubgroup.any((t) => t.subgroup == s.n)) {
            bySubgroup.add(TeacherTarget(groupId: schedule.groupId, title: schedule.title, subgroup: s.n, subgroupLabel: s.label));
          }
        }
      }
    }
  }

  final lessons = [
    for (final (lesson, groups) in merged.values)
      Lesson(
        weekday: lesson.weekday,
        pair: lesson.pair,
        week: lesson.week,
        subgroups: const [1],
        kind: lesson.kind,
        subject: lesson.subject,
        teacher: (groups.toList()..sort(_naturalCompare)).join(', '),
        room: lesson.room,
        tags: const [],
        raw: lesson.raw,
      ),
  ];
  lessons.sort((a, b) {
    final byDay = a.weekday.compareTo(b.weekday);
    return byDay != 0 ? byDay : (a.pair != b.pair ? a.pair.compareTo(b.pair) : a.subject.compareTo(b.subject));
  });

  // Адресаты: если по предмету у группы есть занятие для всей группы, подгруппы отдельно не нужны
  final targets = <String, List<TeacherTarget>>{};
  final subjects = {...wholeGroup.keys, ...subgroupTargets.keys};
  for (final subject in subjects) {
    final list = <TeacherTarget>[...?wholeGroup[subject]?.values];
    final wholeIds = {for (final t in list) t.groupId};
    for (final entry in (subgroupTargets[subject] ?? const <String, List<TeacherTarget>>{}).entries) {
      if (!wholeIds.contains(entry.key)) list.addAll(entry.value);
    }
    list.sort((a, b) => a.label.compareTo(b.label));
    targets[subject] = list;
  }

  return TeacherView(
    schedule: GroupSchedule(
      version: schedules.isEmpty ? '' : schedules.first.version,
      groupId: teacherScheduleId,
      title: teacher,
      form: '',
      subgroups: const [SubgroupInfo(1, 'Все')],
      lessons: lessons,
    ),
    targetsBySubject: targets,
  );
}

/// «1 БИ-24» < «2 БИ-24» < «10 БИ-24»: числа внутри названия сравниваем как числа.
int _naturalCompare(String a, String b) {
  final x = RegExp(r'(\d+)|(\D+)').allMatches(a).map((m) => m.group(0)!).toList();
  final y = RegExp(r'(\d+)|(\D+)').allMatches(b).map((m) => m.group(0)!).toList();
  for (var i = 0; i < x.length && i < y.length; i++) {
    final n = int.tryParse(x[i]), m = int.tryParse(y[i]);
    final c = (n != null && m != null) ? n.compareTo(m) : x[i].compareTo(y[i]);
    if (c != 0) return c;
  }
  return x.length.compareTo(y.length);
}
