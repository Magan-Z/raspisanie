// Карточка пары: название, тип, преподаватель и «табличка» с аудиторией. Цвета — по предмету.

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme/subject_palette.dart';
import '../../theme/tokens.dart';
import 'room_plate.dart';

/// Подпись типа занятия («Лекция» / «Практика»). Смысл несёт слово, а не цвет.
class KindBadge extends StatelessWidget {
  const KindBadge(this.kind, {super.key, this.tone});
  final LessonKind kind;
  final SubjectTone? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (bg, fg) = tone != null
        ? (tone!.accent.withValues(alpha: 0.16), tone!.onContainer)
        : (scheme.secondaryContainer, scheme.onSecondaryContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.sm - 4)),
      child: Text(kind.title, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}

/// Одна пара. [timeLabel] — подпись со временем (в списке «Неделя»); в ленте «Сегодня» время стоит слева, там null.
class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.subject,
    required this.kind,
    this.timeLabel,
    this.teacher,
    this.room,
    this.highlighted = false,
    this.dimmed = false,
    this.note,
    this.hasHomework = false,
    this.footer,
    this.onLongPress,
    this.onTap,
  });

  final String? timeLabel;
  final String subject;
  final LessonKind kind;
  final String? teacher;
  final String? room;
  final bool highlighted;
  final bool dimmed;
  final String? note;
  final bool hasHomework;
  final String? footer; // дополнительная строка внизу (например, список групп в поиске)
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = subjectTone(subject, theme.brightness);
    final textColor = scheme.onSurface;

    final card = Material(
      color: tone.container,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: highlighted ? BorderSide(color: tone.accent, width: 2.5) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 6, color: tone.accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.md, Gap.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (timeLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.xs),
                      child: Text(timeLabel!, style: theme.textTheme.labelMedium?.copyWith(color: tone.onContainer)),
                    ),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: subject),
                      if (hasHomework)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: Gap.sm),
                            child: Icon(Icons.assignment_late_rounded, size: 18, color: scheme.error, semanticLabel: 'Есть домашнее задание'),
                          ),
                        ),
                    ]),
                    style: theme.textTheme.titleMedium?.copyWith(color: textColor),
                  ),
                  const SizedBox(height: Gap.sm),
                  // Нижняя строка: тип и преподаватель слева, «табличка» с аудиторией справа
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Wrap(spacing: Gap.sm, runSpacing: Gap.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        KindBadge(kind, tone: tone),
                        if (teacher != null) Text(teacher!, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                    if (room != null) ...[
                      const SizedBox(width: Gap.sm),
                      RoomPlate(room: room!, tone: tone),
                    ],
                  ]),
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.sm),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_note_rounded, size: 16, color: tone.onContainer),
                        const SizedBox(width: Gap.xs),
                        Flexible(child: Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: tone.onContainer))),
                      ]),
                    ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.sm),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.groups_rounded, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: Gap.xs),
                        Flexible(child: Text(footer!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                      ]),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: '${timeLabel != null ? '$timeLabel, ' : ''}$subject, ${kind.title}'
          '${room != null ? ', аудитория $room' : ''}${teacher != null ? ', $teacher' : ''}'
          '${hasHomework ? '. Есть домашнее задание' : ''}${note != null ? '. $note' : ''}${footer != null ? '. $footer' : ''}',
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressHint: onLongPress == null ? null : 'Действия с парой',
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: dimmed ? 0.55 : 1,
          duration: Motion.of(context, Motion.base),
          child: card,
        ),
      ),
    );
  }
}
