// Свои названия и цвета предметов: логика, хранение, выключатель.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/subject_styles_repository.dart';
import 'package:raspisanie/domain/subject_styles.dart';
import 'package:raspisanie/theme/subject_palette.dart';

void main() {
  const subject = 'Технологическое предпринимательство';

  group('SubjectStyles', () {
    test('без настроек всё как в расписании', () {
      const styles = SubjectStyles();
      expect(styles.name(subject), subject);
      expect(styles.tone(subject, Brightness.light).accent, subjectTone(subject, Brightness.light).accent);
    });

    test('своё название и цвет применяются', () {
      const styles = SubjectStyles(styles: {subject: SubjectStyle(shortName: 'Предпр.', colorIndex: 2)});
      expect(styles.name(subject), 'Предпр.');
      expect(styles.compactName(subject), 'Предпр.');
      expect(styles.tone(subject, Brightness.light).accent, subjectToneByIndex(2, Brightness.light).accent);
      expect(styles.tone(subject, Brightness.dark).accent, subjectToneByIndex(2, Brightness.dark).accent);
    });

    test('только цвет: название остаётся настоящим', () {
      const styles = SubjectStyles(styles: {subject: SubjectStyle(colorIndex: 4)});
      expect(styles.name(subject), subject);
      expect(styles.tone(subject, Brightness.light).accent, subjectToneByIndex(4, Brightness.light).accent);
    });

    test('выключатель: настройки не теряются, но не действуют', () {
      const styles = SubjectStyles(enabled: false, styles: {subject: SubjectStyle(shortName: 'Предпр.', colorIndex: 2)});
      expect(styles.name(subject), subject);
      expect(styles.tone(subject, Brightness.light).accent, subjectTone(subject, Brightness.light).accent);
      expect(styles.hasOwn(subject), isTrue);
    });

    test('compactName без своего названия — сокращённое настоящее', () {
      expect(const SubjectStyles().compactName(subject).length, lessThanOrEqualTo(18));
    });

    test('у другого предмета свои настройки не действуют', () {
      const styles = SubjectStyles(styles: {subject: SubjectStyle(shortName: 'Предпр.')});
      expect(styles.name('Философия'), 'Философия');
    });

    test('номер цвета из любого числа (хеш) попадает в палитру', () {
      expect(() => subjectToneByIndex(123456789, Brightness.light), returnsNormally);
      expect(subjectColorNames.length, subjectPaletteSize);
    });
  });

  group('SubjectStylesRepository', () {
    late AppDatabase db;
    late SubjectStylesRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SubjectStylesRepository(db);
    });
    tearDown(() => db.close());

    test('сохраняет и читает название и цвет', () async {
      await repo.save(subject, const SubjectStyle(shortName: ' Предпр. ', colorIndex: 3));
      final all = await repo.all();
      expect(all[subject]?.shortName, 'Предпр.');
      expect(all[subject]?.colorIndex, 3);
    });

    test('только цвет сохраняется без названия', () async {
      await repo.save(subject, const SubjectStyle(colorIndex: 1));
      final style = (await repo.all())[subject]!;
      expect(style.shortName, isNull);
      expect(style.colorIndex, 1);
    });

    test('пустые настройки удаляют запись', () async {
      await repo.save(subject, const SubjectStyle(shortName: 'Предпр.'));
      await repo.save(subject, const SubjectStyle(shortName: '  '));
      expect(await repo.all(), isEmpty);
    });

    test('повторное сохранение заменяет, сброс всех очищает', () async {
      await repo.save(subject, const SubjectStyle(shortName: 'A'));
      await repo.save(subject, const SubjectStyle(shortName: 'B'));
      await repo.save('Философия', const SubjectStyle(colorIndex: 0));
      expect((await repo.all())[subject]?.shortName, 'B');
      await repo.resetAll();
      expect(await repo.all(), isEmpty);
    });
  });
}
