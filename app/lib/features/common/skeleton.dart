// Заготовка вместо крутящегося индикатора: пока расписание читается, на экране видны «тени» будущих карточек.
// Так приложение сразу выглядит собранным, а появление данных не «прыгает».

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class ScheduleSkeleton extends StatefulWidget {
  const ScheduleSkeleton({super.key});

  @override
  State<ScheduleSkeleton> createState() => _ScheduleSkeletonState();
}

class _ScheduleSkeletonState extends State<ScheduleSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Без анимаций в системе — просто неподвижные заготовки
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Загружаем расписание',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final color = Color.lerp(scheme.surfaceContainerHigh, scheme.surfaceContainerHighest, Curves.easeInOut.transform(_c.value))!;
              Widget bar(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h / 2.5)));
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                bar(220, 28),
                const SizedBox(height: Gap.sm),
                bar(120, 14),
                const SizedBox(height: Gap.xl),
                for (var i = 0; i < 4; i++) ...[
                  Container(height: 96, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radii.lg))),
                  const SizedBox(height: Gap.md),
                ],
              ]);
            },
          ),
        ),
      ),
    );
  }
}
