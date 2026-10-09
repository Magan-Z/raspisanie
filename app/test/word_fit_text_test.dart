// Названия пар не должны рваться посреди слова («пр / едпринимательство»).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raspisanie/features/common/word_fit_text.dart';

Widget _wrap(Widget child, double width) => MaterialApp(
      home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: child))),
    );

void main() {
  const long = 'Технологическое предпринимательство';
  const style = TextStyle(fontSize: 20);

  testWidgets('длинное слово: шрифт уменьшается, и слово помещается целиком', (tester) async {
    await tester.pumpWidget(_wrap(const WordFitText(long, style: style), 160));
    final text = tester.widget<RichText>(find.byType(RichText).first);
    expect(text.text.style!.fontSize, lessThan(20));

    // Самое длинное слово занимает одну строку: ни одна строка не шире блока
    final box = tester.renderObject<RenderBox>(find.byType(RichText).first);
    expect(box.size.width, lessThanOrEqualTo(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('если места хватает, размер шрифта не меняется', (tester) async {
    await tester.pumpWidget(_wrap(const WordFitText(long, style: style), 2000));
    final text = tester.widget<RichText>(find.byType(RichText).first);
    expect(text.text.style!.fontSize, 20);
  });

  testWidgets('значок после текста показывается', (tester) async {
    await tester.pumpWidget(_wrap(
      const WordFitText('Философия', style: style, trailing: WidgetSpan(child: Icon(Icons.check))),
      300,
    ));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
