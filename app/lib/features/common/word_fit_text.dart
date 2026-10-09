// Текст, у которого слова не рвутся посреди слова. Обычный Text при нехватке места переносит длинное слово
// по буквам («Технологическое пр / едпринимательство»). Здесь шрифт слегка уменьшается так, чтобы самое
// длинное слово поместилось в строку целиком; сами строки при этом переносятся как обычно.

import 'package:flutter/material.dart';

class WordFitText extends StatelessWidget {
  const WordFitText(
    this.text, {
    super.key,
    this.style,
    this.trailing,
    this.minScale = 0.6,
  });

  final String text;
  final TextStyle? style;

  /// Что поставить после текста в той же строке (например, значок «есть ДЗ»).
  final InlineSpan? trailing;

  /// Насколько можно уменьшать шрифт (0.6 = до 60%). Дальше слово всё же перенесётся.
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        var factor = 1.0;
        final maxWidth = constraints.maxWidth;
        if (maxWidth.isFinite) {
          for (final word in text.split(RegExp(r'\s+'))) {
            if (word.length < 6) continue; // короткие слова и так помещаются
            final painter = TextPainter(
              text: TextSpan(text: word, style: base),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            if (painter.width > maxWidth) {
              final need = maxWidth / painter.width * 0.98;
              if (need < factor) factor = need;
            }
            painter.dispose();
          }
        }
        factor = factor.clamp(minScale, 1.0);
        final fitted = factor < 1.0
            ? base.copyWith(fontSize: (base.fontSize ?? 14) * factor)
            : base;
        return Text.rich(
          TextSpan(text: text, children: [if (trailing != null) trailing!]),
          style: fitted,
        );
      },
    );
  }
}
