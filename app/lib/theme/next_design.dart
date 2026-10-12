// Новое оформление и анимации («новый вид») — теперь основное, включено по умолчанию.
// Флаг оставлен, чтобы при необходимости быстро вернуть прежний вид: --dart-define=NEXT_DESIGN=false.
// Обычная сборка (Android и /app/ на сайте) его не трогает и получает новый вид.

import 'package:flutter/animation.dart';

const bool kNextDesign = bool.fromEnvironment('NEXT_DESIGN', defaultValue: true);

/// Пометка «Тестовый вид» в настройках: только у специальной тестовой сборки (NEXT_BADGE=true).
const bool kTestBadge = bool.fromEnvironment('NEXT_BADGE');

/// Уверенное торможение (быстрый старт, очень мягкая остановка): для появления элементов.
const Curve kEaseOutExpo = Cubic(0.16, 1, 0.3, 1);
