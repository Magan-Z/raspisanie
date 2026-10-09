// Состояние приложения (Riverpod): настройки, расписание, «сейчас», синхронизация.
// Экраны только читают эти провайдеры — логика живёт здесь и в domain/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'core/bells.dart';
import 'core/clock.dart';
import 'core/week.dart';
import 'data/attachments/attachment_store.dart';
import 'data/local/database.dart';
import 'data/remote/schedule_api.dart';
import 'data/repositories/homework_repository.dart';
import 'data/repositories/overrides_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/subject_styles_repository.dart';
import 'domain/diff_summary.dart';
import 'domain/homework.dart';
import 'domain/models.dart';
import 'domain/subject_styles.dart';
import 'notifications/notification_gateway.dart';
import 'theme/brand_colors.dart';
import 'widget_bridge/deep_links.dart';
import 'widget_bridge/widget_sync.dart';

// ---------- базовые зависимости (в тестах подменяются) ----------

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences передаётся в main()'),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<ScheduleRepository>((ref) => ScheduleRepository(
      db: ref.watch(databaseProvider),
      assets: rootBundle,
      api: scheduleBaseUrl.isEmpty ? null : ScheduleApi(scheduleBaseUrl),
    ));

// ---------- настройки (shared_preferences) ----------

class Settings {
  const Settings({
    this.profile,
    this.themeMode = ThemeMode.system,
    this.forcedWeek,
    this.notifyBeforeMin = 10,
    this.eveningHomeworkReminder = true,
    this.useDynamicColor = false,
    this.palette = AppPalette.petrol,
    this.amoled = false,
    this.customSubjects = true,
  });

  final UserProfile? profile; // null — первый запуск, профиль ещё не выбран
  final ThemeMode themeMode;
  final int? forcedWeek; // null — неделя считается автоматически
  final int notifyBeforeMin; // 0 — уведомления перед парой выключены
  final bool eveningHomeworkReminder;
  final bool useDynamicColor; // цвета из обоев (Material You) вместо фирменных
  final AppPalette palette; // цветовая тема
  final bool amoled; // чёрный фон в тёмной теме
  final bool customSubjects; // показывать свои названия и цвета предметов
}

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Settings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final groupId = prefs.getString('groupId');
    return Settings(
      profile: groupId == null
          ? null
          : UserProfile(
              formCode: prefs.getString('form') ?? '',
              groupId: groupId,
              subgroup: prefs.getInt('subgroup') ?? 1,
              pe: PeChoice.parse(prefs.getString('pe')),
            ),
      themeMode: ThemeMode.values.byName(prefs.getString('theme') ?? 'system'),
      forcedWeek: prefs.getInt('forcedWeek'),
      notifyBeforeMin: prefs.getInt('notifyBeforeMin') ?? 10,
      eveningHomeworkReminder: prefs.getBool('eveningHomeworkReminder') ?? true,
      useDynamicColor: prefs.getBool('useDynamicColor') ?? false,
      palette: AppPalette.parse(prefs.getString('palette')),
      amoled: prefs.getBool('amoled') ?? false,
      customSubjects: prefs.getBool('customSubjects') ?? true,
    );
  }

  Future<void> setProfile(UserProfile profile) async {
    await _prefs.setString('form', profile.formCode);
    await _prefs.setString('groupId', profile.groupId);
    await _prefs.setInt('subgroup', profile.subgroup);
    await _prefs.setString('pe', profile.pe.name);
    ref.invalidateSelf();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('theme', mode.name);
    ref.invalidateSelf();
  }

  Future<void> setForcedWeek(int? week) async {
    if (week == null) {
      await _prefs.remove('forcedWeek');
    } else {
      await _prefs.setInt('forcedWeek', week);
    }
    ref.invalidateSelf();
  }

  Future<void> setNotifyBeforeMin(int minutes) async {
    await _prefs.setInt('notifyBeforeMin', minutes);
    ref.invalidateSelf();
  }

  Future<void> setPalette(AppPalette palette) async {
    await _prefs.setString('palette', palette.id);
    ref.invalidateSelf();
  }

  Future<void> setCustomSubjects(bool value) async {
    await _prefs.setBool('customSubjects', value);
    ref.invalidateSelf();
  }

  Future<void> setAmoled(bool value) async {
    await _prefs.setBool('amoled', value);
    ref.invalidateSelf();
  }

  Future<void> setUseDynamicColor(bool value) async {
    await _prefs.setBool('useDynamicColor', value);
    ref.invalidateSelf();
  }

  Future<void> setEveningHomeworkReminder(bool value) async {
    await _prefs.setBool('eveningHomeworkReminder', value);
    ref.invalidateSelf();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

// ---------- расписание ----------

final indexProvider = FutureProvider<ScheduleIndex>((ref) => ref.watch(repositoryProvider).loadIndex());

final groupScheduleProvider = FutureProvider.family<GroupSchedule, String>(
  (ref, groupId) async {
    await ref.watch(indexProvider.future); // при обновлении списка групп перечитываем и группу
    return ref.watch(repositoryProvider).loadGroup(groupId);
  },
);

/// Всё, что нужно экранам для «моего» расписания.
class MySchedule {
  const MySchedule({
    required this.index,
    required this.schedule,
    required this.profile,
    this.forcedWeek,
    this.overrides = const [],
  });
  final ScheduleIndex index;
  final GroupSchedule schedule;
  final UserProfile profile;
  final int? forcedWeek;
  final List<Override> overrides; // личные правки

  /// Номер недели для даты (с учётом ручного переключателя).
  int weekFor(DateTime day) => forcedWeek ?? weekNumber(day, index.weekAnchor);
}

final myScheduleProvider = FutureProvider<MySchedule?>((ref) async {
  final settings = ref.watch(settingsProvider);
  final profile = settings.profile;
  if (profile == null) return null;
  final index = await ref.watch(indexProvider.future);
  final schedule = await ref.watch(groupScheduleProvider(profile.groupId).future);
  final overrides = await ref.watch(overridesProvider.future);
  return MySchedule(index: index, schedule: schedule, profile: profile, forcedWeek: settings.forcedWeek, overrides: overrides);
});

// ---------- «сейчас» ----------

/// Текущее время, обновляется раз в 15 секунд — чтобы «до конца пары» и прогресс шли сами.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock.now());
  final timer = Timer.periodic(const Duration(seconds: 15), (_) => controller.add(clock.now()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Сегодняшний день по Москве.
final todayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
  return moscowToday(now);
});

// ---------- синхронизация ----------

/// Когда последний раз расписание пришло из сети (для тихой метки «обновлено 2 дня назад»).
final lastFetchedProvider = FutureProvider<DateTime?>((ref) => ref.watch(repositoryProvider).lastFetchedAt());

/// Проверить обновления на сайте и, если что-то изменилось, перечитать расписание.
Future<SyncResult> syncSchedule(ProviderContainer ref) async {
  final repo = ref.read(repositoryProvider);
  final groupId = ref.read(settingsProvider).profile?.groupId;
  final result = await repo.sync(groupId: groupId);
  if (result.indexChanged || result.groupChanged) {
    ref.invalidate(indexProvider);
  }
  final profile = ref.read(settingsProvider).profile;
  if (result.groupChanged && result.diffJson != null && profile != null) {
    final items = summarizeDiff(result.diffJson!, profile);
    if (items.isNotEmpty) {
      ref.read(updateBannerProvider.notifier).show(items);
      // То же — уведомлением (если приложение свёрнуто). Ошибка уведомления не должна ломать синхронизацию
      try {
        await ref.read(notificationGatewayProvider).showNow(
              id: 1,
              title: diffHeadline(items.length),
              body: items.take(3).join('\n'),
            );
      } catch (_) {}
    }
  }
  ref.invalidate(lastFetchedProvider);
  return result;
}

// ---------- домашние задания ----------

/// Файлы вложений к ДЗ (в тестах подменяется).
final attachmentStoreProvider = Provider<AttachmentStore>((ref) => DiskAttachmentStore());

/// Окна выбора файлов и камеры (в тестах подменяется).
final attachmentPickerProvider = Provider<AttachmentPicker>((ref) => SystemAttachmentPicker());

final homeworkRepositoryProvider =
    Provider<HomeworkRepository>((ref) => HomeworkRepository(ref.watch(databaseProvider), ref.watch(attachmentStoreProvider)));

/// Все ДЗ. После любого изменения вызываем ref.invalidate(homeworkProvider).
final homeworkProvider = FutureProvider<List<HomeworkItem>>((ref) => ref.watch(homeworkRepositoryProvider).all());

// ---------- поиск по институту ----------

/// Расписания всех групп (для поиска). Перечитываются, когда обновился список групп.
final allGroupsProvider = FutureProvider<List<GroupSchedule>>((ref) async {
  await ref.watch(indexProvider.future);
  return ref.watch(repositoryProvider).loadAllGroups();
});

// ---------- баннер «Расписание обновилось» ----------

/// Список изменений, который показывается на экране «Сегодня», пока пользователь не нажмёт «Понятно».
class UpdateBannerNotifier extends Notifier<List<String>> {
  static const _key = 'updateBanner';

  @override
  List<String> build() => ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  Future<void> show(List<String> items) async {
    await ref.read(sharedPreferencesProvider).setStringList(_key, items);
    state = items;
  }

  Future<void> dismiss() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = const [];
  }
}

final updateBannerProvider = NotifierProvider<UpdateBannerNotifier, List<String>>(UpdateBannerNotifier.new);

// ---------- мост с Android (виджеты, ссылки) ----------

final widgetBridgeProvider = Provider<WidgetBridge>((ref) => const WidgetBridge());
final linkChannelProvider = Provider<LinkChannel>((ref) => LinkChannel());

/// День, который нужно показать на экране «Сегодня» (после нажатия на уведомление). Экран сам его забирает.
class RequestedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void request(DateTime day) => state = day;
  void clear() => state = null;
}

final requestedDayProvider = NotifierProvider<RequestedDayNotifier, DateTime?>(RequestedDayNotifier.new);

// ---------- свои названия и цвета предметов ----------

final subjectStylesRepositoryProvider = Provider<SubjectStylesRepository>((ref) => SubjectStylesRepository(ref.watch(databaseProvider)));

/// Сохранённые настройки предметов. После изменения вызываем ref.invalidate(subjectStyleMapProvider).
final subjectStyleMapProvider = FutureProvider<Map<String, SubjectStyle>>((ref) => ref.watch(subjectStylesRepositoryProvider).all());

/// То, чем пользуются экраны: настройки + выключатель из «Настройки → Предметы».
final subjectStylesProvider = Provider<SubjectStyles>((ref) {
  final enabled = ref.watch(settingsProvider.select((s) => s.customSubjects));
  final map = ref.watch(subjectStyleMapProvider).value ?? const {};
  return SubjectStyles(enabled: enabled, styles: map);
});

// ---------- личные правки ----------

final overridesRepositoryProvider = Provider<OverridesRepository>((ref) => OverridesRepository(ref.watch(databaseProvider)));

/// Все личные правки. После изменения вызываем ref.invalidate(overridesProvider).
final overridesProvider = FutureProvider<List<Override>>((ref) => ref.watch(overridesRepositoryProvider).all());

// ---------- уведомления ----------

final notificationGatewayProvider = Provider<NotificationGateway>((ref) => LocalNotificationGateway());
