// Переключатель с «ползунком»: нажатие меняет выбор, все части всегда в одну строку (даже на узком экране).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unigraf/features/common/sliding_segments.dart';

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

  testWidgets('пропорциональные части: длинная подпись получает больше места и не ужимается сильнее других', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
                proportional: true,
                segments: const [
                  Segment('a', 'Мои (0)'),
                  Segment('b', 'От старосты (1)', icon: Icons.groups_rounded),
                  Segment('c', 'От преподавателей (1)', icon: Icons.school_rounded),
                ],
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      ),
    );
    // высота подписей одинакова (шрифт не ужат): у ужатого текста высота меньше
    double h(String t) => tester.getSize(find.text(t)).height;
    expect(tester.getSize(find.text('От преподавателей (1)')).width, greaterThan(tester.getSize(find.text('Мои (0)')).width * 2));
    expect(h('От преподавателей (1)'), closeTo(h('Мои (0)'), 0.5));
    await tester.tap(find.text('От преподавателей (1)'));
    await tester.pumpAndSettle();
    expect(selected, 'c');
  });
}
