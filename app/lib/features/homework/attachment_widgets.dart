// Вложения к ДЗ: значок по типу файла, плитка с названием и размером, лента вложений на карточке задания.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state.dart';
import '../../domain/attachment.dart';
import '../../theme/tokens.dart';

/// Значок по расширению файла.
IconData attachmentIcon(Attachment a) {
  if (a.isImage) return Icons.image_outlined;
  return switch (a.extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' || 'odt' || 'rtf' || 'txt' => Icons.description_outlined,
    'xls' || 'xlsx' || 'ods' || 'csv' => Icons.table_chart_outlined,
    'ppt' || 'pptx' || 'odp' => Icons.slideshow_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'mp3' || 'wav' || 'm4a' || 'ogg' => Icons.audiotrack_outlined,
    'mp4' || 'mov' || 'avi' || 'mkv' => Icons.movie_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

/// Плитка вложения: значок, название, размер. [onRemove] — крестик (в окне добавления).
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({super.key, required this.attachment, this.onTap, this.onRemove, this.color});

  final Attachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Color? color; // цвет значка (цвет предмета)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: onTap != null,
      label: 'Вложение ${attachment.name}',
      child: Material(
        color: scheme.surface.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm), side: BorderSide(color: scheme.outlineVariant)),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Gap.sm, Gap.xs, onRemove == null ? Gap.sm : 0, Gap.xs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, maxWidth: 240),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(attachmentIcon(attachment), size: 20, color: color ?? scheme.onSurfaceVariant),
                const SizedBox(width: Gap.sm),
                Flexible(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge),
                    if (attachment.sizeText.isNotEmpty)
                      Text(attachment.sizeText, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ]),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Убрать вложение',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onRemove,
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Вложения на карточке задания: картинки — миниатюрами (нажатие увеличивает), остальное — плитками (открывает в другой программе).
class AttachmentStrip extends ConsumerWidget {
  const AttachmentStrip({super.key, required this.attachments, this.color});

  final List<Attachment> attachments;
  final Color? color;

  Future<void> _open(BuildContext context, WidgetRef ref, Attachment a) async {
    final store = ref.read(attachmentStoreProvider);
    if (a.isImage && store.exists(a)) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            InteractiveViewer(child: store.image(a)),
            Positioned(top: 4, right: 4, child: IconButton.filledTonal(tooltip: 'Закрыть', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop())),
          ]),
        ),
      );
      return;
    }
    final error = await store.open(a);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final store = ref.watch(attachmentStoreProvider);
    final images = attachments.where((a) => a.isImage && store.exists(a)).toList();
    final others = attachments.where((a) => !images.contains(a)).toList();

    return Padding(
      padding: const EdgeInsets.only(top: Gap.sm),
      child: Wrap(spacing: Gap.sm, runSpacing: Gap.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final a in images)
          Semantics(
            button: true,
            label: 'Фото ${a.name}. Нажмите, чтобы увеличить',
            child: GestureDetector(
              onTap: () => _open(context, ref, a),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: store.image(a, width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 216),
              ),
            ),
          ),
        for (final a in others) AttachmentTile(attachment: a, color: color, onTap: () => _open(context, ref, a)),
      ]),
    );
  }
}
