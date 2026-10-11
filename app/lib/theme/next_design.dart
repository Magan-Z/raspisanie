// Тестовое оформление («новый вид»). Включается при сборке: --dart-define=NEXT_DESIGN=true.
// Обычная сборка (Android и /app/ на сайте) этот флаг не включает и выглядит как раньше.
// Если новый вид понравится, флаг убирается, а новое становится основным.

import 'package:flutter/animation.dart';

const bool kNextDesign = bool.fromEnvironment('NEXT_DESIGN');

/// Уверенное торможение (быстрый старт, очень мягкая остановка): для появления элементов.
const Curve kEaseOutExpo = Cubic(0.16, 1, 0.3, 1);
