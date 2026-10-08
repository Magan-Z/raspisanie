package ru.raspisanie.raspisanie.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Проверка логики виджетов на контрольных фактах: среда 7 октября 2026 у 1 БИ-25, подгруппа 1 (АРХИТЕКТУРА.md, §11). */
class WidgetLogicTest {
    private fun lesson(start: String, end: String, pair: Int, short: String, room: String, kind: String, homework: Boolean = false) =
        """{"start":"$start","end":"$end","pair":$pair,"short":"$short","subject":"$short","room":"$room","teacher":null,"kind":"$kind","hasHomework":$homework}"""

    private val json = """
    {"generatedAt":"2026-10-07T08:00+03:00","weekLabel":"2 неделя","days":[
      {"date":"2026-10-07","lessons":[
        ${lesson("2026-10-07T13:00+03:00", "2026-10-07T14:30+03:00", 3, "Технол. предпр.", "2-05", "lecture")},
        ${lesson("2026-10-07T14:40+03:00", "2026-10-07T16:10+03:00", 4, "ЧТК и этика", "2-15", "practice", true)}
      ]},
      {"date":"2026-10-08","lessons":[
        ${lesson("2026-10-08T09:00+03:00", "2026-10-08T10:30+03:00", 1, "Управ. проектами", "2-21", "practice")}
      ]},
      {"date":"2026-10-09","lessons":[]}
    ]}"""
    private val snapshot = WidgetLogic.parse(json)

    private fun t(moment: String) = WidgetLogic.parseMoment(moment)

    @Test
    fun parsesSnapshot() {
        assertEquals("2 неделя", snapshot.weekLabel)
        assertEquals(3, snapshot.days.size)
        assertEquals(3, snapshot.allLessons.size)
        val chtk = snapshot.allLessons[1]
        assertEquals("2-15", chtk.room)
        assertEquals("П", chtk.kindLetter)
        assertTrue(chtk.hasHomework)
        assertNull(chtk.teacher)
    }

    @Test
    fun momentsAreInUtc() {
        // 13:00 по Москве = 10:00 UTC
        assertEquals(1791367200000L, t("2026-10-07T13:00+03:00"))
        assertEquals(t("2026-10-07T10:00+00:00"), t("2026-10-07T13:00+03:00"))
    }

    @Test
    fun beforeFirstPairShowsItAsNext() {
        val state = WidgetLogic.nowNext(snapshot, t("2026-10-07T12:00+03:00"))
        assertFalse(state.isCurrent)
        assertEquals("2-05", state.lesson?.room)
    }

    @Test
    fun duringPairShowsItAsCurrent() {
        val state = WidgetLogic.nowNext(snapshot, t("2026-10-07T13:10+03:00"))
        assertTrue(state.isCurrent)
        assertEquals("Технол. предпр.", state.lesson?.short)
    }

    @Test
    fun pairBoundariesSwitchExactlyOnTheBell() {
        // 14:30:00 — первая пара кончилась, идёт перемена → «далее» ЧТК
        val atEnd = WidgetLogic.nowNext(snapshot, t("2026-10-07T14:30+03:00"))
        assertFalse(atEnd.isCurrent)
        assertEquals("ЧТК и этика", atEnd.lesson?.short)
        // 14:40:00 — началась вторая
        val atStart = WidgetLogic.nowNext(snapshot, t("2026-10-07T14:40+03:00"))
        assertTrue(atStart.isCurrent)
        assertEquals("ЧТК и этика", atStart.lesson?.short)
    }

    @Test
    fun afterLastPairShowsTomorrowsFirst() {
        val state = WidgetLogic.nowNext(snapshot, t("2026-10-07T16:15+03:00"))
        assertFalse(state.isCurrent)
        assertEquals("2-21", state.lesson?.room)
    }

    @Test
    fun nothingLeftInSnapshot() {
        val state = WidgetLogic.nowNext(snapshot, t("2026-10-08T11:00+03:00"))
        assertNull(state.lesson)
    }

    @Test
    fun todayViewShowsTodayWhileLessonsRemain() {
        val view = WidgetLogic.todayView(snapshot, t("2026-10-07T12:00+03:00"))
        assertTrue(view.isToday)
        assertEquals(2, view.lessons.size)
        // Во время последней пары — всё ещё сегодня
        assertTrue(WidgetLogic.todayView(snapshot, t("2026-10-07T15:00+03:00")).isToday)
    }

    @Test
    fun todayViewSwitchesToTomorrowAfterLastPair() {
        val view = WidgetLogic.todayView(snapshot, t("2026-10-07T16:10+03:00"))
        assertFalse(view.isToday)
        assertEquals("2026-10-08", view.date)
        assertEquals(1, view.lessons.size)
    }

    @Test
    fun todayViewSkipsEmptyDays() {
        // 8 октября после пары: 9 октября пусто, дальше в снимке ничего — остаётся сегодняшний (уже прошедший) день
        val view = WidgetLogic.todayView(snapshot, t("2026-10-08T12:00+03:00"))
        assertTrue(view.isToday)
    }

    @Test
    fun nextBoundaryIsNearestStartOrEnd() {
        assertEquals(t("2026-10-07T13:00+03:00"), WidgetLogic.nextBoundary(snapshot, t("2026-10-07T12:00+03:00")))
        assertEquals(t("2026-10-07T14:30+03:00"), WidgetLogic.nextBoundary(snapshot, t("2026-10-07T13:10+03:00")))
        assertEquals(t("2026-10-07T14:40+03:00"), WidgetLogic.nextBoundary(snapshot, t("2026-10-07T14:30+03:00")))
        assertEquals(t("2026-10-08T09:00+03:00"), WidgetLogic.nextBoundary(snapshot, t("2026-10-07T16:10+03:00")))
        assertNull(WidgetLogic.nextBoundary(snapshot, t("2026-10-08T10:30+03:00")))
    }

    @Test
    fun moscowDateRollsOverAtMoscowMidnight() {
        // 21:30 UTC 7 октября = 00:30 МСК 8 октября
        assertEquals("2026-10-08", WidgetLogic.moscowDate(t("2026-10-07T21:30+00:00")))
        assertEquals("2026-10-07", WidgetLogic.moscowDate(t("2026-10-07T20:59+00:00")))
    }

    @Test
    fun weekdayNamesAreRussian() {
        assertEquals("Четверг", WidgetLogic.weekdayName("2026-10-08"))
        assertEquals("Воскресенье", WidgetLogic.weekdayName("2026-10-11"))
    }

    @Test
    fun minutesText() {
        assertEquals("12 мин", WidgetLogic.minutesText(12 * 60_000L))
        assertEquals("1 ч 30 мин", WidgetLogic.minutesText(90 * 60_000L))
        assertEquals("0 мин", WidgetLogic.minutesText(-5))
    }
}
