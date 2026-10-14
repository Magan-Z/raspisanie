// Выбор преподавателя: «Найдите себя в списке». Список строится из расписания всех групп и справочника института,
// поэтому у кого полное ФИО неизвестно, виден с инициалами («Абубакаров М.»). Поиск по любой части имени.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../domain/search.dart';
import '../../theme/tokens.dart';

/// Поле поиска и список преподавателей. [onPicked] вызывается с выбранным именем.
class TeacherPicker extends ConsumerStatefulWidget {
  const TeacherPicker({super.key, required this.onPicked, this.selected});

  final ValueChanged<String> onPicked;
  final String? selected;

  @override
  ConsumerState<TeacherPicker> createState() => _TeacherPickerState();
}

class _TeacherPickerState extends ConsumerState<TeacherPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final all = ref.watch(allGroupsProvider);
    final index = ref.watch(indexProvider).value;

    return all.when(
      loading: () => const Padding(padding: EdgeInsets.all(Gap.xl), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(Gap.lg), child: Text('Не удалось прочитать расписания:\n$e')),
      data: (schedules) {
        final names = teacherNames(schedules, directory: index?.teachers ?? const []);
        final q = _query.text.trim().toLowerCase();
        final shown = q.isEmpty ? names : [for (final n in names) if (n.toLowerCase().contains(q)) n];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(labelText: 'Фамилия или имя', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.md),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.xl),
                child: Text(
                  'Никого не нашлось. Если вас нет в списке, значит ваших пар нет в расписании: напишите автору приложения.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            else
              for (final name in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.xs),
                  child: Material(
                    color: name == widget.selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(Radii.md),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => widget.onPicked(name),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: minTouch),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
                          child: Row(children: [
                            Expanded(child: Text(name, style: theme.textTheme.bodyLarge)),
                            if (name == widget.selected) Icon(Icons.check_rounded, color: scheme.onPrimaryContainer),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Отдельный экран выбора (из «Настройки → Профиль»).
class TeacherPickerScreen extends ConsumerWidget {
  const TeacherPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider.select((s) => s.teacherName));
    return Scaffold(
      appBar: AppBar(title: const Text('Кто вы?')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.lg),
          children: [
            Text('Найдите себя в списке: расписание покажет ваши пары во всех группах.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Gap.lg),
            TeacherPicker(
              selected: current,
              onPicked: (name) async {
                await ref.read(settingsProvider.notifier).setTeacher(name);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
