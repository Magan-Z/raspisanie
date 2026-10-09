// Показ уведомлений на телефоне. Что и когда показывать, считает domain/notification_plan.dart;
// здесь — только «поставить в расписание Android» (АРХИТЕКТУРА.md, §7.7).

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_plan.dart';

/// Канал уведомлений: от него зависит, под каким названием Android покажет настройки.
enum NotificationChannel {
  lessons('lessons', 'Пары', 'Напоминания перед началом пары'),
  homework('homework', 'Домашка', 'Вечернее напоминание о ДЗ на завтра'),
  updates('updates', 'Обновления расписания', 'Когда расписание вашей группы изменилось');

  const NotificationChannel(this.id, this.title, this.description);
  final String id;
  final String title;
  final String description;
}

/// Интерфейс, чтобы в тестах подставлять запись вместо настоящих уведомлений.
abstract class NotificationGateway {
  Future<void> init();

  /// Спрашивает разрешение (Android 13+). true — уведомления разрешены.
  Future<bool> requestPermission();
  Future<bool> areEnabled();

  /// Заменяет все запланированные уведомления новым планом.
  Future<void> replaceAll(List<PlannedNotification> plan);

  /// Нажатия на уведомления, пока приложение открыто или в фоне (значение — payload уведомления).
  Stream<String> get taps;

  /// Payload уведомления, по нажатию на которое приложение было запущено (null — запущено значком).
  Future<String?> launchPayload();

  /// Показать уведомление сразу (например, «Расписание обновилось»).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.updates,
  });
}

/// Заглушка для браузера: запланированных уведомлений там нет, поэтому ничего не делаем.
class NoopNotificationGateway implements NotificationGateway {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> areEnabled() async => false;

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {}

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> showNow({required int id, required String title, required String body, NotificationChannel channel = NotificationChannel.updates}) async {}
}

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  final _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? details?.notificationResponse?.payload : null;
  }
  late final tz.Location _moscow;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _moscow = tz.getLocation('Europe/Moscow');
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
    for (final channel in NotificationChannel.values) {
      await _android?.createNotificationChannel(AndroidNotificationChannel(
        channel.id,
        channel.title,
        description: channel.description,
        importance: channel == NotificationChannel.updates ? Importance.defaultImportance : Importance.high,
      ));
    }
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async => await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> areEnabled() async => await _android?.areNotificationsEnabled() ?? false;

  NotificationDetails _details(NotificationChannel channel) => NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.title,
          channelDescription: channel.description,
          importance: channel == NotificationChannel.updates ? Importance.defaultImportance : Importance.high,
          priority: channel == NotificationChannel.updates ? Priority.defaultPriority : Priority.high,
          icon: 'ic_notification',
        ),
      );

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    await init();
    await _plugin.cancelAllPendingNotifications();
    // Точные будильники — иначе в режиме сна телефона напоминание может опоздать на минуты
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    final mode = exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final n in plan) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.fireAt, _moscow),
        title: n.title,
        body: n.body,
        notificationDetails: _details(n.homework ? NotificationChannel.homework : NotificationChannel.lessons),
        androidScheduleMode: mode,
        payload: n.payload,
      );
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.updates,
  }) async {
    await init();
    await _plugin.show(id: id, title: title, body: body, notificationDetails: _details(channel));
  }
}
