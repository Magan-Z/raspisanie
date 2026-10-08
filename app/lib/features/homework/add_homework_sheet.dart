// Окно «Добавить ДЗ». Срок подставляется сам — следующее занятие этого предмета (АРХИТЕКТУРА.md, §8).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_state.dart';
import '../../core/formatting.dart';
import '../../domain/homework.dart';
import '../../domain/homework_due.dart';
import '../../domain/models.dart';
import '../../domain/week_view.dart';

/// Открывает окно добавления. [subject] — предмет, если уже известен (например, по долгому нажатию на пару).
Future<void> showAddHomework(BuildContext context, {String? subject}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddHomeworkSheet(initialSubject: subject),
  );
}

class _AddHomeworkSheet extends ConsumerStatefulWidget {
  const _AddHomeworkSheet({this.initialSubject});
  final String? initialSubject;

  @override
  ConsumerState<_AddHomeworkSheet> createState() => _AddHomeworkSheetState();
}

class _AddHomeworkSheetState extends ConsumerState<_AddHomeworkSheet> {
  final _text = TextEditingController();
  String? _subject;
  LessonKind? _kind; // null — к любому занятию
  DateTime? _manualDue; // выбранный вручную срок
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Срок: выбранный вручную или следующее занятие предмета.
  DateTime? _due(MySchedule data, DateTime today) {
    if (_manualDue != null) return _manualDue;
    final subject = _subject;
    if (subject == null) return null;
    return nextOccurrence(subject, today, data.index, data.schedule, data.profile, kind: _kind);
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _save(DateTime due) async {
    await ref.read(homeworkRepositoryProvider).add(HomeworkItem(
          subject: _subject!,
          text: _text.text.trim(),
          dueDate: due,
          kind: _kind,
          createdAt: DateTime.now().toUtc(),
          photoPath: _photoPath,
        ));
    ref.invalidate(homeworkProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(myScheduleProvider).value;
    final today = ref.watch(todayProvider);
    final theme = Theme.of(context);
    if (data == null) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));

    final subjects = subjectsOf(data.schedule, data.profile);
    final due = _due(data, today);
    final canSave = _subject != null && _text.text.trim().isNotEmpty && due != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Новое ДЗ', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownMenu<String>(
              key: ValueKey(_subject),
              expandedInsets: EdgeInsets.zero,
              label: const Text('Предмет'),
              initialSelection: _subject,
              enableFilter: true,
              dropdownMenuEntries: [for (final s in subjects) DropdownMenuEntry(value: s, label: s)],
              onSelected: (v) => setState(() {
                _subject = v;
                _manualDue = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              autofocus: widget.initialSubject != null,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Что задали', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('К любому занятию'), selected: _kind == null, onSelected: (_) => setState(() => _kind = null)),
              ChoiceChip(label: const Text('К лекции'), selected: _kind == LessonKind.lecture, onSelected: (_) => setState(() => _kind = LessonKind.lecture)),
              ChoiceChip(label: const Text('К практике'), selected: _kind == LessonKind.practice, onSelected: (_) => setState(() => _kind = LessonKind.practice)),
            ]),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(due == null ? (_subject == null ? 'Выберите предмет' : 'Занятий не найдено — выберите дату') : 'Срок: ${dayTitle(due)}'),
              subtitle: Text(_manualDue == null ? 'Подставлено автоматически — следующее занятие' : 'Выбрано вручную'),
              trailing: TextButton(
                child: const Text('Изменить'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: due ?? today,
                    firstDate: today.subtract(const Duration(days: 30)),
                    lastDate: today.add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _manualDue = DateTime.utc(picked.year, picked.month, picked.day));
                },
              ),
            ),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_outlined),
                label: Text(_photoPath == null ? 'Фото доски' : 'Фото прикреплено'),
              ),
              const Spacer(),
              FilledButton(onPressed: canSave ? () => _save(due) : null, child: const Text('Добавить')),
            ]),
          ],
        ),
      ),
    );
  }
}
