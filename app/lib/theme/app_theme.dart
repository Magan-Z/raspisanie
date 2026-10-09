// Тема приложения (Material 3): шрифт Onest, формы, компоненты.
// Толщина шрифта задаётся осью wght переменного шрифта — это даёт «промежуточные» начертания (550, 650, 750).



import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand_colors.dart';
import 'tokens.dart';

const _family = 'Onest';

TextStyle _style(double size, double weight, {double height = 1.3, double spacing = 0, Color? color}) => TextStyle(
      fontFamily: _family,
      fontSize: size,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', weight)],
      height: height,
      letterSpacing: spacing,
      color: color,
    );

/// Стиль номера аудитории: цифры одинаковой ширины, жирно — читается с вытянутой руки.
TextStyle roomTextStyle(double size, {Color? color}) => _style(size, 800, height: 1.05, spacing: -0.5, color: color)
    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

TextTheme buildTextTheme(ColorScheme s) => TextTheme(
      displayLarge: _style(56, 800, height: 1.05, spacing: -1.5),
      displayMedium: _style(44, 800, height: 1.08, spacing: -1),
      displaySmall: _style(36, 750, height: 1.1, spacing: -0.5),
      headlineLarge: _style(32, 780, height: 1.15, spacing: -0.5),
      headlineMedium: _style(28, 750, height: 1.18, spacing: -0.3),
      headlineSmall: _style(24, 720, height: 1.2, spacing: -0.2),
      titleLarge: _style(21, 700, height: 1.25),
      titleMedium: _style(17, 650, height: 1.3),
      titleSmall: _style(14.5, 650, height: 1.3, spacing: 0.1),
      bodyLarge: _style(16, 450, height: 1.45),
      bodyMedium: _style(14.5, 450, height: 1.42),
      bodySmall: _style(12.5, 450, height: 1.4),
      labelLarge: _style(14.5, 620, height: 1.2, spacing: 0.1),
      labelMedium: _style(12.5, 620, height: 1.2, spacing: 0.3),
      labelSmall: _style(11.5, 620, height: 1.2, spacing: 0.4),
    ).apply(bodyColor: s.onSurface, displayColor: s.onSurface);

ThemeData buildTheme(ColorScheme scheme) {
  final text = buildTextTheme(scheme);
  final isDark = scheme.brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _family,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          )),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      labelStyle: text.labelLarge,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(text.labelLarge),
        minimumSize: const WidgetStatePropertyAll(Size(0, minTouch)),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, minTouch),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(0, minTouch), textStyle: text.labelLarge),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, minTouch),
        textStyle: text.labelLarge,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.tertiaryContainer,
      foregroundColor: scheme.onTertiaryContainer,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedTextStyle: text.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: scheme.primary, width: 2)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: Gap.sm,
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: scheme.surfaceContainerHighest),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    }),
  );
}

/// Схема цветов: выбранная цветовая тема или цвета из обоев (Material You), если пользователь так выбрал.
/// [amoled] — чёрный фон в тёмной теме.
ColorScheme resolveScheme({
  required Brightness brightness,
  ColorScheme? dynamicScheme,
  AppPalette palette = AppPalette.petrol,
  bool amoled = false,
}) {
  if (dynamicScheme != null) {
    final scheme = dynamicScheme.harmonized();
    return brightness == Brightness.dark && amoled ? BrandColors.toAmoled(scheme) : scheme;
  }
  return BrandColors.scheme(palette, brightness, amoled: amoled);
}
