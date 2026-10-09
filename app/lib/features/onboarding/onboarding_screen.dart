// Первый запуск: форма → курс → группа → подгруппа → физ-ра. Без регистрации, ~10 секунд.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../../theme/tokens.dart';
import '../common/brand_mark.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.changing = false});

  /// true — экран открыт из настроек (смена группы), можно вернуться назад.
  final bool changing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  FormInfo? _form;
  int? _course;
  GroupInfo? _group;
  int? _subgroup;

  Future<void> _finish(PeChoice pe) async {
    await ref.read(settingsProvider.notifier).setProfile(UserProfile(
          formCode: _form!.code,
          groupId: _group!.id,
          subgroup: _subgroup ?? 1,
          pe: pe,
        ));
    if (widget.changing && mounted) Navigator.of(context).pop();
  }

  void _afterSubgroup(GroupInfo group) {
    // Если у группы физ-ра делится на юношей и девушек — спрашиваем, иначе готово
    if (!group.hasGenderedPe) _finish(PeChoice.both);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(indexProvider);
    return Scaffold(
      appBar: widget.changing ? AppBar(title: const Text('Выбор группы')) : null,
      body: SafeArea(
        child: index.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Не удалось загрузить список групп:\n$e', textAlign: TextAlign.center)),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(ScheduleIndex index) {
    final theme = Theme.of(context);
    final form = _form;
    final course = _course;
    final group = _group;

    return ListView(
      padding: const EdgeInsets.all(Gap.xl),
      children: [
        if (!widget.changing) ...[
          const Align(alignment: Alignment.centerLeft, child: BrandMark(size: 72)),
          const SizedBox(height: Gap.xl),
          Text('Расписание', style: theme.textTheme.displaySmall),
          const SizedBox(height: Gap.sm),
          Text(
            'Расписание всего института в телефоне: пары, аудитории, домашка и напоминания. Без регистрации.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Gap.xl),
          Text('Выберите свою группу — это займёт несколько секунд', style: theme.textTheme.titleMedium),
          const SizedBox(height: Gap.lg),
        ],
        _Step(
          title: 'Форма обучения',
          choices: [for (final f in index.forms) _Choice(f.title, selected: f == form, onTap: () => setState(() {
                _form = f;
                _course = null;
                _group = null;
                _subgroup = null;
              }))],
        ),
        if (form != null)
          _Step(
            title: 'Курс',
            choices: [
              for (final c in ({for (final g in form.groups) g.course}.toList()..sort()))
                _Choice('$c курс', selected: c == course, onTap: () => setState(() {
                      _course = c;
                      _group = null;
                      _subgroup = null;
                    })),
            ],
          ),
        if (form != null && course != null)
          _Step(
            title: 'Группа',
            choices: [
              for (final g in form.groups.where((g) => g.course == course))
                _Choice(g.title, selected: g == group, onTap: () {
                  setState(() {
                    _group = g;
                    _subgroup = g.subgroups.length == 1 ? 1 : null;
                  });
                  if (g.subgroups.length == 1) _afterSubgroup(g);
                }),
            ],
          ),
        if (group != null && group.subgroups.length > 1)
          _Step(
            title: 'Подгруппа',
            hint: 'Подгруппа 1 — левый столбец группы в таблице расписания.',
            choices: [
              for (final s in group.subgroups)
                _Choice(s.label, selected: s.n == _subgroup, onTap: () {
                  setState(() => _subgroup = s.n);
                  _afterSubgroup(group);
                }),
            ],
          ),
        if (group != null && group.hasGenderedPe && _subgroup != null)
          _Step(
            title: 'Физкультура',
            hint: 'У вашей группы физкультура отдельно у юношей и у девушек.',
            choices: [
              for (final p in PeChoice.values) _Choice(p.title, selected: false, onTap: () => _finish(p)),
            ],
          ),
      ],
    );
  }
}

class _Choice {
  const _Choice(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.choices, this.hint});
  final String title;
  final String? hint;
  final List<_Choice> choices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(Radii.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary, letterSpacing: 1.2)),
            const SizedBox(height: Gap.md),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final c in choices)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: c.selected,
                    onSelected: (_) => c.onTap(),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.sm),
                  ),
              ],
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: Gap.md),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
