// Мягкое появление элементов списка: каждый следующий чуть позже предыдущего (волной сверху вниз).
// Если в системе выключены анимации, всё показывается сразу.

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.index, required this.child});

  /// Порядковый номер в списке: чем он больше, тем позже появится элемент (после 8-го задержка не растёт).
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.slow);
    if (duration == Duration.zero) return child;
    final delay = Duration(milliseconds: 45 * index.clamp(0, 8));
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Motion.enter),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
