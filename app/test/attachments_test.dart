// Вложения к ДЗ: хранение, удаление вместе с заданием, перенос старого «фото доски», подписи файлов.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/data/attachments/attachment_store.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/homework_repository.dart';
import 'package:raspisanie/domain/attachment.dart';
import 'package:raspisanie/domain/homework.dart';

import 'support/fakes.dart';

void main() {
  group('Attachment', () {
    test('расширение и тип файла', () {
      expect(const Attachment(name: 'Задачи.PDF', path: '/x').extension, 'pdf');
      expect(const Attachment(name: 'без_расширения', path: '/x').extension, '');
      expect(const Attachment(name: 'доска.jpg', path: '/x').isImage, isTrue);
      expect(const Attachment(name: 'лекция.pptx', path: '/x').isImage, isFalse);
    });

    test('размер человеческими словами', () {
      expect(formatFileSize(500), '500 Б');
      expect(formatFileSize(320 * 1024), '320 КБ');
      expect(formatFileSize((1.4 * 1024 * 1024).round()), '1,4 МБ');
    });
  });

  group('Репозиторий ДЗ с вложениями', () {
    late AppDatabase db;
    late FakeAttachmentStore store;
    late HomeworkRepository repo;
    late File source;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      store = FakeAttachmentStore();
      repo = HomeworkRepository(db, store);
      source = File('${store.dir.path}/исходник.pdf')..writeAsBytesSync([1, 2, 3, 4]);
    });
    tearDown(() async {
      await db.close();
      store.dir.deleteSync(recursive: true);
    });

    HomeworkItem item(List<Attachment> files) => HomeworkItem(
          subject: 'Философия',
          text: 'Конспект',
          dueDate: DateTime.utc(2026, 10, 14),
          createdAt: DateTime.utc(2026, 10, 7),
          attachments: files,
        );

    test('задание сохраняется вместе с несколькими вложениями', () async {
      final a = await store.save(PickedFileInfo(name: 'Задачи.pdf', path: source.path, sizeBytes: 4));
      final b = await store.save(PickedFileInfo(name: 'Схема.png', path: source.path, sizeBytes: 4));
      await repo.add(item([a, b]));

      final all = await repo.all();
      expect(all, hasLength(1));
      expect(all.single.attachments.map((f) => f.name), ['Задачи.pdf', 'Схема.png']);
      expect(all.single.attachments.first.sizeBytes, 4);
      expect(all.single.attachments.last.isImage, isTrue);
    });

    test('удаление задания удаляет и файлы вложений', () async {
      final a = await store.save(PickedFileInfo(name: 'Задачи.pdf', path: source.path, sizeBytes: 4));
      final id = await repo.add(item([a]));
      expect(File(a.path).existsSync(), isTrue);

      await repo.delete(id);
      expect(await repo.all(), isEmpty);
      expect(File(a.path).existsSync(), isFalse);
      expect(await db.select(db.homeworkAttachments).get(), isEmpty);
    });

    test('ДЗ без вложений работает как раньше', () async {
      await repo.add(item(const []));
      expect((await repo.all()).single.attachments, isEmpty);
    });

    test('перенос ДЗ через буфер не тащит вложения', () async {
      final a = await store.save(PickedFileInfo(name: 'Задачи.pdf', path: source.path, sizeBytes: 4));
      expect(await repo.importItems([item([a])]), 1);
      expect((await repo.all()).single.attachments, isEmpty);
    });
  });

  test('база версии 2: старое «фото доски» становится вложением', () async {
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE homework (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          text TEXT NOT NULL,
          due_date INTEGER NOT NULL,
          kind_hint TEXT NULL,
          done INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          photo_path TEXT NULL
        );
      ''');
      raw.execute("INSERT INTO homework (subject, text, due_date, created_at, photo_path) VALUES ('Философия', 'Читать', 1792000000, 1791000000, '/data/photo1.jpg');");
      raw.execute("INSERT INTO homework (subject, text, due_date, created_at) VALUES ('Физика', 'Задачи', 1792000000, 1791000000);");
      raw.execute('PRAGMA user_version = 2;');
    });
    final db = AppDatabase(executor);
    addTearDown(db.close);

    final all = await HomeworkRepository(db).all();
    expect(all, hasLength(2));
    final withPhoto = all.firstWhere((h) => h.subject == 'Философия');
    expect(withPhoto.attachments.single.path, '/data/photo1.jpg');
    expect(withPhoto.attachments.single.isImage, isTrue);
    expect(all.firstWhere((h) => h.subject == 'Физика').attachments, isEmpty);
  });
}
