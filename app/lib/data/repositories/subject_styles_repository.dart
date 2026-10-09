// Свои названия и цвета предметов в локальной базе (таблица subject_aliases).

import 'package:drift/drift.dart';

import '../../domain/subject_styles.dart';
import '../local/database.dart';

class SubjectStylesRepository {
  SubjectStylesRepository(this.db);
  final AppDatabase db;

  Future<Map<String, SubjectStyle>> all() async {
    final rows = await db.select(db.subjectAliases).get();
    return {for (final r in rows) r.subject: SubjectStyle(shortName: r.shortName.isEmpty ? null : r.shortName, colorIndex: r.colorIndex)};
  }

  /// Сохраняет настройки предмета. Если ничего не задано — запись удаляется (предмет снова «как в расписании»).
  Future<void> save(String subject, SubjectStyle style) async {
    final name = style.shortName?.trim() ?? '';
    if (name.isEmpty && style.colorIndex == null) {
      await reset(subject);
      return;
    }
    await db.into(db.subjectAliases).insertOnConflictUpdate(
          SubjectAliasesCompanion.insert(subject: subject, shortName: name, colorIndex: Value(style.colorIndex)),
        );
  }

  Future<void> reset(String subject) => (db.delete(db.subjectAliases)..where((t) => t.subject.equals(subject))).go();

  Future<void> resetAll() => db.delete(db.subjectAliases).go();
}
