package ru.raspisanie.raspisanie.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * Обновляет все виджеты и ставит будильник на ближайшую границу пары (начало или конец),
 * чтобы виджет переключался ровно по звонку, даже если приложение не запущено.
 */
object WidgetUpdater {
    const val ACTION_UPDATE = "ru.raspisanie.raspisanie.WIDGET_UPDATE"

    // Окно будильника: система может сдвинуть срабатывание не больше чем на минуту
    private const val ALARM_WINDOW_MS = 60_000L
    // Но не реже раза в час — чтобы подписи вроде «Завтра» не устаревали
    private const val MAX_SLEEP_MS = 3600_000L

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val snapshot = SnapshotStore.load(context)
        val now = System.currentTimeMillis()

        fun <T> refresh(provider: Class<T>, render: () -> android.widget.RemoteViews) {
            for (id in manager.getAppWidgetIds(ComponentName(context, provider))) manager.updateAppWidget(id, render())
        }
        refresh(NowNextWidget::class.java) { WidgetRenderer.nowNext(context, snapshot, now) }
        refresh(TodayWidget::class.java) { WidgetRenderer.today(context, snapshot, now) }
        refresh(TomorrowWidget::class.java) { WidgetRenderer.tomorrow(context, snapshot, now) }
        refresh(StripWidget::class.java) { WidgetRenderer.strip(context, snapshot, now) }
        refresh(RoomWidget::class.java) { WidgetRenderer.room(context, snapshot, now) }
        refresh(WeekWidget::class.java) { WidgetRenderer.week(context, snapshot, now) }
        refresh(HomeworkWidget::class.java) { WidgetRenderer.homework(context, snapshot, now) }
        scheduleNext(context, snapshot, now)
    }

    fun scheduleNext(context: Context, snapshot: WidgetSnapshot?, now: Long) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = PendingIntent.getBroadcast(
            context, 0,
            Intent(context, WidgetAlarmReceiver::class.java).setAction(ACTION_UPDATE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val boundary = snapshot?.let { WidgetLogic.nextBoundary(it, now) }
        val at = minOf(boundary ?: Long.MAX_VALUE, now + MAX_SLEEP_MS)
        // setWindow не требует разрешения на точные будильники
        alarms.setWindow(AlarmManager.RTC, at, ALARM_WINDOW_MS, pending)
    }
}
