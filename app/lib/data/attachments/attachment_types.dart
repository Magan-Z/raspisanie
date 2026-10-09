// Работа с файлами вложений: интерфейсы (выбрать файл, сохранить, показать, открыть).
// Настоящие реализации — для телефона (attachment_platform_io.dart) и для браузера (attachment_platform_web.dart);
// нужная подставляется сама при сборке. Всё за интерфейсами, чтобы в тестах использовать «поддельные» файлы.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../domain/attachment.dart';

/// Файл, который выбрал пользователь (ещё не сохранён в приложении).
class PickedFileInfo {
  const PickedFileInfo({required this.name, this.path, this.sizeBytes, this.readBytes});
  final String name;

  /// Путь к файлу на телефоне. В браузере путей нет — там содержимое читается через [readBytes].
  final String? path;
  final int? sizeBytes;
  final Future<Uint8List> Function()? readBytes;
}

/// Окна выбора файлов.
abstract class AttachmentPicker {
  /// Любые файлы (можно несколько): документы, PDF, презентации, картинки.
  Future<List<PickedFileInfo>> pickFiles();

  /// Снимок с камеры (null — отменили).
  Future<PickedFileInfo?> takePhoto();

  /// Картинки из галереи (можно несколько).
  Future<List<PickedFileInfo>> pickImages();
}

/// Где хранятся файлы вложений и как их показать и открыть.
abstract class AttachmentStore {
  /// Сохраняет выбранный файл в приложении и возвращает описание вложения.
  Future<Attachment> save(PickedFileInfo picked);

  /// Удаляет файл вложения (если он ещё есть).
  Future<void> delete(Attachment attachment);

  bool exists(Attachment attachment);

  /// Открывает файл в подходящей программе. Текст ошибки, если не получилось, иначе null.
  Future<String?> open(Attachment attachment);

  /// Картинка-вложение для показа на экране (миниатюра или полный размер).
  Widget image(Attachment attachment, {double? width, double? height, BoxFit? fit, int? cacheWidth});
}
