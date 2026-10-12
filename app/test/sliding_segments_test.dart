// Переключатель с «ползунком»: нажатие меняет выбор, все части всегда в одну строку (даже на узком экране).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/features/common/sliding_segments.dart';

void main() {
  testWidgets('нажатие выбирает часть; три части в один ряд на экране 320 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var selected = 'a';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: SlidingSegments<String>(
                segments: const [
                  Segment('a', 'Преподаватель'),
                  Segment('b', 'Аудитория'),
                  Segment('c', 'Свободные'),
                ],
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      ),
    );

    final ys = [
      for (final t in ['Преподаватель', 'Аудитория', 'Свободные'])
        tester.getCenter(find.text(t)).dy,
    ];
    // допуск 1 px: после ужатия шрифта центры могут отличаться на доли пикселя
    final spread = ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b);
    expect(spread, lessThan(1), reason: 'подписи должны стоять в одной строке');

    await tester.tap(find.text('Свободные'));
    await tester.pumpAndSettle();
    expect(selected, 'c');
  });
}
