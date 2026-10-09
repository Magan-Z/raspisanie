// Небольшие векторные иллюстрации для пустых экранов и приветствия. Рисуются в цветах текущей темы,
// поэтому сами подстраиваются под светлую/тёмную тему и выбранную цветовую тему. Никаких картинок-файлов.

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum IllustrationKind {
  freeDay, // чашка чая: пар нет
  holiday, // солнце: праздник
  noHomework, // планшет с галочкой: ДЗ нет
  welcome, // стопка карточек и звонок: первый запуск
  nothingFound, // лупа: ничего не найдено
}

class Illustration extends StatelessWidget {
  const Illustration(this.kind, {super.key, this.width = 168});

  final IllustrationKind kind;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 0.76,
        child: CustomPaint(painter: _IllustrationPainter(kind, scheme)),
      ),
    );
  }
}

/// Рисуем в «логических» координатах 168×128 и масштабируем под любой размер.
class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.kind, this.s);
  final IllustrationKind kind;
  final ColorScheme s;

  static const _w = 168.0, _h = 128.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _w, size.height / _h);
    switch (kind) {
      case IllustrationKind.freeDay:
        _backdrop(canvas);
        _cup(canvas);
      case IllustrationKind.holiday:
        _backdrop(canvas);
        _sun(canvas);
      case IllustrationKind.noHomework:
        _backdrop(canvas);
        _clipboard(canvas);
      case IllustrationKind.welcome:
        _welcome(canvas);
      case IllustrationKind.nothingFound:
        _backdrop(canvas);
        _magnifier(canvas);
    }
  }

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Мягкое «пятно» позади рисунка.
  void _backdrop(Canvas canvas) {
    canvas.drawOval(Rect.fromCenter(center: const Offset(84, 66), width: 140, height: 112), _fill(s.tertiaryContainer));
    // Мелкие «конфетти»
    final dots = [
      (const Offset(22, 26), 4.0, s.primary),
      (const Offset(148, 34), 3.5, s.tertiary),
      (const Offset(140, 100), 4.5, s.primary),
      (const Offset(26, 98), 3.0, s.secondary),
    ];
    for (final (p, r, c) in dots) {
      canvas.drawCircle(p, r, _fill(c.withValues(alpha: 0.55)));
    }
  }

  void _cup(Canvas canvas) {
    // блюдце
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 100, 76, 8), const Radius.circular(4)), _fill(s.primary.withValues(alpha: 0.8)));
    // ручка
    canvas.drawArc(const Rect.fromLTWH(98, 66, 30, 26), -math.pi / 2, math.pi, false, _stroke(s.primary, 7));
    // чашка
    final body = RRect.fromRectAndCorners(const Rect.fromLTWH(52, 62, 62, 40),
        topLeft: const Radius.circular(6), topRight: const Radius.circular(6), bottomLeft: const Radius.circular(26), bottomRight: const Radius.circular(26));
    canvas.drawRRect(body, _fill(s.primary));
    // чай
    canvas.drawOval(const Rect.fromLTWH(52, 57, 62, 12), _fill(s.primaryContainer));
    canvas.drawOval(const Rect.fromLTWH(56, 59.5, 54, 7), _fill(s.tertiary));
    // блик на чашке
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(60, 76, 5, 16), const Radius.circular(3)), _fill(s.onPrimary.withValues(alpha: 0.35)));
    // пар
    for (final x in [68.0, 83.0, 98.0]) {
      final path = Path()
        ..moveTo(x, 50)
        ..cubicTo(x - 7, 42, x + 7, 36, x, 28);
      canvas.drawPath(path, _stroke(s.onTertiaryContainer.withValues(alpha: 0.45), 3.5));
    }
  }

  void _sun(Canvas canvas) {
    const c = Offset(84, 66);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * 34, c + Offset(math.cos(a), math.sin(a)) * (i.isEven ? 48 : 42), _stroke(s.tertiary, 5));
    }
    canvas.drawCircle(c, 27, _fill(s.tertiary));
    canvas.drawCircle(c, 20, _fill(s.tertiaryContainer.withValues(alpha: 0.55)));
    // улыбка
    canvas.drawArc(Rect.fromCenter(center: c.translate(0, 2), width: 22, height: 16), 0.35, math.pi - 0.7, false, _stroke(s.onTertiary, 3.2));
    canvas.drawCircle(c.translate(-7, -5), 2.4, _fill(s.onTertiary));
    canvas.drawCircle(c.translate(7, -5), 2.4, _fill(s.onTertiary));
  }

  void _clipboard(Canvas canvas) {
    final board = RRect.fromRectAndRadius(const Rect.fromLTWH(54, 24, 60, 82), const Radius.circular(10));
    canvas.drawRRect(board.shift(const Offset(0, 3)), _fill(s.onTertiaryContainer.withValues(alpha: 0.12)));
    canvas.drawRRect(board, _fill(s.surface));
    canvas.drawRRect(board, _stroke(s.primary, 3));
    // зажим
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 18, 28, 14), const Radius.circular(5)), _fill(s.primary));
    canvas.drawCircle(const Offset(84, 25), 2.5, _fill(s.surface));
    // строки: галочка + линия
    for (var i = 0; i < 3; i++) {
      final y = 46.0 + i * 18;
      canvas.drawCircle(Offset(68, y), 5.5, i == 0 ? _fill(s.tertiary) : _stroke(s.outline, 1.8));
      if (i == 0) {
        final tick = Path()
          ..moveTo(65.2, y + 0.2)
          ..lineTo(67.4, y + 2.4)
          ..lineTo(71.2, y - 2);
        canvas.drawPath(tick, _stroke(s.onTertiary, 1.9));
      }
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(79, y - 2, i == 1 ? 24 : 28, 4), const Radius.circular(2)), _fill(s.outlineVariant));
    }
  }

  void _magnifier(Canvas canvas) {
    const c = Offset(78, 58);
    canvas.drawLine(c + const Offset(24, 24), c + const Offset(42, 42), _stroke(s.primary, 9));
    canvas.drawCircle(c, 28, _fill(s.surface));
    canvas.drawCircle(c, 28, _stroke(s.primary, 7));
    // «?» из дуги и точки
    final q = Path()
      ..moveTo(c.dx - 8, c.dy - 8)
      ..cubicTo(c.dx - 8, c.dy - 20, c.dx + 10, c.dy - 20, c.dx + 8, c.dy - 8)
      ..cubicTo(c.dx + 7, c.dy - 2, c.dx, c.dy, c.dx, c.dy + 6);
    canvas.drawPath(q, _stroke(s.tertiary, 4.5));
    canvas.drawCircle(c.translate(0, 15), 2.8, _fill(s.tertiary));
  }

  void _welcome(Canvas canvas) {
    // три карточки-пары лесенкой, как строки расписания
    final cards = [
      (const Rect.fromLTWH(18, 18, 96, 28), s.primary, s.onPrimary),
      (const Rect.fromLTWH(34, 54, 96, 28), s.primaryContainer, s.onPrimaryContainer),
      (const Rect.fromLTWH(50, 90, 96, 28), s.secondaryContainer, s.onSecondaryContainer),
    ];
    for (final (rect, bg, fg) in cards) {
      final r = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      canvas.drawRRect(r.shift(const Offset(0, 2.5)), _fill(s.onSurface.withValues(alpha: 0.08)));
      canvas.drawRRect(r, _fill(bg));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 10, rect.top + 8, 44, 5), const Radius.circular(2.5)), _fill(fg.withValues(alpha: 0.9)));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 10, rect.top + 17, 28, 4), const Radius.circular(2)), _fill(fg.withValues(alpha: 0.5)));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.right - 30, rect.top + 6, 22, 16), const Radius.circular(5)), _fill(fg.withValues(alpha: 0.18)));
    }
    // звонок
    const b = Offset(136, 30);
    canvas.drawCircle(b, 17, _fill(s.tertiaryContainer));
    final bell = Path()
      ..moveTo(b.dx - 8, b.dy + 5)
      ..cubicTo(b.dx - 8, b.dy - 1, b.dx - 7, b.dy - 9, b.dx, b.dy - 9)
      ..cubicTo(b.dx + 7, b.dy - 9, b.dx + 8, b.dy - 1, b.dx + 8, b.dy + 5)
      ..close();
    canvas.drawPath(bell, _fill(s.tertiary));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.dx - 10, b.dy + 4, 20, 3.5), const Radius.circular(1.8)), _fill(s.tertiary));
    canvas.drawCircle(b.translate(0, 10), 2.4, _fill(s.tertiary));
    canvas.drawCircle(const Offset(150, 58), 3.5, _fill(s.primary.withValues(alpha: 0.5)));
    canvas.drawCircle(const Offset(14, 78), 3, _fill(s.tertiary.withValues(alpha: 0.6)));
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) => old.kind != kind || old.s != s;
}
