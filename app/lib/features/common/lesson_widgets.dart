// Общие кусочки интерфейса: цвет предмета, значок типа занятия, строка пары.

import 'package:flutter/material.dart';

import '../../domain/models.dart';

/// Постоянный цвет предмета — по хешу названия (одно и то же название всегда даёт один цвет).
Color subjectColor(String subject, Brightness brightness) {
  var hash = 0;
  for (final unit in subject.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.55, brightness == Brightness.dark ? 0.68 : 0.40).toColor();
}

/// Бейдж «Лекция» / «Практика» / «Физ-ра».
class KindBadge extends StatelessWidget {
  const KindBadge(this.kind, {super.key});
  final LessonKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (kind) {
      LessonKind.lecture => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      LessonKind.practice => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(kind.title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

/// Одна строка пары: время, предмет, преподаватель, аудитория крупно.
class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.start,
    required this.end,
    required this.subject,
    required this.kind,
    this.teacher,
    this.room,
    this.highlighted = false,
    this.dimmed = false,
    this.note,
    this.hasHomework = false,
    this.onLongPress,
  });

  final String start;
  final String end;
  final String subject;
  final LessonKind kind;
  final String? teacher;
  final String? room;
  final bool highlighted;
  final bool dimmed;
  final String? note;
  final bool hasHomework; // есть невыполненное ДЗ на этот день
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = subjectColor(subject, theme.brightness);
    // Крупный системный шрифт: колонка времени шире, аудитория уезжает под название (иначе строка не помещается)
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final roomBelow = scale > 1.3;
    final tile = Container(
      decoration: BoxDecoration(
        color: highlighted ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 5, height: 52, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)))),
          SizedBox(
            width: 52 * scale.clamp(1.0, 2.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(start, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(end, style: theme.textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: subject),
                if (hasHomework)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.assignment_late_outlined, size: 18, color: theme.colorScheme.error)),
                  ),
              ]), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                KindBadge(kind),
                if (teacher != null) Text(teacher!, style: theme.textTheme.bodyMedium),
              ]),
              if (roomBelow && room != null)
                Text(room!, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (note != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note!, style: theme.textTheme.bodySmall)),
            ]),
          ),
          if (!roomBelow && room != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(room!, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
    return Semantics(
      label: '${hasHomework ? 'Есть домашнее задание. ' : ''}$start–$end, $subject, ${kind.title}${room != null ? ', аудитория $room' : ''}${teacher != null ? ', $teacher' : ''}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: onLongPress == null ? tile : GestureDetector(behavior: HitTestBehavior.opaque, onLongPress: onLongPress, child: tile),
        ),
      ),
    );
  }
}
