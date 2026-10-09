package ru.raspisanie.raspisanie.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Виджет 2×2 «Сейчас / Далее». */
class NowNextWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Виджет 4×2 «Сегодня». */
class TodayWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Виджет 4×2 «Завтра». */
class TomorrowWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Виджет 4×1: ближайшая пара одной строкой. */
class StripWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Виджет 3×1: номер аудитории крупно. */
class RoomWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Виджет 4×4: неделя целиком. */
class WeekWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Виджет «Домашка». */
class HomeworkWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) =
        WidgetUpdater.updateAll(context)
}

/** Срабатывает по будильнику на границе пары. */
class WidgetAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = WidgetUpdater.updateAll(context)
}

/** После перезагрузки телефона будильники пропадают — ставим заново. Также реагирует на смену времени и пояса. */
class WidgetBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = WidgetUpdater.updateAll(context)
}
