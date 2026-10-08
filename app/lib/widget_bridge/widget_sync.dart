// Мост с нативными виджетами Android (Kotlin, app/android/.../widget).
// Приложение собирает «снимок» расписания на 7 дней и кладёт его в общее хранилище через пакет home_widget
// (он работает и в фоновой задаче, когда приложение закрыто); дальше виджеты сами выбирают текущую пару по часам
// (АРХИТЕКТУРА.md, §7.6).

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/homework.dart';
import '../domain/models.dart';
import '../domain/widget_snapshot.dart';

/// Ключ снимка в хранилище виджетов (его же читает Kotlin: SnapshotStore).
const snapshotKey = 'snapshot';
const _providers = [
  'ru.raspisanie.raspisanie.widget.NowNextWidget',
  'ru.raspisanie.raspisanie.widget.TodayWidget',
];

class WidgetBridge {
  const WidgetBridge();

  /// Отдаёт снимок виджетам. Ошибки (не Android, тесты) молча игнорируются: виджеты — удобство, а не необходимость.
  Future<void> push({
    required DateTime now,
    required ScheduleIndex index,
    required GroupSchedule schedule,
    required UserProfile profile,
    required List<HomeworkItem> homework,
    List<Override> overrides = const [],
    int? forcedWeek,
  }) async {
    final snapshot = buildWidgetSnapshot(
      now: now,
      index: index,
      schedule: schedule,
      profile: profile,
      homework: homework,
      overrides: overrides,
      forcedWeek: forcedWeek,
    );
    try {
      await HomeWidget.saveWidgetData<String>(snapshotKey, encodeWidgetSnapshot(snapshot));
      for (final provider in _providers) {
        await HomeWidget.updateWidget(qualifiedAndroidName: provider);
      }
    } on MissingPluginException {
      // Запущено не на Android — виджетов нет
    } on PlatformException {
      // Нативная сторона отказала — в следующий раз получится
    }
  }
}
