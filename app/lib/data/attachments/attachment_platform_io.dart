// Вложения на телефоне: файлы копируются в память приложения.

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/attachment.dart';
import '../local/database.dart';
import 'attachment_types.dart';

AttachmentStore createAttachmentStore(AppDatabase db) => DiskAttachmentStore();

AttachmentPicker createAttachmentPicker() => SystemAttachmentPicker();

class SystemAttachmentPicker implements AttachmentPicker {
  final _images = ImagePicker();

  @override
  Future<List<PickedFileInfo>> pickFiles() async {
    final files = await FilePicker.pickFiles();
    return [
      for (final f in files)
        if (f.path != null) PickedFileInfo(name: f.name, path: f.path, sizeBytes: f.lengthSync()),
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

  Future<PickedFileInfo> _fromXFile(XFile f) async => PickedFileInfo(name: f.name, path: f.path, sizeBytes: await f.length());
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
    if (picked.path != null) {
      await File(picked.path!).copy(target);
    } else {
      await File(target).writeAsBytes(await picked.readBytes!());
    }
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
  Future<Uint8List?> readBytes(Attachment attachment) async => exists(attachment) ? File(attachment.path).readAsBytes() : null;

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

  @override
  Widget image(Attachment attachment, {double? width, double? height, BoxFit? fit, int? cacheWidth}) =>
      Image.file(File(attachment.path), width: width, height: height, fit: fit, cacheWidth: cacheWidth, semanticLabel: attachment.name);
}
