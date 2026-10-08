// Ссылки вида raspisanie://homework/new?subject=Философия — приходят с кнопки «+ ДЗ» на виджете.

import 'package:flutter/services.dart';

/// Что нужно сделать по ссылке. Сейчас умеем одно: открыть окно «Новое ДЗ».
class AddHomeworkLink {
  const AddHomeworkLink({this.subject});
  final String? subject;
}

/// Разбор ссылки. Незнакомые ссылки (и мусор) дают null — их просто игнорируем.
AddHomeworkLink? parseLink(String? link) {
  if (link == null) return null;
  final uri = Uri.tryParse(link);
  if (uri == null || uri.scheme != 'raspisanie') return null;
  // raspisanie://homework/new  → host = homework, path = /new
  if (uri.host == 'homework' && uri.path == '/new') {
    final subject = uri.queryParameters['subject'];
    return AddHomeworkLink(subject: (subject == null || subject.isEmpty) ? null : subject);
  }
  return null;
}

class LinkChannel {
  LinkChannel({this.channel = const MethodChannel('raspisanie/links')});
  final MethodChannel channel;

  /// Ссылка, которой приложение было запущено (null — запущено обычным значком).
  Future<String?> initialLink() async {
    try {
      return await channel.invokeMethod<String>('getInitialLink');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Ссылки, пришедшие, пока приложение уже открыто.
  void listen(void Function(String link) onLink) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink' && call.arguments is String) onLink(call.arguments as String);
    });
  }
}
