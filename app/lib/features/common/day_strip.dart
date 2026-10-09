// Полоса дней недели: Пн … Вс. Выбранный день залит, сегодняшний обведён, точка под числом — в этот день есть пары.
// Касание выбирает день, свайп по полосе листает неделю.

import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../theme/tokens.dart';

class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.lessonCounts,
    required this.onSelect,
    required this.onShiftWeek,
  });

  final DateTime selected;
  final DateTime today;

  /// Сколько пар в каждый из 7 дней недели (понедельник … воскресенье).
  final List<int> lessonCounts;
  final ValueChanged<DateTime> onSelect;

  /// −1 — предыдущая неделя, +1 — следующая.
  final ValueChanged<int> onShiftWeek;

  @override
  Widget build(BuildContext context) {
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() > 200) onShiftWeek(v < 0 ? 1 : -1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md),
        child: Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayCell(
                day: monday.add(Duration(days: i)),
                isSelected: monday.add(Duration(days: i)) == selected,
                isToday: monday.add(Duration(days: i)) == today,
                count: lessonCounts[i],
                onTap: () => onSelect(monday.add(Duration(days: i))),
              ),
            ),
        ]),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isSelected, required this.isToday, required this.count, required this.onTap});
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = isSelected ? scheme.onPrimary : (isToday ? scheme.primary : scheme.onSurface);
    final isSunday = day.weekday == DateTime.sunday;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${weekdayTitles[day.weekday]}, ${dateText(day)}${isToday ? ', сегодня' : ''}, '
          '${count == 0 ? 'пар нет' : '$count ${plural(count, 'пара', 'пары', 'пар')}'}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(weekdayShort[day.weekday],
                  style: theme.textTheme.labelSmall?.copyWith(color: isSunday ? scheme.onSurfaceVariant.withValues(alpha: 0.7) : scheme.onSurfaceVariant)),
              const SizedBox(height: Gap.xs),
              AnimatedContainer(
                duration: Motion.of(context, Motion.base),
                curve: Motion.enter,
                width: 40,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: isToday && !isSelected ? Border.all(color: scheme.primary, width: 2) : null,
                ),
                child: Text('${day.day}', style: theme.textTheme.titleMedium?.copyWith(color: fg)),
              ),
              const SizedBox(height: Gap.xs),
              // Точка: в этот день есть пары (не только цветом — ещё и в подписи для скринридера)
              AnimatedContainer(
                duration: Motion.of(context, Motion.base),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: count > 0 ? scheme.tertiary : Colors.transparent,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
