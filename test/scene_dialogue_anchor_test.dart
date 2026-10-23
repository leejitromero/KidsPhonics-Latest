import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/home_village.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/home_guideline_dialog.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void verifyPointer(WidgetTester t, Rect head, String art, {bool flip = false}) {
  final image = t.getRect(find.byKey(const ValueKey('scene-dialogue-art')));
  final point = SceneDialogue.tailFor(art, flip: flip);
  final tip =
      image.topLeft + Offset(point.dx * image.width, point.dy * image.height);
  expect(tip.dx, closeTo(head.center.dx, 1));
  // Transparent PNG margins can intersect the speaker; visible ink cannot.
  expect(tip.dy, closeTo(head.top - 8, 1));
  expect(image.width / image.height,
      closeTo(SceneDialogue.aspectRatioFor(art), .001));
  final content = t
      .getRect(find.byKey(const ValueKey('scene-dialogue-content')))
      .inflate(.1);
  final text = t.getRect(find.byKey(const ValueKey('scene-dialogue-text')));
  expect(content.bottom, lessThan(head.top));
  expect(content.contains(text.topLeft), true);
  expect(content.contains(text.bottomRight), true);
}

SchoolHomeScene scene({String character = 'girl', HomeCategory? guide}) {
  final games = guide == HomeCategory.games;
  return SchoolHomeScene(
      character: character,
      name: 'Sam',
      letter: 'A',
      gameAccess: true,
      busy: false,
      visit: const AlwaysStoppedAnimation(0),
      onSelect: (_) {},
      onCharacter: () {},
      onSettings: () {},
      onContinue: () {},
      progressLabel: '',
      level: 1,
      stars: 0,
      xp: 0,
      showStudent: guide == null,
      dialogueSpeaker: guide,
      studentSpeech: guide == null
          ? SceneDialogue(
              text: 'Hi! Would you like to learn, practice, or play?',
              art: 'dialogue_box_${character == 'girl' ? 4 : 1}.png')
          : null,
      dialogue: guide == null
          ? null
          : SceneDialogue(
              text: homeIntroduction[games ? 5 : 0].text,
              art: 'dialogue_box_${games ? 1 : 2}.png',
              flip: games));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false});
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024)
  ]) {
    for (final character in ['boy', 'girl']) {
      testWidgets(
          '$character speech points to the head and stays clear at $size',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final p = await mount(
            t,
            Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        disableAnimations: true,
                        padding: const EdgeInsets.only(top: 44, bottom: 24)),
                    child: RepaintBoundary(
                        key: key,
                        child: Scaffold(body: scene(character: character))))));
        final student = t.getRect(find.byKey(const ValueKey('home-student')));
        final head = Rect.fromLTRB(student.left,
            student.top + student.height * .04, student.right, student.bottom);
        verifyPointer(
            t, head, 'dialogue_box_${character == 'girl' ? 4 : 1}.png');
        final bubble =
            t.getRect(find.byKey(const ValueKey('scene-dialogue-art')));
        final logo = t.getRect(find.byKey(const ValueKey('home-logo-art')));
        expect(bubble.top, greaterThanOrEqualTo(logo.bottom + 7.9));
        expect(bubble.left, greaterThanOrEqualTo(11.9));
        expect(bubble.right, lessThanOrEqualTo(size.width - 11.9));
        for (final id in [
          'home-lessons',
          'home-start-adventure',
          'home-games'
        ]) {
          expect(bubble.overlaps(t.getRect(find.byKey(ValueKey(id)))), false);
        }
        if (size.width == 390) {
          await capture(t, key, 'dialogue_$character');
        }
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
    for (final category in [HomeCategory.lessons, HomeCategory.games]) {
      testWidgets('${category.name} introduction points to its mascot at $size',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final p = await mount(
            t,
            Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: RepaintBoundary(
                        key: key,
                        child: Scaffold(body: scene(guide: category))))));
        final mascot =
            t.getRect(find.byKey(ValueKey('home-${category.name}-mascot')));
        final side = math.min(mascot.width, mascot.height);
        final head =
            Rect.fromCenter(center: mascot.center, width: side, height: side);
        final games = category == HomeCategory.games;
        verifyPointer(t, head, 'dialogue_box_${games ? 1 : 2}.png',
            flip: games);
        if (size.width == 390) {
          await capture(t, key, 'dialogue_${category.name}');
        }
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }

  for (final games in [false, true]) {
    testWidgets(
        '${games ? 'games' : 'lessons'} guideline keeps bubble near the speaker',
        (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final p = await mount(
          t,
          RepaintBoundary(
              key: key,
              child: Scaffold(body: HomeGuidelineDialog(games: games))));
      verifyPointer(
          t,
          t.getRect(find.byKey(const ValueKey('guideline-speaker'))),
          'dialogue_box_${games ? 1 : 2}.png',
          flip: games);
      await capture(
          t, key, 'dialogue_guideline_${games ? 'games' : 'lessons'}');
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
