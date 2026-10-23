import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/parent_settings_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<AppProvider> open(WidgetTester t, {GlobalKey? boundary}) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'screenTimeDateV2': '2026-10-07',
      'screenTimeUsedSecondsV2': 4020,
      'screenTimeLimitEnabledV2': false,
    });
    mockProgressAudio();
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider(now: () => DateTime(2026, 10, 7, 12));
      await p.ready;
      await p.parentAuth.setup('2580', '2580');
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home:
                RepaintBoundary(key: boundary, child: const ParentScreen()))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parent-tab-2')));
    await t.pumpAndSettle();
    return p;
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(800, 1024), 1.0),
  ]) {
    testWidgets('parent garden settings fit $size at text scale $scale',
        (t) async {
      await t.binding.setSurfaceSize(size);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      final p = await open(t);
      expect(find.text('67 minutes used today'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(t.takeException(), isNull);
      for (final title in [
        'Learning & Play',
        'App Settings',
        'Parent Access',
        'Data / Reset'
      ]) {
        await t.scrollUntilVisible(find.text(title), 180,
            scrollable: find.byType(Scrollable).first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: title);
      }
      await close(t, p);
    });
  }

  testWidgets('styled settings still update preferences and guard PIN/reset',
      (t) async {
    final p = await open(t);
    Future<void> toggle(String label, {bool value = false}) async {
      final tile = find.byWidgetPredicate(
          (w) => w is ParentSettingToggle && w.title == label);
      await t.scrollUntilVisible(tile, 150,
          scrollable: find.byType(Scrollable).first);
      await t.pumpAndSettle();
      await t.runAsync(
          () async => t.widget<ParentSettingToggle>(tile).onChanged!(value));
      await t.pumpAndSettle();
    }

    await toggle('Games');
    expect(p.gameAccess, isFalse);
    await toggle('Daily Time Limit', value: true);
    expect(p.screenTime.isLimitEnabled, isTrue);
    final dropdown = find.byType(DropdownButtonFormField<int>);
    await t.ensureVisible(dropdown);
    await t.pumpAndSettle();
    await t.tap(dropdown);
    await t.pumpAndSettle();
    await t.tap(find.text('45 minutes').last);
    await t.pumpAndSettle();
    expect(p.screenTime.dailyLimitMinutes, 45);
    expect(find.text('Voice Assistance'), findsNothing);
    await t.scrollUntilVisible(find.text('Change Parent PIN'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Change Parent PIN'));
    await t.pumpAndSettle();
    await t.tap(find.text('Change Parent PIN'));
    await t.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    Navigator.of(t.element(find.byType(Dialog))).pop();
    await t.pumpAndSettle();
    await t.runAsync(() => p.addXP(12));
    await t.scrollUntilVisible(find.text('Reset Progress'), 180,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Reset Progress'));
    await t.pumpAndSettle();
    await t.tap(find.text('Reset Progress'));
    await t.pumpAndSettle();
    expect(find.text('Reset all learning progress?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(p.xp, 12);
    expect(p.screenTime.usedSecondsToday, 4020);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  if (const bool.fromEnvironment('CAPTURE_UI')) {
    testWidgets('capture parent settings reference views', (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      final boundary = GlobalKey();
      final p = await open(t, boundary: boundary);
      await t.runAsync(() async {
        await Future.wait(t
            .widgetList<Image>(find.byType(Image))
            .map((w) => precacheImage(w.image, boundary.currentContext!)));
      });
      for (final (name, title) in [
        ('time', null),
        ('app_settings', 'App Settings'),
        ('access', 'Parent Access')
      ]) {
        if (title != null) {
          await t.scrollUntilVisible(find.text(title), 160,
              scrollable: find.byType(Scrollable).first);
          await Scrollable.ensureVisible(t.element(find.text(title)),
              alignment: 0);
        }
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui_previews/parent_settings_$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await close(t, p);
    });
  }
}
