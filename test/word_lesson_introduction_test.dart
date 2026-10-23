import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/data/lesson_instruction_scripts.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

class _Lesson {
  _Lesson(this.blending) {
    if (blending) {
      blend = BlendingLessonController(play: play, stop: () async {});
    } else {
      cvc = CvcLessonController(play: play, stop: () async {});
    }
  }
  final bool blending;
  CvcLessonController? cvc;
  BlendingLessonController? blend;
  final intro = [Completer<bool>(), Completer<bool>()];
  final other = <Completer<bool>>[];
  final heard = <String>[];
  String get key => blending ? 'blend-intro' : 'cvc-intro';
  int get index => blending ? blend!.index : cvc!.index;
  Widget get screen => blending
      ? BlendingSoundsScreen(controller: blend)
      : CvcWordsScreen(controller: cvc);
  Future<bool> play(String phrase) {
    heard.add(phrase);
    if (phrase == '$key-1') return intro[0].future;
    if (phrase == '$key-2') return intro[1].future;
    final pending = Completer<bool>();
    other.add(pending);
    return pending.future;
  }

  void completePending() {
    for (final result in [...intro, ...other]) {
      if (!result.isCompleted) result.complete(true);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  String text(WidgetTester t) => t
      .widget<Text>(find.byKey(const ValueKey('lesson-instruction-text')))
      .data!;
  Future<void> until(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 15 && !ready(); i++) {
      await t.pump();
    }
    expect(ready(), isTrue);
  }

  for (final blending in [false, true]) {
    final name = blending ? 'Blending' : 'CVC';
    for (final part in [0, 1]) {
      for (final action in ['Next', 'Hear Again']) {
        testWidgets(
            '$name: $action during recording ${part + 1} prevents stale continuation',
            (t) async {
          final lesson = _Lesson(blending);
          final p = await mount(t, lesson.screen);
          await until(t, () => lesson.heard.contains('${lesson.key}-1'));
          if (part == 1) {
            lesson.intro.first.complete(true);
            await until(t, () => lesson.heard.contains('${lesson.key}-2'));
          }
          expect(text(t), lessonInstructionScripts[lesson.key]![part]);
          await t.tap(find.widgetWithText(OutlinedButton, action));
          await t.pump();
          expect(lesson.index, action == 'Next' ? 1 : 0);
          expect(text(t), lessonInstructionDefaults[lesson.key]);
          lesson.intro[part].complete(true);
          for (var i = 0; i < 10; i++) {
            await t.pump(const Duration(seconds: 1));
          }
          expect(text(t), lessonInstructionDefaults[lesson.key]);
          expect(lesson.heard.where((p) => p.startsWith(lesson.key)),
              hasLength(part + 1));
          expect((p.xp, p.stars), (0, 0));
          expect(t.takeException(), isNull);
          await close(t, p);
          lesson.completePending();
          await t.pump();
        });
      }
    }

    for (final leave in [false, true]) {
      testWidgets(
          '$name: ${leave ? 'leaving' : 'background'} stops intro without starting part 2',
          (t) async {
        final lesson = _Lesson(blending);
        final p = await mount(t, lesson.screen);
        await until(t, () => lesson.heard.contains('${lesson.key}-1'));
        if (leave) {
          await close(t, p);
        } else {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
          await t.pump();
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await t.pump();
        }
        lesson.completePending();
        await t.pump(const Duration(seconds: 10));
        expect(lesson.heard, ['${lesson.key}-1']);
        expect(t.takeException(), isNull);
        if (!leave) await close(t, p);
      });
    }
  }
}
