// Локальная база данных (drift + SQLite). Таблицы — АРХИТЕКТУРА.md, §7.4.
// После изменения таблиц нужно перегенерировать database.g.dart:
//   dart run build_runner build

import 'package:drift/drift.dart';
import 'connection_io.dart' if (dart.library.js_interop) 'connection_web.dart';

part 'database.g.dart';

/// Кэш файлов групп (groups/ID.json).
class ScheduleCache extends Table {
  TextColumn get groupId => text()();
  TextColumn get version => text()();
  TextColumn get hash => text()();
  TextColumn get json => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {groupId};
}

/// Кэш index.json (всегда одна строка с id = 1).
class IndexCache extends Table {
  IntColumn get id => integer()();
  TextColumn get version => text()();
  TextColumn get json => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Домашние задания.
@DataClassName('HomeworkRow')
class Homework extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  TextColumn get content => text().named('text')();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get kindHint => text().nullable()(); // lecture / practice
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  // Устарело: раньше хранило одно фото. С версии базы 3 вложения лежат в HomeworkAttachments (старые фото перенесены туда)
  TextColumn get photoPath => text().nullable()();
}

/// Вложения к домашним заданиям (фото, PDF, документы). Сами файлы лежат в памяти приложения.
@DataClassName('AttachmentRow')
class HomeworkAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get homeworkId => integer()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  IntColumn get sizeBytes => integer().nullable()();
}

/// Содержимое вложений в браузере (на телефоне файлы лежат на диске, и эта таблица пуста).
@DataClassName('AttachmentBlobRow')
class AttachmentBlobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get bytes => blob()();
}

/// Общие данные группы (правки и ДЗ старосты), скачанные с сервера: одна строка на группу.
@DataClassName('GroupSharedRow')
class GroupSharedCache extends Table {
  TextColumn get groupId => text()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {groupId};
}

/// Личные правки расписания на конкретную дату.
@DataClassName('OverrideRow')
class Overrides extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get pair => integer()();
  TextColumn get type => text()(); // cancel / replace / add
  TextColumn get subject => text().nullable()();
  TextColumn get room => text().nullable()();
  TextColumn get teacher => text().nullable()();
  TextColumn get note => text().nullable()();
  // Добавлено в версии базы 2:
  TextColumn get kind => text().nullable()(); // lecture / practice — для своей (в том числе перенесённой) пары
  BoolColumn get repeatWeekly => boolean().withDefault(const Constant(false))(); // действует каждую неделю
  TextColumn get matchSubject => text().nullable()(); // для «каждую неделю»: к какому предмету относится
}

/// Короткие названия и цвета предметов.
@DataClassName('SubjectAliasRow')
class SubjectAliases extends Table {
  TextColumn get subject => text()();
  TextColumn get shortName => text()();
  IntColumn get colorIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {subject};
}

/// Заметки к предметам.
@DataClassName('NoteRow')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  TextColumn get content => text().named('text')();
}

/// Контрольные, зачёты, экзамены.
@DataClassName('DeadlineRow')
class Deadlines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get kind => text()(); // контрольная / зачёт / экзамен / другое
  TextColumn get subject => text().nullable()();
}

@DriftDatabase(tables: [ScheduleCache, IndexCache, Homework, HomeworkAttachments, AttachmentBlobs, GroupSharedCache, Overrides, SubjectAliases, Notes, Deadlines])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 → v2: правки «каждую неделю» и тип своей пары. Старые правки остаются как были.
          if (from < 2) {
            await m.addColumn(overrides, overrides.kind);
            await m.addColumn(overrides, overrides.repeatWeekly);
            await m.addColumn(overrides, overrides.matchSubject);
          }
          // v2 → v3: несколько вложений к заданию. Старое «фото доски» становится первым вложением.
          if (from < 3) {
            await m.createTable(homeworkAttachments);
            await customStatement(
              "INSERT INTO homework_attachments (homework_id, name, path) "
              "SELECT id, 'Фото.jpg', photo_path FROM homework WHERE photo_path IS NOT NULL",
            );
          }
          // v3 → v4: хранилище вложений для браузерной версии
          if (from < 4) {
            await m.createTable(attachmentBlobs);
          }
          // v4 → v5: кэш общих данных группы (правки и ДЗ старосты)
          if (from < 5) {
            await m.createTable(groupSharedCache);
          }
        },
      );
}
