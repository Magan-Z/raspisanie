// Личные правки расписания: действия над парой (долгое нажатие) и список «Мои правки на этот день».
// Правки живут только на телефоне. Они учитываются в «Сегодня», виджетах и уведомлениях.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/formatting.dart';
import '../../domain/models.dart';
import '../../domain/overrides_text.dart';
import '../homework/add_homework_sheet.dart';

/// Долгое нажатие на пару: что с ней можно сделать.
Future<void> showLessonActions(BuildContext context, ResolvedLesson lesson) {
  // Меню закрывается раньше, чем заканчивается действие, поэтому всё нужное берём заранее у внешнего контекста
  final container = ProviderScope.containerOf(context);
  final repo = container.read(overridesRepositoryProvider);

  Future<void> save(Override o) async {
    await repo.save(o);
    container.invalidate(overridesProvider);
  }

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      void close() => Navigator.of(sheetContext).pop();

      return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(lesson.subject, style: Theme.of(sheetContext).textTheme.titleMedium),
            subtitle: Text('${dayTitle(lesson.date)}, ${lesson.pair} пара'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_add),
            title: const Text('Добавить ДЗ'),
            onTap: () {
              close();
              showAddHomework(context, subject: lesson.subject);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Изменить на этот день'),
            subtitle: const Text('Другая аудитория, преподаватель или заметка'),
            onTap: () async {
              close();
              final changed = await showDialog<Override>(context: context, builder: (_) => _ReplaceDialog(lesson: lesson));
              if (changed != null) await save(changed);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('Отменить пару'),
            subtitle: const Text('Только у вас, на этот день'),
            onTap: () async {
              close();
              await save(Override(date: lesson.date, pair: lesson.pair, type: OverrideType.cancel));
            },
          ),
          if (lesson.isPersonal)
            ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('Вернуть как было'),
              onTap: () async {
                close();
                await repo.clearPair(lesson.date, lesson.pair);
                container.invalidate(overridesProvider);
              },
            ),
        ]),
      );
    },
  );
}

/// «Мои правки на этот день»: список правок (чтобы вернуть отменённую пару) и добавление своей пары.
Future<void> showDayEdits(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DayEditsSheet(day: day),
  );
}

class _DayEditsSheet extends ConsumerWidget {
  const _DayEditsSheet({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(overridesProvider).value ?? const [];
    final mine = [for (final o in all) if (o.date == day) o];
    final repo = ref.read(overridesRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Мои правки · ${dayTitle(day)}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (mine.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('На этот день правок нет. Изменить или отменить пару можно долгим нажатием на неё.'),
          ),
        for (final o in mine)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(describeOverride(o)),
            trailing: IconButton(
              tooltip: 'Убрать правку',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await repo.delete(o.id!);
                ref.invalidate(overridesProvider);
              },
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.add),
          label: const Text('Добавить свою пару'),
          onPressed: () async {
            final added = await showDialog<Override>(context: context, builder: (_) => _AddPairDialog(day: day));
            if (added != null) {
              await repo.save(added);
              ref.invalidate(overridesProvider);
            }
          },
        ),
      ]),
    );
  }
}

class _ReplaceDialog extends StatefulWidget {
  const _ReplaceDialog({required this.lesson});
  final ResolvedLesson lesson;

  @override
  State<_ReplaceDialog> createState() => _ReplaceDialogState();
}

class _ReplaceDialogState extends State<_ReplaceDialog> {
  late final _room = TextEditingController(text: widget.lesson.room ?? '');
  late final _teacher = TextEditingController(text: widget.lesson.teacher ?? '');
  late final _note = TextEditingController(text: widget.lesson.isPersonal ? (widget.lesson.note ?? '') : '');

  @override
  void dispose() {
    _room.dispose();
    _teacher.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    return AlertDialog(
      title: const Text('Изменить на этот день'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _room, decoration: const InputDecoration(labelText: 'Аудитория')),
          TextField(controller: _teacher, decoration: const InputDecoration(labelText: 'Преподаватель')),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Заметка (например, «перенесли с 3 пары»)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            Override(
              date: l.date,
              pair: l.pair,
              type: OverrideType.replace,
              // Сохраняем только то, что действительно изменено
              room: _room.text.trim() == (l.room ?? '') ? null : blankToNull(_room.text),
              teacher: _teacher.text.trim() == (l.teacher ?? '') ? null : blankToNull(_teacher.text),
              note: blankToNull(_note.text),
            ),
          ),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _AddPairDialog extends StatefulWidget {
  const _AddPairDialog({required this.day});
  final DateTime day;

  @override
  State<_AddPairDialog> createState() => _AddPairDialogState();
}

class _AddPairDialogState extends State<_AddPairDialog> {
  final _subject = TextEditingController();
  final _room = TextEditingController();
  final _teacher = TextEditingController();
  final _note = TextEditingController();
  int _pair = 1;

  @override
  void dispose() {
    _subject.dispose();
    _room.dispose();
    _teacher.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Своя пара'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Номер пары'),
          Wrap(spacing: 8, children: [
            for (var p = 1; p <= 5; p++) ChoiceChip(label: Text('$p'), selected: _pair == p, onSelected: (_) => setState(() => _pair = p)),
          ]),
          TextField(controller: _subject, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Название')),
          TextField(controller: _room, decoration: const InputDecoration(labelText: 'Аудитория')),
          TextField(controller: _teacher, decoration: const InputDecoration(labelText: 'Преподаватель')),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Заметка')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: _subject.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    Override(
                      date: widget.day,
                      pair: _pair,
                      type: OverrideType.add,
                      subject: _subject.text.trim(),
                      room: blankToNull(_room.text),
                      teacher: blankToNull(_teacher.text),
                      note: blankToNull(_note.text),
                    ),
                  ),
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
