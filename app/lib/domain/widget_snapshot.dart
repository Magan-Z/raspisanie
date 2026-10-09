// Снимок расписания на 7 дней для виджетов на главном экране (АРХИТЕКТУРА.md, §7.6).
// Виджет не может ходить в сеть и в базу, поэтому приложение заранее складывает такой JSON
// в общее хранилище, а нативный виджет сам смотрит на часы и выбирает текущую или следующую пару.

import 'dart:convert';

import 'package:flutter/material.dart' show Brightness, Color, ColorScheme;

import '../core/bells.dart';
import '../core/week.dart' show dayOnly;
import '../core/formatting.dart';
import '../theme/brand_colors.dart';
import 'homework.dart';
import 'models.dart';
import 'schedule_resolver.dart';

const snapshotDays = 7;
const widgetHomeworkLimit = 8;

/// Цвета виджета из цветовой схемы приложения: фон, текст, акцент и т. д. («#RRGGBB»).
Map<String, String> _widgetColors(ColorScheme s, {bool dark = false}) {
  String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  return {
    'bg': hex(dark ? s.surfaceContainer : s.surface),
    'text': hex(s.onSurface),
    'textSecondary': hex(s.onSurfaceVariant),
    'accent': hex(s.primary),
    'highlight': hex(s.primaryContainer),
    'badgeBg': hex(s.tertiaryContainer),
    'badgeText': hex(s.onTertiaryContainer),
  };
}

/// Собирает снимок. [now] — настоящий момент (UTC), [today] — сегодняшний день по Москве.
Map<String, dynamic> buildWidgetSnapshot({
  required DateTime now,
  required ScheduleIndex index,
  required GroupSchedule schedule,
  required UserProfile profile,
  required List<HomeworkItem> homework,
  List<Override> overrides = const [],
  int? forcedWeek,
  AppPalette? palette, // цветовая тема приложения: виджеты красятся в те же цвета (null — стандартные)
  bool amoled = false,
  String Function(String subject)? compactNameOf, // короткое название предмета для виджета (свои названия)
}) {
  final compact = compactNameOf ?? shortSubject;
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
            'short': compact(l.subject),
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
  // Невыполненное ДЗ по срокам: для виджета «Домашка»
  final open = homework.where((h) => !h.done).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  return {
    'generatedAt': _momentText(now),
    'weekLabel': '$week неделя',
    'days': days,
    'homeworkCount': open.length,
    'homework': [
      for (final h in open.take(widgetHomeworkLimit))
        {
          'subject': h.subject,
          'short': compact(h.subject),
          'text': h.text,
          'due': _dayText(dayOnly(h.dueDate)),
          'files': h.attachments.length,
        },
    ],
    if (palette != null)
      'colors': {
        'light': _widgetColors(BrandColors.scheme(palette, Brightness.light)),
        'dark': _widgetColors(BrandColors.scheme(palette, Brightness.dark, amoled: amoled), dark: true),
      },
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
