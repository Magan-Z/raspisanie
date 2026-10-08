package ru.raspisanie.raspisanie

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Мост между Flutter и нативной частью:
 * Ссылки raspisanie://… (кнопка «+ ДЗ» на виджете) доходят до приложения через канал «raspisanie/links».
 * Данные для виджетов передаёт пакет home_widget (см. lib/widget_bridge/widget_sync.dart).
 */
class MainActivity : FlutterActivity() {
    private var linkChannel: MethodChannel? = null
    private var initialLinkTaken = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

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
