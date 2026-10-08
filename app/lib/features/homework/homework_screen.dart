// Экран «ДЗ»: разделы «Просрочено / На сегодня / На завтра / На этой неделе / Позже / Выполнено».
// Свайп вправо — выполнено, влево — удалить.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/formatting.dart';
import '../../domain/homework.dart';
import 'add_homework_sheet.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(homeworkProvider);
    final today = ref.watch(todayProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddHomework(context),
        icon: const Icon(Icons.add),
        label: const Text('ДЗ'),
      ),
      body: homework.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Не удалось прочитать ДЗ:\n$e', textAlign: TextAlign.center)),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Домашки нет 🎉\nЗадание можно добавить кнопкой «ДЗ» или долгим нажатием на пару на экране «Сегодня».',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final groups = groupHomework(items, today);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('Домашка', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(entry.key.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: entry.key == HomeworkBucket.overdue ? Theme.of(context).colorScheme.error : null,
                          )),
                ),
                for (final item in entry.value) _HomeworkTile(item: item),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HomeworkTile extends ConsumerWidget {
  const _HomeworkTile({required this.item});
  final HomeworkItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(homeworkRepositoryProvider);

    return Dismissible(
      key: ValueKey('hw-${item.id}'),
      background: _swipeBackground(context, Icons.check, 'Выполнено', Alignment.centerLeft, theme.colorScheme.primaryContainer),
      secondaryBackground: _swipeBackground(context, Icons.delete_outline, 'Удалить', Alignment.centerRight, theme.colorScheme.errorContainer),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await repo.setDone(item.id!, !item.done);
        } else {
          await repo.delete(item.id!);
        }
        ref.invalidate(homeworkProvider);
        return false; // список перерисуется сам
      },
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: item.done,
            onChanged: (v) async {
              await repo.setDone(item.id!, v ?? false);
              ref.invalidate(homeworkProvider);
            },
          ),
          title: Text(item.subject, style: TextStyle(decoration: item.done ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.text),
            const SizedBox(height: 2),
            Text('к ${dateText(item.dueDate)}${item.kind == null ? '' : ' · ${item.kind!.title.toLowerCase()}'}', style: theme.textTheme.bodySmall),
            if (item.photoPath != null && File(item.photoPath!).existsSync())
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(child: InteractiveViewer(child: Image.file(File(item.photoPath!)))),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item.photoPath!), height: 80, fit: BoxFit.cover)),
                ),
              ),
          ]),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _swipeBackground(BuildContext context, IconData icon, String label, Alignment alignment, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: alignment,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(width: 8), Text(label)]),
      );
}
