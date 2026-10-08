/// Адрес сайта с расписанием (GitHub Pages), например `https://login.github.io/raspisanie/`.
///
/// Задаётся при сборке:
///   flutter build apk --dart-define=SCHEDULE_BASE_URL=https://login.github.io/raspisanie/
/// Если адрес пустой, приложение работает только со встроенной копией расписания
/// (она лежит в assets/schedule и обновляется при каждой сборке).
const scheduleBaseUrl = String.fromEnvironment('SCHEDULE_BASE_URL');

/// Через сколько часов фоновая проверка обновлений (АРХИТЕКТУРА.md, §7.5).
const backgroundSyncHours = 6;
