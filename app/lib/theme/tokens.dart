// Единые «меры» оформления: отступы, радиусы, время и кривые анимаций.
// Все экраны берут значения отсюда — тогда интерфейс выглядит цельно (сетка 4/8 dp).

import 'package:flutter/material.dart';

/// Отступы (сетка 4/8 dp).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Радиусы скруглений.
abstract final class Radii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

/// Анимации: короткие — отклик на касание, средние — смена содержимого, длинные — крупные переходы.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 400);

  /// Плавное появление (быстрый старт, мягкая остановка).
  static const Curve enter = Curves.easeOutCubic;

  /// Уход быстрее появления.
  static const Curve exit = Curves.easeInCubic;

  /// Если в системе выключены анимации — длительность нулевая.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// Минимальная область касания на Android — 48 dp.
const double minTouch = 48;
