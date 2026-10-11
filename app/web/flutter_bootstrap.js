{{flutter_js}}
{{flutter_build_config}}

// Свой кэш приложения лежит в sw.js и включается из index.html. Встроенный в Flutter кэш выключен (его убирают из Flutter),
// поэтому настройки serviceWorkerSettings здесь не передаём — иначе он заменил бы наш.
_flutter.loader.load();
