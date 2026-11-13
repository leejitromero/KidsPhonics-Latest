import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/lesson_word_order.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/widgets/cvc_word_board.dart';
import 'package:kidsphonics/widgets/cvc_word_picture.dart';
import 'package:kidsphonics/widgets/lesson_swipe_navigation.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  Future<void> flush(WidgetTester t) async {
    var done = false;
    bool? result;
    LessonWordOrder.saved.then((saved) {
      result = saved;
      done = true;
    });
    for (var i = 0; i < 50 && !done; i++) {
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(done, isTrue);
    expect(result, isTrue);
  }

  Future<void> swipe(WidgetTester t, {bool previous = false}) async {
    final rect = t.getRect(find.byType(LessonSwipeNavigation));
    await t.dragFrom(Offset(rect.center.dx, rect.top + 35),
        Offset(previous ? 160 : -160, 0));
    await t.pump();
    await flush(t);
  }

  for (final blending in [false, true]) {
    final key = blending ? 'blending' : 'cvc';
    testWidgets(
        '$key default screen randomizes on reopening and preserves swipe history',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      Widget screen() =>
          blending ? const BlendingSoundsScreen() : const CvcWordsScreen();
      String word() => blending
          ? t.widget<CvcWordPicture>(find.byType(CvcWordPicture)).word.word
          : t.widget<CvcWordBoard>(find.byType(CvcWordBoard)).lesson.word.word;
      final lesson = blending ? WordLesson.blending : WordLesson.cvc;
      final p = await mount(t, screen());
      // Finish the reading-only introduction without waiting through its timers.
      await t.tap(
          find.widgetWithText(OutlinedButton, blending ? 'Try Again' : 'Next'));
      await t.pump();
      await flush(t);
      final first = word();
      await swipe(t);
      final second = word();
      expect(second, isNot(first));
      await swipe(t, previous: true);
      expect(word(), first);
      await t.tap(find.widgetWithText(OutlinedButton, 'Next'));
      await t.pump();
      expect(word(), second);
      await flush(t);
      final prefs = await t.runAsync(() => SharedPreferences.getInstance());
      final stored = prefs!.getString(LessonWordHistory.storageKey)!;
      final data = jsonDecode(stored)['lessons'][key];
      expect(data['remaining'], hasLength(lesson.words.length - 2));
      var settingsSaved = false;
      p.setTextSizeMultiplier(1.1).then((_) => settingsSaved = true);
      for (var i = 0; i < 100 && !settingsSaved; i++) {
        await t.pump();
        await t.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(settingsSaved, isTrue);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(word(), second);
      expect(prefs.getString(LessonWordHistory.storageKey), stored);
      expect(p.wordLessonProgress(lesson).completed, isEmpty);
      expect((p.xp, p.stars), (0, 0));
      expect(t.takeException(), isNull);
      await close(t, p);

      // Restore the persisted data into a fresh preferences instance, as on restart.
      SharedPreferences.setMockInitialValues({
        for (final name in prefs.getKeys()) name: prefs.get(name)!,
      });
      final reopened = await mount(t, screen());
      await t.tap(
          find.widgetWithText(OutlinedButton, blending ? 'Try Again' : 'Next'));
      await t.pump();
      await flush(t);
      expect({first, second}, isNot(contains(word())));
      expect(reopened.wordLessonProgress(lesson).completed, isEmpty);
      expect((reopened.xp, reopened.stars), (0, 0));
      expect(t.takeException(), isNull);
      await close(t, reopened);
    });
  }
}
