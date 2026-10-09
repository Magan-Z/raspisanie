// Вложения к ДЗ: значок по типу файла, плитка с названием и размером, лента вложений на карточке задания.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state.dart';
import '../../data/remote/shared_api.dart';
import '../../domain/attachment.dart';
import '../../domain/group_shared.dart';
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
  const AttachmentTile({super.key, required this.attachment, this.onTap, this.onRemove, this.color, this.trailing});

  final Attachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Color? color; // цвет значка (цвет предмета)
  final Widget? trailing; // например, значок «скачать» у файлов группы

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
                if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
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

  Future<void> _open(BuildContext context, WidgetRef ref, Attachment a) => openAttachment(context, ref, a);

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

/// Открывает вложение: картинка показывается в приложении (можно увеличить), остальное — в другой программе.
Future<void> openAttachment(BuildContext context, WidgetRef ref, Attachment a) async {
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

/// Файлы и фото от старосты на карточке ДЗ. Пока файл не скачан, показана плитка со значком «скачать»;
/// нажатие скачивает файл (один раз) и открывает его. Скачанные фото показываются миниатюрами.
class GroupAttachmentStrip extends ConsumerStatefulWidget {
  const GroupAttachmentStrip({super.key, required this.files, this.color});

  final List<GroupFileRef> files;
  final Color? color;

  @override
  ConsumerState<GroupAttachmentStrip> createState() => _GroupAttachmentStripState();
}

class _GroupAttachmentStripState extends ConsumerState<GroupAttachmentStrip> {
  final _loading = <String>{};

  Future<void> _tap(GroupFileRef f) async {
    final service = ref.read(groupFilesProvider);
    final groupId = ref.read(settingsProvider).profile?.groupId;
    if (service == null || groupId == null || _loading.contains(f.id)) return;
    var a = service.cached(f.id);
    if (a == null) {
      setState(() => _loading.add(f.id));
      try {
        a = await service.download(groupId, f);
      } on SharedApiException catch (e) {
        _say(e.message);
        return;
      } catch (_) {
        _say('Не удалось скачать файл. Проверьте интернет и повторите');
        return;
      } finally {
        if (mounted) setState(() => _loading.remove(f.id));
      }
    }
    if (mounted) await openAttachment(context, ref, a);
  }

  void _say(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) return const SizedBox.shrink();
    final service = ref.watch(groupFilesProvider);
    final store = ref.watch(attachmentStoreProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: Gap.sm),
      child: Wrap(spacing: Gap.sm, runSpacing: Gap.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final f in widget.files)
          Builder(builder: (context) {
            final local = service?.cached(f.id);
            if (local != null && local.isImage) {
              return Semantics(
                button: true,
                label: 'Фото ${f.name}. Нажмите, чтобы увеличить',
                child: GestureDetector(
                  onTap: () => _tap(f),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: store.image(local, width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 216),
                  ),
                ),
              );
            }
            return AttachmentTile(
              attachment: f.asAttachment,
              color: widget.color,
              onTap: () => _tap(f),
              trailing: _loading.contains(f.id)
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : (local == null ? Icon(Icons.download_rounded, size: 18, color: scheme.onSurfaceVariant) : null),
            );
          }),
      ]),
    );
  }
}
