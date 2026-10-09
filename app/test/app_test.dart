// Проверка приложения целиком (без телефона): первый запуск, экран «Сегодня», «Неделя».
// Расписание берётся из встроенной копии assets/schedule, база — в памяти.


import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raspisanie/data/remote/shared_api.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/domain/notification_plan.dart';
import 'package:raspisanie/app_state.dart';
import 'package:raspisanie/core/clock.dart';
import 'package:raspisanie/data/attachments/attachment_store.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/schedule_repository.dart';
import 'package:raspisanie/main.dart';
import 'package:raspisanie/theme/brand_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

Future<void> _start(WidgetTester tester, {Map<String, Object> prefs = const {}, DateTime? now, FakeGateway? gateway, List extraOverrides = const [], SharedApi? sharedApi}) async {
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
      repositoryProvider.overrideWithValue(ScheduleRepository(db: db, assets: DiskAssets())),
      notificationGatewayProvider.overrideWithValue(gateway ?? FakeGateway()),
      clockProvider.overrideWithValue(FixedClock(now ?? DateTime.utc(2026, 10, 7, 10, 30))), // 13:30 по Москве
      sharedApiProvider.overrideWithValue(sharedApi), // по умолчанию общий сервер выключен; тесты старосты подставляют свой
      ...extraOverrides,
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
    expect(find.text('ФОРМА ОБУЧЕНИЯ'), findsOneWidget);

    await tester.tap(find.text('Очная'));
    await tester.pump();
    await tester.tap(find.text('2 курс'));
    await tester.pump();
    await tester.tap(find.text('1 БИ-25'));
    await tester.pump();
    expect(find.text('ПОДГРУППА'), findsOneWidget);

    await tester.tap(find.text('БИ-25-1'));
    await tester.pump();
    expect(find.text('ФИЗКУЛЬТУРА'), findsOneWidget);

    await tester.tap(find.text('Юноши'));
    await _settle(tester);
    expect(find.text('Сегодня'), findsWidgets); // нижняя панель
    expect(find.text('ФОРМА ОБУЧЕНИЯ'), findsNothing);
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

  testWidgets('ДЗ: прикрепить файл → он виден на карточке задания и открывается', (tester) async {
    final dir = Directory.systemTemp.createTempSync('hw_files');
    addTearDown(() => dir.deleteSync(recursive: true));
    final source = File('${dir.path}/Задачи.pdf')..writeAsBytesSync(List.filled(2048, 1));
    final store = FakeAttachmentStore();
    addTearDown(() => store.dir.deleteSync(recursive: true));

    await _start(tester, prefs: profile, extraOverrides: [
      attachmentStoreProvider.overrideWithValue(store),
      attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker([PickedFileInfo(name: 'Задачи.pdf', path: source.path, sizeBytes: 2048)])),
    ]);

    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Добавить ДЗ'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Решить задачи');
    await tester.pump();

    await tester.tap(find.text('Прикрепить'));
    await _settle(tester);
    await tester.tap(find.text('Файл'));
    await _settle(tester);
    expect(find.text('Задачи.pdf'), findsOneWidget); // плитка в окне добавления
    expect(find.text('2 КБ'), findsOneWidget);

    await tester.tap(find.text('Добавить'));
    await _settle(tester);

    await tester.tap(find.text('ДЗ').last);
    await _settle(tester);
    expect(find.text('Решить задачи'), findsOneWidget);
    await tester.tap(find.text('Задачи.pdf'));
    await _settle(tester);
    expect(store.opened, ['Задачи.pdf']);
  });

  testWidgets('ДЗ: закрыли окно без сохранения — скопированные файлы удаляются', (tester) async {
    final dir = Directory.systemTemp.createTempSync('hw_files');
    addTearDown(() => dir.deleteSync(recursive: true));
    final source = File('${dir.path}/Фото.jpg')..writeAsBytesSync([1, 2, 3]);
    final store = FakeAttachmentStore();
    addTearDown(() => store.dir.deleteSync(recursive: true));

    await _start(tester, prefs: profile, extraOverrides: [
      attachmentStoreProvider.overrideWithValue(store),
      attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker([PickedFileInfo(name: 'Фото.jpg', path: source.path, sizeBytes: 3)])),
    ]);
    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Добавить ДЗ'));
    await _settle(tester);
    await tester.tap(find.text('Прикрепить'));
    await _settle(tester);
    await tester.tap(find.text('Файл'));
    await _settle(tester);
    expect(find.text('Фото.jpg'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10)); // закрыть окно
    await _settle(tester);
    expect(store.deleted, ['Фото.jpg']);
  });

  testWidgets('Настройки: выбор цветовой темы меняет цвета и запоминается; «Чёрный фон» работает в тёмной теме', (tester) async {
    await _start(tester, prefs: {...profile, 'theme': 'light'});
    await tester.tap(find.text('Настройки').last);
    await _settle(tester);

    Color primary() => Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.primary;
    expect(primary(), BrandColors.scheme(AppPalette.petrol, Brightness.light).primary);

    await tester.tap(find.text('Океан'));
    await _settle(tester);
    expect(primary(), BrandColors.scheme(AppPalette.ocean, Brightness.light).primary);
    expect((await SharedPreferences.getInstance()).getString('palette'), 'ocean');

    // Тёмная тема + чёрный фон
    await tester.tap(find.text('Тема').first);
    await _settle(tester);
    await tester.tap(find.text('Тёмная'));
    await _settle(tester);
    await tester.tap(find.text('Чёрный фон'));
    await _settle(tester);
    final surface = Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.surface;
    expect(surface, Colors.black);
  });

  testWidgets('Предметы: своё название и цвет через меню пары; выключатель в настройках возвращает названия из расписания', (tester) async {
    final gateway = FakeGateway();
    await _start(tester, prefs: profile, gateway: gateway);
    expect(find.text('ЧТК и этика'), findsWidgets);

    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Название и цвет'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Своё короткое название'), 'Этика');
    await tester.tap(find.byTooltip('Коралловый'));
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await _settle(tester);

    // На экране — своё название; настоящее исчезло; в уведомлениях тоже своё
    expect(find.text('Этика'), findsWidgets);
    expect(find.text('ЧТК и этика'), findsNothing);
    expect(gateway.lastPlan.map((n) => n.title), contains('Этика → 2-15'));

    // Выключаем в настройках — возвращается название из расписания
    await tester.tap(find.text('Настройки').last);
    await _settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await _settle(tester);
    await tester.tap(find.text('Свои названия и цвета'));
    await _settle(tester);
    await tester.tap(find.text('Сегодня').last);
    await _settle(tester);
    expect(find.text('ЧТК и этика'), findsWidgets);
    expect(find.text('Этика'), findsNothing);
    expect(gateway.lastPlan.map((n) => n.title), contains('ЧТК и этика → 2-15'));
  });

  testWidgets('Быстрые действия на значке: ссылки открывают «Завтра», «Неделю» и «Поиск»', (tester) async {
    final links = FakeLinks();
    await _start(tester, prefs: profile, extraOverrides: [linkChannelProvider.overrideWithValue(links)]); // среда 7 октября
    expect(find.textContaining('среда, 7 октября'), findsWidgets);

    links.send('raspisanie://day/tomorrow');
    await _settle(tester);
    expect(find.textContaining('четверг, 8 октября'), findsWidgets);

    links.send('raspisanie://week');
    await _settle(tester);
    expect(find.text('1 неделя'), findsWidgets); // вкладка «Неделя»

    links.send('raspisanie://search');
    await _settle(tester);
    expect(find.text('Свободные'), findsOneWidget); // вкладка «Поиск»
  });

  group('Староста и группа', () {
    // Хеш расписания 1 БИ-25 в встроенной копии: правки старосты привязаны к нему
    String groupHash() {
      final index = jsonDecode(File('assets/schedule/index.json').readAsStringSync()) as Map<String, dynamic>;
      for (final form in index['forms'] as List) {
        for (final g in (form as Map)['groups'] as List) {
          if ((g as Map)['id'] == 'ofo-1-bi-25') return g['hash'] as String;
        }
      }
      throw StateError('нет группы');
    }

    Future<void> openSettingsAndScrollTo(WidgetTester tester, String text) async {
      await tester.tap(find.text('Настройки').last);
      await _settle(tester);
      await tester.dragUntilVisible(find.text(text), find.byType(Scrollable).first, const Offset(0, -300));
      await _settle(tester);
    }

    testWidgets('студент видит правку старосты (аудитория 3-33, пометка), а правки к старому расписанию — нет', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      backend.overrides['o1'] = backend.override(); // 7 октября, 4 пара: аудитория 3-33
      backend.overrides['old'] = backend.override(id: 'old', pair: 3, room: '9-99', hash: 'старый-хеш'); // к прошлому расписанию
      await _start(tester, prefs: profile, sharedApi: backend.api());
      await _settle(tester);

      expect(find.text('3-33'), findsWidgets);
      expect(find.text('2-15'), findsNothing); // прежняя аудитория заменена
      expect(find.text('изменено старостой'), findsOneWidget);
      expect(find.text('9-99'), findsNothing); // устаревшая правка не действует
    });

    testWidgets('выключатель «Правки и ДЗ старосты» возвращает расписание как есть', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      backend.overrides['o1'] = backend.override();
      await _start(tester, prefs: profile, sharedApi: backend.api());
      await _settle(tester);
      expect(find.text('3-33'), findsWidgets);

      await openSettingsAndScrollTo(tester, 'Правки и ДЗ старосты');
      await tester.tap(find.text('Правки и ДЗ старосты'));
      await _settle(tester);
      await tester.tap(find.text('Сегодня').last);
      await _settle(tester);
      expect(find.text('3-33'), findsNothing);
      expect(find.text('2-15'), findsWidgets);
    });

    testWidgets('вкладка «От старосты» в ДЗ: задание видно, отметить «сделано» можно у себя', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      backend.homework['h1'] = backend.hw();
      await _start(tester, prefs: profile, sharedApi: backend.api());
      await _settle(tester);

      await tester.tap(find.text('ДЗ').last);
      await _settle(tester);
      expect(find.textContaining('От старосты (1)'), findsOneWidget);
      await tester.tap(find.textContaining('От старосты'));
      await _settle(tester);
      expect(find.text('Читать главу 3'), findsOneWidget);
      expect(find.text('от старосты'), findsOneWidget);
      expect(find.byTooltip('Удалить для всей группы'), findsNothing); // студент удалить не может

      await tester.tap(find.byType(Checkbox));
      await _settle(tester);
      expect(find.textContaining('От старосты (0)'), findsOneWidget); // отметил выполненным
    });

    testWidgets('староста: неверный код — ошибка; верный код (регистр не важен) — режим старосты', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      await _start(tester, prefs: profile, sharedApi: backend.api());
      await openSettingsAndScrollTo(tester, 'Я староста');

      await tester.tap(find.text('Я староста'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).last, 'WRONG');
      await tester.tap(find.text('Подтвердить'));
      await _settle(tester);
      expect(find.textContaining('Код не подошёл'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'goodcode'); // регистр не важен
      await tester.tap(find.text('Подтвердить'));
      await _settle(tester);
      expect(find.textContaining('Вы староста:'), findsOneWidget);
      expect(find.text('Изменения для группы'), findsOneWidget);
    });

    testWidgets('староста отменяет пару для всей группы: пара исчезает, на сервер уходит правка с хешем расписания', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      await _start(tester, prefs: {...profile, 'editorToken': 'tok-GOODCODE', 'editorGroup': 'ofo-1-bi-25'}, sharedApi: backend.api());
      await _settle(tester);
      expect(find.text('ЧТК и этика'), findsWidgets);

      await tester.longPress(find.text('ЧТК и этика').last);
      await _settle(tester);
      await tester.dragUntilVisible(find.text('Отменить пару для группы'), find.byType(Scrollable).last, const Offset(0, -200));
      await tester.tap(find.text('Отменить пару для группы'));
      await _settle(tester);

      expect(backend.calls, contains('put_group_override'));
      final saved = backend.overrides.values.single;
      expect(saved['type'], 'cancel');
      expect(saved['pair'], 4);
      expect(saved['date'], '2026-10-07');
      expect(saved['base_hash'], groupHash());
      expect(find.text('ЧТК и этика'), findsNothing); // у всех (и у самого старосты) пары нет
    });

    testWidgets('староста задаёт ДЗ для всей группы: уходит на сервер и появляется во вкладке «От старосты»', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      await _start(tester, prefs: {...profile, 'editorToken': 'tok-GOODCODE', 'editorGroup': 'ofo-1-bi-25'}, sharedApi: backend.api());
      await _settle(tester);

      await tester.longPress(find.text('ЧТК и этика').last);
      await _settle(tester);
      await tester.tap(find.text('Добавить ДЗ'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).last, 'Подготовить доклад');
      await tester.tap(find.text('Для всей группы'));
      await _settle(tester);
      await tester.tap(find.text('Добавить'));
      await _settle(tester);

      expect(backend.homework.values.single['body'], 'Подготовить доклад');
      expect(backend.homework.values.single['subject'], 'ЧТК и этика');

      await tester.tap(find.text('ДЗ').last);
      await _settle(tester);
      await tester.tap(find.textContaining('От старосты'));
      await _settle(tester);
      expect(find.text('Подготовить доклад'), findsOneWidget);
      expect(find.byTooltip('Удалить для всей группы'), findsOneWidget); // староста может удалить

      await tester.tap(find.byTooltip('Удалить для всей группы'));
      await _settle(tester);
      expect(backend.homework.values.single['deleted'], isTrue);
      expect(find.text('Подготовить доклад'), findsNothing);
    });

    testWidgets('когда расписание обновилось (новый хеш), староста стирает устаревшие правки на сервере', (tester) async {
      final backend = FakeBackend(hash: 'старый-хеш');
      backend.overrides['o1'] = backend.override(); // привязана к «старому» расписанию
      await _start(tester, prefs: {...profile, 'editorToken': 'tok-GOODCODE', 'editorGroup': 'ofo-1-bi-25'}, sharedApi: backend.api());
      await _settle(tester);
      await _settle(tester);

      expect(backend.calls, contains('clear_stale_group_overrides'));
      expect(backend.overrides['o1']!['deleted'], isTrue);
      expect(find.text('3-33'), findsNothing);
    });

    testWidgets('без интернета остаётся то, что сохранено в телефоне; ошибок на экране нет', (tester) async {
      final backend = FakeBackend(hash: groupHash());
      backend.overrides['o1'] = backend.override();
      final failing = SharedApi('https://fake.test', 'key', client: MockClient((_) async => throw http.ClientException('нет сети')));
      await _start(tester, prefs: profile, sharedApi: failing);
      await _settle(tester);
      expect(find.text('3-33'), findsNothing); // ещё ничего не скачано
      expect(find.text('ЧТК и этика'), findsWidgets); // обычное расписание работает
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Поиск: свободные аудитории и расписание преподавателя', (tester) async {
    await _start(tester, prefs: profile); // среда 07.10.2026 13:30 МСК, 3 пара идёт

    await tester.tap(find.text('Поиск').last);
    await _settle(tester);

    // Преподаватель: набираем имя («Сайд-Усманович» — из середины полного ФИО) → выбираем из подсказок
    await tester.enterText(find.byType(TextField).first, 'Сайд-Усман');
    await _settle(tester);
    await tester.tap(find.text('Халиев Магомед Сайд-Усманович').last);
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
    // Настоящий шрифт приложения: тестовый шрифт Ahem намного шире и дал бы ложные переполнения
    await tester.runAsync(() async {
      final loader = FontLoader('Onest')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Onest.ttf').readAsBytesSync())));
      await loader.load();
    });
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

  testWidgets('Крупный шрифт (×2): поиск преподавателя с длинным полным ФИО и режимы поиска не ломаются', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('Onest')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Onest.ttf').readAsBytesSync())));
      await loader.load();
    });
    await _start(tester, prefs: profile);
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _settle(tester);

    await tester.tap(find.text('Поиск').last);
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Сайд-Усман');
    await _settle(tester);
    await tester.tap(find.text('Халиев Магомед Сайд-Усманович').last);
    await _settle(tester);
    expect(tester.takeException(), isNull);

    for (final mode in ['Аудитория', 'Свободные', 'Преподаватель']) {
      await tester.tap(find.text(mode));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: 'режим «$mode»');
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

  testWidgets('Уведомления: нажатие открывает нужный день или вкладку «ДЗ»', (tester) async {
    final gateway = FakeGateway();
    await _start(tester, prefs: profile, gateway: gateway); // среда 07.10.2026
    expect(gateway.lastPlan.first.payload, 'day:2026-10-07');
    expect(find.textContaining('7 октября'), findsWidgets);

    gateway.tapController.add('day:2026-10-09'); // пятница
    await _settle(tester);
    expect(find.textContaining('9 октября'), findsWidgets);
    expect(find.textContaining('7 октября'), findsNothing);

    gateway.tapController.add(homeworkPayload);
    await _settle(tester);
    expect(find.text('Добавить ДЗ'), findsOneWidget);
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
    await tester.tap(find.text('Изменить'));
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

  testWidgets('Перенос пары: ЧТК с 4 пары на 5 — на экране «перенесено», старое место пустое', (tester) async {
    final gateway = FakeGateway();
    await _start(tester, prefs: profile, gateway: gateway); // ср 07.10, 13:30
    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Перенести'));
    await _settle(tester);
    expect(find.text('Перенести пару'), findsOneWidget);

    await tester.tap(find.text('5 пара'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Перенести'));
    await _settle(tester);

    // Время 5 пары — 16:20 (раньше ЧТК была в 14:40)
    expect(find.text('16:20'), findsOneWidget);
    expect(find.text('14:40'), findsNothing);
    expect(find.text('перенесено'), findsOneWidget);
    // Напоминание теперь за 10 минут до 16:20, то есть в 16:10 (13:10 UTC)
    expect(gateway.lastPlan.first.title, 'ЧТК и этика → 2-15');
    expect(gateway.lastPlan.first.fireAt, DateTime.utc(2026, 10, 7, 13, 10));
  });

  testWidgets('Отмена каждую неделю: в «Мои правки» видно правило, удаление возвращает пару', (tester) async {
    await _start(tester, prefs: profile);
    await tester.longPress(find.text('ЧТК и этика').last);
    await _settle(tester);
    await tester.tap(find.text('Отменить каждую неделю'));
    await _settle(tester);
    expect(find.text('ЧТК и этика'), findsNothing);

    await tester.tap(find.text('Мои правки (1)'));
    await _settle(tester);
    expect(find.textContaining('каждую неделю'), findsWidgets);
    await tester.tap(find.byTooltip('Убрать правку'));
    await _settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);
    expect(find.text('ЧТК и этика'), findsWidgets);
  });
}
