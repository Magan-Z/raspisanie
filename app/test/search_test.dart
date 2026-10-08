// Поиск: преподаватель, аудитория, свободные аудитории — на реальных данных всех 50 групп.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/domain/models.dart';
import 'package:raspisanie/domain/search.dart';

Map<String, dynamic> _json(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final index = ScheduleIndex.fromJson(_json('test/fixtures/index.json'));
  final schedules = [
    for (final f in Directory('test/fixtures/all').listSync().whereType<File>().where((f) => f.path.endsWith('.json')))
      GroupSchedule.fromJson(_json(f.path)),
  ];
  final wednesday = DateTime.utc(2026, 10, 7); // 2 неделя
  final lessons = campusLessons(wednesday, index, schedules);

  test('загружены все 50 групп', () => expect(schedules, hasLength(50)));

  test('воскресенье, праздник и вне семестра — пусто', () {
    expect(campusLessons(DateTime.utc(2026, 10, 11), index, schedules), isEmpty);
    expect(campusLessons(DateTime.utc(2026, 11, 4), index, schedules), isEmpty);
    expect(campusLessons(DateTime.utc(2026, 8, 31), index, schedules), isEmpty);
  });

  test('общая лекция — одна запись на несколько групп', () {
    // В среду 13:00 (3 пара) в 2-05 лекция «Технологическое предпринимательство» у обеих групп БИ-25
    final lecture = lessons.where((l) => l.pair == 3 && l.room == '2-05' && l.subject == 'Технологическое предпринимательство');
    expect(lecture, hasLength(1));
    expect(lecture.single.groups, containsAll(['1 БИ-25', '2 БИ-25']));
  });

  group('Преподаватели', () {
    final names = teacherNames(schedules);

    test('Батаева П.С. — одно имя, а не два (с точкой и без)', () {
      expect(names.where((n) => n.startsWith('Батаева П')).toList(), ['Батаева П.С.']);
    });
    test('список по алфавиту, без пустых', () {
      expect(names, isNotEmpty);
      expect(names, orderedEquals([...names]..sort()));
    });
    test('занятия преподавателя находятся при любом написании', () {
      final a = lessonsOfTeacher('Халиев М.С-У.', lessons);
      final b = lessonsOfTeacher('Халиев М.С', lessons);
      expect(a, isNotEmpty);
      expect(a.length, b.length);
      expect(a.every((l) => l.teacher!.startsWith('Халиев')), isTrue);
    });
  });

  group('Аудитории', () {
    final rooms = allRooms(schedules);

    test('в списке только настоящие номера', () {
      expect(rooms, contains('2-05'));
      expect(rooms, contains('3-01'));
      expect(rooms.any((r) => r.contains('корпус') || r.contains('зал')), isFalse);
    });

    test('кто занимается в 2-15 в среду 7 октября: 14:40 «ЧТК и этика» у 1 БИ-25', () {
      final inRoom = lessonsInRoom('2-15', lessons).where((l) => l.pair == 4);
      expect(inRoom.map((l) => l.subject), contains('ЧТК и этика'));
    });

    test('свободные аудитории: занятая не попадает в список, свободная попадает', () {
      final free = freeRooms(4, lessons, rooms);
      expect(free, isNot(contains('2-15')));
      expect(free.length, lessThan(rooms.length));
      // Любая аудитория, занятая в 4 пару, исключена
      final busy = lessons.where((l) => l.pair == 4 && l.room != null).map((l) => l.room!).toSet();
      expect(free.toSet().intersection(busy), isEmpty);
      expect(free.toSet().union(busy.intersection(rooms.toSet())), rooms.toSet());
    });
  });
}
