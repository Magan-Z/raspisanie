// «Расписание обновилось»: текст изменений из diff парсера и баннер на экране «Сегодня».

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/domain/diff_summary.dart';
import 'package:raspisanie/domain/models.dart';

Map<String, dynamic> lesson(int weekday, int pair, int week, List<int> subgroups, String subject, String? room, {List<String> tags = const []}) => {
      'weekday': weekday, 'pair': pair, 'week': week, 'subgroups': subgroups, 'kind': 'practice',
      'subject': subject, 'teacher': 'Иванов И.И.', 'room': room, 'tags': tags, 'raw': subject,
    };

void main() {
  const profile = UserProfile(formCode: 'ofo', groupId: 'ofo-1-bi-25', subgroup: 1, pe: PeChoice.male);

  final diff = jsonEncode({
    'from': 'a', 'to': 'b',
    'groups': {
      'ofo-1-bi-25': {
        'added': [lesson(2, 3, 0, [1], 'Философия', '3-01'), lesson(2, 4, 0, [2], 'Чужая подгруппа', '1-01')],
        'removed': [lesson(4, 1, 1, [1, 2], 'Математика', '2-05')],
        'changed': [
          {'lesson': lesson(3, 4, 2, [1], 'ЧТК и этика', '2-16'), 'changes': {'room': ['2-15', '2-16']}},
          {'lesson': lesson(5, 2, 0, [1], 'Физкультура', null, tags: ['female']), 'changes': {'teacher': ['А', 'Б']}}, // не для юношей
        ],
      },
      'ofo-2-bi-25': {'added': [lesson(1, 1, 0, [1], 'Другая группа', '1-01')], 'removed': [], 'changed': []},
    },
  });

  test('только изменения вашей группы и подгруппы, понятным языком', () {
    expect(summarizeDiff(diff, profile), [
      'Добавлено: Вт, 3 пара — Философия, 3-01',
      'Убрано: Чт, 1 пара, 1 нед. — Математика, 2-05',
      'Изменено: Ср, 4 пара, 2 нед. — ЧТК и этика (аудитория: 2-15 → 2-16)',
    ]);
  });

  test('для девушек видна физкультура, для юношей — нет', () {
    final items = summarizeDiff(diff, profile.copyWith(pe: PeChoice.female));
    expect(items.any((i) => i.contains('Физкультура')), isTrue);
  });

  test('нет изменений / чужая группа / мусор → пустой список', () {
    expect(summarizeDiff(diff, profile.copyWith(groupId: 'ofo-3-bi-25')), isEmpty);
    expect(summarizeDiff('не json', profile), isEmpty);
    expect(summarizeDiff('{"groups": {}}', profile), isEmpty);
  });

  test('заголовок со склонением', () {
    expect(diffHeadline(1), 'Расписание обновилось: 1 изменение');
    expect(diffHeadline(2), 'Расписание обновилось: 2 изменения');
    expect(diffHeadline(5), 'Расписание обновилось: 5 изменений');
    expect(diffHeadline(21), 'Расписание обновилось: 21 изменение');
  });
}
