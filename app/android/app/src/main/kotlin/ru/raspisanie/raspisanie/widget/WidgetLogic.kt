package ru.raspisanie.raspisanie.widget

import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/**
 * Чистая логика виджетов — без Android-классов, поэтому проверяется обычными тестами.
 *
 * Данные приходят из приложения как «снимок» расписания на 7 дней (АРХИТЕКТУРА.md, §7.6).
 * Виджет сам смотрит на часы и выбирает из снимка текущую или следующую пару,
 * поэтому остаётся верным целую неделю, даже если приложение не запускали.
 */
data class WidgetLesson(
    val startMs: Long,
    val endMs: Long,
    val pair: Int,
    val short: String,
    val subject: String,
    val room: String?,
    val teacher: String?,
    val kind: String,
    val hasHomework: Boolean,
) {
    /** Л / П / Ф / К — значок типа занятия. */
    val kindLetter: String
        get() = when (kind) {
            "lecture" -> "Л"
            "practice" -> "П"
            "pe" -> "Ф"
            "curator" -> "К"
            else -> ""
        }
}

data class WidgetDay(val date: String, val lessons: List<WidgetLesson>)

data class WidgetSnapshot(val weekLabel: String, val days: List<WidgetDay>) {
    val allLessons: List<WidgetLesson> get() = days.flatMap { it.lessons }
}

object WidgetLogic {
    private const val MOSCOW_OFFSET_MS = 3 * 3600_000L

    /** «2026-10-08T09:00+03:00» → миллисекунды (UTC). */
    fun parseMoment(text: String): Long {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mmXXX", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.parse(text)!!.time
    }

    fun parse(json: String): WidgetSnapshot {
        val root = JSONObject(json)
        val daysJson = root.getJSONArray("days")
        val days = (0 until daysJson.length()).map { i ->
            val day = daysJson.getJSONObject(i)
            val lessonsJson = day.getJSONArray("lessons")
            WidgetDay(
                date = day.getString("date"),
                lessons = (0 until lessonsJson.length()).map { j ->
                    val l = lessonsJson.getJSONObject(j)
                    WidgetLesson(
                        startMs = parseMoment(l.getString("start")),
                        endMs = parseMoment(l.getString("end")),
                        pair = l.getInt("pair"),
                        short = l.getString("short"),
                        subject = l.getString("subject"),
                        room = if (l.isNull("room")) null else l.getString("room"),
                        teacher = if (l.isNull("teacher")) null else l.getString("teacher"),
                        kind = l.getString("kind"),
                        hasHomework = l.optBoolean("hasHomework", false),
                    )
                },
            )
        }
        return WidgetSnapshot(root.optString("weekLabel", ""), days)
    }

    /** Пара, которая идёт прямо сейчас. */
    fun current(snapshot: WidgetSnapshot, nowMs: Long): WidgetLesson? =
        snapshot.allLessons.firstOrNull { nowMs >= it.startMs && nowMs < it.endMs }

    /** Ближайшая будущая пара (на любой день снимка). */
    fun next(snapshot: WidgetSnapshot, nowMs: Long): WidgetLesson? =
        snapshot.allLessons.filter { it.startMs > nowMs }.minByOrNull { it.startMs }

    /** Что показать в виджете 2×2: идущая пара или, если не идёт, следующая. */
    data class NowNext(val lesson: WidgetLesson?, val isCurrent: Boolean)

    fun nowNext(snapshot: WidgetSnapshot, nowMs: Long): NowNext {
        current(snapshot, nowMs)?.let { return NowNext(it, true) }
        return NowNext(next(snapshot, nowMs), false)
    }

    /** Дата «сегодня» по Москве в формате ГГГГ-ММ-ДД. */
    fun moscowDate(nowMs: Long): String {
        val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(nowMs + MOSCOW_OFFSET_MS)
    }

    /**
     * Что показать в виджете 4×2: пары сегодняшнего дня; когда они закончились (или их нет) —
     * пары ближайшего следующего дня с парами и пометка «Завтра» / название дня.
     */
    data class TodayView(val date: String, val lessons: List<WidgetLesson>, val isToday: Boolean)

    fun todayView(snapshot: WidgetSnapshot, nowMs: Long): TodayView {
        val today = moscowDate(nowMs)
        val todays = snapshot.days.firstOrNull { it.date == today }?.lessons.orEmpty()
        if (todays.isNotEmpty() && todays.any { it.endMs > nowMs }) return TodayView(today, todays, true)

        val later = snapshot.days.filter { it.date > today && it.lessons.isNotEmpty() }.minByOrNull { it.date }
        return if (later != null) TodayView(later.date, later.lessons, false) else TodayView(today, todays, true)
    }

    /** Ближайший момент, когда виджет нужно перерисовать: начало или конец какой-то пары. */
    fun nextBoundary(snapshot: WidgetSnapshot, nowMs: Long): Long? =
        snapshot.allLessons.flatMap { listOf(it.startMs, it.endMs) }.filter { it > nowMs }.minOrNull()

    /** «через 12 мин» для подписи, когда обратный отсчёт не нужен. */
    fun minutesText(ms: Long): String {
        val minutes = (ms / 60_000).coerceAtLeast(0)
        return if (minutes >= 60) "${minutes / 60} ч ${minutes % 60} мин" else "$minutes мин"
    }

    fun weekdayName(date: String): String {
        val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        val cal = java.util.Calendar.getInstance(TimeZone.getTimeZone("UTC"))
        cal.time = format.parse(date)!!
        return when (cal.get(java.util.Calendar.DAY_OF_WEEK)) {
            java.util.Calendar.MONDAY -> "Понедельник"
            java.util.Calendar.TUESDAY -> "Вторник"
            java.util.Calendar.WEDNESDAY -> "Среда"
            java.util.Calendar.THURSDAY -> "Четверг"
            java.util.Calendar.FRIDAY -> "Пятница"
            java.util.Calendar.SATURDAY -> "Суббота"
            else -> "Воскресенье"
        }
    }
}
