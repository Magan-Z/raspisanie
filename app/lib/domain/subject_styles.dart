// Свои названия и цвета предметов (по желанию пользователя, в «Настройки → Предметы»).
// Название предмета в расписании («Технологическое предпринимательство») можно сократить до «Предпр.»,
// а цвет карточки выбрать из палитры. Само расписание не меняется: сопоставление идёт по настоящему названию.

import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../theme/subject_palette.dart';

class SubjectStyle {
  const SubjectStyle({this.shortName, this.colorIndex});

  /// Своё короткое название (null — показывать настоящее).
  final String? shortName;

  /// Номер цвета в палитре предметов (null — цвет выбирается автоматически по названию).
  final int? colorIndex;

  bool get isEmpty => (shortName == null || shortName!.trim().isEmpty) && colorIndex == null;
}

/// Все настройки предметов + выключатель. Везде, где показывается предмет, берут название и цвет отсюда.
class SubjectStyles {
  const SubjectStyles({this.enabled = true, this.styles = const {}});

  /// Выключатель в настройках: выключено — всё как в расписании, но настройки не теряются.
  final bool enabled;
  final Map<String, SubjectStyle> styles;

  static const none = SubjectStyles(enabled: false);

  SubjectStyle? _of(String subject) => enabled ? styles[subject] : null;

  /// Название для показа: своё, если задано, иначе настоящее.
  String name(String subject) {
    final own = _of(subject)?.shortName?.trim();
    return own == null || own.isEmpty ? subject : own;
  }

  /// Название для узких мест (виджеты, уведомления): своё как есть или сокращённое настоящее.
  String compactName(String subject) {
    final own = _of(subject)?.shortName?.trim();
    return own == null || own.isEmpty ? shortSubject(subject) : own;
  }

  /// Цвета предмета: выбранный вручную или автоматический (по названию).
  SubjectTone tone(String subject, Brightness brightness) {
    final index = _of(subject)?.colorIndex;
    if (index == null) return subjectTone(subject, brightness);
    return subjectToneByIndex(index, brightness);
  }

  bool hasOwn(String subject) => styles[subject] != null && !styles[subject]!.isEmpty;
}
