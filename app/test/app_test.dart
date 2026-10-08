// Проверка приложения целиком (без телефона): первый запуск, экран «Сегодня», «Неделя».
// Расписание берётся из встроенной копии assets/schedule, база — в памяти.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/app_state.dart';
import 'package:raspisanie/core/clock.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/schedule_repository.dart';
import 'package:raspisanie/domain/notification_plan.dart';
import 'package:raspisanie/notifications/notification_gateway.dart';
import 'package:raspisanie/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ассеты читаются прямо с диска и без ожидания — в тестах так надёжнее, чем настоящий rootBundle.
class _DiskAssets extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = File(key).readAsBytesSync();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => utf8.decode(File(key).readAsBytesSync());

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) async =>
      parser(await loadString(key));
}

/// Вместо настоящих уведомлений — запись того, что приложение собиралось показать.
class FakeGateway implements NotificationGateway {
  final plans = <List<PlannedNotification>>[];
  final shown = <String>[];
  int permissionRequests = 0;

  List<PlannedNotification> get lastPlan => plans.isEmpty ? const [] : plans.last;

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<bool> areEnabled() async => true;
  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async => plans.add(plan);
  @override
  Future<void> showNow({required int id, required String title, required String body, NotificationChannel channel = NotificationChannel.updates}) async =>
      shown.add(title);
}

Future<void> _start(WidgetTester tester, {Map<String, Object> prefs = const {}, DateTime? now, FakeGateway? gateway}) async {
  // Высокий «экран», чтобы весь список строился сразу (ListView строит только видимое)
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  // Базу открываем заранее и в реальном времени: внутри «поддельных» часов теста drift зависает
  await tester.runAsync(() => db.customSelect('select 1').get());
  addTearDown(() => tester.runAsync(db.close));

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      databaseProvider.overrideWithValue(db),
      repositoryProvider.overrideWithValue(ScheduleRepository(db: db, assets: _DiskAssets())),
      notificationGatewayProvider.overrideWithValue(gateway ?? FakeGateway()),
      clockProvider.overrideWithValue(FixedClock(now ?? DateTime.utc(2026, 10, 7, 10, 30))), // 13:30 по Москве
    ],
    child: const RaspisanieApp(),
  ));
  await _settle(tester);
}

/// Даёт загрузкам (ассеты, база) завершиться: несколько раз ждём реальное время и обновляем экран.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  const profile = {'form': 'ofo', 'groupId': 'ofo-1-bi-25', 'subgroup': 1, 'pe': 'male'};

  testWidgets('Первый запуск: выбор группы 1 БИ-25 → подгруппа → физ-ра → экран «Сегодня»', (tester) async {
    await _start(tester);
    expect(find.text('Форма обучения'), findsOneWidget);

    await tester.tap(find.text('Очная'));
    await tester.pump();
    await tester.tap(find.text('2 курс'));
    await tester.pump();
    await tester.tap(find.text('1 БИ-25'));
    await tester.pump();
    expect(find.text('Подгруппа'), findsOneWidget);

    await tester.tap(find.text('БИ-25-1'));
    await tester.pump();
    expect(find.text('Физкультура'), findsOneWidget);

    await tester.tap(find.text('Юноши'));
    await _settle(tester);
    expect(find.text('Сегодня'), findsWidgets); // нижняя панель
    expect(find.text('Форма обучения'), findsNothing);
  });

  testWidgets('«Сегодня» 07.10.2026 13:30: идёт ТП в 2-05, дальше ЧТК практика 2-15', (tester) async {
    await _start(tester, prefs: profile);
    expect(find.text('2 неделя'), findsOneWidget);
    expect(find.text('СЕЙЧАС'), findsOneWidget);
    expect(find.text('Технологическое предпринимательство'), findsWidgets);
    expect(find.text('2-05'), findsWidgets);
    expect(find.text('ЧТК и этика'), findsOneWidget);
    expect(find.text('2-15'), findsOneWidget);
    expect(find.text('Кураторский час'), findsNothing); // он только на 1 неделе
  });

  testWidgets('«Неделя»: 1 неделя содержит кураторский час, 2 неделя — нет', (tester) async {
    await _start(tester, prefs: profile);
    await tester.tap(find.text('Неделя').last);
    await _settle(tester);
    expect(find.text('Кураторский час'), findsNothing); // сейчас 2 неделя

    await tester.tap(find.textContaining('1 неделя'));
    await _settle(tester);
    expect(find.text('Кураторский час'), findsOneWidget);
  });

  testWidgets('После последней пары открывается следующий учебный день', (tester) async {
    // 07.10.2026 18:30 по Москве — пары кончились → показывается четверг 08.10
    await _start(tester, prefs: profile, now: DateTime.utc(2026, 10, 7, 15, 30));
    expect(find.textContaining('четверг, 8 октября'), findsOneWidget);
  });

  testWidgets('Воскресенье → открывается понедельник', (tester) async {
    await _start(tester, prefs: profile, now: DateTime.utc(2026, 10, 11, 9, 0));
    expect(find.textContaining('понедельник, 12 октября'), findsOneWidget);
  });

  testWidgets('ДЗ: долгое нажатие на пару → срок сам = следующее занятие → появляется в списке ДЗ', (tester) async {
    await _start(tester, prefs: profile);

    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Добавить ДЗ'));
    await _settle(tester);
    expect(find.text('Новое ДЗ'), findsOneWidget);
    // ЧТК в среду есть каждую неделю (1 нед — лекция, 2 нед — практика) → следующее занятие 14 октября
    expect(find.textContaining('Срок: среда, 14 октября'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Прочитать главу 3');
    await tester.pump();
    await tester.tap(find.text('Добавить'));
    await _settle(tester);
    expect(find.text('Новое ДЗ'), findsNothing);

    await tester.tap(find.text('ДЗ').last);
    await _settle(tester);
    expect(find.text('Прочитать главу 3'), findsOneWidget);
    expect(find.text('Позже'), findsOneWidget); // 14 октября — уже следующая неделя
  });

  testWidgets('Поиск: свободные аудитории и расписание преподавателя', (tester) async {
    await _start(tester, prefs: profile); // среда 07.10.2026 13:30 МСК, 3 пара идёт

    await tester.tap(find.text('Поиск').last);
    await _settle(tester);

    // Преподаватель: набираем «Халиев» → выбираем из подсказок
    await tester.enterText(find.byType(TextField).first, 'Халиев');
    await _settle(tester);
    await tester.tap(find.text('Халиев М.С-У.').last);
    await _settle(tester);
    expect(find.textContaining('Сейчас ведёт: Технологическое предпринимательство'), findsOneWidget);

    // Свободные аудитории на 3 пару: 2-05 занята, значит в списке свободных её нет
    await tester.tap(find.text('Свободные'));
    await _settle(tester);
    await tester.tap(find.text('3 пара'));
    await _settle(tester);
    expect(find.textContaining('свободно'), findsOneWidget);
    expect(find.widgetWithText(Chip, '2-05'), findsNothing);
    expect(find.widgetWithText(Chip, '3 корпус'), findsNothing); // «3 корпус» — не аудитория
  });

  testWidgets('Баннер «Расписание обновилось» показывается и закрывается кнопкой «Понятно»', (tester) async {
    await _start(tester, prefs: {...profile, 'updateBanner': ['Изменено: Ср, 4 пара — ЧТК и этика (аудитория: 2-15 → 2-16)']});
    expect(find.text('Расписание обновилось: 1 изменение'), findsOneWidget);
    expect(find.textContaining('2-15 → 2-16'), findsOneWidget);

    await tester.tap(find.text('Понятно'));
    await _settle(tester);
    expect(find.text('Расписание обновилось: 1 изменение'), findsNothing);
  });

  testWidgets('Крупный шрифт (×2) и узкий экран: ни на одной вкладке нет переполнения', (tester) async {
    await _start(tester, prefs: profile);
    tester.view.physicalSize = const Size(320, 640); // узкий телефон
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _settle(tester);

    for (final tab in ['Сегодня', 'Неделя', 'ДЗ', 'Поиск', 'Настройки']) {
      await tester.tap(find.text(tab).last);
      await _settle(tester);
      final problem = tester.takeException();
      if (problem != null) fail('вкладка «$tab» ломается при крупном шрифте: $problem');
    }
  });

  testWidgets('Уведомления: план строится из расписания, разрешение спрашивается один раз', (tester) async {
    final gateway = FakeGateway();
    await _start(tester, prefs: profile, gateway: gateway); // среда 07.10.2026 13:30 МСК
    await _settle(tester);

    expect(gateway.permissionRequests, 1);
    expect(gateway.plans, isNotEmpty);
    final titles = gateway.lastPlan.map((n) => n.title).toList();
    expect(titles.first, 'ЧТК и этика → 2-15'); // пара в 14:40, напоминание в 14:30
    expect(titles, isNot(contains('Технологическое предпринимательство → 2-05'))); // уже идёт
  });

  testWidgets('Личные правки: отмена пары убирает её с экрана и из уведомлений, «Мои правки» возвращает', (tester) async {
    final gateway = FakeGateway();
    await _start(tester, prefs: profile, gateway: gateway);
    expect(find.text('ЧТК и этика'), findsWidgets);

    // Долгое нажатие на строку пары → «Отменить пару»
    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    expect(find.text('Отменить пару'), findsOneWidget);
    await tester.tap(find.text('Отменить пару'));
    await _settle(tester);

    expect(find.text('ЧТК и этика'), findsNothing);
    expect(gateway.lastPlan.map((n) => n.title), isNot(contains('ЧТК и этика → 2-15')));
    expect(find.text('Мои правки (1)'), findsOneWidget);

    // Открываем список правок и убираем отмену
    await tester.tap(find.text('Мои правки (1)'));
    await _settle(tester);
    expect(find.text('Отменена: 4 пара'), findsOneWidget);
    await tester.tap(find.byTooltip('Убрать правку'));
    await _settle(tester);
    await tester.tapAt(const Offset(10, 10)); // закрыть окно
    await _settle(tester);

    expect(find.text('ЧТК и этика'), findsWidgets);
    expect(gateway.lastPlan.map((n) => n.title), contains('ЧТК и этика → 2-15'));
  });

  testWidgets('Личные правки: изменение аудитории показывается на экране и помечается', (tester) async {
    await _start(tester, prefs: profile);
    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Изменить на этот день'));
    await _settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Аудитория'), '3-01');
    await tester.tap(find.text('Сохранить'));
    await _settle(tester);

    expect(find.text('3-01'), findsWidgets);
    expect(find.text('2-15'), findsNothing);
    expect(find.text('изменено вами'), findsOneWidget);
  });

  testWidgets('Личные правки: своя пара на свободный день', (tester) async {
    // Пятница 09.10 у юношей пуста (физ-ра только у девушек). Приложение сразу открывает субботу — листаем назад
    await _start(tester, prefs: profile, now: DateTime.utc(2026, 10, 9, 8, 0)); // пт 09.10, 11:00 МСК
    await tester.fling(find.byType(PageView), const Offset(600, 0), 2000);
    await _settle(tester);
    await tester.pumpAndSettle(); // дать странице докатиться до конца
    await _settle(tester);
    expect(find.textContaining('пятница, 9 октября'), findsOneWidget);
    expect(find.text('Пар нет'), findsOneWidget);

    await tester.tap(find.text('Мои правки').hitTestable());
    await _settle(tester);
    await tester.tap(find.text('Добавить свою пару'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Название'), 'Консультация');
    await tester.enterText(find.widgetWithText(TextField, 'Аудитория'), '2-10');
    await tester.pump();
    await tester.tap(find.text('Добавить'));
    await _settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);

    expect(find.text('Консультация'), findsWidgets);
    expect(find.text('2-10'), findsWidgets);
  });
}
