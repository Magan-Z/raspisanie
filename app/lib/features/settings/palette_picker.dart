// Выбор цветовой темы: ряд карточек-превью. На каждой — мини-экран в цветах темы
// (фон, основной цвет, акцент «звонка»), чтобы выбор был наглядным, а не по названию.

import 'package:flutter/material.dart';

import '../../theme/brand_colors.dart';
import '../../theme/tokens.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({super.key, required this.selected, required this.onSelected, required this.amoled});

  final AppPalette selected;
  final ValueChanged<AppPalette> onSelected;
  final bool amoled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, Gap.md, 0, Gap.md),
      child: SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          itemCount: AppPalette.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: Gap.md),
          itemBuilder: (context, i) {
            final palette = AppPalette.values[i];
            return _PaletteCard(
              palette: palette,
              scheme: BrandColors.scheme(palette, brightness, amoled: amoled),
              selected: palette == selected,
              onTap: () => onSelected(palette),
            );
          },
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.palette, required this.scheme, required this.selected, required this.onTap});

  final AppPalette palette;
  final ColorScheme scheme; // цвета этой темы (не текущей)
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Цветовая тема «${palette.title}». ${palette.subtitle}${selected ? '. Выбрана' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: selected ? current.primary : current.outlineVariant, width: selected ? 2.5 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.lg - 2),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: scheme.surface,
                  padding: const EdgeInsets.all(Gap.sm),
                  child: ExcludeSemantics(child: _MiniScreen(scheme: scheme)),
                ),
              ),
              Container(
                width: double.infinity,
                color: current.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(vertical: Gap.sm, horizontal: Gap.sm),
                child: Row(children: [
                  Expanded(child: Text(palette.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge)),
                  if (selected) Icon(Icons.check_circle_rounded, size: 18, color: current.primary),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Крошечный «экран приложения»: выбранный день, карточка пары, акцент.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, Color color, {double height = 6}) =>
        Container(width: width, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 4),
        for (var i = 0; i < 3; i++) ...[bar(8, scheme.outlineVariant, height: 8), const SizedBox(width: 3)],
      ]),
      const SizedBox(height: 6),
      Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: scheme.tertiary, shape: BoxShape.circle)),
              const SizedBox(width: 3),
              bar(18, scheme.onPrimaryContainer.withValues(alpha: 0.5), height: 4),
            ]),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 22,
                height: 12,
                decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
