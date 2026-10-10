// «Добавить виджет»: выбор вида виджета и просьба к системе положить его на главный экран.
// Если телефон так не умеет — подсказываем, как добавить руками.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../widget_bridge/widget_pinner.dart';

/// Возвращает true, если виджет попросили добавить.
Future<bool> showWidgetPicker(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showModalBottomSheet<WidgetChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Какой виджет добавить?', style: Theme.of(sheetContext).textTheme.titleLarge),
          ),
          for (final w in widgetChoices)
            ListTile(
              leading: const Icon(Icons.widgets_rounded),
              title: Text(w.title),
              subtitle: Text(w.description),
              onTap: () => Navigator.of(sheetContext).pop(w),
            ),
        ]),
      ),
    ),
  );
  if (choice == null) return false;

  final pinner = container.read(widgetPinnerProvider);
  if (await pinner.isSupported()) {
    try {
      await pinner.pin(choice.className);
      return true;
    } catch (_) {
      // не вышло — покажем ручной способ ниже
    }
  }
  messenger.showSnackBar(const SnackBar(
    duration: Duration(seconds: 8),
    content: Text('Ваш телефон не умеет добавлять виджет кнопкой. Нажмите и удерживайте пустое место на главном экране → «Виджеты» → «Расписание».'),
  ));
  return false;
}
