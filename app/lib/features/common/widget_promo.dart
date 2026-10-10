// Одноразовая подсказка на «Сегодня»: «Добавьте виджет на главный экран». Закрывается крестиком или после добавления.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../theme/tokens.dart';
import 'widget_picker.dart';

class WidgetPromo extends ConsumerWidget {
  const WidgetPromo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wanted = ref.watch(widgetPromoProvider);
    final supported = ref.watch(widgetPinSupportedProvider).value ?? false;
    if (!wanted || !supported) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.xs, Gap.xs),
          // Две строки, а не одна: при крупном шрифте и на узком экране всё остаётся читаемым
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Icon(Icons.widgets_rounded, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Виджет на главный экран', style: theme.textTheme.titleSmall?.copyWith(color: scheme.onTertiaryContainer)),
                  Text('Пара и аудитория — без открытия приложения',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer)),
                ]),
              ),
              IconButton(
                tooltip: 'Скрыть подсказку',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, color: scheme.onTertiaryContainer),
                onPressed: () => ref.read(widgetPromoProvider.notifier).dismiss(),
              ),
            ]),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final asked = await showWidgetPicker(context);
                  if (asked) await ref.read(widgetPromoProvider.notifier).dismiss();
                },
                child: const Text('Добавить'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
