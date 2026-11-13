import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/letter_introduction_screen.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
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
  for (final letter in ['A', 'I', 'Z']) {
    testWidgets(
        'completed $letter Quick Check reviews the current lesson at $letter without duplicate rewards',
        (t) async {
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final audio = AdventureTestAudio();
      final content = adventureContents.singleWhere((c) => c.letter == letter);
      final p = await openAdventure(t, audio, letter: letter);
      await press(t, find.byKey(const ValueKey('start-adventure')));
      await press(
          t, find.byKey(ValueKey('adventure-option-${letter.toLowerCase()}')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, 'lesson-sound-$letter');
      await press(t, find.byKey(ValueKey('adventure-option-$letter')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, adventureWordKey(content.word));
      await press(t, find.byKey(ValueKey('adventure-option-$letter')));
      await press(t, find.text('Next Challenge'));
      await hear(t, audio, 'lesson-sound-$letter');
      await press(
          t, find.byKey(ValueKey('adventure-option-${content.pictureWord}')));
      await press(t, find.text('Next Challenge'));
      await finishHunt(t, letter);
      for (var i = 0; i < 10; i++) {
        await flushAdventure(t);
      }
      final xp = p.xp, stars = p.stars, mastered = p.overallMasteredCount;
      final completed = p.adventureProgress(letter).completed;
      final questions = p.dailyActivity.values.single.questionsAnswered;
      expect(completed, 1);
      expect(find.text('Review Lesson'), findsOneWidget);
      await press(t, find.text('Review Lesson'));
      await t.pumpAndSettle();
      expect(find.byType(LetterIntroductionScreen), findsNothing);
      expect(find.byType(LetterRecognitionScreen), findsOneWidget);
      expect(find.text('Letter Recognition'), findsOneWidget);
      final picture = find.byKey(const ValueKey('recognition-letter'));
      expect(picture, findsOneWidget);
      final image = t.widget<Image>(picture);
      expect(image.semanticLabel, 'Letter $letter');
      ImageProvider imageProvider = image.image;
      if (imageProvider is ResizeImage) {
        imageProvider = imageProvider.imageProvider;
      }
      final path = (imageProvider as AssetImage).assetName;
      expect(path, 'assets/images/letters/${letter.toLowerCase()}.webp');
      await t.runAsync(() async {
        await rootBundle.load(path);
        await precacheImage(image.image, t.element(picture));
      });
      await t.pump();
      expect(t.takeException(), isNull);
      expect(p.xp, xp);
      expect(p.stars, stars);
      expect(p.overallMasteredCount, mastered);
      expect(p.adventureProgress(letter).completed, completed);
      expect(p.dailyActivity.values.single.questionsAnswered, questions);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.text('Score: 5 / 5'), findsOneWidget);
      expect(p.adventureProgress(letter).completed, completed);
      expect((p.xp, p.stars), (xp, stars));
      await t.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
