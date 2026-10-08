// Настройки: группа, подгруппа, физ-ра, тема, ручной переключатель недели, «О приложении».
// (Уведомления, короткие названия и экспорт ДЗ добавятся на этапах 4–5.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/formatting.dart';
import '../../domain/homework.dart';
import '../../domain/models.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final profile = settings.profile;
    final index = ref.watch(indexProvider).value;
    final group = profile == null ? null : index?.findGroup(profile.groupId);
    final today = ref.watch(todayProvider);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text('Настройки', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: Text(group?.title ?? 'Группа не выбрана'),
          subtitle: const Text('Сменить группу'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen(changing: true))),
        ),
        if (group != null && group.subgroups.length > 1 && profile != null)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Подгруппа'),
            subtitle: DropdownButton<int>(
              isExpanded: true,
              value: profile.subgroup,
              underline: const SizedBox(),
              items: [for (final s in group.subgroups) DropdownMenuItem(value: s.n, child: Text(s.label))],
              onChanged: (v) => v == null ? null : notifier.setProfile(profile.copyWith(subgroup: v)),
            ),
          ),
        if (group != null && group.hasGenderedPe && profile != null)
          ListTile(
            leading: const Icon(Icons.sports_outlined),
            title: const Text('Физкультура'),
            subtitle: DropdownButton<PeChoice>(
              isExpanded: true,
              value: profile.pe,
              underline: const SizedBox(),
              items: [for (final p in PeChoice.values) DropdownMenuItem(value: p, child: Text(p.title))],
              onChanged: (v) => v == null ? null : notifier.setProfile(profile.copyWith(pe: v)),
            ),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Тема'),
          subtitle: DropdownButton<ThemeMode>(
            isExpanded: true,
            value: settings.themeMode,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('Системная')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Светлая')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Тёмная')),
            ],
            onChanged: (v) => v == null ? null : notifier.setThemeMode(v),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Напоминание перед парой'),
          subtitle: DropdownButton<int>(
            isExpanded: true,
            value: const [0, 5, 10, 15, 30].contains(settings.notifyBeforeMin) ? settings.notifyBeforeMin : 10,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Выключено')),
              DropdownMenuItem(value: 5, child: Text('За 5 минут')),
              DropdownMenuItem(value: 10, child: Text('За 10 минут')),
              DropdownMenuItem(value: 15, child: Text('За 15 минут')),
              DropdownMenuItem(value: 30, child: Text('За 30 минут')),
            ],
            onChanged: (v) => v == null ? null : notifier.setNotifyBeforeMin(v),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.assignment_late_outlined),
          title: const Text('Вечером напоминать о ДЗ'),
          subtitle: const Text('В 19:00, если на завтра есть невыполненные задания'),
          value: settings.eveningHomeworkReminder,
          onChanged: notifier.setEveningHomeworkReminder,
        ),
        Consumer(builder: (context, ref, _) {
          return ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Разрешить уведомления'),
            subtitle: const Text('Если уведомления не приходят — нажмите, чтобы разрешить их в системе'),
            onTap: () async {
              var allowed = false;
              try {
                final gateway = ref.read(notificationGatewayProvider);
                await gateway.init();
                allowed = await gateway.requestPermission() || await gateway.areEnabled();
              } catch (_) {}
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(allowed ? 'Уведомления разрешены' : 'Уведомления запрещены. Включите их в настройках телефона: Приложения → Расписание → Уведомления'),
              ));
            },
          );
        }),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: const Text('Номер недели'),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(settings.forcedWeek == null
                ? 'Считается автоматически (${index == null ? '—' : '${_autoWeek(index, today)} неделя'}). Переключите вручную, если в институте чередование сбилось.'
                : 'Выбрана вручную: ${settings.forcedWeek} неделя'),
            DropdownButton<int?>(
              isExpanded: true,
              value: settings.forcedWeek,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null, child: Text('Авто')),
                DropdownMenuItem(value: 1, child: Text('1 неделя')),
                DropdownMenuItem(value: 2, child: Text('2 неделя')),
              ],
              onChanged: notifier.setForcedWeek,
            ),
          ]),
        ),
        const Divider(),
        Consumer(builder: (context, ref, _) {
          final fetched = ref.watch(lastFetchedProvider).value;
          final now = ref.watch(nowProvider).value ?? ref.read(clockProvider).now();
          return ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Обновить расписание'),
            subtitle: Text(fetched == null ? 'Сейчас используется встроенная копия' : 'Обновлено ${agoText(fetched, now)}'),
            onTap: () async {
              final result = await syncSchedule(ref);
              if (!context.mounted) return;
              final text = result.error != null ? 'Нет связи с сервером — работаем с сохранённым расписанием' : 'Расписание актуально';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
            },
          );
        }),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Экспорт ДЗ'),
          subtitle: const Text('Скопировать все ДЗ в буфер обмена — например, чтобы сохранить в заметках или отправить себе'),
          onTap: () async {
            final items = await ref.read(homeworkRepositoryProvider).all();
            await Clipboard.setData(ClipboardData(text: exportHomework(items)));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скопировано ДЗ: ${items.length}')));
          },
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Импорт ДЗ'),
          subtitle: const Text('Вставить ДЗ, скопированные раньше (на новом телефоне)'),
          onTap: () async {
            final clip = await Clipboard.getData(Clipboard.kTextPlain);
            String message;
            try {
              final added = await ref.read(homeworkRepositoryProvider).importItems(importHomework(clip?.text ?? ''));
              ref.invalidate(homeworkProvider);
              message = 'Добавлено ДЗ: $added';
            } on FormatException catch (e) {
              message = '${e.message}. Сначала скопируйте текст экспорта.';
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('О приложении'),
          subtitle: Text('Версия расписания: ${index?.version.substring(0, 10) ?? '—'}\nБез аккаунтов, рекламы и слежки.'),
          isThreeLine: true,
        ),
      ],
    );
  }

  int _autoWeek(ScheduleIndex index, DateTime today) {
    final days = today.difference(index.weekAnchor).inDays;
    return (days / 7).floor() % 2 + 1;
  }
}
