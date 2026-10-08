// Локальная база данных (drift + SQLite). Таблицы — АРХИТЕКТУРА.md, §7.4.
// После изменения таблиц нужно перегенерировать database.g.dart:
//   dart run build_runner build

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  TextColumn get photoPath => text().nullable()();
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

@DriftDatabase(tables: [ScheduleCache, IndexCache, Homework, Overrides, SubjectAliases, Notes, Deadlines])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'raspisanie'));

  @override
  int get schemaVersion => 1;
}
