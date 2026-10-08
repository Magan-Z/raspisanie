package ru.raspisanie.raspisanie.widget

import android.content.Context

/** Снимок расписания, который приложение кладёт для виджетов (SharedPreferences, доступны без запуска Flutter). */
object SnapshotStore {
    private const val PREFS = "raspisanie_widget"
    private const val KEY = "snapshot"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
    }

    /** null — приложение ещё ни разу не сохранило снимок или он повреждён. */
    fun load(context: Context): WidgetSnapshot? {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return null
        return try {
            WidgetLogic.parse(json)
        } catch (e: Exception) {
            null
        }
    }
}
