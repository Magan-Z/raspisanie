// Отклик на касание: пока палец на карточке, она чуть уменьшается («продавливается»), при отпускании возвращается.
// Это сообщает «я тебя почувствовал» ещё до того, как что-то откроется. Если в системе выключены анимации, ничего не двигается.

import 'package:flutter/widgets.dart';

import '../../theme/next_design.dart';
import '../../theme/tokens.dart';

class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.975});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    // Listener не мешает нажатиям внутри (InkWell и т.д.): он только наблюдает
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        // нажатие быстрое, возврат чуть дольше и мягче
        duration: Motion.of(context, _down ? const Duration(milliseconds: 90) : const Duration(milliseconds: 260)),
        curve: _down ? Curves.easeOut : kEaseOutExpo,
        child: widget.child,
      ),
    );
  }
}
