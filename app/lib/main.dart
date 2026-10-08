import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'background/background_sync.dart';
import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  registerBackgroundSync(); // раз в ~6 часов проверяет обновления, даже когда приложение закрыто
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const RaspisanieApp(),
  ));
}

class RaspisanieApp extends ConsumerWidget {
  const RaspisanieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Material You: цвета из обоев на Android 12+, иначе — запасной синий
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme scheme(Brightness b, ColorScheme? dynamic) =>
            dynamic ?? ColorScheme.fromSeed(seedColor: const Color(0xFF2F5BD3), brightness: b);
        return MaterialApp(
          title: 'Расписание',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(useMaterial3: true, colorScheme: scheme(Brightness.light, lightDynamic)),
          darkTheme: ThemeData(useMaterial3: true, colorScheme: scheme(Brightness.dark, darkDynamic)),
          home: settings.profile == null ? const OnboardingScreen() : const HomeShell(),
        );
      },
    );
  }
}
