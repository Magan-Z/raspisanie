// Экран «Поиск»: преподаватель (где сейчас и расписание), аудитория (кто занимается),
// свободные аудитории на выбранную пару.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_state.dart';
import '../../core/bells.dart';
import '../../core/formatting.dart';
import '../../domain/models.dart';
import '../../domain/search.dart';
import '../../theme/tokens.dart';
import '../common/lesson_widgets.dart';

enum _Mode { teacher, room, free }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  _Mode _mode = _Mode.teacher;
  String? _teacher;
  String? _room;
  int _dayOffset = 0; // 0 — сегодня, 1 — завтра …
  int _pair = 1;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allGroupsProvider);
    final index = ref.watch(indexProvider).value;
    final today = ref.watch(todayProvider);

    return all.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Не удалось прочитать расписания:\n$e', textAlign: TextAlign.center)),
      data: (schedules) {
        if (index == null) return const SizedBox();
        final day = today.add(Duration(days: _dayOffset));
        final dayLessons = campusLessons(day, index, schedules, forcedWeek: ref.watch(settingsProvider).forcedWeek);

        return ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xl),
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: Gap.xs), child: Text('Поиск', style: Theme.of(context).textTheme.headlineMedium)),
            const SizedBox(height: 12),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.teacher, label: Text('Преподаватель')),
                ButtonSegment(value: _Mode.room, label: Text('Аудитория')),
                ButtonSegment(value: _Mode.free, label: Text('Свободные')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 12),
            _DayChips(today: today, selected: _dayOffset, onSelected: (i) => setState(() => _dayOffset = i)),
            const SizedBox(height: 12),
            ...switch (_mode) {
              _Mode.teacher => _teacherView(schedules, index, dayLessons, day),
              _Mode.room => _roomView(schedules, index, dayLessons, day),
              _Mode.free => _freeView(schedules, index, dayLessons),
            },
          ],
        );
      },
    );
  }

  // ---------- преподаватель ----------

  List<Widget> _teacherView(List<GroupSchedule> schedules, ScheduleIndex index, List<CampusLesson> dayLessons, DateTime day) {
    final names = teacherNames(schedules);
    final teacher = _teacher;
    final lessons = teacher == null ? <CampusLesson>[] : lessonsOfTeacher(teacher, dayLessons);
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider).now();

    return [
      _Autocomplete(key: const ValueKey('teacher'), label: 'Фамилия преподавателя', options: names, onSelected: (v) => setState(() => _teacher = v)),
      const SizedBox(height: 12),
      if (teacher != null) ...[
        if (_dayOffset == 0) _teacherNow(lessons, index, now),
        _LessonList(lessons: lessons, index: index, emptyText: 'В этот день занятий нет'),
      ],
    ];
  }

  Widget _teacherNow(List<CampusLesson> lessons, ScheduleIndex index, DateTime now) {
    var status = 'Сейчас занятий нет';
    for (final l in lessons) {
      final (start, end) = pairTimes(moscowToday(now), l.pair, index.bells);
      if (!now.isBefore(start) && now.isBefore(end)) {
        status = 'Сейчас ведёт: ${l.subject}${l.room != null ? ' · ${l.room}' : ''}';
        break;
      }
      if (start.isAfter(now)) {
        status = 'Следующая пара в ${moscowTimeText(start)}${l.room != null ? ' · ${l.room}' : ''}';
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(status, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  // ---------- аудитория ----------

  List<Widget> _roomView(List<GroupSchedule> schedules, ScheduleIndex index, List<CampusLesson> dayLessons, DateTime day) {
    final room = _room;
    return [
      _Autocomplete(key: const ValueKey('room'), label: 'Аудитория, например 2-05', options: allRooms(schedules), onSelected: (v) => setState(() => _room = v)),
      const SizedBox(height: 12),
      if (room != null) _LessonList(lessons: lessonsInRoom(room, dayLessons), index: index, emptyText: 'В этот день аудитория свободна'),
    ];
  }

  // ---------- свободные аудитории ----------

  List<Widget> _freeView(List<GroupSchedule> schedules, ScheduleIndex index, List<CampusLesson> dayLessons) {
    final free = freeRooms(_pair, dayLessons, allRooms(schedules));
    final theme = Theme.of(context);
    final bell = index.bells[_pair - 1];
    // По корпусам: 2, 3, 4
    final byBuilding = <String, List<String>>{};
    for (final r in free) {
      byBuilding.putIfAbsent(r.substring(0, 1), () => []).add(r);
    }

    return [
      Wrap(spacing: 8, children: [
        for (var p = 1; p <= index.bells.length; p++)
          ChoiceChip(label: Text('$p пара'), selected: _pair == p, onSelected: (_) => setState(() => _pair = p)),
      ]),
      const SizedBox(height: 8),
      Text('${bell.startText}–${bell.endText} · свободно ${free.length} ${plural(free.length, 'аудитория', 'аудитории', 'аудиторий')}',
          style: theme.textTheme.bodyMedium),
      for (final entry in byBuilding.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text('${entry.key} корпус', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final r in entry.value) Chip(label: Text(r))]),
      ],
      const SizedBox(height: 12),
      Text('Свободной считается аудитория, в которой по расписанию нет занятий. Её могли занять без расписания — уточняйте.',
          style: theme.textTheme.bodySmall),
    ];
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({required this.today, required this.selected, required this.onSelected});
  final DateTime today;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(i == 0 ? 'Сегодня' : i == 1 ? 'Завтра' : '${weekdayShort[today.add(Duration(days: i)).weekday]} ${today.add(Duration(days: i)).day}'),
              selected: selected == i,
              onSelected: (_) => onSelected(i),
            ),
          ),
      ]),
    );
  }
}

class _Autocomplete extends StatelessWidget {
  const _Autocomplete({super.key, required this.label, required this.options, required this.onSelected});
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return options.where((o) => o.toLowerCase().contains(q)).take(8);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focus, submit) => TextField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.search)),
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.lessons, required this.index, required this.emptyText});
  final List<CampusLesson> lessons;
  final ScheduleIndex index;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.lg),
        child: Row(children: [
          Icon(Icons.event_available_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: Gap.sm),
          Flexible(child: Text(emptyText, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      );
    }
    return Column(children: [
      for (final l in lessons)
        Padding(
          padding: const EdgeInsets.only(bottom: Gap.sm),
          child: LessonTile(
            timeLabel: '${index.bells[l.pair - 1].startText}–${index.bells[l.pair - 1].endText} · ${l.pair} пара',
            subject: l.subject,
            kind: l.kind,
            teacher: l.teacher,
            room: l.room,
            footer: l.groups.join(', '),
          ),
        ),
    ]);
  }
}
