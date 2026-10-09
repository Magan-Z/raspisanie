import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'background/background_sync.dart';
import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

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
    // Если выбранной группы больше нет в расписании (например, новый семестр) — снова предлагаем выбрать группу
    final index = ref.watch(indexProvider).value;
    final profile = settings.profile;
    final needsOnboarding = profile == null || (index != null && index.findGroup(profile.groupId) == null);

    // По умолчанию — фирменные цвета; в настройках можно включить цвета из обоев (Material You, Android 12+)
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ThemeData theme(Brightness b, ColorScheme? dynamic) => buildTheme(
              resolveScheme(brightness: b, dynamicScheme: settings.useDynamicColor ? dynamic : null),
            );
        return MaterialApp(
          title: 'Расписание',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: theme(Brightness.light, lightDynamic),
          darkTheme: theme(Brightness.dark, darkDynamic),
          home: needsOnboarding ? const OnboardingScreen() : const HomeShell(),
        );
      },
    );
  }
}
