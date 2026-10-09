// «Выходы» приложения за пределы экрана: данные для виджетов и уведомления.
// Вызывается и с экрана (после любого изменения), и из фоновой задачи (раз в ~6 часов),
// поэтому принимает ProviderContainer, а не WidgetRef.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';
import 'domain/notification_plan.dart';

/// Отдаёт виджетам свежий снимок расписания на 7 дней.
Future<void> pushWidgets(ProviderContainer c) async {
  final my = await c.read(myScheduleProvider.future);
  if (my == null) return;
  final homework = await c.read(homeworkProvider.future);
  await c.read(subjectStyleMapProvider.future); // свои названия предметов должны быть загружены
  final styles = c.read(subjectStylesProvider);
  await c.read(widgetBridgeProvider).push(
        now: c.read(clockProvider).now(),
        index: my.index,
        schedule: my.schedule,
        profile: my.profile,
        homework: homework,
        overrides: my.overrides,
        forcedWeek: my.forcedWeek,
        // Цвета из обоев виджету недоступны — тогда он остаётся в стандартных цветах
        palette: c.read(settingsProvider).useDynamicColor ? null : c.read(settingsProvider).palette,
        amoled: c.read(settingsProvider).amoled,
        compactNameOf: styles.compactName,
      );
}

/// Заново ставит уведомления на 7 дней вперёд (перед парой и вечернее напоминание о ДЗ).
Future<void> replanNotifications(ProviderContainer c) async {
  final my = await c.read(myScheduleProvider.future);
  if (my == null) return;
  final settings = c.read(settingsProvider);
  await c.read(subjectStyleMapProvider.future);
  final styles = c.read(subjectStylesProvider);
  final plan = planNotifications(
    now: c.read(clockProvider).now(),
    index: my.index,
    schedule: my.schedule,
    profile: my.profile,
    homework: await c.read(homeworkProvider.future),
    notifyBeforeMin: settings.notifyBeforeMin,
    eveningReminder: settings.eveningHomeworkReminder,
    overrides: my.overrides,
    forcedWeek: my.forcedWeek,
    nameOf: styles.name,
  );
  try {
    await c.read(notificationGatewayProvider).replaceAll(plan);
  } catch (_) {
    // Уведомления — удобство: если система отказала, приложение работает как обычно
  }
}

/// Виджеты + уведомления одним вызовом.
Future<void> refreshOutputs(ProviderContainer c) async {
  await pushWidgets(c);
  await replanNotifications(c);
}
