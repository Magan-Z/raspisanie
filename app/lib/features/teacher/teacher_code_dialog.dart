// Окно ввода кода преподавателя. Код выдаёт автор приложения (на конкретного преподавателя и его группы).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/shared_api.dart';
import '../../domain/teacher_homework.dart';
import '../../teacher_actions.dart';
import '../../theme/tokens.dart';

/// Показывает окно и возвращает данные кода, если он подошёл (иначе null).
Future<TeacherSession?> showTeacherCodeDialog(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  return showDialog<TeacherSession>(context: context, builder: (_) => _TeacherCodeDialog(container: container));
}

class _TeacherCodeDialog extends StatefulWidget {
  const _TeacherCodeDialog({required this.container});
  final ProviderContainer container;

  @override
  State<_TeacherCodeDialog> createState() => _TeacherCodeDialogState();
}

class _TeacherCodeDialogState extends State<_TeacherCodeDialog> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await TeacherActions.redeem(widget.container, _code.text);
      if (mounted) Navigator.of(context).pop(session);
    } on SharedApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Код преподавателя'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Введите код, который вам выдали. С ним можно отправлять ДЗ студентам ваших групп.'),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _code,
          autofocus: true,
          enabled: !_busy,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: 'Код', errorText: _error, errorMaxLines: 3),
        ),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Отмена')),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Проверяем…' : 'Подтвердить')),
      ],
    );
  }
}
