// Переключатель из нескольких равных частей с «ползунком»: выбранная часть подсвечена плашкой,
// а плашка плавно переезжает на новое место. Используется в «Поиске», «ДЗ» и «Неделе» — везде одинаково.
// Все части всегда в одну строку: длинное слово чуть уменьшается, если не влезает.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/next_design.dart';
import '../../theme/tokens.dart';
import 'press_scale.dart';

class Segment<T> {
  const Segment(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class SlidingSegments<T> extends StatelessWidget {
  const SlidingSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = segments.length;
    final index = segments
        .indexWhere((s) => s.value == selected)
        .clamp(0, n - 1);
    final duration = Motion.of(context, const Duration(milliseconds: 380));
    final labelStyle = Theme.of(context).textTheme.labelLarge!;

    // Material, а не Container: иначе всплеск от нажатия прячется под фоном
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // ползунок: стоит под подписями и переезжает к выбранной части
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: kEaseOutExpo,
                alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      child: PressScale(
                        scale: 0.96,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          onTap: () {
                            if (i == index) return;
                            HapticFeedback.selectionClick();
                            onChanged(segments[i].value);
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: minTouch - 8,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: Gap.sm,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedDefaultTextStyle(
                                    duration: duration == Duration.zero
                                        ? Duration.zero
                                        : const Duration(milliseconds: 220),
                                    style: labelStyle.copyWith(
                                      color: i == index
                                          ? scheme.onPrimaryContainer
                                          : scheme.onSurfaceVariant,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (segments[i].icon != null) ...[
                                          Icon(
                                            segments[i].icon,
                                            size: 18,
                                            color: i == index
                                                ? scheme.onPrimaryContainer
                                                : scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(segments[i].label),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
