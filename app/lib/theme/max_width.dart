// На широких экранах (компьютер, планшет) экраны не растягиваются на всю ширину, а встают колонкой по центру:
// карточки шириной 1300 пикселей читать неудобно. На телефоне ничего не меняется. Всплывающие окна (листы, диалоги)
// сюда не входят: у них свой предел ширины, а затемнение закрывает весь экран, поэтому нажатие сбоку закрывает окно.

import 'package:flutter/material.dart';

class MaxContentWidth extends StatelessWidget {
  const MaxContentWidth({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child)),
    );
  }
}

/// Оборачивает переход между экранами: каждый экран получает колонку по центру.
class CenteredColumnTransitions extends PageTransitionsBuilder {
  const CenteredColumnTransitions(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      inner.buildTransitions(route, context, animation, secondaryAnimation, MaxContentWidth(child: child));
}
