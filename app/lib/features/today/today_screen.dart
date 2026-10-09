// Главный экран «Сегодня»: дата и неделя, полоса дней, крупная карточка «Сейчас / Далее» и лента пар дня.
// Дни листаются свайпом, полосой сверху или кнопками ‹ ›. В воскресенье и после последней пары
// открывается ближайший учебный день. Потянуть вниз — проверить обновления расписания.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/bells.dart';
import '../../core/formatting.dart';
import '../../domain/diff_summary.dart';
import '../../domain/homework.dart';
import '../../domain/models.dart';
import '../../domain/schedule_resolver.dart';
import '../../theme/subject_palette.dart';
import '../../theme/tokens.dart';
import '../common/day_strip.dart';
import '../common/empty_state.dart';
import '../common/illustrations.dart';
import '../common/lesson_widgets.dart';
import '../common/room_plate.dart';
import '../common/word_fit_text.dart';
import '../overrides/day_edits.dart';

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

  void _goTo(DateTime day) {
    final target = _firstPage + day.difference(_baseDay!).inDays;
    _controller.animateToPage(target, duration: Motion.of(context, Motion.base), curve: Motion.enter);
  }

  @override
  Widget build(BuildContext context) {
    final my = ref.watch(myScheduleProvider);
    ref.watch(requestedDayProvider); // перестроиться, когда пришёл запрос на день
    return my.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Не удалось прочитать расписание',
        subtitle: '$e',
      ),
      data: (data) {
        if (data == null) return const SizedBox();
        final now = ref.watch(nowProvider).value ?? ref.read(clockProvider).now();
        final today = moscowToday(now);

        // Первый показ: если сегодня пар нет или они уже кончились — открываем ближайший учебный день
        if (_baseDay == null) {
          final todayLessons = resolve(today, data.index, data.schedule, data.profile, overrides: data.overrides, forcedWeek: data.forcedWeek);
          final over = todayLessons.isEmpty || todayLessons.every((l) => !l.endAt.isAfter(now));
          _baseDay = today;
          if (over) {
            final next = nextStudyDay(today.add(const Duration(days: 1)), data.index, data.schedule, data.profile,
                overrides: data.overrides, forcedWeek: data.forcedWeek);
            if (next != null) {
              _page = _firstPage + next.difference(today).inDays;
              WidgetsBinding.instance.addPostFrameCallback((_) => _controller.jumpToPage(_page));
            }
          }
        }

        // Нажали на уведомление — открываем день из него (и если экран только что построился, и если уже был открыт)
        final requested = ref.read(requestedDayProvider);
        if (requested != null) {
          _page = _firstPage + requested.difference(_baseDay!).inDays;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.hasClients) _controller.jumpToPage(_page);
            ref.read(requestedDayProvider.notifier).clear();
          });
        }

        final shownDay = _dayFor(_page);
        final monday = shownDay.subtract(Duration(days: shownDay.weekday - 1));
        final counts = [
          for (var i = 0; i < 7; i++)
            resolve(monday.add(Duration(days: i)), data.index, data.schedule, data.profile, overrides: data.overrides, forcedWeek: data.forcedWeek).length,
        ];

        return Column(
          children: [
            _Header(
              day: shownDay,
              week: data.weekFor(shownDay),
              isToday: shownDay == today,
              onToday: () => _goTo(today),
              onPrevious: () => _controller.previousPage(duration: Motion.of(context, Motion.base), curve: Motion.enter),
              onNext: () => _controller.nextPage(duration: Motion.of(context, Motion.base), curve: Motion.enter),
            ),
            DayStrip(
              selected: shownDay,
              today: today,
              lessonCounts: counts,
              onSelect: _goTo,
              onShiftWeek: (shift) => _goTo(shownDay.add(Duration(days: 7 * shift))),
            ),
            const SizedBox(height: Gap.sm),
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
  const _Header({
    required this.day,
    required this.week,
    required this.isToday,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime day;
  final int week;
  final bool isToday;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.sm, Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.xs),
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
                  child: Text('$week неделя', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer)),
                ),
                if (!isToday)
                  TextButton.icon(
                    onPressed: onToday,
                    icon: const Icon(Icons.today_rounded, size: 18),
                    label: const Text('Сегодня'),
                  ),
              ]),
              const SizedBox(height: Gap.xs),
              // Название дня сжимается, а не ломается посередине слова (при крупном системном шрифте)
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.base),
                child: FittedBox(
                  key: ValueKey(day),
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(dayTitle(day), maxLines: 1, style: theme.textTheme.headlineSmall),
                ),
              ),
            ]),
          ),
          IconButton(tooltip: 'Предыдущий день', onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded, size: 28)),
          IconButton(tooltip: 'Следующий день', onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded, size: 28)),
        ],
      ),
    );
  }
}

/// Какой «момент» у пары по отношению к текущему времени — от этого зависит оформление ленты.
enum _Phase { past, current, future }

class _DayPage extends ConsumerWidget {
  const _DayPage({required this.day, required this.today, required this.now, required this.data});
  final DateTime day;
  final DateTime today;
  final DateTime now;
  final MySchedule data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkDue = dueOn(ref.watch(homeworkProvider).value ?? const [], day);
    final lessons = resolve(day, data.index, data.schedule, data.profile, overrides: data.overrides, forcedWeek: data.forcedWeek);
    final theme = Theme.of(context);
    final container = ProviderScope.containerOf(context);
    final editsCount = data.overrides.where((o) => o.appliesOn(day)).length;

    // Потянуть вниз — проверить обновления (ошибки сети не показываем, см. АРХИТЕКТУРА.md §7.5)
    Future<void> refresh() async {
      await syncSchedule(container);
    }

    if (lessons.isEmpty) {
      final holiday = data.index.holidays.contains(day);
      final sunday = day.weekday == DateTime.sunday;
      return RefreshIndicator(
        onRefresh: refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  EmptyState(
                    illustration: holiday ? IllustrationKind.holiday : IllustrationKind.freeDay,
                    title: holiday ? 'Праздничный день' : 'Пар нет',
                    subtitle: sunday ? 'Воскресенье — отдыхаем' : 'Можно заняться своими делами',
                    action: _EditsButton(day: day, count: editsCount),
                  ),
                ]),
              ),
            ],
          ),
        ),
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
    if (focus != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: Gap.lg),
        child: _NowCard(lesson: focus, now: now, isCurrent: current != null),
      ));
    }
    if (isToday && focus == null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: Gap.lg),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: Gap.sm),
          Text('На сегодня всё', style: theme.textTheme.titleMedium),
        ]),
      ));
    }

    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      if (i > 0) {
        final gap = l.startAt.difference(lessons[i - 1].endAt);
        if (lessons[i - 1].pair == 2 && l.pair == 3) {
          children.add(const _GapRow(icon: Icons.free_breakfast_rounded, text: 'большая перемена'));
        } else if (l.pair - lessons[i - 1].pair > 1) {
          children.add(_GapRow(icon: Icons.hourglass_empty_rounded, text: 'окно ${durationText(gap)}'));
        }
      }
      final phase = !isToday
          ? _Phase.future
          : (!now.isBefore(l.endAt) ? _Phase.past : (l == current ? _Phase.current : _Phase.future));
      children.add(_TimelineRow(
        start: moscowTimeText(l.startAt),
        end: moscowTimeText(l.endAt),
        phase: phase,
        tone: subjectTone(l.subject, theme.brightness),
        child: LessonTile(
          subject: l.subject,
          kind: l.kind,
          teacher: l.teacher,
          room: l.room,
          highlighted: phase == _Phase.current,
          dimmed: phase == _Phase.past,
          note: l.note ?? (l.isPersonal ? 'изменено вами' : null),
          hasHomework: homeworkDue.any((h) => h.subject == l.subject),
          onLongPress: () => showLessonActions(context, l),
          onTap: () => showLessonActions(context, l),
        ),
      ));
    }

    children.add(Padding(
      padding: const EdgeInsets.only(top: Gap.sm),
      child: Center(child: _EditsButton(day: day, count: editsCount)),
    ));

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.xl),
        children: children,
      ),
    );
  }
}

/// Строка ленты: время слева, линия времени с «точкой», карточка пары справа.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.start, required this.end, required this.phase, required this.tone, required this.child});
  final String start;
  final String end;
  final _Phase phase;
  final SubjectTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // При крупном шрифте колонка времени шире, иначе «09:00» не поместится
    final timeWidth = MediaQuery.textScalerOf(context).scale(48).clamp(48.0, 92.0);

    final dot = switch (phase) {
      _Phase.current => Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: tone.accent,
            shape: BoxShape.circle,
            border: Border.all(color: tone.accent.withValues(alpha: 0.3), width: 4),
          ),
        ),
      _Phase.past => Container(width: 10, height: 10, decoration: BoxDecoration(color: scheme.outline, shape: BoxShape.circle)),
      _Phase.future => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle, border: Border.all(color: tone.accent, width: 2.5)),
        ),
    };

    // Линия времени — часть правой ячейки (а не отдельная колонка с IntrinsicHeight): внутри карточек есть LayoutBuilder
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: timeWidth,
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(start, style: theme.textTheme.titleSmall?.copyWith(color: phase == _Phase.past ? scheme.onSurfaceVariant : scheme.onSurface)),
            Text(end, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
      Expanded(
        child: Stack(children: [
          Positioned(left: 11, top: 0, bottom: 0, width: 2, child: ColoredBox(color: scheme.outlineVariant)),
          Positioned(top: Gap.lg, left: 0, width: 24, child: Center(child: dot)),
          Padding(padding: const EdgeInsets.only(left: 24, bottom: Gap.md), child: child),
        ]),
      ),
    ]);
  }
}

/// Промежуток между парами («окно», «большая перемена») на той же линии времени.
class _GapRow extends StatelessWidget {
  const _GapRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeWidth = MediaQuery.textScalerOf(context).scale(48).clamp(48.0, 92.0);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: timeWidth),
      Expanded(
        child: Stack(children: [
          Positioned(left: 11, top: 0, bottom: 0, width: 2, child: ColoredBox(color: scheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: Gap.md, top: Gap.xs),
            child: Row(children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: Gap.sm),
              Flexible(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

/// Крупная карточка текущей или следующей пары: аудитория — самый большой элемент экрана.
class _NowCard extends StatelessWidget {
  const _NowCard({required this.lesson, required this.now, required this.isCurrent});
  final ResolvedLesson lesson;
  final DateTime now;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = subjectTone(lesson.subject, theme.brightness);
    final total = lesson.endAt.difference(lesson.startAt).inSeconds;
    final passed = now.difference(lesson.startAt).inSeconds.clamp(0, total);
    final progress = isCurrent && total > 0 ? passed / total : 0.0;
    final status = isCurrent
        ? 'идёт · до конца ${durationText(lesson.endAt.difference(now))}'
        : 'начнётся через ${durationText(lesson.startAt.difference(now))}';

    return Semantics(
      container: true,
      label: '${isCurrent ? 'Сейчас' : 'Далее'}: ${lesson.subject}, ${lesson.room != null ? 'аудитория ${lesson.room}, ' : ''}$status',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Gap.xl),
          decoration: BoxDecoration(
            color: tone.container,
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: tone.accent.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: Gap.sm, runSpacing: Gap.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.xs),
                decoration: BoxDecoration(
                  color: isCurrent ? scheme.tertiaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: isCurrent ? null : Border.all(color: tone.onContainer.withValues(alpha: 0.6)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isCurrent) ...[
                    Icon(Icons.notifications_active_rounded, size: 14, color: scheme.onTertiaryContainer),
                    const SizedBox(width: Gap.xs),
                  ],
                  Text(isCurrent ? 'СЕЙЧАС' : 'ДАЛЕЕ',
                      style: theme.textTheme.labelSmall?.copyWith(color: isCurrent ? scheme.onTertiaryContainer : tone.onContainer, letterSpacing: 1.2)),
                ]),
              ),
              KindBadge(lesson.kind, tone: tone),
            ]),
            const SizedBox(height: Gap.md),
            WordFitText(lesson.subject, style: theme.textTheme.titleLarge?.copyWith(color: scheme.onSurface)),
            const SizedBox(height: Gap.lg),
            // При очень крупном системном шрифте табличка и подписи идут друг под другом, а не в ряд
            Builder(builder: (context) {
              final big = MediaQuery.textScalerOf(context).scale(1) > 1.35;
              final plate = lesson.room == null ? null : RoomPlate(room: lesson.room!, tone: tone, size: big ? 32 : 46, filled: true);
              final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (lesson.teacher != null) Text(lesson.teacher!, style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface)),
                const SizedBox(height: Gap.xs),
                Text('${moscowTimeText(lesson.startAt)}–${moscowTimeText(lesson.endAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: tone.onContainer)),
              ]);
              if (big) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (plate != null) plate,
                  if (plate != null) const SizedBox(height: Gap.md),
                  info,
                ]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (plate != null) plate,
                if (plate != null) const SizedBox(width: Gap.lg),
                Expanded(child: info),
              ]);
            }),
            const SizedBox(height: Gap.lg),
            if (isCurrent)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: Motion.of(context, Motion.slow),
                curve: Motion.enter,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: tone.accent,
                    backgroundColor: tone.accent.withValues(alpha: 0.2),
                  ),
                ),
              ),
            if (isCurrent) const SizedBox(height: Gap.sm),
            Text(status, style: theme.textTheme.labelLarge?.copyWith(color: tone.onContainer)),
          ]),
        ),
      ),
    );
  }
}

/// «Мои правки (N)» — список правок дня и добавление своей пары.
class _EditsButton extends StatelessWidget {
  const _EditsButton({required this.day, required this.count});
  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: () => showDayEdits(context, day),
        icon: const Icon(Icons.edit_calendar_rounded, size: 20),
        label: Text(count == 0 ? 'Мои правки' : 'Мои правки ($count)'),
      );
}

/// «Расписание обновилось: 2 изменения» + список. Остаётся, пока не нажмёте «Понятно».
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(updateBannerProvider);
    if (items.isEmpty) return const SizedBox();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.xs),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(Radii.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.update_rounded, color: scheme.onTertiaryContainer, size: 20),
          const SizedBox(width: Gap.sm),
          Expanded(child: Text(diffHeadline(items.length), style: theme.textTheme.titleSmall?.copyWith(color: scheme.onTertiaryContainer))),
        ]),
        const SizedBox(height: Gap.xs),
        for (final item in items.take(6)) Text(item, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onTertiaryContainer)),
        if (items.length > 6) Text('…и ещё ${items.length - 6}', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onTertiaryContainer)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => ref.read(updateBannerProvider.notifier).dismiss(),
            style: TextButton.styleFrom(foregroundColor: scheme.onTertiaryContainer),
            child: const Text('Понятно'),
          ),
        ),
      ]),
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
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
