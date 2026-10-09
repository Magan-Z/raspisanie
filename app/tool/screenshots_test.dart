// Инструмент разработчика (не часть набора тестов): рисует экраны приложения в PNG с настоящими шрифтами,
// чтобы оценить внешний вид без телефона. Запуск из папки app/:
//   flutter test tool/screenshots_test.dart
// Картинки появятся в /tmp/claude-shots/design/. Шрифт значков берётся из установленного Flutter.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/app_state.dart';
import 'package:raspisanie/core/clock.dart';
import 'package:raspisanie/data/local/database.dart';
import 'package:raspisanie/data/repositories/schedule_repository.dart';
import 'package:raspisanie/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/fakes.dart';

const outDir = '/tmp/claude-shots/design';

Future<void> loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  Future<ByteData> read(String path) async => ByteData.sublistView(File(path).readAsBytesSync());
  final onest = FontLoader('Onest')..addFont(read('assets/fonts/Onest.ttf'));
  await onest.load();
  final icons = FontLoader('MaterialIcons')..addFont(read('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  Future<void> shoot(WidgetTester tester, String name, {required bool dark, DateTime? now, double textScale = 1, Future<void> Function()? act, Map<String, Object> prefs = const {}, bool noProfile = false, Size size = const Size(1080, 2340)}) async {
    tester.view.physicalSize = size;
    // Как на настоящем телефоне: строка состояния сверху и жестовая полоса снизу
    tester.view.padding = const FakeViewPadding(top: 72, bottom: 66);
    tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 66);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      if (!noProfile) ...{'form': 'ofo', 'groupId': 'ofo-1-bi-25', 'subgroup': 1, 'pe': 'male'},
      'theme': dark ? 'dark' : 'light',
      ...prefs,
    });
    final sp = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() => db.customSelect('select 1').get());
    addTearDown(() => tester.runAsync(db.close));

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          databaseProvider.overrideWithValue(db),
          repositoryProvider.overrideWithValue(ScheduleRepository(db: db, assets: DiskAssets())),
          notificationGatewayProvider.overrideWithValue(FakeGateway()),
          clockProvider.overrideWithValue(FixedClock(now ?? DateTime.utc(2026, 10, 7, 10, 30))), // ср 13:30 МСК
        ],
        child: const RaspisanieApp(),
      ),
    ));

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    }

    await settle();
    if (name == '1-today-light') {
      debugPrint('RECT nav=${tester.getRect(find.byType(NavigationBar))} scaffold=${tester.getRect(find.byType(Scaffold).first)} view=${tester.view.physicalSize / tester.view.devicePixelRatio}');
    }
    if (act != null) {
      await act();
      await settle();
    }
    await tester.runAsync(() async {
      Directory(outDir).createSync(recursive: true);
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  for (final dark in [false, true]) {
    final suffix = dark ? 'dark' : 'light';

    testWidgets('today $suffix', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '1-today-$suffix', dark: dark);
    });

    testWidgets('week $suffix', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '2-week-$suffix', dark: dark, act: () async {
        await tester.tap(find.text('Неделя').last);
      });
    });

    testWidgets('homework $suffix', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '3-homework-$suffix', dark: dark, act: () async {
        await tester.tap(find.text('ДЗ').last);
      });
    });

    testWidgets('search $suffix', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '4-search-$suffix', dark: dark, act: () async {
        await tester.tap(find.text('Поиск').last);
      });
    });

    testWidgets('settings $suffix', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '5-settings-$suffix', dark: dark, act: () async {
        await tester.tap(find.text('Настройки').last);
      });
    });
  }

  testWidgets('onboarding', (tester) async {
    await tester.runAsync(loadFonts);
    await shoot(tester, '6-onboarding', dark: false, noProfile: true);
    await shoot(tester, '6-onboarding-dark', dark: true, noProfile: true);
  });

  for (final entry in {'today': null, 'week': 'Неделя', 'homework': 'ДЗ', 'search': 'Поиск', 'settings': 'Настройки'}.entries) {
    testWidgets('narrow big font ${entry.key}', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '8-narrow-${entry.key}', dark: false, textScale: 2, size: const Size(960, 2000), act: () async {
        if (entry.value != null) await tester.tap(find.text(entry.value!).last);
      });
    });
  }

  // Как на телефоне пользователя: шрифт крупнее обычного, вкладки поиска и этажи
  for (final tab in ['Преподаватель', 'Аудитория', 'Свободные']) {
    testWidgets('search phone $tab', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '9-search-phone-$tab', dark: false, textScale: 1.3, act: () async {
        await tester.tap(find.text('Поиск').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(tab).first);
      });
    });
  }

  for (final entry in {'today': null, 'week': 'Неделя', 'homework': 'ДЗ', 'settings': 'Настройки'}.entries) {
    testWidgets('phone font ${entry.key}', (tester) async {
      await tester.runAsync(loadFonts);
      await shoot(tester, '9-phone-${entry.key}', dark: false, textScale: 1.3, act: () async {
        if (entry.value != null) await tester.tap(find.text(entry.value!).last);
      });
    });
  }

  // Все цветовые темы: «Сегодня» светлая и тёмная, настройки с выбором темы
  for (final id in ['ocean', 'forest', 'plum', 'sunset', 'graphite']) {
    for (final dark in [false, true]) {
      testWidgets('palette $id ${dark ? 'dark' : 'light'}', (tester) async {
        await tester.runAsync(loadFonts);
        await shoot(tester, 'A-palette-$id-${dark ? 'dark' : 'light'}', dark: dark, prefs: {'palette': id});
      });
    }
  }
  testWidgets('amoled', (tester) async {
    await tester.runAsync(loadFonts);
    await shoot(tester, 'A-amoled', dark: true, prefs: {'amoled': true, 'palette': 'ocean'});
  });
  testWidgets('settings palettes', (tester) async {
    await tester.runAsync(loadFonts);
    await shoot(tester, 'A-settings-themes', dark: false, act: () async {
      await tester.tap(find.text('Настройки').last);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('today large font', (tester) async {
    await tester.runAsync(loadFonts);
    await shoot(tester, '7-today-bigfont', dark: false, textScale: 1.6);
  });
}
