// Фирменный знак: два «блока пары» разной длины (как строки расписания) и янтарная точка — звонок.
// Тот же рисунок используется в значке приложения (см. tool/make_icon.py), поэтому они всегда совпадают.

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.background, this.foreground, this.accent});

  final double size;

  /// Цвет «плитки» под знаком. null — фирменный петроль.
  final Color? background;
  final Color? foreground;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BrandMarkPainter(
            background: background ?? const Color(0xFF0B5563),
            foreground: foreground ?? Colors.white,
            accent: accent ?? const Color(0xFFF2A93B),
          ),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({required this.background, required this.foreground, required this.accent});
  final Color background;
  final Color foreground;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Плитка со скруглением
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.28)), Paint()..color = background);

    // Два блока: длинный белый и короткий янтарный — «две строки одной пары»
    final block = Paint()..color = foreground;
    final amber = Paint()..color = accent;
    final r = Radius.circular(s * 0.07);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.22, s * 0.30, s * 0.56, s * 0.14), r), block);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.22, s * 0.56, s * 0.34, s * 0.14), r), amber);
    // Точка-звонок справа от нижнего блока
    canvas.drawCircle(Offset(s * 0.68, s * 0.63), s * 0.07, amber);
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.background != background || old.foreground != foreground || old.accent != accent;
}
