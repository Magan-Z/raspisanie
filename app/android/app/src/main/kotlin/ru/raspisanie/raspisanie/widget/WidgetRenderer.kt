package ru.raspisanie.raspisanie.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.StyleSpan
import android.graphics.Typeface
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


    // ---------- цвета выбранной темы ----------

    /** Цвета темы приложения для текущего режима (светлый/тёмный). Только Android 12+: там можно перекрашивать фон. */
    private fun colorsFor(context: Context, snapshot: WidgetSnapshot?): WidgetColors? {
        if (Build.VERSION.SDK_INT < 31 || snapshot == null) return null
        val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        return if (night) snapshot.darkColors else snapshot.lightColors
    }

    private fun tint(views: RemoteViews, id: Int, color: Int) {
        if (Build.VERSION.SDK_INT >= 31) views.setColorStateList(id, "setBackgroundTintList", ColorStateList.valueOf(color))
    }

    /**
     * Красит виджет в цвета темы. [text] — основной текст, [secondary] — второстепенный, [accent] — акцент,
     * [badges] — «таблетки» на янтарном фоне, [plates] — таблички с аудиторией.
     */
    private fun paint(
        views: RemoteViews,
        c: WidgetColors?,
        text: List<Int> = emptyList(),
        secondary: List<Int> = emptyList(),
        accent: List<Int> = emptyList(),
        badges: List<Int> = emptyList(),
        plates: List<Int> = emptyList(),
    ) {
        if (c == null) return
        tint(views, R.id.widget_root, c.bg)
        text.forEach { views.setTextColor(it, c.text) }
        secondary.forEach { views.setTextColor(it, c.textSecondary) }
        accent.forEach { views.setTextColor(it, c.accent) }
        badges.forEach { tint(views, it, c.badgeBg); views.setTextColor(it, c.badgeText) }
        plates.forEach { tint(views, it, c.highlight) }
    }

    /** Подсветка строки (идущая пара, сегодняшний день): фон и, если есть тема, её цвет. */
    private fun highlightRow(views: RemoteViews, row: Int, on: Boolean, c: WidgetColors?) {
        views.setInt(row, "setBackgroundResource", if (on) R.drawable.widget_row_highlight else 0)
        if (on && c != null) tint(views, row, c.highlight)
    }

    /** Обратный отсчёт («до конца 42 мин») или, если событие далеко, подпись «Четверг, 09:00». */
    private fun countdown(
        views: RemoteViews, countdownId: Int, statusId: Int,
        snapshot: WidgetSnapshot, lesson: WidgetLesson, isCurrent: Boolean, nowMs: Long,
    ) {
        val target = if (isCurrent) lesson.endMs else lesson.startMs
        val remaining = target - nowMs
        if (remaining <= COUNTDOWN_LIMIT_MS) {
            // Chronometer тикает сам, без перерисовки виджета каждую секунду
            views.setViewVisibility(countdownId, View.VISIBLE)
            views.setViewVisibility(statusId, View.GONE)
            views.setChronometerCountDown(countdownId, true)
            views.setChronometer(countdownId, SystemClock.elapsedRealtime() + remaining, if (isCurrent) "до конца %s" else "через %s", true)
        } else {
            views.setViewVisibility(countdownId, View.GONE)
            views.setViewVisibility(statusId, View.VISIBLE)
            val day = WidgetLogic.weekdayName(snapshotDate(snapshot, lesson))
            views.setTextViewText(statusId, "$day, ${moscowTime(lesson.startMs)}")
        }
    }

    // ---------- 2×2: «Сейчас / Далее» ----------

    fun nowNext(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_now_next)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 1))

        val colors = colorsFor(context, snapshot)
        paint(views, colors, text = listOf(R.id.subject, R.id.room), secondary = listOf(R.id.countdown, R.id.status), accent = listOf(R.id.label), badges = listOf(R.id.badge))
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

        countdown(views, R.id.countdown, R.id.status, snapshot, lesson, state.isCurrent, nowMs)
        return views
    }

    private fun snapshotDate(snapshot: WidgetSnapshot, lesson: WidgetLesson): String =
        snapshot.days.first { day -> day.lessons.contains(lesson) }.date

    // ---------- 4×2: «Сегодня» и «Завтра» ----------


    fun today(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_today)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 2))
        val colors = colorsFor(context, snapshot)
        paint(views, colors, text = listOf(R.id.title) + rowIds.flatMap { listOf(it.third.first, it.third.second) },
            secondary = rowIds.map { it.second }, accent = listOf(R.id.week), badges = listOf(R.id.add_homework))

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
        fillDay(context, views, snapshot, view, nowMs, colors, request = 3)
        return views
    }

    /** «Завтра»: пары завтрашнего дня (в той же вёрстке, что «Сегодня»). */
    fun tomorrow(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_today)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 4))
        val colors = colorsFor(context, snapshot)
        paint(views, colors, text = listOf(R.id.title) + rowIds.flatMap { listOf(it.third.first, it.third.second) },
            secondary = rowIds.map { it.second }, accent = listOf(R.id.week), badges = listOf(R.id.add_homework))

        if (snapshot == null) {
            views.setTextViewText(R.id.title, "Откройте приложение")
            views.setTextViewText(R.id.week, "")
            for ((row, _, _) in rowIds) views.setViewVisibility(row, View.GONE)
            views.setOnClickPendingIntent(R.id.add_homework, openApp(context, 5, "raspisanie://homework/new"))
            return views
        }
        val view = WidgetLogic.tomorrowView(snapshot, nowMs)
        views.setTextViewText(R.id.title, if (view.lessons.isEmpty()) "Завтра пар нет" else "Завтра, " + WidgetLogic.weekdayShort(view.date).lowercase())
        fillDay(context, views, snapshot, view, nowMs, colors, request = 5)
        return views
    }

    /** Заполняет строки пар дня и кнопку «+ ДЗ» (общая часть «Сегодня» и «Завтра»). */
    private fun fillDay(
        context: Context, views: RemoteViews, snapshot: WidgetSnapshot, view: WidgetLogic.TodayView,
        nowMs: Long, colors: WidgetColors?, request: Int,
    ) {
        views.setTextViewText(R.id.week, snapshot.weekLabel)
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
            highlightRow(views, row, view.isToday && nowMs >= lesson.startMs && nowMs < lesson.endMs, colors)
        }

        // «+ ДЗ» — открывает ввод домашки с предметом ближайшей (или идущей) пары
        val subject = view.lessons.firstOrNull { it.endMs > nowMs }?.subject ?: view.lessons.lastOrNull()?.subject
        val uri = "raspisanie://homework/new" + if (subject != null) "?subject=" + Uri.encode(subject) else ""
        views.setOnClickPendingIntent(R.id.add_homework, openApp(context, request, uri))
    }

    // ---------- 4×1: ближайшая пара строкой ----------

    fun strip(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_strip)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 6))
        paint(views, colorsFor(context, snapshot), text = listOf(R.id.subject, R.id.room),
            secondary = listOf(R.id.teacher, R.id.countdown, R.id.status), accent = listOf(R.id.label), plates = listOf(R.id.room))

        val state = snapshot?.let { WidgetLogic.nowNext(it, nowMs) }
        val lesson = state?.lesson
        if (snapshot == null || lesson == null) {
            views.setTextViewText(R.id.label, if (snapshot == null) "ОТКРОЙТЕ" else "ПАР НЕТ")
            views.setTextViewText(R.id.subject, if (snapshot == null) "Откройте приложение" else "Ближайших пар нет")
            views.setTextViewText(R.id.teacher, "")
            views.setViewVisibility(R.id.room, View.GONE)
            views.setViewVisibility(R.id.countdown, View.GONE)
            views.setViewVisibility(R.id.status, View.GONE)
            return views
        }
        views.setViewVisibility(R.id.room, if (lesson.room != null) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.label, if (state.isCurrent) "СЕЙЧАС" else "ДАЛЕЕ")
        views.setTextViewText(R.id.subject, lesson.short)
        views.setTextViewText(R.id.teacher, lesson.teacher ?: "")
        views.setTextViewText(R.id.room, lesson.room ?: "")
        countdown(views, R.id.countdown, R.id.status, snapshot, lesson, state.isCurrent, nowMs)
        return views
    }

    // ---------- 3×1: аудитория крупно ----------

    fun room(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_room)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 7))
        paint(views, colorsFor(context, snapshot), text = listOf(R.id.room, R.id.subject),
            secondary = listOf(R.id.countdown, R.id.status), accent = listOf(R.id.label), plates = listOf(R.id.room))

        val state = snapshot?.let { WidgetLogic.nowNext(it, nowMs) }
        val lesson = state?.lesson
        if (snapshot == null || lesson == null) {
            views.setTextViewText(R.id.room, "—")
            views.setTextViewText(R.id.label, if (snapshot == null) "ОТКРОЙТЕ" else "ПАР НЕТ")
            views.setTextViewText(R.id.subject, if (snapshot == null) "приложение" else "Ближайших пар нет")
            views.setViewVisibility(R.id.countdown, View.GONE)
            views.setViewVisibility(R.id.status, View.GONE)
            return views
        }
        views.setTextViewText(R.id.room, lesson.room ?: "—")
        views.setTextViewText(R.id.label, if (state.isCurrent) "СЕЙЧАС" else "ДАЛЕЕ")
        views.setTextViewText(R.id.subject, lesson.short)
        countdown(views, R.id.countdown, R.id.status, snapshot, lesson, state.isCurrent, nowMs)
        return views
    }

    // ---------- 4×4: неделя ----------

    /** Идентификаторы строк берём по имени: так не нужно перечислять десятки одинаковых констант R.id. */
    private lateinit var appContext: Context
    private fun idByName(name: String): Int = appContext.resources.getIdentifier(name, "id", appContext.packageName)

    fun week(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        appContext = context.applicationContext
        val views = RemoteViews(context.packageName, R.layout.widget_week)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 8))
        val ids = (1..7).map { Triple(idByName("week_row_$it"), idByName("week_day_$it"), idByName("week_info_$it")) }
        val colors = colorsFor(context, snapshot)
        paint(views, colors, text = listOf(R.id.title) + ids.map { it.second }, secondary = ids.map { it.third }, accent = listOf(R.id.week))

        views.setTextViewText(R.id.title, if (snapshot == null) "Откройте приложение" else "Неделя")
        views.setTextViewText(R.id.week, snapshot?.weekLabel ?: "")
        val rows = snapshot?.let { WidgetLogic.weekRows(it, nowMs) }.orEmpty()
        for ((i, rowIds) in ids.withIndex()) {
            val (row, day, info) = rowIds
            val data = rows.getOrNull(i)
            if (data == null) {
                views.setViewVisibility(row, View.GONE)
                continue
            }
            views.setViewVisibility(row, View.VISIBLE)
            views.setTextViewText(day, data.dayLabel)
            views.setTextViewText(info, if (data.count == 0) "Пар нет" else WidgetLogic.pairsText(data.count) + " · " + data.range)
            highlightRow(views, row, data.isToday, colors)
        }
        return views
    }

    // ---------- «Домашка» ----------

    fun homework(context: Context, snapshot: WidgetSnapshot?, nowMs: Long): RemoteViews {
        appContext = context.applicationContext
        val views = RemoteViews(context.packageName, R.layout.widget_homework)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, 9, "raspisanie://homework"))
        views.setOnClickPendingIntent(R.id.add_homework, openApp(context, 10, "raspisanie://homework/new"))
        val ids = (1..4).map { Triple(idByName("hw_row_$it"), idByName("hw_title_$it"), idByName("hw_due_$it")) }
        paint(views, colorsFor(context, snapshot), text = listOf(R.id.title) + ids.map { it.second },
            accent = listOf(R.id.count) + ids.map { it.third }, badges = listOf(R.id.add_homework))

        views.setTextViewText(R.id.title, "Домашка")
        if (snapshot == null) {
            views.setTextViewText(R.id.count, "")
            for ((i, rowIds) in ids.withIndex()) {
                views.setViewVisibility(rowIds.first, if (i == 0) View.VISIBLE else View.GONE)
                views.setTextViewText(rowIds.second, if (i == 0) "Откройте приложение" else "")
                views.setTextViewText(rowIds.third, "")
            }
            return views
        }

        views.setTextViewText(R.id.count, if (snapshot.homeworkCount == 0) "" else WidgetLogic.tasksText(snapshot.homeworkCount))
        val today = WidgetLogic.moscowDate(nowMs)
        for ((i, rowIds) in ids.withIndex()) {
            val (row, title, due) = rowIds
            val item = snapshot.homework.getOrNull(i)
            if (item == null) {
                if (i == 0) {
                    // Заданий нет — спокойное сообщение вместо пустого виджета
                    views.setViewVisibility(row, View.VISIBLE)
                    views.setTextViewText(title, "Всё сделано — можно отдыхать")
                    views.setTextViewText(due, "")
                } else {
                    views.setViewVisibility(row, View.GONE)
                }
                continue
            }
            views.setViewVisibility(row, View.VISIBLE)
            val text = SpannableStringBuilder(item.short)
            text.setSpan(StyleSpan(Typeface.BOLD), 0, item.short.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            if (item.text.isNotBlank()) text.append(" · ").append(item.text.replace('\n', ' '))
            views.setTextViewText(title, text)
            views.setTextViewText(due, WidgetLogic.dueLabel(item.due, today))
        }
        return views
    }
}
