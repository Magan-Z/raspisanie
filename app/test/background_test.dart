// Фоновая проверка: приложение закрыто, а расписание изменилось на сайте.
// Должно: скачать новое, показать «Расписание обновилось», обновить виджеты и заново поставить уведомления.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/app_state.dart';
import 'package:raspisanie/background/background_sync.dart';
import 'package:raspisanie/core/clock.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/remote/schedule_api.dart';
import 'package:raspisanie/data/repositories/schedule_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('фоновая синхронизация: новое расписание → баннер, уведомление, виджеты, план уведомлений', () async {
    SharedPreferences.setMockInitialValues({'form': 'ofo', 'groupId': 'ofo-1-bi-25', 'subgroup': 1, 'pe': 'male'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final gateway = FakeGateway();

    // «Сайт» с расписанием, где у 1 БИ-25 в среду 4 пары лекция/практика ЧТК перенесена в другую аудиторию
    final index = jsonDecode(File('test/fixtures/index.json').readAsStringSync()) as Map<String, dynamic>;
    index['version'] = '2099-01-01T00:00:00Z-new';
    for (final form in index['forms']) {
      for (final g in form['groups']) {
        if (g['id'] == 'ofo-1-bi-25') g['hash'] = 'newhash';
      }
    }
    final files = <String, String>{'index.json': jsonEncode(index)};
    for (final f in Directory('test/fixtures/all').listSync().whereType<File>()) {
      final group = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      group['version'] = '2099-01-01T00:00:00Z-new';
      if (f.path.endsWith('ofo-1-bi-25.json')) {
        for (final l in group['lessons']) {
          if (l['subject'] == 'ЧТК и этика' && l['week'] == 2) l['room'] = '3-33';
        }
      }
      files['groups/${f.path.split('/').last}'] = jsonEncode(group);
    }
    final changedLesson = ((jsonDecode(files['groups/ofo-1-bi-25.json']!) as Map)['lessons'] as List)
        .firstWhere((l) => l['subject'] == 'ЧТК и этика' && l['week'] == 2);
    files['diff/latest.json'] = jsonEncode({
      'groups': {
        'ofo-1-bi-25': {
          'added': [],
          'removed': [],
          'changed': [
            {'lesson': changedLesson, 'changes': {'room': ['2-15', '3-33']}},
          ],
        },
      },
    });
    final site = FakeSite(files);

    // Виджетам должен уйти новый снимок
    MethodCall? widgetCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (call) async {
      if (call.method == 'saveWidgetData') widgetCall = call;
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null));

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 10, 7, 5, 0))), // среда 08:00 МСК
      notificationGatewayProvider.overrideWithValue(gateway),
      repositoryProvider.overrideWithValue(ScheduleRepository(
        db: db,
        assets: DiskAssets(),
        api: ScheduleApi('https://example.test/site/', client: site.client),
      )),
    ]);
    addTearDown(container.dispose);

    // Первый запуск «из кэша»: группа ещё не скачивалась — это не считается изменением
    await container.read(repositoryProvider).sync(groupId: 'ofo-1-bi-25');
    // Теперь на сайте появляется следующая версия, и фоновая задача её замечает
    final next = jsonDecode(files['index.json']!) as Map<String, dynamic>;
    for (final form in next['forms']) {
      for (final g in form['groups']) {
        if (g['id'] == 'ofo-1-bi-25') g['hash'] = 'newhash-2';
      }
    }
    next['version'] = '2099-02-02T00:00:00Z-next';
    final nextGroup = jsonDecode(files['groups/ofo-1-bi-25.json']!) as Map<String, dynamic>;
    nextGroup['version'] = '2099-02-02T00:00:00Z-next'; // содержимое действительно изменилось → другой ETag
    site.files = {...files, 'index.json': jsonEncode(next), 'groups/ofo-1-bi-25.json': jsonEncode(nextGroup)};

    await runBackgroundSync(container);

    // 1. Показано уведомление «Расписание обновилось», а в приложении будет баннер
    expect(gateway.shown, ['Расписание обновилось: 1 изменение']);
    expect(prefs.getStringList('updateBanner'), isNotNull);
    expect(prefs.getStringList('updateBanner')!.single, contains('аудитория: 2-15 → 3-33'));

    // 2. Уведомления перепланированы на основе нового расписания
    expect(gateway.plans, isNotEmpty);
    expect(gateway.lastPlan.map((n) => n.title), contains('ЧТК и этика → 3-33'));

    // 3. Виджетам ушёл снимок с новой аудиторией
    expect(widgetCall?.method, 'saveWidgetData');
    expect(widgetCall!.arguments['data'] as String, contains('3-33'));
  });

  test('без выбранной группы фоновая задача ничего не делает и не падает', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final gateway = FakeGateway();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      notificationGatewayProvider.overrideWithValue(gateway),
      repositoryProvider.overrideWithValue(ScheduleRepository(db: db, assets: DiskAssets())),
    ]);
    addTearDown(container.dispose);

    await runBackgroundSync(container);
    expect(gateway.plans, isEmpty);
    expect(gateway.shown, isEmpty);
  });
}
