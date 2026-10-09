// Вложение к домашнему заданию: фото доски, PDF, документ, презентация — любой файл.
// Сам файл копируется в память приложения (чтобы не пропал, если его удалят из «Загрузок»); здесь — только описание.

class Attachment {
  const Attachment({this.id, required this.name, required this.path, this.sizeBytes});

  final int? id; // null — ещё не сохранено в базу
  final String name; // как файл назывался у пользователя: «Задачи.pdf»
  final String path; // где лежит копия в памяти приложения
  final int? sizeBytes;

  /// Расширение без точки, строчными буквами: «pdf». Пустая строка, если его нет.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 || dot == name.length - 1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// Картинку можно показать прямо в приложении, остальное открывается в другой программе.
  bool get isImage => const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic'}.contains(extension);

  /// «1,4 МБ», «320 КБ». Пусто, если размер неизвестен.
  String get sizeText => sizeBytes == null ? '' : formatFileSize(sizeBytes!);
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} КБ';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(1).replaceAll('.', ',')} МБ';
}

/// Сколько вложений можно прикрепить к одному заданию и какого размера (чтобы не забить память телефона).
const maxAttachmentsPerHomework = 10;
const maxAttachmentBytes = 50 * 1024 * 1024;
