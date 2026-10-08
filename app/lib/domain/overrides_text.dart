// Описание личных правок простыми словами — для списка «Мои правки на этот день».

import 'models.dart';

String describeOverride(Override o) {
  final pair = '${o.pair} пара';
  switch (o.type) {
    case OverrideType.cancel:
      return 'Отменена: $pair';
    case OverrideType.replace:
      final changes = [
        if (o.subject != null) 'предмет: ${o.subject}',
        if (o.teacher != null) 'преподаватель: ${o.teacher}',
        if (o.room != null) 'аудитория: ${o.room}',
        if (o.note != null) 'заметка: ${o.note}',
      ];
      return 'Изменена: $pair${changes.isEmpty ? '' : ' — ${changes.join(', ')}'}';
    case OverrideType.add:
      final parts = [o.subject ?? 'Занятие', if (o.room != null) o.room!, if (o.teacher != null) o.teacher!];
      return 'Своя пара: $pair — ${parts.join(', ')}';
  }
}

/// Пустая строка из поля ввода → null (то есть «не менять»).
String? blankToNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}
