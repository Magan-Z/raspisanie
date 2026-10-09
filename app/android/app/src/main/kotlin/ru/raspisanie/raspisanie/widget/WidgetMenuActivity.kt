package ru.raspisanie.raspisanie.widget

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import ru.raspisanie.raspisanie.MainActivity
import ru.raspisanie.raspisanie.R

/**
 * Меню действий, которое открывается одиночным нажатием на любой виджет:
 * «Открыть приложение», «Добавить ДЗ», «Завтра», «Неделя», «Поиск».
 * (Удержание виджета оставлено системе — это перемещение и удаление.)
 *
 * Рисуется обычными нативными элементами, без запуска Flutter, поэтому открывается мгновенно.
 * Цвета берёт из цветовой темы приложения (снимок виджетов), если она есть, иначе — стандартные.
 */
class WidgetMenuActivity : Activity() {

    private data class Item(val icon: Int, val title: String, val uri: String?)

    private val items = listOf(
        Item(R.drawable.ic_menu_open_app, "Открыть приложение", null),
        Item(R.drawable.ic_shortcut_add, "Добавить ДЗ", "raspisanie://homework/new"),
        Item(R.drawable.ic_shortcut_tomorrow, "Завтра", "raspisanie://day/tomorrow"),
        Item(R.drawable.ic_shortcut_week, "Неделя", "raspisanie://week"),
        Item(R.drawable.ic_shortcut_search, "Поиск", "raspisanie://search"),
    )

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics).toInt()

    private fun colors(): WidgetColors {
        val night = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val snapshot = SnapshotStore.load(this)
        snapshot?.let { (if (night) it.darkColors else it.lightColors)?.let { c -> return c } }
        return WidgetColors(
            bg = getColor(R.color.widget_bg),
            text = getColor(R.color.widget_text),
            textSecondary = getColor(R.color.widget_text_secondary),
            accent = getColor(R.color.widget_accent),
            highlight = getColor(R.color.widget_highlight),
            badgeBg = getColor(R.color.widget_badge_bg),
            badgeText = getColor(R.color.widget_badge_text),
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val c = colors()

        // Весь экран: нажатие мимо карточки закрывает меню
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(24), dp(24), dp(24))
            setOnClickListener { finish() }
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(8), dp(12), dp(8), dp(8))
            background = GradientDrawable().apply {
                setColor(c.bg)
                cornerRadius = dp(28).toFloat()
            }
            elevation = dp(8).toFloat()
            isClickable = true // нажатие по самой карточке не закрывает меню
        }
        root.addView(card, LinearLayout.LayoutParams(dp(300).coerceAtMost(resources.displayMetrics.widthPixels - dp(48)), ViewGroup.LayoutParams.WRAP_CONTENT))

        card.addView(TextView(this).apply {
            text = "Расписание"
            setTextColor(c.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            letterSpacing = 0.05f
            setPadding(dp(16), dp(4), dp(16), dp(8))
        })

        for (item in items) card.addView(row(item, c))

        setContentView(root)
    }

    private fun row(item: Item, c: WidgetColors): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(52)
            setPadding(dp(16), 0, dp(16), 0)
            isClickable = true
            isFocusable = true
            contentDescription = item.title
            // Нажатие подсвечивается цветом темы
            background = RippleDrawable(
                ColorStateList.valueOf(c.highlight),
                null,
                GradientDrawable().apply { setColor(Color.WHITE); cornerRadius = dp(16).toFloat() },
            )
            setOnClickListener { go(item) }
        }
        row.addView(ImageView(this).apply {
            setImageResource(item.icon)
            imageTintList = ColorStateList.valueOf(c.accent)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }, LinearLayout.LayoutParams(dp(24), dp(24)))
        row.addView(TextView(this).apply {
            text = item.title
            setTextColor(c.text)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(dp(16), 0, 0, 0)
        })
        return row
    }

    private fun go(item: Item) {
        val intent = if (item.uri == null) {
            packageManager.getLaunchIntentForPackage(packageName)
        } else {
            Intent(Intent.ACTION_VIEW, Uri.parse(item.uri)).setClass(this, MainActivity::class.java)
        }
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (intent != null) startActivity(intent)
        finish()
    }
}
