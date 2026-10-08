// Домашка: разбивка по срокам, экспорт/импорт, база (АРХИТЕКТУРА.md, §8).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/homework_repository.dart';
import 'package:raspisanie/domain/homework.dart';
import 'package:raspisanie/domain/models.dart';

HomeworkItem hw(String subject, DateTime due, {bool done = false, String text = 'задание', LessonKind? kind}) =>
    HomeworkItem(subject: subject, text: text, dueDate: due, done: done, kind: kind, createdAt: DateTime.utc(2026, 10, 1));

void main() {
  // Четверг, 8 октября 2026
  final today = DateTime.utc(2026, 10, 8);

  group('Разделы списка ДЗ', () {
    final items = [
      hw('Вчера', DateTime.utc(2026, 10, 7)),
      hw('Сегодня', DateTime.utc(2026, 10, 8)),
      hw('Завтра', DateTime.utc(2026, 10, 9)),
      hw('Суббота', DateTime.utc(2026, 10, 10)),
      hw('Воскресенье', DateTime.utc(2026, 10, 11)),
      hw('Понедельник', DateTime.utc(2026, 10, 12)),
      hw('Готово', DateTime.utc(2026, 10, 7), done: true),
    ];
    final groups = groupHomework(items, today);

    String names(HomeworkBucket b) => groups[b]!.map((i) => i.subject).join(',');

    test('просрочено / сегодня / завтра', () {
      expect(names(HomeworkBucket.overdue), 'Вчера');
      expect(names(HomeworkBucket.today), 'Сегодня');
      expect(names(HomeworkBucket.tomorrow), 'Завтра');
    });
    test('на этой неделе — до воскресенья включительно, дальше «Позже»', () {
      expect(names(HomeworkBucket.thisWeek), 'Суббота,Воскресенье');
      expect(names(HomeworkBucket.later), 'Понедельник');
    });
    test('выполненное — отдельно, даже если просрочено', () {
      expect(names(HomeworkBucket.done), 'Готово');
    });
    test('пустые разделы не возвращаются, порядок — как в списке', () {
      final only = groupHomework([hw('А', DateTime.utc(2026, 10, 9))], today);
      expect(only.keys, [HomeworkBucket.tomorrow]);
      expect(groups.keys.toList(), HomeworkBucket.values);
    });
  });

  test('dueOn: только невыполненные на нужный день', () {
    final items = [hw('А', DateTime.utc(2026, 10, 9)), hw('Б', DateTime.utc(2026, 10, 9), done: true), hw('В', DateTime.utc(2026, 10, 10))];
    expect(dueOn(items, DateTime.utc(2026, 10, 9)).map((i) => i.subject), ['А']);
  });

  group('Экспорт и импорт', () {
    test('круг: экспорт → импорт возвращает то же самое', () {
      final original = [
        hw('Аккаунтинг и аудит', DateTime.utc(2026, 10, 8), text: 'Задача №3, стр. 45', kind: LessonKind.practice),
        hw('Философия', DateTime.utc(2026, 10, 12), done: true),
      ];
      final restored = importHomework(exportHomework(original));
      expect(restored.length, 2);
      expect(restored[0].subject, 'Аккаунтинг и аудит');
      expect(restored[0].text, 'Задача №3, стр. 45');
      expect(restored[0].dueDate, DateTime.utc(2026, 10, 8));
      expect(restored[0].kind, LessonKind.practice);
      expect(restored[0].done, isFalse);
      expect(restored[1].kind, isNull);
      expect(restored[1].done, isTrue);
    });

    test('посторонний текст → понятная ошибка', () {
      expect(() => importHomework('привет'), throwsA(isA<FormatException>()));
      expect(() => importHomework('{"a": 1}'), throwsA(isA<FormatException>()));
      expect(() => importHomework('{"app":"raspisanie","homework":[{"subject":1}]}'), throwsA(isA<FormatException>()));
    });
  });

  group('База', () {
    late AppDatabase db;
    late HomeworkRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = HomeworkRepository(db);
    });
    tearDown(() => db.close());

    test('добавить, прочитать, отметить выполненным, удалить', () async {
      await repo.add(hw('Философия', DateTime.utc(2026, 10, 12), text: 'Конспект', kind: LessonKind.lecture));
      var all = await repo.all();
      expect(all, hasLength(1));
      expect(all.single.dueDate, DateTime.utc(2026, 10, 12)); // дата не «съезжает» из-за часового пояса
      expect(all.single.kind, LessonKind.lecture);
      expect(all.single.done, isFalse);

      await repo.setDone(all.single.id!, true);
      all = await repo.all();
      expect(all.single.done, isTrue);

      await repo.delete(all.single.id!);
      expect(await repo.all(), isEmpty);
    });

    test('импорт не создаёт дубликаты', () async {
      final items = [hw('А', DateTime.utc(2026, 10, 9)), hw('Б', DateTime.utc(2026, 10, 10))];
      expect(await repo.importItems(items), 2);
      expect(await repo.importItems(items), 0);
      expect(await repo.all(), hasLength(2));
    });
  });
}
