// ДЗ от преподавателя: что хранится на телефоне преподавателя (код, отправленное) и как это описывает сервер.
// Одна «отправка» нескольким группам называется пачкой: на сервере это несколько строк с общим номером пачки.

import 'attachment.dart';
import 'group_shared.dart';
import 'models.dart';

/// Преподаватель: токен на этом телефоне, имя из кода и группы, которым он может отправлять ДЗ.
class TeacherSession {
  const TeacherSession({required this.token, required this.teacher, required this.groups});

  final String token;
  final String teacher; // как записал владелец при выдаче кода («Иванов А.Б.»)
  final List<String> groups; // номера групп, которым разрешена отправка

  factory TeacherSession.fromJson(Map<String, dynamic> j) => TeacherSession(
        token: j['token'] as String,
        teacher: j['teacher'] as String,
        groups: [for (final g in (j['groups'] as List)) g as String],
      );
}

/// Кому ушло ДЗ: группа и, если не всей группе, номер подгруппы.
class TeacherSentTarget {
  const TeacherSentTarget({required this.groupId, this.subgroup});

  final String groupId;
  final int? subgroup;

  factory TeacherSentTarget.fromJson(Map<String, dynamic> j) =>
      TeacherSentTarget(groupId: j['id'] as String, subgroup: (j['subgroup'] as num?)?.toInt());

  Map<String, dynamic> toJson() => {'id': groupId, if (subgroup != null) 'subgroup': subgroup};
}

/// Отправка ДЗ (одна пачка): текст, срок, группы, файлы.
class TeacherHomeworkBatch {
  const TeacherHomeworkBatch({
    this.id,
    required this.subject,
    required this.text,
    required this.dueDate,
    required this.targets,
    this.kind,
    this.files = const [],
  });

  final String? id; // null — ещё не отправлено
  final String subject;
  final String text;
  final DateTime dueDate; // «только день», UTC
  final LessonKind? kind;
  final List<TeacherSentTarget> targets;
  final List<GroupFileRef> files;

  factory TeacherHomeworkBatch.fromJson(Map<String, dynamic> j) => TeacherHomeworkBatch(
        id: j['batch_id'] as String?,
        subject: j['subject'] as String,
        text: j['body'] as String,
        dueDate: parseDay(j['due_date'] as String),
        kind: j['kind'] == null ? null : LessonKind.parse(j['kind'] as String),
        targets: [for (final t in (j['groups'] as List)) TeacherSentTarget.fromJson(t as Map<String, dynamic>)],
        files: [for (final f in (j['files'] as List? ?? const [])) GroupFileRef.fromJson(f as Map<String, dynamic>)],
      );

  /// В том виде, в каком отправляется на сервер (и хранится в кэше телефона).
  Map<String, dynamic> toJson() => {
        if (id != null) 'batch_id': id,
        'subject': subject,
        'body': text,
        'due_date': dayText(dueDate),
        'kind': kind?.name,
        'groups': [for (final t in targets) t.toJson()],
        'files': [for (final f in files) f.toJson()],
      };

  /// Для показа файлов теми же плитками, что у других ДЗ.
  List<Attachment> get attachments => [for (final f in files) f.asAttachment];
}
