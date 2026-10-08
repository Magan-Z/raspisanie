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

Future<void> _start(WidgetTester tester, {Map<String, Object> prefs = const {}, DateTime? now}) async {
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
}
