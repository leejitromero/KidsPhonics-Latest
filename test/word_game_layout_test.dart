import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('word games share large pictures and aligned no-scroll choices',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    Size? pictureSize;
    for (final page in [
      const SoundMatchScreen(difficulty: Difficulty.hard),
      const PhonicsQuizScreen(difficulty: Difficulty.hard),
      const WordBuilderScreen(difficulty: Difficulty.hard),
      const MissingVowelScreen(difficulty: Difficulty.hard),
      const RumbledWordsScreen(difficulty: Difficulty.hard),
    ]) {
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p = await mount(t, page);
      if (page is SoundMatchScreen) {
        final audio = t.widget<AudioButton>(find.byType(AudioButton));
        final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
        final letter = gameWordFor(word)!.letter.toLowerCase();
        expect(audio.label, 'Hear Sound');
        expect(PhonicsAudioService.assetForPhrase(audio.phrase),
            'audio/phonics/lesson_audio/sounds/sound-$letter.mp3');
        expect(find.text('Which letter makes this sound?'), findsOneWidget);
      }
      expect(find.byType(Scrollable), findsNothing);
      final picture = t.getSize(find.byType(GameWordPicture));
      pictureSize ??= picture;
      expect(picture, pictureSize);
      expect(picture.width, greaterThanOrEqualTo(200));
      for (final grid in find.byType(WordChoiceGrid).evaluate()) {
        final rect = t.getRect(find.byWidget(grid.widget));
        expect(rect.bottom, lessThanOrEqualTo(844));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(390));
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    }
  });
}
