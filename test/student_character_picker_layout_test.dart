import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
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
      'studentCharacter': 'girl',
      'studentName': 'Lala',
    });
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
  ]) {
    testWidgets(
        'aligned portraits and readable picker over a dark app at $size',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final p = await mount(t, const SizedBox());
      await t.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: MaterialApp(
              theme: ThemeData.dark(),
              builder: (context, child) => RepaintBoundary(
                  key: boundary,
                  child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: true),
                      child: child!)),
              home: const HomeScreen())));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('home-student')));
      await t.pumpAndSettle();
      final boy = t.getRect(find.byKey(const ValueKey('choose-boy')));
      final girl = t.getRect(find.byKey(const ValueKey('choose-girl')));
      expect(boy.size, girl.size);
      expect(boy.top, girl.top);
      expect(boy.right, lessThan(girl.left));
      for (final character in ['boy', 'girl']) {
        final choice = t.getRect(find.byKey(ValueKey('choose-$character')));
        final portrait = t.getRect(
            find.byKey(ValueKey('character-selection-$character-art')));
        expect(choice.contains(portrait.topLeft), true);
        expect(choice.contains(portrait.bottomRight), true);
        expect(portrait.width / portrait.height, closeTo(.75, .001));
        expect(
            t
                .widget<Image>(
                    find.byKey(ValueKey('character-selection-$character-art')))
                .fit,
            BoxFit.contain);
        expect(
            t
                .widget<Semantics>(
                    find.byKey(ValueKey('character-choice-$character')))
                .properties
                .label,
            character == 'boy' ? 'Boy' : 'Girl');
      }
      final banner =
          t.getRect(find.byKey(const ValueKey('character-selection-banner')));
      expect(banner.bottom, lessThanOrEqualTo(boy.top));
      expect(t.widget<TextField>(find.byType(TextField)).style!.color,
          const Color(0xFF63497F));
      expect(Theme.of(t.element(find.byType(TextField))).brightness,
          Brightness.light);
      expect(girl.bottom, lessThan(t.getRect(find.byType(TextField)).top));
      await capture(t, boundary, 'character_picker_${size.width.toInt()}');
      await t.tap(find.byKey(const ValueKey('choose-boy')));
      await t.pumpAndSettle();
      expect(
          t
              .widget<Semantics>(
                  find.byKey(const ValueKey('character-choice-boy')))
              .properties
              .selected,
          true);
      expect(
          t
              .widget<Semantics>(
                  find.byKey(const ValueKey('character-choice-girl')))
              .properties
              .selected,
          false);
      expect(p.studentCharacter, 'girl'); // Selecting alone does not save.
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(p.studentCharacter, 'girl');
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('large text and keyboard keep name input and save reachable',
      (t) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final p = await mount(
        t,
        MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: child!),
            home: const Scaffold(
                resizeToAvoidBottomInset: false,
                body: StudentCharacterPicker(firstSetup: true))));
    await t.ensureVisible(find.byType(TextField));
    await t.tap(find.byType(TextField));
    t.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(t.view.resetViewInsets);
    await t.pumpAndSettle();
    await t.ensureVisible(find.byType(TextField));
    await t.enterText(find.byType(TextField), 'Mia');
    await t.pump();
    expect(find.text('3/24'), findsOneWidget);
    final input = t.getRect(find.byType(TextField));
    final count =
        t.getRect(find.byKey(const ValueKey('character-selection-name-count')));
    expect(input.contains(count.topLeft), true);
    expect(input.contains(count.bottomRight), true);
    final save = t.getRect(find.byKey(const ValueKey('save-student')));
    expect(save.bottom, lessThanOrEqualTo(568 - 220));
    expect(find.byKey(const ValueKey('save-student')).hitTestable(),
        findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
