// Фирменные цвета: «бумага + петроль + янтарь звонка».
//  • бумага — тёплый светлый фон, как страница расписания;
//  • петроль — глубокий сине-зелёный, основной цвет;
//  • янтарь — цвет школьного звонка, акцент (напоминания, «сейчас»).
// Тёмная тема — не инверсия светлой, а отдельно подобранные тона (контраст текста ≥ 4.5:1).

import 'package:flutter/material.dart';

abstract final class BrandColors {
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
