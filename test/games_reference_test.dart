import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/games_menu_art.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/widgets/game_zone_card.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/student_character_picker.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'sfx': false,
      'studentCharacter': 'girl',
      'studentName': 'Mia',
      'xp': 210,
      'stars': 7
    });
  });
  void reduced(WidgetTester t) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Finder grid() => find.byKey(const PageStorageKey('games-grid'));
  Finder scroller() =>
      find.descendant(of: grid(), matching: find.byType(Scrollable));
  int count(WidgetTester t) => (t.widget<GridView>(grid()).childrenDelegate
          as SliverChildBuilderDelegate)
      .childCount!;
  Future<void> filter(WidgetTester t, String value) async {
    final target = find.byKey(ValueKey('games-filter-$value'));
    await t.ensureVisible(target);
    await t.pumpAndSettle();
    await t.tap(target);
    await t.pumpAndSettle();
  }

  Future<void> reach(WidgetTester t, String title) async {
    await t.scrollUntilVisible(find.byKey(ValueKey('game-open-$title')), 140,
        scrollable: scroller());
    await t.pumpAndSettle();
  }

  test('frame has real transparency in its center and outside', () async {
    final codec = await ui
        .instantiateImageCodec(File(GamesFrameArt.frame).readAsBytesSync());
    final picture = (await codec.getNextFrame()).image;
    expect((picture.width, picture.height), (1536, 1024));
    final rgba =
        (await picture.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    expect(
        rgba.getUint8(
            ((picture.height ~/ 2) * picture.width + picture.width ~/ 2) * 4 +
                3),
        0);
    expect(rgba.getUint8(3), 0);
    expect(rgba.getUint8((80 * picture.width + 768) * 4 + 3), greaterThan(200));
    picture.dispose();
    codec.dispose();
  });
  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(430, 932), scale: 1.0),
    (size: const Size(768, 1024), scale: 1.0),
    (size: const Size(1024, 1366), scale: 1.0),
    (size: const Size(844, 390), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
        'compact glossy Games cards fit $scenario and all eleven games are reachable',
        (t) async {
      reduced(t);
      t.view.physicalSize = scenario.size;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final boundary = GlobalKey();
      final p = await mount(
          t,
          Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.only(top: 24, bottom: 24)),
                  child: RepaintBoundary(
                      key: boundary, child: const GamesScreen()))));
      await t.pumpAndSettle();
      expect(count(t), 11);
      expect(
          (t.widget<GridView>(grid()).gridDelegate
                  as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          2);
      expect(find.byType(KidsNavigationBar), findsOneWidget);
      expect(find.byKey(const ValueKey('category-menu')), findsNothing);
      expect(find.byKey(const ValueKey('game-zone-mascot')), findsNothing);
      expect(find.byKey(const ValueKey('games-profile-girl')), findsOneWidget);
      final dock = t.getRect(find.byKey(const ValueKey('kids-navigation-bar')));
      expect(t.getRect(grid()).bottom, lessThanOrEqualTo(dock.top));
      expect(dock.bottom, lessThanOrEqualTo(scenario.size.height - 24));
      final header = t.getRect(find.byKey(const ValueKey('games-banner')));
      final profile = t.getRect(find.byKey(const ValueKey('games-profile')));
      final back = t.getRect(find.byKey(const ValueKey('games-back')));
      expect(back.right, lessThanOrEqualTo(header.left));
      expect(profile.left, greaterThanOrEqualTo(header.right));
      final first =
          t.getRect(find.byKey(const ValueKey('game-card-Flappy Letters')));
      final second =
          t.getRect(find.byKey(const ValueKey('game-card-Sound Match')));
      expect(first.top, second.top);
      expect(first.size, second.size);
      expect(first.width / first.height, closeTo(1.05, .0001));
      if (scenario.scale == 1 && [390.0, 768.0].contains(scenario.size.width)) {
        await capture(
            t, boundary, 'games_reference_${scenario.size.width.toInt()}');
      }
      for (final title in gamesMenuArt.keys) {
        await reach(t, title);
        final frame = find.byKey(ValueKey('game-frame-$title'));
        expect(t.widget(frame), isNot(isA<Image>()));
        final native = t.getSize(frame);
        expect(native.width, closeTo(first.width, .001));
        expect(native.height, closeTo(first.height, .001));
        final card = find.byKey(ValueKey('game-card-$title'));
        for (final image in t.widgetList<Image>(
            find.descendant(of: card, matching: find.byType(Image)))) {
          final provider = image.image is ResizeImage
              ? (image.image as ResizeImage).imageProvider
              : image.image;
          if (provider is AssetImage) {
            expect(provider.assetName, isNot(GamesFrameArt.frame));
          }
        }
        final art = t.widget<Image>(find.byKey(ValueKey('game-art-$title')));
        expect(art.fit, BoxFit.contain);
        expect(
            find.byKey(ValueKey('game-character-$title-girl')), findsOneWidget);
        final play = find.byKey(ValueKey('game-play-$title'));
        await t.ensureVisible(play);
        await t.pumpAndSettle();
        expect(play.hitTestable(), findsOneWidget);
        expect(
            t.getRect(play).width, greaterThan(t.getRect(play).height * 1.8));
        expect(find.descendant(of: play, matching: find.text('Play')),
            findsOneWidget);
        final titleRect = t.getRect(find.byKey(ValueKey('game-title-$title')));
        final description =
            t.getRect(find.byKey(ValueKey('game-description-$title')));
        expect(titleRect.bottom, lessThanOrEqualTo(description.top + .01));
        expect(description.bottom, lessThanOrEqualTo(t.getRect(play).top));
        expect(t.getRect(frame).contains(t.getRect(play).center), true);
        expect(t.getRect(play).bottom, lessThan(dock.top));
        expect(t.getRect(find.byKey(const ValueKey('games-banner'))), header);
        expect(
            t.getRect(find.byKey(const ValueKey('kids-navigation-bar'))), dock);
        expect(t.takeException(), isNull);
      }
      await close(t, p);
    });
  }
  testWidgets(
      'filters preserve saves, per-filter offsets, and profile selection',
      (t) async {
    reduced(t);
    final p = await mount(t, const GamesScreen());
    await t.drag(grid(), const Offset(0, -420));
    await t.pumpAndSettle();
    final allOffset = t.widget<GridView>(grid()).controller!.offset;
    for (final (category, expected) in [
      ('Letters', 2),
      ('Sounds', 3),
      ('Words', 6),
      ('All Games', 11)
    ]) {
      await filter(t, category);
      expect(count(t), expected);
      expect(
          t
              .widget<ChoiceChip>(
                  find.byKey(ValueKey('games-filter-$category')))
              .selected,
          true);
    }
    expect(
        t.widget<GridView>(grid()).controller!.offset, closeTo(allOffset, .1));
    expect((p.studentName, p.xp, p.stars), ('Mia', 210, 7));
    await t.tap(find.byKey(const ValueKey('games-profile')));
    await t.pumpAndSettle();
    expect(find.byType(StudentCharacterPicker), findsOneWidget);
    await t.runAsync(() => p.setStudentCharacter('boy', 'Sam'));
    Navigator.of(t.element(find.byType(StudentCharacterPicker))).pop();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('games-profile-boy')), findsOneWidget);
    for (final card in t.widgetList<GameZoneCard>(find.byType(GameZoneCard))) {
      expect(card.character, 'boy');
    }
    expect(
        t.widget<GridView>(grid()).controller!.offset, closeTo(allOffset, .1));
    expect((p.xp, p.stars), (210, 7));
    await close(t, p);
  });
  testWidgets('card tap scales, illuminates frame, returns, and opens once',
      (t) async {
    var opened = 0;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 180,
                    height: 270,
                    child: GameZoneCard(
                        title: 'Sound Match',
                        description: 'Match the sound!',
                        imageAsset: gamesMenuArt['Sound Match']!,
                        accent: Colors.blue,
                        character: 'boy',
                        onPressed: () => opened++))))));
    final target = find.byKey(const ValueKey('game-open-Sound Match'));
    await t.tap(target);
    await t.tap(target);
    await t.pump();
    expect(
        t
            .widget<AnimatedScale>(
                find.byKey(const ValueKey('game-scale-Sound Match')))
            .scale,
        .97);
    expect(
        t
            .widget<AnimatedOpacity>(
                find.byKey(const ValueKey('game-frame-light-Sound Match')))
            .opacity,
        .22);
    expect(opened, 0);
    await t.pump(const Duration(milliseconds: 90));
    expect(
        t
            .widget<AnimatedScale>(
                find.byKey(const ValueKey('game-scale-Sound Match')))
            .scale,
        1);
    await t.pump(const Duration(milliseconds: 90));
    expect(opened, 1);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'all eleven cards preserve their difficulty and game destinations',
      (t) async {
    reduced(t);
    final p = await mount(t, const GamesScreen());
    final menu = t.state(find.byType(GamesScreen));
    const destinations = [
      FlappyLettersScreen,
      SoundMatchScreen,
      MemoryGameScreen,
      PhonicsQuizScreen,
      WordBuilderScreen,
      VoiceRecognitionScreen,
      AlphabetOrderScreen,
      MissingVowelScreen,
      PictureWordMatchScreen,
      RumbledWordsScreen,
      RhymingWordsScreen
    ];
    for (var index = 0; index < destinations.length; index++) {
      final title = gamesMenuArt.keys.elementAt(index);
      await reach(t, title);
      final play = find.byKey(ValueKey('game-play-$title'));
      await t.ensureVisible(play);
      await t.pumpAndSettle();
      final offset = t.widget<GridView>(grid()).controller!.offset;
      final open = t
          .widgetList<GameZoneCard>(find.byType(GameZoneCard))
          .singleWhere((card) => card.title == title)
          .onPressed!;
      open();
      open();
      await t.pumpAndSettle();
      expect(find.text('Easy'), findsOneWidget);
      await t.tap(find.text('Easy'));
      await t.pump();
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(destinations[index]), findsOneWidget);
      Navigator.of(t.element(find.byType(destinations[index])))
          .popUntil((route) => route.isFirst);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.pump();
      expect(t.state(find.byType(GamesScreen)), same(menu));
      expect(
          t.widget<GridView>(grid()).controller!.offset, closeTo(offset, .1));
      expect(t.takeException(), isNull);
    }
    await close(t, p);
  });

  testWidgets(
      'Words filter, scroll, and saved completion refresh on game return',
      (t) async {
    reduced(t);
    final p = await mount(t, const GamesScreen());
    await filter(t, 'Words');
    await reach(t, 'Rhyming Words');
    final play = find.byKey(const ValueKey('game-play-Rhyming Words'));
    await t.ensureVisible(play);
    await t.pumpAndSettle();
    final offset = t.widget<GridView>(grid()).controller!.offset;
    await t.tap(play);
    await t.pumpAndSettle();
    await t.tap(find.text('Easy'));
    await t.pump();
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 400));
    await t.runAsync(() => p.markRhymingWordsDone());
    Navigator.of(t.element(find.byType(RhymingWordsScreen))).pop();
    await t.pumpAndSettle();
    expect(
        t
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('games-filter-Words')))
            .selected,
        true);
    expect(t.widget<GridView>(grid()).controller!.offset, closeTo(offset, .1));
    expect(find.text('Completed'), findsOneWidget);
    expect((p.xp, p.stars), (210, 7));
    await close(t, p);
  });

  testWidgets(
      'Games navigation reuses Home and Progress states and Back returns safely',
      (t) async {
    reduced(t);
    final p = await mount(t, const HomeScreen());
    final home = t.state(find.byType(HomeScreen));
    await t.tap(find.byKey(const ValueKey('main-nav-progress')));
    await t.pumpAndSettle();
    final progress = t.element(find.byType(ProgressScreen));
    await t.tap(find.byKey(const ValueKey('main-nav-home')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('home-games')));
    await t.pumpAndSettle();
    expect(find.byType(GamesScreen), findsOneWidget);
    expect(find.byType(KidsNavigationBar), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('main-nav-progress')));
    await t.pumpAndSettle();
    expect(t.element(find.byType(ProgressScreen)), same(progress));
    await t.tap(find.byKey(const ValueKey('main-nav-home')));
    await t.pumpAndSettle();
    expect(t.state(find.byType(HomeScreen)), same(home));
    await t.tap(find.byKey(const ValueKey('home-games')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('games-back')));
    await t.pumpAndSettle();
    expect(t.state(find.byType(HomeScreen)), same(home));
    expect(find.byType(GamesScreen), findsNothing);
    await close(t, p);
  });

  testWidgets(
      'parent game-access restrictions keep the header and navigation available',
      (t) async {
    reduced(t);
    SharedPreferences.setMockInitialValues(
        {'voice': false, 'gameAccess': false, 'studentCharacter': 'boy'});
    final p = await mount(t, const GamesScreen());
    expect(find.text('Games are turned off by a parent.'), findsOneWidget);
    expect(find.byType(GameZoneCard), findsNothing);
    expect(find.byType(KidsNavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('games-profile-boy')), findsOneWidget);
    await close(t, p);
  });
}
