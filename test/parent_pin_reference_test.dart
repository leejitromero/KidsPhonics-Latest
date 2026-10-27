import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/parent_pin_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'musicEnabled': false,
      'xp': 215,
      'stars': 7,
      'studentName': 'Sam'
    });
  });

  Future<AppProvider> open(WidgetTester t,
      {required bool setup,
      required Size size,
      double scale = 1,
      GlobalKey? boundary}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
      t.view.resetViewInsets();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
      if (!setup) {
        await p.parentAuth.setup('2580', '2580');
        p.parentAuth.endSession();
      }
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(top: 24, bottom: 24)),
                child: child!),
            home:
                RepaintBoundary(key: boundary, child: const ParentScreen()))));
    await t.pumpAndSettle();
    return p;
  }

  Future<void> finish(WidgetTester t, AppProvider p) async {
    await t.pumpWidget(const SizedBox());
    await t.pump();
    p.dispose();
  }

  Future<void> reveal(WidgetTester t, Finder target) async {
    await Scrollable.ensureVisible(t.element(target), alignment: .5);
    await t.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
    expect(t.takeException(), isNull);
  }

  Future<void> capture(WidgetTester t, GlobalKey boundary, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await t.runAsync(() async {
      await Future.wait(t
          .widgetList<Image>(find.byType(Image))
          .map((w) => precacheImage(w.image, boundary.currentContext!)));
    });
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/ui_previews/parent_pin_$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('both 3D lock assets have actual transparent corners', () async {
    for (final asset in [parentPinAccessArt, parentPinSetupArt]) {
      final codec =
          await ui.instantiateImageCodec(File(asset).readAsBytesSync());
      final image = (await codec.getNextFrame()).image;
      final pixels =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      expect(pixels.getUint8(3), 0, reason: asset);
      expect(image.width, greaterThanOrEqualTo(512));
      expect(image.height, greaterThanOrEqualTo(512));
      image.dispose();
      codec.dispose();
    }
  });

  for (final setup in [true, false]) {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(430, 932), 1.0),
      (const Size(768, 1024), 1.0),
      (const Size(844, 390), 1.0),
      (const Size(320, 568), 2.0),
    ]) {
      testWidgets(
          '${setup ? 'PIN setup' : 'Parent access'} fits $size at text $scale',
          (t) async {
        final boundary = GlobalKey();
        final p = await open(t,
            setup: setup, size: size, scale: scale, boundary: boundary);
        expect(find.text(setup ? 'Set Up Parent PIN' : 'Parent Access'),
            findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(setup ? 2 : 1));
        expect(find.byType(ParentPinPanel), findsOneWidget);
        expect(find.byIcon(Icons.eco_rounded), findsNothing);
        expect(t.takeException(), isNull);
        if (scale == 1 && [390.0, 768.0].contains(size.width)) {
          await capture(t, boundary,
              '${setup ? 'setup' : 'access'}_${size.width.toInt()}');
        }
        final fields = find.byType(TextField);
        for (var i = 0; i < (setup ? 2 : 1); i++) {
          await reveal(t, fields.at(i));
          expect(t.widget<TextField>(fields.at(i)).obscureText, true);
        }
        final submit =
            find.widgetWithText(ElevatedButton, setup ? 'Set PIN' : 'Unlock');
        await reveal(t, submit);
        final rect = t.getRect(submit);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48 - .01));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom,
            lessThanOrEqualTo(t.getRect(find.byType(KidsNavigationBar)).top));
        await reveal(t, find.widgetWithText(TextButton, 'Back'));
        expect(p.parentAuth.isAuthenticated, false);
        expect((p.xp, p.stars, p.studentName), (215, 7, 'Sam'));
        await finish(t, p);
      });
    }
  }

  testWidgets(
      'setup fields mask independently and stay usable with keyboard open',
      (t) async {
    final p = await open(t, setup: true, size: const Size(390, 844));
    final first = find.byKey(const ValueKey('parent-pin'));
    final confirm = find.byKey(const ValueKey('parent-pin-confirm'));
    await reveal(t, first);
    await t.enterText(first, 'a25b80c9');
    expect(t.widget<TextField>(first).controller!.text, '2580');
    await reveal(t, find.byTooltip('Show PIN').first);
    await t.tap(find.byTooltip('Show PIN').first);
    await t.pumpAndSettle();
    expect(t.widget<TextField>(first).obscureText, false);
    expect(t.widget<TextField>(confirm).obscureText, true);
    await reveal(t, confirm);
    await t.showKeyboard(confirm);
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.pumpAndSettle();
    await reveal(t, confirm);
    await t.enterText(confirm, '2581');
    final submit = find.widgetWithText(ElevatedButton, 'Set PIN');
    await reveal(t, submit);
    await t.tap(submit);
    await t.pumpAndSettle();
    expect(find.text('PINs do not match.'), findsOneWidget);
    expect(t.widget<TextField>(first).controller!.text, '');
    expect(t.widget<TextField>(confirm).controller!.text, '');
    expect(t.widget<TextField>(first).obscureText, true);
    expect(p.parentAuth.isAuthenticated, false);
    expect(t.takeException(), isNull);
    await finish(t, p);
  });

  for (final setup in [true, false]) {
    for (final (size, keyboard, scale) in [
      (const Size(390, 844), 340.0, 1.0),
      (const Size(320, 568), 250.0, 1.0),
      (const Size(320, 568), 250.0, 2.0),
      (const Size(768, 1024), 400.0, 1.0),
    ]) {
      testWidgets(
          '${setup ? 'setup' : 'access'} keeps its frame while scrolling above keyboard $size x$scale',
          (t) async {
        final boundary = GlobalKey();
        final p = await open(t,
            setup: setup, size: size, scale: scale, boundary: boundary);
        final field =
            find.byKey(ValueKey(setup ? 'parent-pin-confirm' : 'parent-pin'));
        await reveal(t, field);
        await t.showKeyboard(field);
        t.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await t.pumpAndSettle();
        final panel = find.byKey(const ValueKey('parent-pin-frame'));
        final originalFrame = t.getRect(panel);
        final contentBottom = t
            .getRect(find.byKey(const ValueKey('room-parents-content')))
            .bottom;
        expect(
            contentBottom,
            inInclusiveRange(
                size.height - keyboard - 40, size.height - keyboard));
        expect(originalFrame.top, greaterThanOrEqualTo(24));
        expect(originalFrame.bottom, lessThanOrEqualTo(size.height - keyboard));
        expect(find.byType(KidsNavigationBar), findsNothing);
        expect(
            t.widget<ParentPinHeading>(find.byType(ParentPinHeading)).compact,
            isTrue);
        for (final target in [
          field,
          find.widgetWithText(ElevatedButton, setup ? 'Set PIN' : 'Unlock'),
          find.widgetWithText(TextButton, 'Back'),
          find.byKey(const ValueKey('parent-pin')),
        ]) {
          await reveal(t, target);
          final rect = t.getRect(target);
          expect(originalFrame.contains(rect.topLeft), isTrue);
          expect(originalFrame.contains(rect.bottomRight), isTrue);
          expect(t.getRect(panel).top, closeTo(originalFrame.top, .1));
          expect(t.getRect(panel).bottom, closeTo(originalFrame.bottom, .1));
        }
        if (size.width == 390 && setup) {
          await reveal(t, find.widgetWithText(TextButton, 'Back'));
          final viewport = t
              .getRect(find.byKey(const ValueKey('parent-pin-content-scroll')));
          final heading = t.getRect(find.byType(ParentPinHeading));
          expect(viewport.contains(heading.topLeft), isTrue);
          expect(viewport.contains(heading.bottomRight), isTrue);
          await capture(t, boundary, 'setup_keyboard_scrolled');
        }
        t.view.resetViewInsets();
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        expect(find.byType(KidsNavigationBar), findsOneWidget);
        expect(t.takeException(), isNull);
        await finish(t, p);
      });
    }
  }
}
