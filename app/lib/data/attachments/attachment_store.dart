// Вложения к ДЗ. Интерфейсы — в attachment_types.dart; реализация для телефона или браузера выбирается при сборке.

export 'attachment_types.dart';
export 'attachment_platform_io.dart' if (dart.library.js_interop) 'attachment_platform_web.dart';
