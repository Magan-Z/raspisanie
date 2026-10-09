// Фирменные цвета: «бумага + петроль + янтарь звонка».
//  • бумага — тёплый светлый фон, как страница расписания;
//  • петроль — глубокий сине-зелёный, основной цвет;
//  • янтарь — цвет школьного звонка, акцент (напоминания, «сейчас»).
// Тёмная тема — не инверсия светлой, а отдельно подобранные тона (контраст текста ≥ 4.5:1).

import 'package:flutter/material.dart';

/// Цветовые темы приложения. «Петроль» — фирменная (подобрана вручную), остальные строятся от оттенка по одним правилам,
/// а проверка контраста в тестах гарантирует читаемость каждой из них в светлом и тёмном виде.
enum AppPalette {
  petrol('petrol', 'Петроль', 'Фирменная: бумага и сине-зелёный', 190, 1.0),
  ocean('ocean', 'Океан', 'Спокойный синий', 215, 1.0),
  forest('forest', 'Лес', 'Глубокий зелёный', 150, 0.9),
  plum('plum', 'Слива', 'Тёплый фиолетовый', 285, 0.9),
  sunset('sunset', 'Закат', 'Терракота и коралл', 14, 1.0),
  graphite('graphite', 'Графит', 'Строгий серый, без цвета', 220, 0.12);

  const AppPalette(this.id, this.title, this.subtitle, this.hue, this.saturation);

  final String id;
  final String title;
  final String subtitle;
  final double hue; // оттенок 0–360
  final double saturation; // множитель насыщенности (графит почти без цвета)

  static AppPalette parse(String? id) => values.firstWhere((p) => p.id == id, orElse: () => AppPalette.petrol);
}

abstract final class BrandColors {
  /// Схема для выбранной цветовой темы. [amoled] — чисто чёрный фон в тёмной теме (экономит батарею на OLED-экранах).
  static ColorScheme scheme(AppPalette palette, Brightness brightness, {bool amoled = false}) {
    final base = palette == AppPalette.petrol
        ? (brightness == Brightness.dark ? dark() : light())
        : _generated(palette, brightness);
    return brightness == Brightness.dark && amoled ? toAmoled(base) : base;
  }

  /// Тёмная схема с чёрным фоном: поверхности — от чистого чёрного до тёмно-серого, остальное без изменений.
  static ColorScheme toAmoled(ColorScheme dark) => dark.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0B0B0C),
        surfaceContainer: const Color(0xFF121314),
        surfaceContainerHigh: const Color(0xFF191A1C),
        surfaceContainerHighest: const Color(0xFF212325),
        outlineVariant: const Color(0xFF30333A),
      );

  static Color _hsl(double hue, double sat, double light) =>
      HSLColor.fromAHSL(1, hue % 360, sat.clamp(0.0, 1.0), light.clamp(0.0, 1.0)).toColor();

  static ColorScheme _generated(AppPalette p, Brightness brightness) {
    final h = p.hue, k = p.saturation;
    final isDark = brightness == Brightness.dark;
    final seed = _hsl(h, 0.6 * k, 0.3);
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    if (!isDark) {
      return base.copyWith(
        primary: _hsl(h, 0.62 * k, 0.27),
        onPrimary: Colors.white,
        primaryContainer: _hsl(h, 0.5 * k, 0.88),
        onPrimaryContainer: _hsl(h, 0.8 * k, 0.1),
        secondary: _hsl(h, 0.22 * k, 0.33),
        onSecondary: Colors.white,
        secondaryContainer: _hsl(h, 0.24 * k, 0.89),
        onSecondaryContainer: _hsl(h, 0.35 * k, 0.1),
        tertiary: const Color(0xFF8A5600),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFFDDA8),
        onTertiaryContainer: const Color(0xFF2B1A00),
        surface: _hsl(h, 0.28 * k, 0.965),
        onSurface: _hsl(h, 0.12 * k, 0.1),
        onSurfaceVariant: _hsl(h, 0.1 * k, 0.32),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: _hsl(h, 0.26 * k, 0.945),
        surfaceContainer: _hsl(h, 0.24 * k, 0.925),
        surfaceContainerHigh: _hsl(h, 0.22 * k, 0.905),
        surfaceContainerHighest: _hsl(h, 0.2 * k, 0.885),
        outline: _hsl(h, 0.08 * k, 0.44),
        outlineVariant: _hsl(h, 0.16 * k, 0.82),
        error: const Color(0xFFB3261E),
        errorContainer: const Color(0xFFF9DEDC),
        onErrorContainer: const Color(0xFF410E0B),
      );
    }
    return base.copyWith(
      primary: _hsl(h, 0.62 * k, 0.74),
      onPrimary: _hsl(h, 0.9 * k, 0.12),
      primaryContainer: _hsl(h, 0.5 * k, 0.22),
      onPrimaryContainer: _hsl(h, 0.7 * k, 0.9),
      secondary: _hsl(h, 0.28 * k, 0.78),
      onSecondary: _hsl(h, 0.35 * k, 0.14),
      secondaryContainer: _hsl(h, 0.22 * k, 0.26),
      onSecondaryContainer: _hsl(h, 0.3 * k, 0.9),
      tertiary: const Color(0xFFF5C26B),
      onTertiary: const Color(0xFF442C00),
      tertiaryContainer: const Color(0xFF5E4100),
      onTertiaryContainer: const Color(0xFFFFDDA8),
      surface: _hsl(h, 0.22 * k, 0.075),
      onSurface: _hsl(h, 0.1 * k, 0.9),
      onSurfaceVariant: _hsl(h, 0.08 * k, 0.72),
      surfaceContainerLowest: _hsl(h, 0.22 * k, 0.055),
      surfaceContainerLow: _hsl(h, 0.22 * k, 0.095),
      surfaceContainer: _hsl(h, 0.22 * k, 0.12),
      surfaceContainerHigh: _hsl(h, 0.2 * k, 0.145),
      surfaceContainerHighest: _hsl(h, 0.2 * k, 0.175),
      outline: _hsl(h, 0.08 * k, 0.58),
      outlineVariant: _hsl(h, 0.14 * k, 0.26),
      error: const Color(0xFFFFB4AB),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );
  }

  static const Color petrol = Color(0xFF0B5563);
  static const Color bellAmber = Color(0xFFF2A93B);

  static ColorScheme light() => ColorScheme.fromSeed(seedColor: petrol, brightness: Brightness.light).copyWith(
        primary: const Color(0xFF0B5563),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFCDEBF0),
        onPrimaryContainer: const Color(0xFF00282F),
        secondary: const Color(0xFF47606A),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFDCE8EC),
        onSecondaryContainer: const Color(0xFF0E1D22),
        tertiary: const Color(0xFF8A5600),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFFDDA8),
        onTertiaryContainer: const Color(0xFF2B1A00),
        surface: const Color(0xFFFBF8F3),
        onSurface: const Color(0xFF1B1C1A),
        onSurfaceVariant: const Color(0xFF51565A),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F2EA),
        surfaceContainer: const Color(0xFFF0ECE3),
        surfaceContainerHigh: const Color(0xFFEAE6DC),
        surfaceContainerHighest: const Color(0xFFE4E0D6),
        outline: const Color(0xFF787D80),
        outlineVariant: const Color(0xFFD8D4CA),
        error: const Color(0xFFB3261E),
        errorContainer: const Color(0xFFF9DEDC),
        onErrorContainer: const Color(0xFF410E0B),
      );

  static ColorScheme dark() => ColorScheme.fromSeed(seedColor: petrol, brightness: Brightness.dark).copyWith(
        primary: const Color(0xFF7FD3E0),
        onPrimary: const Color(0xFF00363E),
        primaryContainer: const Color(0xFF0F4A55),
        onPrimaryContainer: const Color(0xFFBFEFF7),
        secondary: const Color(0xFFADC8D0),
        onSecondary: const Color(0xFF173038),
        secondaryContainer: const Color(0xFF2B434B),
        onSecondaryContainer: const Color(0xFFD0E6EC),
        tertiary: const Color(0xFFF5C26B),
        onTertiary: const Color(0xFF442C00),
        tertiaryContainer: const Color(0xFF5E4100),
        onTertiaryContainer: const Color(0xFFFFDDA8),
        surface: const Color(0xFF0E1416),
        onSurface: const Color(0xFFE3E7E8),
        onSurfaceVariant: const Color(0xFFB5BEC0),
        surfaceContainerLowest: const Color(0xFF0A0F11),
        surfaceContainerLow: const Color(0xFF131A1C),
        surfaceContainer: const Color(0xFF172023),
        surfaceContainerHigh: const Color(0xFF1D272A),
        surfaceContainerHighest: const Color(0xFF243034),
        outline: const Color(0xFF899295),
        outlineVariant: const Color(0xFF3A4548),
        error: const Color(0xFFFFB4AB),
        errorContainer: const Color(0xFF93000A),
        onErrorContainer: const Color(0xFFFFDAD6),
      );
}
