// Нижняя панель: «Сегодня» · «Неделя» · «ДЗ» · «Поиск» · «Настройки».

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_outputs.dart';
import '../app_state.dart';
import '../core/bells.dart' show moscowToday;
import '../domain/notification_plan.dart';
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

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Расписание уже показано из кэша — обновления проверяем фоном и молча
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => syncSchedule(ProviderScope.containerOf(context)),
    );

    // Виджеты и уведомления: после любого изменения (расписание, ДЗ, правки, профиль, настройки) пересобираем
    ref.listenManual(
      myScheduleProvider,
      (_, _) => _scheduleRefresh(),
      fireImmediately: true,
    );
    ref.listenManual(homeworkProvider, (_, _) => _scheduleRefresh());
    ref.listenManual(settingsProvider, (_, _) => _scheduleRefresh());
    ref.listenManual(subjectStyleMapProvider, (_, _) => _scheduleRefresh()); // свои названия предметов попадают в виджеты и уведомления
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _askNotificationPermissionOnce(),
    );

    // Ссылки с виджета («+ ДЗ»)
    final links = ref.read(linkChannelProvider);
    links.listen(_openLink);
    links.initialLink().then(_openLink);

    // Нажатие на уведомление: пара → её день на «Сегодня», напоминание о ДЗ → вкладка «ДЗ»
    final gateway = ref.read(notificationGatewayProvider);
    _tapSub = gateway.taps.listen(_openNotification);
    gateway.launchPayload().then(_openNotification).catchError((_) {});
  }

  StreamSubscription<String>? _tapSub;

  void _openNotification(String? payload) {
    if (payload == null || !mounted) return;
    if (payload == homeworkPayload) {
      setState(() => _tab = 2);
      return;
    }
    final day = parseDayPayload(payload);
    if (day == null) return;
    setState(() => _tab = 0);
    ref.read(requestedDayProvider.notifier).request(day);
  }

  void _openLink(String? link) {
    final action = parseAnyLink(link);
    if (action == null || !mounted) return;
    switch (action) {
      case AddHomeworkLink():
        setState(() => _tab = 2); // вкладка «ДЗ»
        showAddHomework(context, subject: action.subject);
      case OpenHomeworkLink():
        setState(() => _tab = 2);
      case OpenTabLink():
        setState(() => _tab = action.tab);
      case OpenTomorrowLink():
        setState(() => _tab = 0);
        ref.read(requestedDayProvider.notifier).request(moscowToday(ref.read(clockProvider).now()).add(const Duration(days: 1)));
    }
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
    if (kIsWeb) return; // в браузере разрешение на уведомления не нужно
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
    _tapSub?.cancel();
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
    const pages = [
      TodayScreen(),
      WeekScreen(),
      HomeworkScreen(),
      SearchScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      // Подписи нижней панели не растут выше 1.15× — иначе слова переносятся и панель разваливается
      bottomNavigationBar: Builder(
        // MediaQuery берём именно здесь, внутри Scaffold: он уже убрал лишние отступы (иначе панель получается выше)
        builder: (navContext) => MediaQuery(
          data: MediaQuery.of(navContext).copyWith(
            textScaler: MediaQuery.textScalerOf(navContext)
                // на узких экранах (≈360 dp) пять подписей помещаются только в обычном размере
                .clamp(maxScaleFactor: MediaQuery.sizeOf(navContext).width < 380 ? 1.0 : 1.15),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'Сегодня',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_view_week_outlined),
                selectedIcon: Icon(Icons.calendar_view_week),
                label: 'Неделя',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'ДЗ',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: 'Поиск',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Настройки',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
