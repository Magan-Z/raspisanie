// Добавление виджета на главный экран одним нажатием (Android 8+ и лаунчеры, которые это умеют).
// Всё за интерфейсом, чтобы в тестах подставить «поддельный» вариант.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

/// Виджет, который можно добавить: имя класса в Android-части, название и описание для человека.
class WidgetChoice {
  const WidgetChoice(this.className, this.title, this.description);
  final String className;
  final String title;
  final String description;
}

/// Те же виджеты, что в списке «Виджеты» на телефоне (названия — из widget_strings.xml).
const widgetChoices = [
  WidgetChoice('NowNextWidget', 'Сейчас / Далее', 'Текущая или следующая пара и аудитория'),
  WidgetChoice('TodayWidget', 'Сегодня', 'Все пары дня'),
  WidgetChoice('TomorrowWidget', 'Завтра', 'Все пары завтрашнего дня'),
  WidgetChoice('StripWidget', 'Ближайшая пара (строка)', 'Следующая пара одной узкой строкой с отсчётом'),
  WidgetChoice('RoomWidget', 'Аудитория', 'Номер аудитории крупно'),
  WidgetChoice('WeekWidget', 'Неделя', 'Неделя целиком: сколько пар в каждый день'),
  WidgetChoice('HomeworkWidget', 'Домашка', 'Ближайшие невыполненные задания'),
];

abstract class WidgetPinner {
  /// Умеет ли телефон добавить виджет по кнопке (иначе — только вручную через долгое нажатие на рабочий стол).
  Future<bool> isSupported();

  /// Просит систему добавить виджет; она сама покажет окно «Добавить виджет?».
  Future<void> pin(String className);
}

class HomeWidgetPinner implements WidgetPinner {
  static const _package = 'ru.raspisanie.raspisanie.widget';

  @override
  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> pin(String className) => HomeWidget.requestPinWidget(qualifiedAndroidName: '$_package.$className');
}
