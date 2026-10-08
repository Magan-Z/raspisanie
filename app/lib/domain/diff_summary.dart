// Что изменилось в расписании — простыми словами (из diff/latest.json, формат: АРХИТЕКТУРА.md, §4).

import 'dart:convert';

import '../core/formatting.dart';
import 'models.dart';

const _fieldNames = {'subject': 'предмет', 'teacher': 'преподаватель', 'room': 'аудитория', 'kind': 'тип занятия'};

/// Список изменений для вашей группы и подгруппы. Пустой — изменений нет (или они вас не касаются).
List<String> summarizeDiff(String diffJson, UserProfile profile) {
  final Object? data;
  try {
    data = jsonDecode(diffJson);
  } on FormatException {
    return [];
  }
  if (data is! Map) return [];
  final group = (data['groups'] as Map?)?[profile.groupId];
  if (group is! Map) return [];

  bool mine(Map lesson) {
    if (!(lesson['subgroups'] as List).contains(profile.subgroup)) return false;
    final tags = (lesson['tags'] as List).cast<String>();
    if (profile.pe == PeChoice.male && tags.contains('female')) return false;
    if (profile.pe == PeChoice.female && tags.contains('male')) return false;
    return true;
  }

  String when(Map l) {
    final week = l['week'] as int;
    final weekText = week == 0 ? '' : ', $week нед.';
    return '${weekdayShort[l['weekday'] as int]}, ${l['pair']} пара$weekText';
  }

  String what(Map l) => '${l['subject']}${l['room'] == null ? '' : ', ${l['room']}'}';

  final items = <String>[];
  for (final l in (group['added'] as List).cast<Map>().where(mine)) {
    items.add('Добавлено: ${when(l)} — ${what(l)}');
  }
  for (final l in (group['removed'] as List).cast<Map>().where(mine)) {
    items.add('Убрано: ${when(l)} — ${what(l)}');
  }
  for (final c in (group['changed'] as List).cast<Map>()) {
    final lesson = c['lesson'] as Map;
    if (!mine(lesson)) continue;
    final changes = (c['changes'] as Map).entries
        .map((e) => '${_fieldNames[e.key] ?? e.key}: ${e.value[0] ?? '—'} → ${e.value[1] ?? '—'}')
        .join('; ');
    items.add('Изменено: ${when(lesson)} — ${lesson['subject']} ($changes)');
  }
  return items;
}

/// «Расписание обновилось: 2 изменения».
String diffHeadline(int count) =>
    'Расписание обновилось: $count ${plural(count, 'изменение', 'изменения', 'изменений')}';
