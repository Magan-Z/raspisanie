// «Что вы изменили для группы»: список правок расписания и ДЗ, которые видит вся группа. Староста может удалить любую.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/formatting.dart';
import '../../data/remote/shared_api.dart';
import '../../domain/overrides_text.dart';
import '../../group_actions.dart';
import '../../theme/tokens.dart';

class GroupChangesScreen extends ConsumerWidget {
  const GroupChangesScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on SharedApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(groupSharedProvider).value;
    final index = ref.watch(indexProvider).value;
    final groupId = ref.watch(editorProvider)?.groupId;
    final hash = groupId == null ? null : index?.findGroup(groupId)?.hash;

    final overrides = state == null ? <dynamic>[] : (state.activeOverrides(hash).toList()..sort((a, b) => a.date.compareTo(b.date)));
    final homework = state?.homeworkList ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Изменения для группы')),
      body: (overrides.isEmpty && homework.isEmpty)
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(Gap.xl),
                child: Text('Пока вы ничего не меняли для группы. Нажмите на пару на экране «Сегодня» — там появятся действия «Для всей группы».', textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
              children: [
                if (overrides.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: Gap.sm), child: Text('Расписание', style: theme.textTheme.titleMedium)),
                for (final o in overrides)
                  _Item(
                    title: describeOverride(o.toOverride()),
                    subtitle: dayTitle(o.date),
                    onDelete: () => _run(context, () => GroupEditorActions.of(context).deleteOverride(o.id)),
                  ),
                if (homework.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.sm), child: Text('Домашние задания', style: theme.textTheme.titleMedium)),
                for (final h in homework)
                  _Item(
                    title: '${h.subject}: ${h.text}',
                    subtitle: 'к ${dateText(h.dueDate)}',
                    onDelete: () => _run(context, () => GroupEditorActions.of(context).deleteHomework(h.id)),
                  ),
                const SizedBox(height: Gap.lg),
                Text(
                  'Когда на сайт загрузят новое расписание, правки расписания старосты стираются сами: новое расписание точнее.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.title, required this.subtitle, required this.onDelete});
  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.xs, Gap.sm),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
            IconButton(tooltip: 'Удалить для всей группы', icon: const Icon(Icons.delete_outline_rounded), onPressed: onDelete),
          ]),
        ),
      ),
    );
  }
}
