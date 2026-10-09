/// Адрес сайта с расписанием (GitHub Pages), например `https://login.github.io/raspisanie/`.
///
/// По умолчанию — настоящий адрес сайта, поэтому любая сборка (в том числе локальная) обновляет расписание из интернета.
/// Другой адрес можно задать при сборке:
///   flutter build apk --dart-define=SCHEDULE_BASE_URL=https://login.github.io/raspisanie/
/// Пустой адрес (--dart-define=SCHEDULE_BASE_URL=) — приложение работает только со встроенной копией расписания
/// (она лежит в assets/schedule и обновляется при каждой сборке).
const scheduleBaseUrl = String.fromEnvironment('SCHEDULE_BASE_URL', defaultValue: 'https://magan-z.github.io/raspisanie/');

/// Общий сервер для старост (Supabase): правки расписания и ДЗ для всей группы.
/// Адрес и «публичный» ключ предназначены для приложений и не секретны: доступ к данным защищён на стороне сервера
/// (студенты только читают, писать может староста с токеном). Пустой адрес — функции старосты скрыты.
const sharedApiUrl = String.fromEnvironment('SHARED_API_URL', defaultValue: 'https://ktavbvmeohtwzdoptueq.supabase.co');
const sharedApiKey = String.fromEnvironment('SHARED_API_KEY', defaultValue: 'sb_publishable_dYboAghNJ7NXFp6lF5prSA_GspY9-p7');

/// Через сколько часов фоновая проверка обновлений (АРХИТЕКТУРА.md, §7.5).
const backgroundSyncHours = 6;
