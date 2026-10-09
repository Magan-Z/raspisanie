// Работа с файлами вложений: выбрать (галерея, камера, любой файл), скопировать в память приложения, открыть.
// Всё за интерфейсами, чтобы в тестах подставлять «поддельные» файлы без настоящих окон выбора.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/attachment.dart';

/// Файл, который выбрал пользователь (ещё не скопирован в приложение).
class PickedFileInfo {
  const PickedFileInfo({required this.name, required this.path, this.sizeBytes});
  final String name;
  final String path;
  final int? sizeBytes;
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

class SystemAttachmentPicker implements AttachmentPicker {
  final _images = ImagePicker();

  @override
  Future<List<PickedFileInfo>> pickFiles() async {
    final files = await FilePicker.pickFiles();
    return [
      for (final f in files)
        if (f.path != null) PickedFileInfo(name: f.name, path: f.path!, sizeBytes: f.lengthSync()),
    ];
  }

  @override
  Future<PickedFileInfo?> takePhoto() async {
    final shot = await _images.pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 85);
    return shot == null ? null : await _fromXFile(shot);
  }

  @override
  Future<List<PickedFileInfo>> pickImages() async {
    final shots = await _images.pickMultiImage(maxWidth: 2000, imageQuality: 85);
    return [for (final s in shots) await _fromXFile(s)];
  }

  Future<PickedFileInfo> _fromXFile(XFile f) async =>
      PickedFileInfo(name: f.name, path: f.path, sizeBytes: await f.length());
}

/// Где хранятся файлы вложений и как их открыть.
abstract class AttachmentStore {
  /// Копирует выбранный файл в память приложения и возвращает описание вложения.
  Future<Attachment> save(PickedFileInfo picked);

  /// Удаляет файл вложения (если он ещё есть).
  Future<void> delete(Attachment attachment);

  bool exists(Attachment attachment);

  /// Открывает файл в подходящей программе телефона. Текст ошибки, если не получилось, иначе null.
  Future<String?> open(Attachment attachment);
}

class DiskAttachmentStore implements AttachmentStore {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/attachments');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<Attachment> save(PickedFileInfo picked) async {
    final dir = await _dir();
    // Время в имени — чтобы два файла с одинаковым названием («Задачи.pdf») не затёрли друг друга
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final safeName = picked.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final target = '${dir.path}/${stamp}_$safeName';
    await File(picked.path).copy(target);
    return Attachment(name: picked.name, path: target, sizeBytes: picked.sizeBytes ?? File(target).lengthSync());
  }

  @override
  Future<void> delete(Attachment attachment) async {
    final file = File(attachment.path);
    if (file.existsSync()) await file.delete();
  }

  @override
  bool exists(Attachment attachment) => File(attachment.path).existsSync();

  @override
  Future<String?> open(Attachment attachment) async {
    if (!exists(attachment)) return 'Файл не найден: возможно, его удалили из памяти телефона';
    final result = await OpenFilex.open(attachment.path);
    return switch (result.type) {
      ResultType.done => null,
      ResultType.noAppToOpen => 'На телефоне нет программы, которая откроет «${attachment.name}»',
      ResultType.fileNotFound => 'Файл не найден',
      ResultType.permissionDenied => 'Нет доступа к файлу',
      ResultType.error => 'Не удалось открыть файл',
    };
  }
}
