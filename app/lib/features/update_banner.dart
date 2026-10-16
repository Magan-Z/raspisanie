// Обновление приложения: мягкая плашка «Вышла новая версия» над содержимым, экран «Нужно обновить» и наблюдатель,
// который спрашивает сайт при запуске и при возвращении в приложение (логика — lib/update_check.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import '../update_check.dart';
import 'common/brand_mark.dart';

/// Спрашивает сайт про новую версию при запуске и при возвращении в приложение (не чаще раза в 6 часов).
class UpdateWatcher extends ConsumerStatefulWidget {
  const UpdateWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateWatcher> createState() => _UpdateWatcherState();
}

class _UpdateWatcherState extends ConsumerState<UpdateWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(updateInfoProvider.notifier).check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(updateInfoProvider.notifier).check();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Скачать обновление; если телефон не смог открыть ссылку, показывает её текстом.
Future<void> openUpdateDownload(BuildContext context, WidgetRef ref) async {
  final opened = await ref.read(updateOpenerProvider)();
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось открыть загрузку. Скачайте файл на сайте: $apkDownloadUrl')));
}

/// Плашка над содержимым: «Вышла версия …». Закрывается кнопкой «Позже» (до следующей версии).
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateStatusProvider);
    final info = ref.watch(updateInfoProvider);
    if (status != UpdateStatus.available || info == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
          child: Row(children: [
            Icon(Icons.system_update_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Вышла версия ${info.latest}', style: text.titleSmall?.copyWith(color: scheme.onPrimaryContainer)),
                Text('Настройки и ДЗ сохранятся', style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
              ]),
            ),
            TextButton(onPressed: () => openUpdateDownload(context, ref), child: const Text('Скачать')),
            IconButton(
              tooltip: 'Позже',
              icon: Icon(Icons.close, color: scheme.onPrimaryContainer),
              onPressed: () => ref.read(dismissedUpdateProvider.notifier).dismiss(info.latest),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Версия слишком старая: дальше пустить нельзя, предлагаем скачать новую.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final info = ref.watch(updateInfoProvider);
    final current = ref.watch(appVersionProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const BrandMark(size: 72),
                const SizedBox(height: Gap.xl),
                Text('Нужно обновить приложение', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: Gap.md),
                Text(
                  'Версия $current больше не поддерживается. Скачайте новую${info == null ? '' : ' (${info.latest})'}: настройки и ДЗ сохранятся.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Gap.xl),
                FilledButton.icon(
                  onPressed: () => openUpdateDownload(context, ref),
                  icon: const Icon(Icons.download),
                  label: const Text('Скачать обновление'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
