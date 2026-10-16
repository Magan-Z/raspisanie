package ru.unigraf.unigraf

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Мост между Flutter и нативной частью:
 * Ссылки unigraf://… (кнопка «+ ДЗ» на виджете) доходят до приложения через канал «raspisanie/links».
 * Канал «unigraf/system»: открыть системные настройки уведомлений приложения (если разрешение не выдано и окно с вопросом Android больше не показывает)
 * и открыть ссылку в браузере (скачивание новой версии приложения).
 * Данные для виджетов передаёт пакет home_widget (см. lib/widget_bridge/widget_sync.dart).
 */
class MainActivity : FlutterActivity() {
    private var linkChannel: MethodChannel? = null
    private var initialLinkTaken = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "unigraf/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url == null || !(url.startsWith("https://") || url.startsWith("http://"))) {
                        result.success(false)
                    } else {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        linkChannel = MethodChannel(messenger, "unigraf/links").also { channel ->
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
