import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/picture_frame_animation.dart';

void main() {
  testWidgets('word frames pause in the background and respect reduced motion',
      (t) async {
    var reduced = false;
    Future<void> render() => t.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Center(child: GameWordPicture(word: 'Cow')))));
    int visible() => t
        .widgetList<Opacity>(find.descendant(
            of: find.byType(PictureFrameAnimation),
            matching: find.byType(Opacity)))
        .toList()
        .indexWhere((opacity) => opacity.opacity == 1);
    await render();
    await t.pump(const Duration(milliseconds: 650));
    await t.pump(const Duration(milliseconds: 750));
    final before = visible();
    expect(before, greaterThanOrEqualTo(0));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 2));
    expect(visible(), before);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    reduced = true;
    await render();
    await t.pump(const Duration(seconds: 2));
    expect(visible(), 0);
    await t.pumpWidget(const SizedBox());
  });
}
