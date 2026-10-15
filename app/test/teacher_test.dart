// Режим преподавателя (домен): расписание собирается из файлов всех групп; адресаты ДЗ; совпадение имён.
// Данные — настоящие расписания всех 50 групп.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unigraf/domain/models.dart';
import 'package:unigraf/domain/schedule_resolver.dart';
import 'package:unigraf/domain/teacher.dart';
import 'package:unigraf/domain/teacher_homework.dart';

Map<String, dynamic> _json(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final index = ScheduleIndex.fromJson(_json('test/fixtures/index.json'));
  final schedules = [
    for (final f in Directory('test/fixtures/all').listSync().whereType<File>().where((f) => f.path.endsWith('.json')))
      GroupSchedule.fromJson(_json(f.path)),
  ];
  final view = buildTeacherView('Эльмурзаева М.Э.', schedules);

  group('Расписание преподавателя', () {
    test('лекция для четырёх групп — одна пара, а в «teacher» — группы по порядку', () {
      final lecture = view.schedule.lessons.where((l) => l.weekday == 1 && l.pair == 1 && l.subject == 'Информатика' && l.kind == LessonKind.lecture);
      expect(lecture, hasLength(1));
      expect(lecture.single.teacher!.replaceAll('\u00A0', ' '), '1 ИТиСС-26, 2 ИТиСС-26, 3 ИТиСС-26, 4 ИТиСС-26');
      expect(lecture.single.room, '2-05');
      expect(lecture.single.week, 0);
    });

    test('практика только для подгруппы показывает подгруппу, а не всю группу', () {
      final group = schedules.firstWhere((s) => s.title == '1 ИТиСС-26');
      final label = group.subgroups.firstWhere((s) => s.n == 1).label;
      final practice = view.schedule.lessons.where((l) => l.weekday == 4 && l.week == 2 && l.pair == 1 && l.subject == 'Информатика');
      expect(practice, isNotEmpty);
      expect(practice.first.teacher, contains(label));
      expect(practice.first.teacher!.replaceAll('\u00A0', ' '), isNot(contains('1 ИТиСС-26,')));
    });

    test('физкультура девушек: в группах пометка «(девушки)»', () {
      final pe = buildTeacherView('Магомадова Я.Г.', schedules).schedule.lessons.where((l) => l.kind == LessonKind.pe);
      expect(pe, isNotEmpty);
      expect(pe.first.teacher!.replaceAll('\u00A0', ' '), contains('(девушки)'));
    });

    test('инициалы без отчества и полное ФИО дают то же расписание', () {
      final short = buildTeacherView('Эльмурзаева М.', schedules);
      final full = buildTeacherView('Эльмурзаева Мадина Эльмурзаевна', schedules);
      expect(short.schedule.lessons.length, view.schedule.lessons.length);
      expect(full.schedule.lessons.length, view.schedule.lessons.length);
    });

    test('неизвестное имя — пустое расписание', () {
      final nobody = buildTeacherView('Несуществующий Н.Н.', schedules);
      expect(nobody.isEmpty, isTrue);
      expect(nobody.subjects, isEmpty);
    });

    test('проходит через общий расчёт дня: понедельник 12.10.2026 (1 неделя) и воскресенье', () {
      final monday = resolve(DateTime.utc(2026, 10, 12), index, view.schedule, teacherProfile);
      expect(monday.any((l) => l.subject == 'Информатика' && l.teacher!.replaceAll('\u00A0', ' ').contains('4 ИТиСС-26') && l.room == '2-05'), isTrue);
      expect(resolve(DateTime.utc(2026, 10, 11), index, view.schedule, teacherProfile), isEmpty);
      // пары по порядку
      final pairs = [for (final l in monday) l.pair];
      expect([...pairs]..sort(), pairs);
    });

    test('чётная и нечётная недели считаются как у студентов', () {
      // практика по четвергам идёт только на 2 неделе: 8 октября (2 неделя) есть, 15 октября (1 неделя) нет
      bool has(DateTime d) => resolve(d, index, view.schedule, teacherProfile).any((l) => l.pair == 1 && l.subject == 'Информатика' && l.room == '3-21');
      expect(has(DateTime.utc(2026, 10, 8)), isTrue);
      expect(has(DateTime.utc(2026, 10, 15)), isFalse);
    });
  });

  group('Кому отправлять ДЗ', () {
    test('у предмета с лекцией для всей группы подгруппы отдельно не предлагаются', () {
      final targets = view.targetsBySubject['Информатика']!;
      expect(targets.where((t) => t.title == '1 ИТиСС-26'), hasLength(1));
      expect(targets.firstWhere((t) => t.title == '1 ИТиСС-26').subgroup, isNull);
    });

    test('группы без общего занятия получают отдельные цели по подгруппам', () {
      final bySubgroup = [for (final list in view.targetsBySubject.values) ...list.where((t) => t.subgroup != null)];
      for (final t in bySubgroup) {
        expect(t.subgroupLabel, isNotNull);
        // для этой группы у предмета нет занятия для всей группы
        final subjects = view.targetsBySubject.entries.where((e) => e.value.contains(t)).map((e) => e.key);
        for (final s in subjects) {
          expect(view.targetsBySubject[s]!.any((x) => x.groupId == t.groupId && x.subgroup == null), isFalse);
        }
      }
    });

    test('allTargets — группы без повторов, по алфавиту', () {
      final all = view.allTargets;
      expect(all.map((t) => t.groupId).toSet().length, all.length);
      expect(all.map((t) => t.title).toList(), ([...all.map((t) => t.title)]..sort()));
    });
  });

  group('Отправка ДЗ: модели', () {
    test('пачка читается и записывается без потерь (группа и подгруппа, файлы)', () {
      final batch = TeacherHomeworkBatch.fromJson({
        'batch_id': 'b1',
        'subject': 'Математика',
        'body': 'Номера 1-5',
        'due_date': '2026-10-20',
        'kind': 'practice',
        'groups': [
          {'id': 'ofo-1-bi-25', 'subgroup': null},
          {'id': 'ofo-2-bi-25', 'subgroup': 2},
        ],
        'files': [
          {'id': 'f1', 'name': 'a.pdf', 'size': 10},
        ],
      });
      expect(batch.targets, hasLength(2));
      expect(batch.targets[1].subgroup, 2);
      expect(batch.kind, LessonKind.practice);
      final json = batch.toJson();
      expect(json['groups'], [
        {'id': 'ofo-1-bi-25'},
        {'id': 'ofo-2-bi-25', 'subgroup': 2},
      ]);
      expect(TeacherHomeworkBatch.fromJson(json).files.single.name, 'a.pdf');
    });
  });
}
