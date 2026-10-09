// Экран «Неделя»: переключатель 1 / 2 неделя (по умолчанию текущая). Показываются настоящие даты,
// поэтому здесь видны и ваши личные правки (отмены, переносы, свои пары).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/bells.dart';
import '../../core/formatting.dart';
import '../../domain/homework.dart';
import '../../domain/schedule_resolver.dart';
import '../../theme/tokens.dart';
import '../common/lesson_widgets.dart';
import '../overrides/day_edits.dart';

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  int? _week; // null — показывать текущую

  /// Понедельник недели с нужным номером: текущая неделя, если номер совпадает, иначе следующая.
  DateTime _mondayOf(int week, DateTime today, MySchedule data) {
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return data.weekFor(thisMonday) == week ? thisMonday : thisMonday.add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final my = ref.watch(myScheduleProvider);
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider).now();
    final homework = ref.watch(homeworkWithGroupProvider).value ?? const <HomeworkItem>[];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return my.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Не удалось прочитать расписание:\n$e', textAlign: TextAlign.center)),
      data: (data) {
        if (data == null) return const SizedBox();
        final currentWeek = data.weekFor(today);
        final week = _week ?? currentWeek;
        final monday = _mondayOf(week, today, data);
        final saturday = monday.add(const Duration(days: 5));

        // Дни недели с парами; воскресенье показываем, только если там есть ваша своя пара
        final days = [
          for (var i = 0; i < 7; i++)
            (
              day: monday.add(Duration(days: i)),
              lessons: resolve(monday.add(Duration(days: i)), data.index, data.schedule, data.profile,
                  overrides: data.overrides, forcedWeek: _week ?? data.forcedWeek),
            ),
        ].where((d) => d.day.weekday != DateTime.sunday || d.lessons.isNotEmpty).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
              child: Text('Неделя', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: Gap.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
              child: Text('${dateText(monday)} – ${dateText(saturday)}', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: Gap.lg),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text(currentWeek == 1 ? '1 неделя · сейчас' : '1 неделя'))),
                ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text(currentWeek == 2 ? '2 неделя · сейчас' : '2 неделя'))),
              ],
              selected: {week},
              onSelectionChanged: (s) => setState(() => _week = s.first),
            ),
            for (final entry in days) ...[
              _DayHeader(day: entry.day, isToday: entry.day == today),
              if (entry.lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: Gap.xs, bottom: Gap.sm),
                  child: Row(children: [
                    Icon(data.index.holidays.contains(entry.day) ? Icons.celebration_rounded : Icons.free_breakfast_rounded,
                        size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: Gap.sm),
                    Text(data.index.holidays.contains(entry.day) ? 'Праздничный день' : 'Пар нет',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ]),
                ),
              for (final l in entry.lessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: LessonTile(
                    timeLabel: '${moscowTimeText(l.startAt)}–${moscowTimeText(l.endAt)} · ${l.pair} пара',
                    subject: l.subject,
                    kind: l.kind,
                    teacher: l.teacher,
                    room: l.room,
                    highlighted: entry.day == today && !now.isBefore(l.startAt) && now.isBefore(l.endAt),
                    dimmed: entry.day == today && !now.isBefore(l.endAt),
                    note: l.note ?? (l.isPersonal ? 'изменено вами' : (l.isGroup ? 'изменено старостой' : null)),
                    hasHomework: dueOn(homework, entry.day).any((h) => h.subject == l.subject),
                    onLongPress: () => showLessonActions(context, l),
                    onTap: () => showLessonActions(context, l),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.isToday});
  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xl, Gap.xs, Gap.sm),
      child: Wrap(spacing: Gap.sm, runSpacing: Gap.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(weekdayTitles[day.weekday], style: theme.textTheme.titleMedium),
        Text(dateText(day), style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
            decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(999)),
            child: Text('сегодня', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onTertiaryContainer)),
          ),
      ]),
    );
  }
}
