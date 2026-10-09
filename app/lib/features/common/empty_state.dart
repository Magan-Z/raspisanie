// Пустое состояние: иллюстрация (или значок в мягком круге) + пояснение. Вместо эмодзи — векторные значки (одинаково на всех телефонах).

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'illustrations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon, this.illustration, required this.title, this.subtitle, this.action})
      : assert(icon != null || illustration != null);

  final IconData? icon;
  final IllustrationKind? illustration; // если задана — вместо значка рисуется иллюстрация
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Если на узком экране при крупном шрифте не помещается — прокручивается, а не обрезается
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (illustration != null)
                  Illustration(illustration!)
                else
                  ExcludeSemantics(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(color: scheme.tertiaryContainer, shape: BoxShape.circle),
                      child: Icon(icon, size: 44, color: scheme.onTertiaryContainer),
                    ),
                  ),
                const SizedBox(height: Gap.lg),
                Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: Gap.sm),
                  Text(subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
                if (action != null) ...[const SizedBox(height: Gap.lg), action!],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
