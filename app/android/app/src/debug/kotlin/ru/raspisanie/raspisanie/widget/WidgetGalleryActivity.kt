package ru.raspisanie.raspisanie.widget

import android.app.Activity
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.RemoteViews
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import ru.raspisanie.raspisanie.R

/**
 * ТОЛЬКО ДЛЯ ОТЛАДОЧНОЙ СБОРКИ. «Витрина» виджетов: рисует настоящие RemoteViews всех виджетов на образцовых данных,
 * чтобы оценить внешний вид на эмуляторе без размещения виджетов на рабочем столе.
 * Запуск: adb shell am start -n ru.raspisanie.raspisanie/.widget.WidgetGalleryActivity --ez empty false
 * Тёмная тема: adb shell cmd uimode night yes
 */
class WidgetGalleryActivity : Activity() {
    private data class Quad(val name: String, val id: Int, val w: Int, val h: Int)

    private fun dp(v: Int) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val snapshot = WidgetLogic.parse(sampleJson())
        // «Сейчас» 12 октября 2026, 10:55 по Москве: идёт вторая пара
        val nowMs = WidgetLogic.parseMoment("2026-10-12T10:55+03:00")

        val column = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(16), dp(88), dp(16), dp(32)) }
        val dark = (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
        column.setBackgroundColor(if (dark) 0xFF000000.toInt() else 0xFFD8D2C8.toInt())

        fun add(title: String, wDp: Int, hDp: Int, views: RemoteViews) {
            column.addView(TextView(this).apply { text = title; textSize = 11f; setTextColor(if (dark) 0xFFBBBBBB.toInt() else 0xFF333333.toInt()); setPadding(0, dp(12), 0, dp(4)) })
            val frame = FrameLayout(this)
            val inflated = views.apply(this, frame)
            frame.addView(inflated, FrameLayout.LayoutParams(dp(wDp), dp(hDp)))
            column.addView(frame, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply { gravity = Gravity.START })
        }
        add("Сейчас / Далее 2×2", 160, 160, WidgetRenderer.nowNext(this, snapshot, nowMs))
        add("Сегодня 4×2", 320, 160, WidgetRenderer.today(this, snapshot, nowMs))
        add("Ближайшая пара 4×1", 320, 56, WidgetRenderer.strip(this, snapshot, nowMs))
        add("Аудитория 3×1", 240, 56, WidgetRenderer.room(this, snapshot, nowMs))
        // Длинное «место» вместо номера аудитории (физкультура: «3 корпус»): ближайшая пара — физкультура 14 октября
        val nowPe = WidgetLogic.parseMoment("2026-10-14T08:00+03:00")
        add("Ближайшая пара 4×1, «3 корпус»", 320, 56, WidgetRenderer.strip(this, snapshot, nowPe))
        add("Аудитория 3×1, «3 корпус»", 240, 56, WidgetRenderer.room(this, snapshot, nowPe))
        add("Домашка 4×2", 320, 160, WidgetRenderer.homework(this, snapshot, nowMs))
        add("Завтра 4×2", 320, 160, WidgetRenderer.tomorrow(this, snapshot, nowMs))
        add("Неделя 4×4", 320, 320, WidgetRenderer.week(this, snapshot, nowMs))
        // Предпросмотры из списка выбора виджетов (статичные макеты с образцовым текстом)
        for ((name, id, w, h) in listOf(
            Quad("preview: сейчас/далее", R.layout.widget_now_next_preview, 160, 160), Quad("preview: сегодня", R.layout.widget_today_preview, 320, 160),
            Quad("preview: завтра", R.layout.widget_tomorrow_preview, 320, 160), Quad("preview: строка", R.layout.widget_strip_preview, 320, 56),
            Quad("preview: аудитория", R.layout.widget_room_preview, 240, 56), Quad("preview: неделя", R.layout.widget_week_preview, 320, 320),
            Quad("preview: домашка", R.layout.widget_homework_preview, 320, 160),
        )) add(name, w, h, RemoteViews(packageName, id))
        setContentView(ScrollView(this).apply { addView(column) })
    }

    // Цвета предметов — настоящие, из палитры приложения (светлые и тёмные)
    private val tones = JSONObject(TONES)

    private fun lesson(date: String, pair: Int, start: String, end: String, short: String, subject: String, room: String, teacher: String, kind: String, hw: Boolean = false) =
        JSONObject().put("start", "${date}T$start+03:00").put("end", "${date}T$end+03:00").put("pair", pair).put("short", short)
            .put("subject", subject).put("room", room).put("teacher", teacher).put("kind", kind).put("hasHomework", hw)
            .put("changed", date == "2026-10-12" && pair == 3) // для примера: иностранный язык изменён старостой
            .put("tone", tones.optJSONObject(subject))

    private fun sampleJson(): String {
        val bells = listOf("09:00" to "10:30", "10:40" to "12:10", "13:00" to "14:30", "14:40" to "16:10", "16:20" to "17:50")
        val days = JSONArray()
        fun day(date: String, vararg l: Triple<Int, Array<String>, String>) {
            val arr = JSONArray()
            for ((pair, f, kind) in l) arr.put(lesson(date, pair, bells[pair - 1].first, bells[pair - 1].second, f[0], f[1], f[2], f[3], kind, f.size > 4))
            days.put(JSONObject().put("date", date).put("lessons", arr))
        }
        day("2026-10-12",
            Triple(1, arrayOf("Философия", "Философия", "3-01", "Кутаев А.Х."), "lecture"),
            Triple(2, arrayOf("Философия", "Философия", "2-07", "Кутаев А.Х."), "practice"),
            Triple(3, arrayOf("Иностр. язык", "Иностранный язык", "2-16", "Идразова Э.С-А."), "practice"),
            Triple(4, arrayOf("Бизнес-коммуникации", "Технологии бизнес-коммуникаций", "3-20", "Юнаева С.М.", "hw"), "practice"))
        day("2026-10-13",
            Triple(1, arrayOf("Математика", "Математика", "3-03", "Гагаева Х.Л."), "lecture"),
            Triple(2, arrayOf("Информатика", "Информатика", "2-14", "Алиева М.В."), "practice"),
            Triple(3, arrayOf("История России", "История России", "4-10", "Матагова Х.А."), "lecture"))
        day("2026-10-14",
            Triple(2, arrayOf("Физкультура", "Физическая культура", "3 корпус", "Тамаев М."), "pe"),
            Triple(3, arrayOf("Математика", "Математика", "3-03", "Гагаева Х.Л."), "practice"),
            Triple(4, arrayOf("Кураторский час", "Кураторский час", "2-21", "Батукаева А.Р."), "curator"),
            Triple(5, arrayOf("Информатика", "Информатика", "2-14", "Алиева М.В."), "practice"))
        day("2026-10-15",
            Triple(1, arrayOf("Иностр. язык", "Иностранный язык", "2-16", "Идразова Э.С-А."), "practice"),
            Triple(2, arrayOf("Правоведение", "Правоведение", "4-02", "Дадаева М.С."), "lecture"),
            Triple(3, arrayOf("Математика", "Математика", "3-03", "Гагаева Х.Л."), "lecture"))
        day("2026-10-16",
            Triple(1, arrayOf("Информатика", "Информатика", "2-14", "Алиева М.В."), "lecture"),
            Triple(2, arrayOf("Философия", "Философия", "2-07", "Кутаев А.Х."), "practice"),
            Triple(3, arrayOf("История России", "История России", "4-10", "Матагова Х.А."), "practice"))
        day("2026-10-17",
            Triple(1, arrayOf("Математика", "Математика", "3-03", "Гагаева Х.Л."), "practice"),
            Triple(2, arrayOf("Правоведение", "Правоведение", "4-02", "Дадаева М.С."), "practice"))
        val hw = JSONArray()
            .put(JSONObject().put("subject", "Математика").put("short", "Математика").put("text", "Номера 14–19 из задачника").put("due", "2026-10-13").put("files", 0).put("tone", tones.getJSONObject("Математика")))
            .put(JSONObject().put("subject", "Информатика").put("short", "Информатика").put("text", "Лабораторная №3, отчёт").put("due", "2026-10-14").put("files", 1).put("tone", tones.getJSONObject("Информатика")))
            .put(JSONObject().put("subject", "История России").put("short", "История России").put("text", "Конспект §12").put("due", "2026-10-16").put("files", 0).put("tone", tones.getJSONObject("История России")))
        val light = JSONObject().put("bg", "#FBF8F3").put("text", "#1B1C1A").put("textSecondary", "#51565A").put("accent", "#0B5563").put("highlight", "#CDEBF0").put("badgeBg", "#FFDDA8").put("badgeText", "#2B1A00")
        val night = JSONObject().put("bg", "#0E1416").put("text", "#E1E3E0").put("textSecondary", "#B5BEC0").put("accent", "#80D0DE").put("highlight", "#134A55").put("badgeBg", "#5C4300").put("badgeText", "#FFDDA8")
        return JSONObject().put("weekLabel", "1 неделя").put("days", days).put("homeworkCount", 3).put("homework", hw)
            .put("colors", JSONObject().put("light", light).put("dark", night)).toString()
    }

    private companion object {
        const val TONES = "{\"Философия\":{\"light\":{\"accent\":\"#7A8A12\",\"container\":\"#EBF0C6\",\"onContainer\":\"#3D4314\"},\"dark\":{\"accent\":\"#CBD870\",\"container\":\"#3B4306\",\"onContainer\":\"#EDF1D0\"}},\"Иностранный язык\":{\"light\":{\"accent\":\"#7A8A12\",\"container\":\"#EBF0C6\",\"onContainer\":\"#3D4314\"},\"dark\":{\"accent\":\"#CBD870\",\"container\":\"#3B4306\",\"onContainer\":\"#EDF1D0\"}},\"Технологии бизнес-коммуникаций\":{\"light\":{\"accent\":\"#566676\",\"container\":\"#E1E6EB\",\"onContainer\":\"#142B43\"},\"dark\":{\"accent\":\"#A9B7C4\",\"container\":\"#28313A\",\"onContainer\":\"#D0E1F1\"}},\"Математика\":{\"light\":{\"accent\":\"#C23B67\",\"container\":\"#FBE0E9\",\"onContainer\":\"#431423\"},\"dark\":{\"accent\":\"#FF9DBD\",\"container\":\"#5A1C32\",\"onContainer\":\"#F1D0DB\"}},\"Информатика\":{\"light\":{\"accent\":\"#0E8F86\",\"container\":\"#D6F0EC\",\"onContainer\":\"#144340\"},\"dark\":{\"accent\":\"#5CD6C9\",\"container\":\"#12403D\",\"onContainer\":\"#D0F1EE\"}},\"История России\":{\"light\":{\"accent\":\"#566676\",\"container\":\"#E1E6EB\",\"onContainer\":\"#142B43\"},\"dark\":{\"accent\":\"#A9B7C4\",\"container\":\"#28313A\",\"onContainer\":\"#D0E1F1\"}},\"Физическая культура\":{\"light\":{\"accent\":\"#8A4FC7\",\"container\":\"#EBDDF8\",\"onContainer\":\"#2B1443\"},\"dark\":{\"accent\":\"#CBA3F0\",\"container\":\"#3F2260\",\"onContainer\":\"#E1D0F1\"}},\"Кураторский час\":{\"light\":{\"accent\":\"#D2552F\",\"container\":\"#FCE0D6\",\"onContainer\":\"#431F14\"},\"dark\":{\"accent\":\"#FFA586\",\"container\":\"#5C2413\",\"onContainer\":\"#F1D8D0\"}},\"Правоведение\":{\"light\":{\"accent\":\"#3F8F3A\",\"container\":\"#DDF0D8\",\"onContainer\":\"#164314\"},\"dark\":{\"accent\":\"#8FD987\",\"container\":\"#1F4119\",\"onContainer\":\"#D3F1D0\"}}}"
    }
}
