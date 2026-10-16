// Фирменный знак UniGraf: шапочка выпускника и буква «U». Картинка лежит в assets/logo/unigraf.png.
// Параметры цвета оставлены для совместимости (знак теперь готовая картинка со своим фоном).

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.background, this.foreground, this.accent});

  final double size;
  final Color? background;
  final Color? foreground;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset('assets/logo/unigraf.png', width: size, height: size, filterQuality: FilterQuality.high),
    );
  }
}
