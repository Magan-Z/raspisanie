// Новая версия приложения: сравнение версий, плашка «Вышла версия», экран «Нужно обновить», защита от ошибок.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unigraf/app_state.dart';
import 'package:unigraf/core/clock.dart';
import 'package:unigraf/features/update_banner.dart';
import 'package:unigraf/update_check.dart';


void main() {
  group('версии', () {
    test('сравнение', () {
      expect(compareVersions('0.3.4', '0.3.10'), lessThan(0));
      expect(compareVersions('0.4.0', '0.3.9'), greaterThan(0));
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('v0.3.4', '0.3.4'), 0);
      expect(compareVersions('мусор', '0.3.4'), isNull);
      expect(compareVersions('', '0.3.4'), isNull);
    });

    test('apk.json разбирается, странный ответ отбрасывается', () {
      final info = UpdateInfo.parse({'version': '0.3.5', 'size': 1, 'min': '0.3.0'})!;
      expect((info.latest, info.min), ('0.3.5', '0.3.0'));
      expect(UpdateInfo.parse({'version': '0.3.5'})!.min, '0.0.0'); // старый формат без min
      expect(UpdateInfo.parse({'version': 5}), isNull);
      expect(UpdateInfo.parse({'version': 'abc'}), isNull);
      expect(UpdateInfo.parse('строка'), isNull);
      expect(UpdateInfo.parse({'version': '0.3.5', 'min': 'abc'})!.min, '0.0.0');
    });
  });

  group('что показывать', () {
    const info = UpdateInfo(latest: '0.3.5', min: '0.3.0');

    test('новее нет → ничего', () {
      expect(computeUpdateStatus(current: '0.3.5', info: info), UpdateStatus.none);
      expect(computeUpdateStatus(current: '0.4.0', info: info), UpdateStatus.none);
    });

    test('есть новее → плашка; после «Позже» не показываем ту же версию, но показываем следующую', () {
      expect(computeUpdateStatus(current: '0.3.4', info: info), UpdateStatus.available);
      expect(computeUpdateStatus(current: '0.3.4', info: info, dismissed: '0.3.5'), UpdateStatus.none);
      expect(computeUpdateStatus(current: '0.3.4', info: const UpdateInfo(latest: '0.3.6'), dismissed: '0.3.5'), UpdateStatus.available);
    });

    test('версия ниже минимальной → обязательное обновление, «Позже» не помогает', () {
      expect(computeUpdateStatus(current: '0.2.9', info: info, dismissed: '0.3.5'), UpdateStatus.required);
    });

    test('защита: нет данных, нет своей версии, min выше последней версии → не блокируем', () {
      expect(computeUpdateStatus(current: '0.2.9', info: null), UpdateStatus.none);
      expect(computeUpdateStatus(current: '', info: info), UpdateStatus.none);
      expect(computeUpdateStatus(current: '0.3.4', info: const UpdateInfo(latest: '0.3.5', min: '9.0.0')), UpdateStatus.available);
      expect(computeUpdateStatus(current: 'мусор', info: info), UpdateStatus.none);
    });
  });

  test('сайт недоступен или ответил не так → null, ничего не падает', () async {
    expect(await fetchUpdateInfo('https://example.test', client: MockClient((_) async => throw http.ClientException('нет сети'))), isNull);
    expect(await fetchUpdateInfo('https://example.test', client: MockClient((_) async => http.Response('нет такого', 404))), isNull);
    expect(await fetchUpdateInfo('https://example.test', client: MockClient((_) async => http.Response('не json', 200))), isNull);
    final ok = MockClient((r) async {
      expect(r.url.toString(), 'https://example.test/apk.json');
      return http.Response('{"version":"0.3.5","size":10,"min":"0.3.0"}', 200);
    });
    expect((await fetchUpdateInfo('https://example.test', client: ok))!.latest, '0.3.5');
  });

  group('экран', () {
    Future<(ProviderContainer, List<String>)> pump(WidgetTester tester, {required String current, required UpdateInfo? info, bool opens = true, Map<String, Object> prefs = const {}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      final sp = await SharedPreferences.getInstance();
      final log = <String>[];
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 10, 17, 10))),
        appVersionProvider.overrideWithValue(current),
        updateEnabledProvider.overrideWithValue(true),
        updateFetcherProvider.overrideWithValue(() async => info),
        updateOpenerProvider.overrideWithValue(() async {
          log.add('открыто');
          return opens;
        }),
      ]);
      addTearDown(container.dispose);
      await container.read(updateInfoProvider.notifier).check();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: Column(children: [UpdateBanner(), Expanded(child: SizedBox())]))),
      ));
      return (container, log);
    }

    testWidgets('плашка: показывается, «Скачать» открывает загрузку, «Позже» прячет её и запоминает версию', (tester) async {
      final (container, log) = await pump(tester, current: '0.3.4', info: const UpdateInfo(latest: '0.3.5'));
      expect(find.text('Вышла версия 0.3.5'), findsOneWidget);

      await tester.tap(find.text('Скачать'));
      await tester.pump();
      expect(log, ['открыто']);

      await tester.tap(find.byTooltip('Позже'));
      await tester.pump();
      expect(find.text('Вышла версия 0.3.5'), findsNothing);
      expect(container.read(sharedPreferencesProvider).getString('update.dismissed'), '0.3.5');
    });

    testWidgets('плашки нет, если версия свежая или версию узнать не удалось', (tester) async {
      await pump(tester, current: '0.3.5', info: const UpdateInfo(latest: '0.3.5'));
      expect(find.textContaining('Вышла версия'), findsNothing);
      await pump(tester, current: '0.3.4', info: null);
      expect(find.textContaining('Вышла версия'), findsNothing);
    });

    testWidgets('плашки нет, если про эту версию уже нажали «Позже» раньше', (tester) async {
      await pump(tester, current: '0.3.4', info: const UpdateInfo(latest: '0.3.5'), prefs: {'update.dismissed': '0.3.5'});
      expect(find.textContaining('Вышла версия'), findsNothing);
    });

    testWidgets('экран «Нужно обновить»: показывает версии и открывает загрузку; если не открылось — подсказывает адрес', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      var opened = false;
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        appVersionProvider.overrideWithValue('0.2.9'),
        updateOpenerProvider.overrideWithValue(() async {
          opened = true;
          return false;
        }),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: UpdateRequiredScreen())));
      expect(find.text('Нужно обновить приложение'), findsOneWidget);
      expect(find.textContaining('0.2.9'), findsOneWidget);
      await tester.tap(find.text('Скачать обновление'));
      await tester.pump();
      await tester.pump();
      expect(opened, isTrue);
      expect(find.textContaining('unigraf.apk'), findsOneWidget);
    });
  });

  test('проверка не чаще раза в 6 часов, но с force — сразу', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    var calls = 0;
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 10, 17, 10))),
      updateEnabledProvider.overrideWithValue(true),
      updateFetcherProvider.overrideWithValue(() async {
        calls++;
        return const UpdateInfo(latest: '0.3.5');
      }),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(updateInfoProvider.notifier);
    await notifier.check();
    await notifier.check();
    expect(calls, 1);
    await notifier.check(force: true);
    expect(calls, 2);
  });

  test('если проверка выключена (веб, локальная сборка), сайт не опрашивается', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    var calls = 0;
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      updateEnabledProvider.overrideWithValue(false),
      updateFetcherProvider.overrideWithValue(() async {
        calls++;
        return null;
      }),
    ]);
    addTearDown(container.dispose);
    await container.read(updateInfoProvider.notifier).check();
    expect(calls, 0);
  });
}
