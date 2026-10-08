package ru.raspisanie.raspisanie.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import ru.raspisanie.raspisanie.MainActivity
import ru.raspisanie.raspisanie.R
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** Собирает картинку виджетов (RemoteViews) из снимка и текущего времени. */
object WidgetRenderer {
    // Обратный отсчёт показываем, только если до события не больше этого времени
    private const val COUNTDOWN_LIMIT_MS = 3 * 3600_000L

    private val rowIds = listOf(
        Triple(R.id.row_1, R.id.time_1, Pair(R.id.subject_1, R.id.room_1)),
        Triple(R.id.row_2, R.id.time_2, Pair(R.id.subject_2, R.id.room_2)),
        Triple(R.id.row_3, R.id.time_3, Pair(R.id.subject_3, R.id.room_3)),
        Triple(R.id.row_4, R.id.time_4, Pair(R.id.subject_4, R.id.room_4)),
        Triple(R.id.row_5, R.id.time_5, Pair(R.id.subject_5, R.id.room_5)),
    )

    private fun moscowTime(ms: Long): String {
        val format = SimpleDateFormat("HH:mm", Locale.US)
        format.timeZone = TimeZone.getTimeZone("GMT+03:00")
        return format.format(ms)
    }

    private fun openApp(context: Context, request: Int, uri: String? = null): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (uri != null) data = Uri.parse(uri)
        }
        return PendingIntent.getActivity(
            context, request, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    // ---------- 2×2: «Сейчас / Далее» ----------

    fun nowNext(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_now_next)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 1))

        val state = snapshot?.let { WidgetLogic.nowNext(it, nowMs) }
        val lesson = state?.lesson
        if (lesson == null) {
            views.setTextViewText(R.id.label, if (snapshot == null) "Откройте приложение" else "Пар нет")
            views.setTextViewText(R.id.subject, "")
            views.setTextViewText(R.id.room, "—")
            views.setTextViewText(R.id.badge, "")
            views.setViewVisibility(R.id.countdown, View.GONE)
            views.setViewVisibility(R.id.status, View.GONE)
            return views
        }

        views.setTextViewText(R.id.label, if (state.isCurrent) "СЕЙЧАС" else "ДАЛЕЕ")
        views.setTextViewText(R.id.subject, lesson.short)
        views.setTextViewText(R.id.room, lesson.room ?: "—")
        views.setTextViewText(R.id.badge, lesson.kindLetter)

        // Сколько осталось: до конца идущей пары или до начала следующей
        val target = if (state.isCurrent) lesson.endMs else lesson.startMs
        val remaining = target - nowMs
        if (remaining <= COUNTDOWN_LIMIT_MS) {
            // Chronometer тикает сам, без перерисовки виджета каждую секунду
            views.setViewVisibility(R.id.countdown, View.VISIBLE)
            views.setViewVisibility(R.id.status, View.GONE)
            views.setChronometerCountDown(R.id.countdown, true)
            views.setChronometer(
                R.id.countdown,
                SystemClock.elapsedRealtime() + remaining,
                if (state.isCurrent) "до конца %s" else "через %s",
                true,
            )
        } else {
            views.setViewVisibility(R.id.countdown, View.GONE)
            views.setViewVisibility(R.id.status, View.VISIBLE)
            val day = WidgetLogic.weekdayName(snapshotDate(snapshot, lesson))
            views.setTextViewText(R.id.status, "$day, ${moscowTime(lesson.startMs)}")
        }
        return views
    }

    private fun snapshotDate(snapshot: WidgetSnapshot, lesson: WidgetLesson): String =
        snapshot.days.first { day -> day.lessons.contains(lesson) }.date

    // ---------- 4×2: «Сегодня» ----------

    fun today(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_today)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 2))

        if (snapshot == null) {
            views.setTextViewText(R.id.title, "Откройте приложение")
            views.setTextViewText(R.id.week, "")
            for ((row, _, _) in rowIds) views.setViewVisibility(row, View.GONE)
            views.setOnClickPendingIntent(R.id.add_homework, openApp(context, 3, "raspisanie://homework/new"))
            return views
        }

        val view = WidgetLogic.todayView(snapshot, nowMs)
        val tomorrow = WidgetLogic.moscowDate(nowMs + 24 * 3600_000L)
        views.setTextViewText(
            R.id.title,
            when {
                view.lessons.isEmpty() -> "Пар нет"
                view.isToday -> "Сегодня"
                view.date == tomorrow -> "Завтра"
                else -> WidgetLogic.weekdayName(view.date)
            },
        )
        views.setTextViewText(R.id.week, snapshot.weekLabel)

        val highlight = context.getColor(R.color.widget_highlight)
        for ((i, ids) in rowIds.withIndex()) {
            val (row, time, texts) = ids
            val lesson = view.lessons.getOrNull(i)
            if (lesson == null) {
                views.setViewVisibility(row, View.GONE)
                continue
            }
            views.setViewVisibility(row, View.VISIBLE)
            views.setTextViewText(time, moscowTime(lesson.startMs))
            views.setTextViewText(texts.first, lesson.short)
            views.setTextViewText(texts.second, lesson.room ?: "")
            val isCurrent = view.isToday && nowMs >= lesson.startMs && nowMs < lesson.endMs
            views.setInt(row, "setBackgroundColor", if (isCurrent) highlight else 0)
        }

        // «+ ДЗ» — открывает ввод домашки с предметом ближайшей (или идущей) пары
        val subject = view.lessons.firstOrNull { it.endMs > nowMs }?.subject ?: view.lessons.lastOrNull()?.subject
        val uri = "raspisanie://homework/new" + if (subject != null) "?subject=" + Uri.encode(subject) else ""
        views.setOnClickPendingIntent(R.id.add_homework, openApp(context, 3, uri))
        return views
    }
}
