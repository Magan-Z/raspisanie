// Домашние задания в локальной базе.

import 'package:drift/drift.dart';

import '../../core/week.dart';
import '../../domain/homework.dart';
import '../../domain/models.dart';
import '../local/database.dart';

class HomeworkRepository {
  HomeworkRepository(this.db);
  final AppDatabase db;

  Future<List<HomeworkItem>> all() async {
    final rows = await (db.select(db.homework)..orderBy([(t) => OrderingTerm.asc(t.dueDate)])).get();
    return rows.map(_fromRow).toList();
  }

  Future<void> add(HomeworkItem item) async {
    await db.into(db.homework).insert(_toCompanion(item));
  }

  Future<void> setDone(int id, bool done) =>
      (db.update(db.homework)..where((t) => t.id.equals(id))).write(HomeworkCompanion(done: Value(done)));

  Future<void> delete(int id) => (db.delete(db.homework)..where((t) => t.id.equals(id))).go();

  /// Добавляет ДЗ из файла, пропуская те, что уже есть. Возвращает, сколько добавлено.
  Future<int> importItems(List<HomeworkItem> items) async {
    final existing = {for (final i in await all()) i.fingerprint};
    var added = 0;
    for (final item in items) {
      if (existing.add(item.fingerprint)) {
        await add(item);
        added++;
      }
    }
    return added;
  }

  HomeworkItem _fromRow(HomeworkRow row) => HomeworkItem(
        id: row.id,
        subject: row.subject,
        text: row.content,
        // Дату храним как UTC-полночь; drift отдаёт её в местном времени, возвращаем в UTC
        dueDate: dayOnly(row.dueDate.toUtc()),
        kind: row.kindHint == null ? null : LessonKind.parse(row.kindHint!),
        done: row.done,
        createdAt: row.createdAt.toUtc(),
        photoPath: row.photoPath,
      );

  HomeworkCompanion _toCompanion(HomeworkItem item) => HomeworkCompanion.insert(
        subject: item.subject,
        content: item.text,
        dueDate: dayOnly(item.dueDate),
        kindHint: Value(item.kind?.name),
        done: Value(item.done),
        createdAt: item.createdAt,
        photoPath: Value(item.photoPath),
      );
}
