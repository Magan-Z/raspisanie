// Снимок расписания на 7 дней для виджетов на главном экране (АРХИТЕКТУРА.md, §7.6).
// Виджет не может ходить в сеть и в базу, поэтому приложение заранее складывает такой JSON
// в общее хранилище, а нативный виджет сам смотрит на часы и выбирает текущую или следующую пару.

import 'dart:convert';

import '../core/bells.dart';
import '../core/formatting.dart';
import 'homework.dart';
import 'models.dart';
import 'schedule_resolver.dart';

const snapshotDays = 7;

/// Собирает снимок. [now] — настоящий момент (UTC), [today] — сегодняшний день по Москве.
Map<String, dynamic> buildWidgetSnapshot({
  required DateTime now,
  required ScheduleIndex index,
  required GroupSchedule schedule,
  required UserProfile profile,
  required List<HomeworkItem> homework,
  List<Override> overrides = const [],
  int? forcedWeek,
}) {
  final today = moscowToday(now);
  final days = <Map<String, dynamic>>[];

  for (var i = 0; i < snapshotDays; i++) {
    final day = today.add(Duration(days: i));
    final lessons = resolve(day, index, schedule, profile, overrides: overrides, forcedWeek: forcedWeek);
    final due = dueOn(homework, day);
    days.add({
      'date': _dayText(day),
      'lessons': [
        for (final l in lessons)
          {
            'start': _momentText(l.startAt),
            'end': _momentText(l.endAt),
            'pair': l.pair,
            'short': shortSubject(l.subject),
            'subject': l.subject,
            'room': l.room,
            'teacher': l.teacher,
            'kind': l.kind.name,
            'hasHomework': due.any((h) => h.subject == l.subject),
          },
      ],
    });
  }

  final week = forcedWeek ?? ((today.difference(index.weekAnchor).inDays / 7).floor() % 2 + 1);
  return {
    'generatedAt': _momentText(now),
    'weekLabel': '$week неделя',
    'days': days,
  };
}

String encodeWidgetSnapshot(Map<String, dynamic> snapshot) => jsonEncode(snapshot);

String _dayText(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// «2026-10-08T09:00+03:00» — время по Москве со смещением, как ждёт нативный виджет.
String _momentText(DateTime moment) {
  final m = moment.toUtc().add(moscowOffset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${_dayText(DateTime.utc(m.year, m.month, m.day))}T${two(m.hour)}:${two(m.minute)}+03:00';
}
