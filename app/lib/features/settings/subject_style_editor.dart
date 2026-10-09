// Окно «Название и цвет предмета»: короткое своё название и цвет карточки из палитры.
// Открывается из «Настройки → Предметы» и из меню пары (долгое нажатие).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../domain/subject_styles.dart';
import '../../theme/subject_palette.dart';
import '../../theme/tokens.dart';

/// Возвращает true, если что-то сохранено или сброшено.
Future<bool> showSubjectStyleEditor(BuildContext context, String subject) async {
  final container = ProviderScope.containerOf(context);
  // Загружаем сохранённое заранее, чтобы окно сразу показало текущие значения
  final current = (await container.read(subjectStyleMapProvider.future))[subject];
  if (!context.mounted) return false;
  final result = await showModalBottomSheet<_Result>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _Editor(subject: subject, initial: current),
  );
  if (result == null) return false;
  final repo = container.read(subjectStylesRepositoryProvider);
  if (result.reset) {
    await repo.reset(subject);
  } else {
    await repo.save(subject, result.style);
  }
  container.invalidate(subjectStyleMapProvider);
  return true;
}

class _Result {
  const _Result(this.style, {this.reset = false});
  final SubjectStyle style;
  final bool reset;
}

class _Editor extends StatefulWidget {
  const _Editor({required this.subject, this.initial});
  final String subject;
  final SubjectStyle? initial;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.shortName ?? '');
  late int? _color = widget.initial?.colorIndex;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final previewName = _name.text.trim().isEmpty ? widget.subject : _name.text.trim();
    final previewTone = _color == null ? subjectTone(widget.subject, brightness) : subjectToneByIndex(_color!, brightness);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, Gap.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Название и цвет', style: theme.textTheme.titleLarge),
          const SizedBox(height: Gap.xs),
          Text(widget.subject, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Gap.lg),

          // Как будет выглядеть карточка
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Gap.lg),
            decoration: BoxDecoration(
              color: previewTone.container,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border(left: BorderSide(color: previewTone.accent, width: 6)),
            ),
            child: Text(previewName, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface)),
          ),
          const SizedBox(height: Gap.lg),

          TextField(
            controller: _name,
            maxLength: 24,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Своё короткое название', helperText: 'Пусто — показывать название из расписания'),
          ),
          const SizedBox(height: Gap.sm),
          Text('Цвет', style: theme.textTheme.titleSmall),
          const SizedBox(height: Gap.sm),
          Wrap(spacing: Gap.sm, runSpacing: Gap.sm, children: [
            _Swatch(
              label: 'Авто',
              semantic: 'Цвет выбирается автоматически',
              selected: _color == null,
              onTap: () => setState(() => _color = null),
              child: Icon(Icons.auto_awesome_rounded, size: 20, color: scheme.onSurfaceVariant),
              color: scheme.surfaceContainerHighest,
            ),
            for (var i = 0; i < subjectPaletteSize; i++)
              _Swatch(
                label: subjectColorNames[i],
                semantic: subjectColorNames[i],
                selected: _color == i,
                onTap: () => setState(() => _color = i),
                color: subjectToneByIndex(i, brightness).accent,
              ),
          ]),
          const SizedBox(height: Gap.xl),
          Row(children: [
            if (widget.initial != null && !widget.initial!.isEmpty)
              TextButton(onPressed: () => Navigator.pop(context, const _Result(SubjectStyle(), reset: true)), child: const Text('Сбросить')),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            const SizedBox(width: Gap.sm),
            FilledButton(
              onPressed: () => Navigator.pop(context, _Result(SubjectStyle(shortName: _name.text.trim(), colorIndex: _color))),
              child: const Text('Сохранить'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.semantic, required this.selected, required this.onTap, required this.color, this.child});
  final String label;
  final String semantic;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: semantic,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? scheme.onSurface : scheme.outlineVariant, width: selected ? 3 : 1),
            ),
            child: selected && child == null ? const Icon(Icons.check_rounded, size: 22, color: Colors.white) : child,
          ),
        ),
      ),
    );
  }
}
