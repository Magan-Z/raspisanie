// «Настройки → Предметы»: список предметов вашей группы со своими названиями и цветами.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../domain/subject_styles.dart';
import '../../theme/tokens.dart';
import 'subject_style_editor.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final my = ref.watch(myScheduleProvider).value;
    final styles = ref.watch(subjectStylesProvider);
    final enabled = ref.watch(settingsProvider.select((s) => s.customSubjects));

    // Все предметы группы (и свои добавленные пары), по алфавиту
    final subjects = <String>{
      if (my != null) for (final l in my.schedule.lessons) l.subject,
      if (my != null) for (final o in my.overrides) if (o.subject != null) o.subject!,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Предметы'),
        actions: [
          if (styles.styles.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Сбросить все предметы?'),
                    content: const Text('Все свои названия и цвета будут удалены, предметы станут такими, как в расписании.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сбросить')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(subjectStylesRepositoryProvider).resetAll();
                  ref.invalidate(subjectStyleMapProvider);
                }
              },
              child: const Text('Сбросить всё'),
            ),
        ],
      ),
      body: subjects.isEmpty
          ? const Center(child: Text('Предметов пока нет'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
              children: [
                if (!enabled)
                  Container(
                    margin: const EdgeInsets.only(bottom: Gap.md),
                    padding: const EdgeInsets.all(Gap.md),
                    decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(Radii.md)),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded, color: scheme.onTertiaryContainer),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Text('Свои названия и цвета сейчас выключены — в приложении показываются названия из расписания.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onTertiaryContainer)),
                      ),
                    ]),
                  ),
                Text('Нажмите на предмет, чтобы задать короткое название и цвет. Расписание при этом не меняется.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: Gap.md),
                for (final subject in subjects) _SubjectRow(subject: subject),
              ],
            ),
    );
  }
}

class _SubjectRow extends ConsumerWidget {
  const _SubjectRow({required this.subject});
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Здесь показываем настройки всегда (даже если выключатель выключен), чтобы их можно было готовить заранее
    final map = ref.watch(subjectStyleMapProvider).value ?? const {};
    final own = map[subject];
    final preview = SubjectStyles(styles: map); // «как будет, если включить»
    final shown = preview.tone(subject, theme.brightness);
    final name = preview.name(subject);
    final hasOwn = own != null && !own.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showSubjectStyleEditor(context, subject),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
            child: Row(children: [
              Container(width: 14, height: 40, decoration: BoxDecoration(color: shown.accent, borderRadius: BorderRadius.circular(7))),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: theme.textTheme.titleSmall?.copyWith(fontSize: 16)),
                  if (name != subject) Text(subject, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ),
              if (hasOwn) Icon(Icons.edit_rounded, size: 18, color: scheme.primary) else Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}
