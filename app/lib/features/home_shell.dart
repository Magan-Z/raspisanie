// Нижняя панель: «Сегодня» · «Неделя» · «ДЗ» · «Поиск» · «Настройки».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => syncSchedule(ref));

    // Виджеты: после любого изменения (расписание, ДЗ, профиль, неделя) пересобираем снимок
    ref.listenManual(myScheduleProvider, (_, _) => _pushWidgets(), fireImmediately: true);
    ref.listenManual(homeworkProvider, (_, _) => _pushWidgets());

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

  /// Отдаёт виджетам свежий снимок расписания на 7 дней.
  Future<void> _pushWidgets() async {
    final my = ref.read(myScheduleProvider).value;
    if (my == null) return;
    final homework = ref.read(homeworkProvider).value ?? const [];
    await ref.read(widgetBridgeProvider).push(
          now: ref.read(clockProvider).now(),
          index: my.index,
          schedule: my.schedule,
          profile: my.profile,
          homework: homework,
          forcedWeek: my.forcedWeek,
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncSchedule(ref);
      _pushWidgets(); // наступил новый день — снимок «7 дней вперёд» сдвигается
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
