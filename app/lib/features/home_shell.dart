// Нижняя панель: «Сегодня» · «Неделя» · «ДЗ» · «Поиск» · «Настройки».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_outputs.dart';
import '../app_state.dart';
import '../widget_bridge/deep_links.dart';
import 'homework/add_homework_sheet.dart';
import 'homework/homework_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'today/today_screen.dart';
import 'week/week_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Расписание уже показано из кэша — обновления проверяем фоном и молча
    WidgetsBinding.instance.addPostFrameCallback((_) => syncSchedule(ProviderScope.containerOf(context)));

    // Виджеты и уведомления: после любого изменения (расписание, ДЗ, правки, профиль, настройки) пересобираем
    ref.listenManual(myScheduleProvider, (_, _) => _scheduleRefresh(), fireImmediately: true);
    ref.listenManual(homeworkProvider, (_, _) => _scheduleRefresh());
    ref.listenManual(settingsProvider, (_, _) => _scheduleRefresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _askNotificationPermissionOnce());

    // Ссылки с виджета («+ ДЗ»)
    final links = ref.read(linkChannelProvider);
    links.listen(_openLink);
    links.initialLink().then(_openLink);
  }

  void _openLink(String? link) {
    final action = parseLink(link);
    if (action == null || !mounted) return;
    setState(() => _tab = 2); // вкладка «ДЗ»
    showAddHomework(context, subject: action.subject);
  }

  Timer? _debounce;

  /// Изменения часто приходят пачкой (расписание, ДЗ, настройки) — пересобираем один раз.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _refreshOutputs);
  }

  Future<void> _refreshOutputs() async {
    if (!mounted) return;
    try {
      await refreshOutputs(ProviderScope.containerOf(context));
    } catch (_) {
      // Виджеты и уведомления — удобство: сбой не должен мешать приложению
    }
  }

  /// Один раз спрашиваем разрешение на уведомления (Android 13+), когда они включены по умолчанию.
  Future<void> _askNotificationPermissionOnce() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool('notificationPermissionAsked') ?? false) return;
    await prefs.setBool('notificationPermissionAsked', true);
    try {
      final gateway = ref.read(notificationGatewayProvider);
      await gateway.init();
      await gateway.requestPermission();
    } catch (_) {}
    _scheduleRefresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncSchedule(ProviderScope.containerOf(context));
      _scheduleRefresh(); // наступил новый день — снимок и уведомления «7 дней вперёд» сдвигаются
    }
  }

  @override
  Widget build(BuildContext context) {
    const pages = [TodayScreen(), WeekScreen(), HomeworkScreen(), SearchScreen(), SettingsScreen()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Сегодня'),
          NavigationDestination(
              icon: Icon(Icons.calendar_view_week_outlined), selectedIcon: Icon(Icons.calendar_view_week), label: 'Неделя'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'ДЗ'),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Поиск'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
