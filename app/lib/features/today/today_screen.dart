// Главный экран «Сегодня»: неделя и дата сверху, карточка текущей/следующей пары, остальные пары дня.
// Дни листаются свайпом. В воскресенье и после последней пары открывается ближайший учебный день.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/bells.dart';
import '../../core/formatting.dart';
import '../../domain/models.dart';
import '../../domain/schedule_resolver.dart';
import '../../domain/diff_summary.dart';
import '../../domain/homework.dart';
import '../common/lesson_widgets.dart';
import '../homework/add_homework_sheet.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  static const _firstPage = 5000; // листаем и назад, и вперёд от «середины»
  final _controller = PageController(initialPage: _firstPage);
  DateTime? _baseDay; // день, который соответствует странице _firstPage
  int _page = _firstPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _dayFor(int page) => _baseDay!.add(Duration(days: page - _firstPage));

  @override
  Widget build(BuildContext context) {
    final my = ref.watch(myScheduleProvider);
    return my.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Не удалось прочитать расписание:\n$e', textAlign: TextAlign.center)),
      data: (data) {
        if (data == null) return const SizedBox();
        final now = ref.watch(nowProvider).value ?? ref.read(clockProvider).now();
        final today = moscowToday(now);

        // Первый показ: если сегодня пар уже нет или их не было — открываем ближайший учебный день
        if (_baseDay == null) {
          final todayLessons = resolve(today, data.index, data.schedule, data.profile, forcedWeek: data.forcedWeek);
          final over = todayLessons.isEmpty || todayLessons.every((l) => !l.endAt.isAfter(now));
          _baseDay = today;
          if (over) {
            final next = nextStudyDay(today.add(const Duration(days: 1)), data.index, data.schedule, data.profile,
                forcedWeek: data.forcedWeek);
            if (next != null && todayLessons.isEmpty) {
              _page = _firstPage + next.difference(today).inDays;
              WidgetsBinding.instance.addPostFrameCallback((_) => _controller.jumpToPage(_page));
            } else if (next != null) {
              _page = _firstPage + next.difference(today).inDays;
              WidgetsBinding.instance.addPostFrameCallback((_) => _controller.jumpToPage(_page));
            }
          }
        }

        final shownDay = _dayFor(_page);
        return Column(
          children: [
            _Header(day: shownDay, week: data.weekFor(shownDay), isToday: shownDay == today, onToday: () {
              _controller.animateToPage(_firstPage + today.difference(_baseDay!).inDays,
                  duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
            }),
            const _UpdateBanner(),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, page) => _DayPage(day: _dayFor(page), today: today, now: now, data: data),
              ),
            ),
            const _SyncLabel(),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.day, required this.week, required this.isToday, required this.onToday});
  final DateTime day;
  final int week;
  final bool isToday;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$week неделя', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
              Text(dayTitle(day), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
          if (!isToday) TextButton(onPressed: onToday, child: const Text('Сегодня')),
        ],
      ),
    );
  }
}

class _DayPage extends ConsumerWidget {
  const _DayPage({required this.day, required this.today, required this.now, required this.data});
  final DateTime day;
  final DateTime today;
  final DateTime now;
  final MySchedule data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkDue = dueOn(ref.watch(homeworkProvider).value ?? const [], day);
    final lessons = resolve(day, data.index, data.schedule, data.profile, forcedWeek: data.forcedWeek);
    final theme = Theme.of(context);

    if (lessons.isEmpty) {
      final holiday = data.index.holidays.contains(day);
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(holiday ? 'Праздничный день' : 'Пар нет', style: theme.textTheme.titleLarge),
        ]),
      );
    }

    final isToday = day == today;
    // Текущая пара — идёт сейчас; если не идёт — ближайшая будущая
    ResolvedLesson? current, next;
    if (isToday) {
      for (final l in lessons) {
        if (!now.isBefore(l.startAt) && now.isBefore(l.endAt)) current = l;
      }
      next = lessons.where((l) => l.startAt.isAfter(now)).firstOrNull;
    }
    final focus = current ?? next;

    final children = <Widget>[];
    if (focus != null) children.add(_FocusCard(lesson: focus, now: now, isCurrent: current != null));
    if (isToday && focus == null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('На сегодня всё 🎉', style: theme.textTheme.titleMedium),
      ));
    }

    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      // Окно между парами и большая перемена
      if (i > 0) {
        final gap = l.startAt.difference(lessons[i - 1].endAt);
        if (lessons[i - 1].pair == 2 && l.pair == 3) {
          children.add(_GapLabel(gap > const Duration(minutes: 60) && lessons.any((x) => x.pair == 3)
              ? 'большая перемена'
              : 'большая перемена'));
        } else if (l.pair - lessons[i - 1].pair > 1) {
          children.add(_GapLabel('окно ${durationText(gap)}'));
        }
      }
      final finished = isToday && !now.isBefore(l.endAt);
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LessonTile(
          start: moscowTimeText(l.startAt),
          end: moscowTimeText(l.endAt),
          subject: l.subject,
          kind: l.kind,
          teacher: l.teacher,
          room: l.room,
          highlighted: l == current,
          dimmed: finished,
          note: l.note,
          hasHomework: homeworkDue.any((h) => h.subject == l.subject),
          onLongPress: () => showAddHomework(context, subject: l.subject),
        ),
      ));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: children);
  }
}

class _GapLabel extends StatelessWidget {
  const _GapLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      );
}

/// Большая карточка текущей или следующей пары.
class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.lesson, required this.now, required this.isCurrent});
  final ResolvedLesson lesson;
  final DateTime now;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = lesson.endAt.difference(lesson.startAt).inSeconds;
    final passed = now.difference(lesson.startAt).inSeconds.clamp(0, total);
    final status = isCurrent
        ? 'идёт · до конца ${durationText(lesson.endAt.difference(now))}'
        : 'начнётся через ${durationText(lesson.startAt.difference(now))}';

    return Semantics(
      container: true,
      label: '${isCurrent ? 'Сейчас' : 'Далее'}: ${lesson.subject}, ${lesson.room != null ? 'аудитория ${lesson.room}, ' : ''}$status',
      child: ExcludeSemantics(
        child: Card(
          color: scheme.primaryContainer,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isCurrent ? 'СЕЙЧАС' : 'ДАЛЕЕ', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(lesson.subject, style: theme.textTheme.titleLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
              if (lesson.room != null)
                Text(lesson.room!, style: theme.textTheme.displayMedium?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 8),
              Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                KindBadge(lesson.kind),
                if (lesson.teacher != null) Text(lesson.teacher!, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onPrimaryContainer)),
              ]),
              const SizedBox(height: 12),
              if (isCurrent) ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: total == 0 ? 0 : passed / total, minHeight: 6)),
              const SizedBox(height: 6),
              Text('${moscowTimeText(lesson.startAt)}–${moscowTimeText(lesson.endAt)} · $status', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Тихая метка внизу: «обновлено 2 дня назад». Ошибок сети пользователю не показываем.
class _SyncLabel extends ConsumerWidget {
  const _SyncLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetched = ref.watch(lastFetchedProvider).value;
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider).now();
    final text = fetched == null ? 'встроенная копия расписания' : 'обновлено ${agoText(fetched, now)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// «Расписание обновилось: 2 изменения» + список. Остаётся, пока не нажмёте «Понятно».
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(updateBannerProvider);
    if (items.isEmpty) return const SizedBox();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(diffHeadline(items.length),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final item in items.take(6)) Text(item, style: TextStyle(color: scheme.onTertiaryContainer)),
          if (items.length > 6) Text('…и ещё ${items.length - 6}', style: TextStyle(color: scheme.onTertiaryContainer)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => ref.read(updateBannerProvider.notifier).dismiss(), child: const Text('Понятно')),
          ),
        ]),
      ),
    );
  }
}
