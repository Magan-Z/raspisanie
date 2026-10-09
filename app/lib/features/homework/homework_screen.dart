// Экран «ДЗ»: разделы «Просрочено / На сегодня / На завтра / На этой неделе / Позже / Выполнено».
// Свайп вправо — выполнено, влево — удалить (то же есть кнопками: флажок слева и меню действий).


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/formatting.dart';
import '../../domain/homework.dart';
import '../../theme/subject_palette.dart';
import '../../theme/tokens.dart';
import '../common/word_fit_text.dart';
import 'attachment_widgets.dart';
import '../common/empty_state.dart';
import '../common/illustrations.dart';
import 'add_homework_sheet.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(homeworkProvider);
    final today = ref.watch(todayProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddHomework(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить ДЗ'),
      ),
      body: homework.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, title: 'Не удалось прочитать ДЗ', subtitle: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              illustration: IllustrationKind.noHomework,
              title: 'Домашки нет',
              subtitle: 'Задание можно добавить кнопкой «Добавить ДЗ» или нажатием на пару на экране «Сегодня».',
            );
          }
          final groups = groupHomework(items, today);
          final open = items.where((i) => !i.done).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 104),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                child: Text('Домашка', style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: Gap.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                child: Text(
                  open == 0 ? 'Всё сделано' : 'Не сделано: $open',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xl, Gap.xs, Gap.sm),
                  child: Row(children: [
                    if (entry.key == HomeworkBucket.overdue) ...[
                      Icon(Icons.error_rounded, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: Gap.xs),
                    ],
                    Text(
                      entry.key.title,
                      style: theme.textTheme.titleSmall?.copyWith(color: entry.key == HomeworkBucket.overdue ? theme.colorScheme.error : null),
                    ),
                    const SizedBox(width: Gap.sm),
                    Text('${entry.value.length}', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
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
    final scheme = theme.colorScheme;
    final repo = ref.read(homeworkRepositoryProvider);
    final tone = subjectTone(item.subject, theme.brightness);

    Future<void> toggle() async {
      // лёгкая вибрация: при отметке «сделано» — щелчок, при возврате — слабее
      item.done ? HapticFeedback.selectionClick() : HapticFeedback.lightImpact();
      await repo.setDone(item.id!, !item.done);
      ref.invalidate(homeworkProvider);
    }

    Future<void> remove() async {
      await repo.delete(item.id!);
      ref.invalidate(homeworkProvider);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Dismissible(
        key: ValueKey('hw-${item.id}'),
        background: _swipeBackground(context, Icons.check_rounded, 'Выполнено', Alignment.centerLeft, scheme.primaryContainer, scheme.onPrimaryContainer),
        secondaryBackground: _swipeBackground(context, Icons.delete_outline_rounded, 'Удалить', Alignment.centerRight, scheme.errorContainer, scheme.onErrorContainer),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await toggle();
          } else {
            await remove();
          }
          return false; // список перерисуется сам
        },
        child: Material(
          color: item.done ? scheme.surfaceContainerLow : tone.container,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            // цветная полоса слева — граница карточки (без IntrinsicHeight, внутри есть LayoutBuilder)
            decoration: BoxDecoration(border: Border(left: BorderSide(color: item.done ? scheme.outlineVariant : tone.accent, width: 6))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(left: Gap.xs),
                child: Semantics(
                  label: item.done ? 'Выполнено. Нажмите, чтобы вернуть' : 'Отметить выполненным',
                  child: Checkbox(
                    value: item.done,
                    shape: const CircleBorder(),
                    side: BorderSide(color: tone.accent, width: 2),
                    activeColor: tone.accent,
                    onChanged: (_) => toggle(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, Gap.md, Gap.xs, Gap.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    WordFitText(
                      item.subject,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: item.done ? scheme.onSurfaceVariant : tone.onContainer,
                        decoration: item.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(item.text, style: theme.textTheme.bodyLarge?.copyWith(color: item.done ? scheme.onSurfaceVariant : scheme.onSurface)),
                    const SizedBox(height: Gap.sm),
                    Row(children: [
                      Icon(Icons.event_rounded, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: Gap.xs),
                      Flexible(
                        child: Text(
                          'к ${dateText(item.dueDate)}${item.kind == null ? '' : ' · ${item.kind!.title.toLowerCase()}'}',
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ]),
                    AttachmentStrip(attachments: item.attachments, color: tone.accent),
                  ]),
                ),
              ),
              // Кнопка вместо скрытых свайпов: «Удалить» доступно и без жестов
              PopupMenuButton<String>(
                tooltip: 'Действия с заданием',
                icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
                onSelected: (v) => v == 'delete' ? remove() : toggle(),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'toggle', child: Text(item.done ? 'Вернуть в невыполненные' : 'Отметить выполненным')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground(BuildContext context, IconData icon, String label, Alignment alignment, Color color, Color onColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        alignment: alignment,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radii.lg)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: onColor),
          const SizedBox(width: Gap.sm),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: onColor)),
        ]),
      );
}
