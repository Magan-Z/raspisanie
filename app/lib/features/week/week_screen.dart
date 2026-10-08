// Экран «Неделя»: переключатель 1 / 2 неделя (по умолчанию текущая), дни списком.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/bells.dart';
import '../../core/formatting.dart';
import '../../domain/week_view.dart';
import '../common/lesson_widgets.dart';
import '../homework/add_homework_sheet.dart';

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  int? _week; // null — показывать текущую

  @override
  Widget build(BuildContext context) {
    final my = ref.watch(myScheduleProvider);
    final today = ref.watch(todayProvider);
    return my.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Не удалось прочитать расписание:\n$e', textAlign: TextAlign.center)),
      data: (data) {
        if (data == null) return const SizedBox();
        final currentWeek = data.weekFor(today);
        final week = _week ?? currentWeek;
        final template = weekTemplate(data.schedule, data.profile, week);
        final bells = data.index.bells;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text(currentWeek == 1 ? '1 неделя · сейчас' : '1 неделя'))),
                ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text(currentWeek == 2 ? '2 неделя · сейчас' : '2 неделя'))),
              ],
              selected: {week},
              onSelectionChanged: (s) => setState(() => _week = s.first),
            ),
            for (var weekday = 1; weekday <= 6; weekday++)
              if (template[weekday]!.isNotEmpty || weekday < 6) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(
                    weekdayTitles[weekday] + (week == currentWeek && weekday == today.weekday ? ' · сегодня' : ''),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (template[weekday]!.isEmpty) Text('Пар нет', style: theme.textTheme.bodyMedium),
                for (final l in template[weekday]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LessonTile(
                      start: bells[l.pair - 1].startText,
                      end: bells[l.pair - 1].endText,
                      subject: l.subject,
                      kind: l.kind,
                      teacher: l.teacher,
                      room: l.room,
                      onLongPress: () => showAddHomework(context, subject: l.subject),
                      highlighted: week == currentWeek && weekday == today.weekday && _isNow(ref, l.pair, bells),
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }

  bool _isNow(WidgetRef ref, int pair, List bells) {
    final now = ref.read(nowProvider).value ?? ref.read(clockProvider).now();
    final (start, end) = pairTimes(ref.read(todayProvider), pair, List.castFrom(bells));
    return !now.isBefore(start) && now.isBefore(end);
  }
}
