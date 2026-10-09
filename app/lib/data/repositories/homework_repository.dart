// Домашние задания в локальной базе.

import 'package:drift/drift.dart';

import '../../core/week.dart';
import '../../domain/attachment.dart';
import '../../domain/homework.dart';
import '../../domain/models.dart';
import '../attachments/attachment_store.dart';
import '../local/database.dart';

class HomeworkRepository {
  HomeworkRepository(this.db, [this.store]);
  final AppDatabase db;

  /// Где лежат файлы вложений; нужен, чтобы удалить файлы вместе с заданием.
  final AttachmentStore? store;

  Future<List<HomeworkItem>> all() async {
    final rows = await (db.select(db.homework)..orderBy([(t) => OrderingTerm.asc(t.dueDate)])).get();
    final files = await db.select(db.homeworkAttachments).get();
    final byHomework = <int, List<Attachment>>{};
    for (final f in files) {
      byHomework.putIfAbsent(f.homeworkId, () => []).add(Attachment(id: f.id, name: f.name, path: f.path, sizeBytes: f.sizeBytes));
    }
    return [for (final row in rows) _fromRow(row, byHomework[row.id] ?? const [])];
  }

  /// Сохраняет задание вместе с вложениями. Возвращает номер задания.
  Future<int> add(HomeworkItem item) async {
    final id = await db.into(db.homework).insert(_toCompanion(item));
    for (final a in item.attachments) {
      await _insertAttachment(id, a);
    }
    return id;
  }

  Future<void> _insertAttachment(int homeworkId, Attachment a) => db.into(db.homeworkAttachments).insert(
        HomeworkAttachmentsCompanion.insert(
          homeworkId: homeworkId,
          name: a.name,
          path: a.path,
          sizeBytes: Value(a.sizeBytes),
        ),
      );

  Future<void> setDone(int id, bool done) =>
      (db.update(db.homework)..where((t) => t.id.equals(id))).write(HomeworkCompanion(done: Value(done)));

  /// Удаляет задание, его вложения и файлы вложений.
  Future<void> delete(int id) async {
    final files = await (db.select(db.homeworkAttachments)..where((t) => t.homeworkId.equals(id))).get();
    for (final f in files) {
      await store?.delete(Attachment(name: f.name, path: f.path));
    }
    await (db.delete(db.homeworkAttachments)..where((t) => t.homeworkId.equals(id))).go();
    await (db.delete(db.homework)..where((t) => t.id.equals(id))).go();
  }

  /// Добавляет ДЗ из файла, пропуская те, что уже есть. Возвращает, сколько добавлено.
  /// Вложения при переносе через буфер не передаются (файлов в тексте нет) — только само задание.
  Future<int> importItems(List<HomeworkItem> items) async {
    final existing = {for (final i in await all()) i.fingerprint};
    var added = 0;
    for (final item in items) {
      if (existing.add(item.fingerprint)) {
        await add(item.copyWith(attachments: const []));
        added++;
      }
    }
    return added;
  }

  HomeworkItem _fromRow(HomeworkRow row, List<Attachment> attachments) => HomeworkItem(
        id: row.id,
        subject: row.subject,
        text: row.content,
        // Дату храним как UTC-полночь; drift отдаёт её в местном времени, возвращаем в UTC
        dueDate: dayOnly(row.dueDate.toUtc()),
        kind: row.kindHint == null ? null : LessonKind.parse(row.kindHint!),
        done: row.done,
        createdAt: row.createdAt.toUtc(),
        attachments: attachments,
      );

  HomeworkCompanion _toCompanion(HomeworkItem item) => HomeworkCompanion.insert(
        subject: item.subject,
        content: item.text,
        dueDate: dayOnly(item.dueDate),
        kindHint: Value(item.kind?.name),
        done: Value(item.done),
        createdAt: item.createdAt,
      );
}
