// Мост с нативными виджетами Android (Kotlin, app/android/.../widget).
// Приложение собирает «снимок» расписания на 7 дней и отдаёт его через канал «raspisanie/widget»;
// дальше виджеты сами выбирают текущую пару по часам (АРХИТЕКТУРА.md, §7.6).

import 'package:flutter/services.dart';

import '../domain/homework.dart';
import '../domain/models.dart';
import '../domain/widget_snapshot.dart';

class WidgetBridge {
  const WidgetBridge({this.channel = const MethodChannel('raspisanie/widget')});
  final MethodChannel channel;

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
      await channel.invokeMethod<void>('saveSnapshot', encodeWidgetSnapshot(snapshot));
    } on MissingPluginException {
      // Запущено не на Android — виджетов нет
    } on PlatformException {
      // Нативная сторона отказала — в следующий раз получится
    }
  }
}
