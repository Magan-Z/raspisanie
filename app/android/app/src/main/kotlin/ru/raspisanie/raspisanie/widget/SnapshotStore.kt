package ru.raspisanie.raspisanie.widget

import android.content.Context

/**
 * Снимок расписания, который приложение кладёт для виджетов через пакет home_widget
 * (хранилище «HomeWidgetPreferences», ключ «snapshot»). Читается без запуска Flutter.
 */
object SnapshotStore {
    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY = "snapshot"

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
