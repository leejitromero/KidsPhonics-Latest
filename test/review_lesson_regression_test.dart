import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/letter_introduction_screen.dart';
import 'package:kidsphonics/widgets/lesson_picture.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'letter_mastery_check_test.dart'
    show
        AdventureTestAudio,
        openAdventure,
        press,
        hear,
        finishHunt,
        flushAdventure;

void main() {
  testWidgets(
      'completed A Quick Check opens decoded Review Lesson without duplicating rewards or mastery',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final audio = AdventureTestAudio();
    final p = await openAdventure(t, audio, letter: 'A');
    await press(t, find.byKey(const ValueKey('start-adventure')));
    await press(t, find.byKey(const ValueKey('adventure-option-a')));
    await press(t, find.text('Next Challenge'));
    await hear(t, audio, 'lesson-sound-A');
    await press(t, find.byKey(const ValueKey('adventure-option-A')));
    await press(t, find.text('Next Challenge'));
    await hear(t, audio, 'cvc-word-cat');
    await press(t, find.byKey(const ValueKey('adventure-option-A')));
    await press(t, find.text('Next Challenge'));
    await hear(t, audio, 'lesson-sound-A');
    await press(t, find.byKey(const ValueKey('adventure-option-Apple')));
    await press(t, find.text('Next Challenge'));
    await finishHunt(t, 'A');
    for (var i = 0; i < 10; i++) {
      await flushAdventure(t);
    }
    final xp = p.xp, stars = p.stars, mastered = p.overallMasteredCount;
    final completed = p.adventureProgress('A').completed;
    expect(completed, 1);
    expect(find.text('Review Lesson'), findsOneWidget);
    await press(t, find.text('Review Lesson'));
    await t.pumpAndSettle();
    expect(find.byType(LetterIntroductionScreen), findsOneWidget);
    final picture = find.byType(LessonPicture);
    expect(picture, findsOneWidget);
    final images = t
        .widgetList<Image>(
            find.descendant(of: picture, matching: find.byType(Image)))
        .toList();
    final names = <String>[];
    await t.runAsync(() async {
      for (final image in images) {
        ImageProvider provider = image.image;
        if (provider is ResizeImage) provider = provider.imageProvider;
        names.add((provider as AssetImage).assetName);
        await rootBundle.load(provider.assetName);
        await precacheImage(image.image, t.element(picture));
      }
    });
    await t.pump();
    expect(names, [
      'assets/images/lesson_frames/ant_A.png',
      'assets/images/lesson_frames/ant_A1.png',
      'assets/images/lesson_frames/ant_A2.png'
    ]);
    expect(t.takeException(), isNull);
    expect(p.xp, xp);
    expect(p.stars, stars);
    expect(p.overallMasteredCount, mastered);
    expect(p.adventureProgress('A').completed, completed);
    // Viewing the lesson is legitimate practice; it must not award another assessment.
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });
}
