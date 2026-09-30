import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/floating_choice.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';

void main() {
  testWidgets('choices share blue styling and float with a fixed tap target',
      (t) async {
    var taps = 0;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
      width: 300,
      child: GameChoiceGrid(children: [
        GameAnswerButton(
            label: 'A',
            buttonKey: const ValueKey('a'),
            onPressed: () => taps++),
        GameAnswerButton(label: 'B', onPressed: () {}),
      ]),
    )))));
    for (final button
        in t.widgetList<ElevatedButton>(find.byType(ElevatedButton))) {
      expect(button.style!.backgroundColor!.resolve({}), choiceBlue);
    }
    final resting = t.getRect(find.byKey(const ValueKey('a')));
    await t.pump(const Duration(milliseconds: 750));
    final floating = t.getRect(find.byKey(const ValueKey('a')));
    expect(floating.top, lessThan(resting.top));
    expect(resting.top - floating.top, lessThanOrEqualTo(2));
    await t.tapAt(resting.center);
    expect(taps, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion and disabled choices stay still', (t) async {
    for (final reduced in [false, true]) {
      await t.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
            body: Center(
                child: FloatingChoice(
                    enabled: reduced,
                    child: const SizedBox(
                        key: ValueKey('tile'), width: 60, height: 60)))),
      )));
      final before = t.getRect(find.byKey(const ValueKey('tile')));
      await t.pump(const Duration(milliseconds: 750));
      expect(t.getRect(find.byKey(const ValueKey('tile'))), before);
      await t.pumpAndSettle();
    }
  });
}
