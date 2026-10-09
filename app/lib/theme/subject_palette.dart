// Цвета предметов. У каждого предмета свой постоянный цвет (по названию): глаз быстро находит
// «свою» пару в списке. Палитра подобрана вручную из 10 разнесённых оттенков, одинаково
// аккуратно выглядящих в светлой и тёмной теме. Цвет никогда не единственный признак: рядом всегда название.

import 'package:flutter/material.dart';

class SubjectTone {
  const SubjectTone({required this.accent, required this.container, required this.onContainer});

  /// Насыщенный цвет: полоска слева, рамка таблички с аудиторией, прогресс.
  final Color accent;

  /// Мягкий фон карточки.
  final Color container;

  /// Цвет текста и значков поверх мягкого фона (контраст ≥ 4.5:1).
  final Color onContainer;
}

// (акцент светлой темы, фон светлой, акцент тёмной, фон тёмной)
const _palette = <(Color, Color, Color, Color)>[
  (Color(0xFF0E8F86), Color(0xFFD6F0EC), Color(0xFF5CD6C9), Color(0xFF12403D)), // бирюза
  (Color(0xFF4F5BD5), Color(0xFFE2E5FB), Color(0xFFA5ADFF), Color(0xFF262C5E)), // индиго
  (Color(0xFFC23B67), Color(0xFFFBE0E9), Color(0xFFFF9DBD), Color(0xFF5A1C32)), // роза
  (Color(0xFFB8740A), Color(0xFFFBEBCB), Color(0xFFF5C26B), Color(0xFF4D3406)), // янтарь
  (Color(0xFF3F8F3A), Color(0xFFDDF0D8), Color(0xFF8FD987), Color(0xFF1F4119)), // зелень
  (Color(0xFF8A4FC7), Color(0xFFEBDDF8), Color(0xFFCBA3F0), Color(0xFF3F2260)), // фиалка
  (Color(0xFFD2552F), Color(0xFFFCE0D6), Color(0xFFFFA586), Color(0xFF5C2413)), // коралл
  (Color(0xFF1B7FC0), Color(0xFFD9ECF9), Color(0xFF86C6F2), Color(0xFF12395A)), // небо
  (Color(0xFF7A8A12), Color(0xFFEBF0C6), Color(0xFFCBD870), Color(0xFF3B4306)), // олива
  (Color(0xFF566676), Color(0xFFE1E6EB), Color(0xFFA9B7C4), Color(0xFF28313A)), // сланец
];

/// Устойчивый хеш строки (FNV-1a): один и тот же предмет всегда получает один и тот же цвет,
/// на любом телефоне и после обновления приложения.
int stableHash(String text) {
  var hash = 0x811C9DC5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

SubjectTone subjectTone(String subject, Brightness brightness) {
  final (lightAccent, lightContainer, darkAccent, darkContainer) = _palette[stableHash(subject) % _palette.length];
  if (brightness == Brightness.dark) {
    return SubjectTone(accent: darkAccent, container: darkContainer, onContainer: _tint(darkAccent, 0.88));
  }
  return SubjectTone(accent: lightAccent, container: lightContainer, onContainer: _tint(lightAccent, 0.17));
}

/// Тот же оттенок, но заданной светлоты — для читаемого текста на мягком фоне.
Color _tint(Color color, double lightness) => HSLColor.fromColor(color).withLightness(lightness).withSaturation(0.55).toColor();

/// Для проверок: размер палитры.
int get subjectPaletteSize => _palette.length;
