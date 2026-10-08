package ru.raspisanie.raspisanie

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import ru.raspisanie.raspisanie.widget.SnapshotStore
import ru.raspisanie.raspisanie.widget.WidgetUpdater

/**
 * Мост между Flutter и нативной частью:
 *  • «raspisanie/widget» — приложение отдаёт снимок расписания, виджеты обновляются;
 *  • «raspisanie/links» — ссылки raspisanie://… (кнопка «+ ДЗ» на виджете) доходят до приложения.
 */
class MainActivity : FlutterActivity() {
    private var linkChannel: MethodChannel? = null
    private var initialLinkTaken = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "raspisanie/widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "saveSnapshot" -> {
                    SnapshotStore.save(this, call.arguments as String)
                    WidgetUpdater.updateAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        linkChannel = MethodChannel(messenger, "raspisanie/links").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    // Ссылка, которой приложение было запущено (отдаём один раз)
                    "getInitialLink" -> {
                        val link = if (initialLinkTaken) null else intent?.dataString
                        initialLinkTaken = true
                        result.success(link)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Приложение уже открыто, а на виджете нажали «+ ДЗ»
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.dataString?.let { linkChannel?.invokeMethod("onLink", it) }
    }
}
