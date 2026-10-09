// Доступность: контраст текста и фона не ниже 4,5:1 (WCAG AA) во всех цветовых парах приложения,
// в светлой и тёмной темах, для всех десяти цветов предметов.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/theme/brand_colors.dart';
import 'package:raspisanie/theme/subject_palette.dart';

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Контраст по WCAG; полупрозрачный верхний цвет предварительно смешивается с фоном.
double contrast(Color fg, Color bg) {
  final blended = Color.alphaBlend(fg, bg);
  final l1 = _luminance(blended), l2 = _luminance(bg);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  // Все цветовые темы: светлая, тёмная и тёмная с чёрным фоном
  final schemes = <(String, ColorScheme)>[
    for (final p in AppPalette.values) ...[
      ('${p.title}, светлая', BrandColors.scheme(p, Brightness.light)),
      ('${p.title}, тёмная', BrandColors.scheme(p, Brightness.dark)),
      ('${p.title}, чёрный фон', BrandColors.scheme(p, Brightness.dark, amoled: true)),
    ],
  ];
  for (final (name, scheme) in schemes) {
    group('Тема: $name', () {
      void expectAa(String what, Color fg, Color bg, {double min = 4.5}) {
        final ratio = contrast(fg, bg);
        expect(ratio, greaterThanOrEqualTo(min), reason: '$what: контраст ${ratio.toStringAsFixed(2)}:1 (нужно ≥ $min)');
      }

      test('основной и второстепенный текст на фонах', () {
        for (final (label, bg) in [
          ('surface', scheme.surface),
          ('container low', scheme.surfaceContainerLow),
          ('container', scheme.surfaceContainer),
          ('container high', scheme.surfaceContainerHigh),
        ]) {
          expectAa('onSurface на $label', scheme.onSurface, bg);
          expectAa('onSurfaceVariant на $label', scheme.onSurfaceVariant, bg);
          expectAa('primary на $label', scheme.primary, bg);
        }
      });

      test('пары «цвет + цвет текста поверх»', () {
        expectAa('onPrimary на primary (выбранный день)', scheme.onPrimary, scheme.primary);
        expectAa('onPrimaryContainer на primaryContainer', scheme.onPrimaryContainer, scheme.primaryContainer);
        expectAa('onTertiaryContainer на tertiaryContainer («Сейчас», баннер)', scheme.onTertiaryContainer, scheme.tertiaryContainer);
        expectAa('onSecondaryContainer на secondaryContainer', scheme.onSecondaryContainer, scheme.secondaryContainer);
        expectAa('onErrorContainer на errorContainer', scheme.onErrorContainer, scheme.errorContainer);
        expectAa('error на surface (просрочено)', scheme.error, scheme.surface);
      });

      test('значки и границы: не менее 3:1 к фону', () {
        expect(contrast(scheme.outline, scheme.surface), greaterThanOrEqualTo(3.0));
        expect(contrast(scheme.primary, scheme.surface), greaterThanOrEqualTo(3.0));
      });

      test('цвета предметов: текст на мягком фоне карточки, акцент и «табличка»', () {
        for (var i = 0; i < 200; i++) {
          final tone = subjectTone('предмет $i', scheme.brightness);
          expectAa('onSurface на карточке предмета $i', scheme.onSurface, tone.container);
          expectAa('onSurfaceVariant (преподаватель) на карточке предмета $i', scheme.onSurfaceVariant, tone.container);
          expectAa('текст типа занятия на карточке предмета $i', tone.onContainer, tone.container);
          // «табличка» с аудиторией: тёмный/светлый текст на бумаге
          expectAa('номер аудитории на табличке предмета $i', tone.onContainer, scheme.surface);
          // залитая табличка в крупной карточке: цвет поверхности на акценте
          expectAa('номер аудитории на залитой табличке предмета $i', scheme.surface, tone.accent, min: 3.0); // крупный текст (≥ 24sp)
          // акцентная полоска и рамка различимы на карточке
          expectAa('акцент предмета $i на своей карточке (значок/рамка)', tone.accent, tone.container, min: 1.4);
        }
      });
    });
  }

  test('палитра предметов: цвета распределяются по всем 10 вариантам, один предмет — один цвет', () {
    final used = {for (var i = 0; i < 500; i++) subjectTone('предмет $i', Brightness.light).accent};
    expect(used.length, subjectPaletteSize);
    expect(subjectTone('Философия', Brightness.light).accent, subjectTone('Философия', Brightness.light).accent);
    expect(stableHash('Философия'), stableHash('Философия'));
    expect(stableHash('Философия'), isNot(stableHash('Математика')));
  });
}
