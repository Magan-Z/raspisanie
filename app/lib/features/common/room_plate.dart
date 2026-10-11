// «Табличка на двери»: номер аудитории в рамке цвета предмета. Это главный элемент экрана,
// поэтому читается с первого взгляда. Нестандартные места («3 корпус», «читальный зал») пишутся мельче.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/next_design.dart';
import '../../theme/subject_palette.dart';
import '../../theme/tokens.dart';

class RoomPlate extends StatelessWidget {
  const RoomPlate({super.key, required this.room, required this.tone, this.size = 22, this.filled = false, this.pop = false});

  final String room;
  final SubjectTone tone;

  /// Размер цифр. Для длинных названий уменьшается сам.
  final double size;

  /// true — залитая табличка (в крупной карточке «Сейчас»).
  final bool filled;

  /// true — при появлении табличка «выскакивает» (небольшой рывок вперёд): так подчёркивается, что аудитория изменена.
  final bool pop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPlainNumber = room.length <= 6;
    final fontSize = isPlainNumber ? size : size * 0.62;
    final plate = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minTouch, maxWidth: isPlainNumber ? double.infinity : 110),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isPlainNumber ? Gap.md : Gap.sm, vertical: Gap.sm),
        decoration: BoxDecoration(
          color: filled ? tone.accent : scheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: tone.accent, width: kNextDesign ? 2.5 : 2),
        ),
        child: Text(
          room,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: roomTextStyle(fontSize, color: filled ? scheme.surface : tone.onContainer),
        ),
      ),
    );
    final duration = Motion.of(context, const Duration(milliseconds: 520));
    if (!pop || duration == Duration.zero) return plate;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      child: plate,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
    );
  }
}

