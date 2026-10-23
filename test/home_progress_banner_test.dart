import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/widgets/home_progress_banner.dart';
import 'package:kidsphonics/widgets/student_character_picker.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'xp': 195,
      'stars': 9,
      'studentName': 'Mia',
      'studentCharacter': 'girl',
    });
  });

  Future<AppProvider> create(WidgetTester t, {DateTime? at}) async {
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider(now: at == null ? null : () => at);
      await p.ready;
    });
    return p;
  }

  Future<void> mount(WidgetTester t, AppProvider p,
      {GlobalKey? boundary, double textScale = 1}) async {
    await t.runAsync(() => p.ready);
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    padding: const EdgeInsets.only(top: 44, bottom: 24),
                    textScaler: TextScaler.linear(textScale)),
                child: child!),
            home: RepaintBoundary(key: boundary, child: const HomeScreen()))));
    await t.pump();
  }

  String text(WidgetTester t, String id) {
    final widget = t.widget<Text>(find.byKey(ValueKey(id)));
    return widget.data ?? widget.textSpan!.toPlainText();
  }

  test('cutouts preserve original RGB pixels and have real transparency',
      () async {
    final manifest = jsonDecode(File('tools/home_banner_extraction.json')
        .readAsStringSync()
        .replaceFirst('\ufeff', '')) as Map;
    final sourceBytes = File(manifest['source'] as String).readAsBytesSync();
    expect(sha256.convert(sourceBytes).toString().toUpperCase(),
        manifest['sourceSha256']);
    final sourceCodec = await ui.instantiateImageCodec(sourceBytes);
    final source = (await sourceCodec.getNextFrame()).image;
    final sourceRgba =
        (await source.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    for (final part in manifest['assets'] as List) {
      final bytes = File(part['asset'] as String).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      final rect = (part['sourceRect'] as List).cast<int>();
      expect(image.width, rect[2]);
      expect(image.height, rect[3]);
      final rgba =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      expect(rgba.getUint8(3), 0, reason: part['asset']);
      var opaque = 0, transparent = 0;
      for (var y = 0; y < image.height; y += 7) {
        for (var x = 0; x < image.width; x += 7) {
          final offset = (y * image.width + x) * 4;
          final alpha = rgba.getUint8(offset + 3);
          if (alpha == 0) transparent++;
          final original = ((y + rect[1]) * source.width + x + rect[0]) * 4;
          if (alpha < 240 || alpha != sourceRgba.getUint8(original + 3)) {
            continue;
          }
          opaque++;
          for (var channel = 0; channel < 3; channel++) {
            expect(rgba.getUint8(offset + channel),
                sourceRgba.getUint8(original + channel),
                reason: part['asset']);
          }
        }
      }
      expect(opaque, greaterThan(20), reason: part['asset']);
      expect(transparent, greaterThan(5), reason: part['asset']);
      image.dispose();
      codec.dispose();
    }
    source.dispose();
    sourceCodec.dispose();
  });

  testWidgets(
      'saved rewards and mastery refresh the banner and survive reopening',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final p = await create(t, at: DateTime(2026, 10, 15, 15));
    await mount(t, p, boundary: boundary);
    expect(text(t, 'home-banner-recommendation'),
        'Your next little step: Letter A');
    expect(text(t, 'home-banner-name'), 'Mia');
    expect(text(t, 'home-banner-xp'), '195 XP');
    expect(text(t, 'home-banner-stars'), '9 Stars');
    expect(text(t, 'home-banner-level'), 'Level 1');
    expect(text(t, 'home-banner-streak'), '0 Day Streak');
    expect(
        (t.widget<Image>(find.byKey(const ValueKey('home-banner-avatar'))).image
                as ResizeImage)
            .imageProvider,
        AssetImage(HomeBannerArt.portrait('girl')));

    // Four correct responses still fail if an essential skill was missed.
    await t.runAsync(() => p.completeAdventure(
        'A', [true, false, true, true, true], 'banner-a-fail'));
    await t.pump();
    expect(p.adventureProgress('A').mastered, false);
    expect(text(t, 'home-banner-recommendation'), endsWith('Letter A'));
    expect(text(t, 'home-banner-xp'), '200 XP');
    expect(text(t, 'home-banner-level'), 'Level 2');
    expect(text(t, 'home-banner-profile-level'), 'Level 2');
    expect(text(t, 'home-banner-stars'), '9 Stars');
    expect(text(t, 'home-banner-streak'), '1 Day Streak');

    await t.runAsync(
        () => p.completeAdventure('B', List.filled(5, false), 'banner-b-fail'));
    await t.pump();
    expect(text(t, 'home-banner-recommendation'), endsWith('Letter A'));
    await t.runAsync(() => p.completeAdventure(
        'A', [true, true, true, true, false], 'banner-a-pass'));
    await t.pump();
    expect(text(t, 'home-banner-recommendation'), endsWith('Letter B'));
    expect(text(t, 'home-banner-xp'), '230 XP');
    expect(text(t, 'home-banner-stars'), '10 Stars');
    final before = (
      p.xp,
      p.stars,
      p.adventureAssessments,
      p.dailyActivity.values.single.questionsAnswered,
      p.dailyActivity.values.single.activitiesCompleted
    );
    await t.runAsync(() => p.completeAdventure(
        'A', [true, true, true, true, false], 'banner-a-pass'));
    await t.pump();
    expect((
      p.xp,
      p.stars,
      p.adventureAssessments,
      p.dailyActivity.values.single.questionsAnswered,
      p.dailyActivity.values.single.activitiesCompleted
    ), before);
    await t.runAsync(() => p.setStudentCharacter('boy', 'Leo'));
    await t.pump();
    expect(text(t, 'home-banner-name'), 'Leo');
    await capture(t, boundary, 'home_banner_saved_progress');
    expect(
        (t.widget<Image>(find.byKey(const ValueKey('home-banner-avatar'))).image
                as ResizeImage)
            .imageProvider,
        AssetImage(HomeBannerArt.portrait('boy')));
    await t.pumpWidget(const SizedBox());
    p.dispose();

    final restored = await create(t, at: DateTime(2026, 10, 15, 18));
    await mount(t, restored);
    expect(text(t, 'home-banner-recommendation'), endsWith('Letter B'));
    expect(text(t, 'home-banner-name'), 'Leo');
    expect(text(t, 'home-banner-xp'), '230 XP');
    expect(text(t, 'home-banner-stars'), '10 Stars');
    expect(text(t, 'home-banner-level'), 'Level 2');
    expect(text(t, 'home-banner-streak'), '1 Day Streak');
    expect(restored.adventureAssessments, 3);
    await t.pumpWidget(const SizedBox());
    restored.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1024, 1366),
    const Size(1024, 768)
  ]) {
    for (final textScale in [1.0, 2.5]) {
      testWidgets(
          'banner, long profile and large totals fit $size at $textScale',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'voice': false,
          'xp': 9876543,
          'stars': 123456,
          'studentName': 'Alexandria Isabella Rose',
          'studentCharacter': 'girl'
        });
        final key = GlobalKey();
        final p = await create(t);
        await mount(t, p, boundary: key, textScale: textScale);
        final panel =
            t.getRect(find.byKey(const ValueKey('home-progress-banner')));
        final logo = t.getRect(find.byKey(const ValueKey('home-logo-art')));
        final student = t.getRect(find.byKey(const ValueKey('home-student')));
        expect(logo.top, greaterThanOrEqualTo(44));
        expect(panel.center.dx, closeTo(size.width / 2, .001));
        expect(panel.bottom, lessThan(student.top));
        expect(logo.bottom, lessThanOrEqualTo(panel.top + 7));
        final bounds = panel.inflate(.1);
        expect(t.getRect(find.byKey(const ValueKey('home-banner-name'))).right,
            lessThan(panel.left + panel.width * 1110 / 1235));
        for (final id in [
          'home-banner-recommendation',
          'home-banner-level',
          'home-banner-xp',
          'home-banner-stars',
          'home-banner-streak',
          'home-banner-name',
          'home-banner-avatar',
          'home-banner-profile-level'
        ]) {
          final content = t.getRect(find.byKey(ValueKey(id)));
          expect(bounds.contains(content.topLeft), true, reason: id);
          expect(bounds.contains(content.bottomRight), true, reason: id);
        }
        for (final image in t.widgetList<Image>(find.descendant(
            of: find.byType(HomeProgressBanner),
            matching: find.byType(Image)))) {
          if (image.key == const ValueKey('home-banner-avatar')) continue;
          expect(image.fit, BoxFit.contain);
        }
        if (textScale == 1 && [390.0, 768.0].contains(size.width)) {
          await capture(t, key, 'dynamic_banner_${size.width.toInt()}');
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        p.dispose();
      });
    }
  }

  testWidgets('profile section opens the existing saved character picker',
      (t) async {
    final p = await create(t);
    await mount(t, p);
    await t.tap(find.byKey(const ValueKey('home-banner-profile')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    expect(find.byType(StudentCharacterPicker), findsOneWidget);
    expect(p.studentCharacter, 'girl');
    expect(p.studentName, 'Mia');
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });

  testWidgets(
      'all mastered letters show review without inventing another letter',
      (t) async {
    final p = await create(t);
    await t.runAsync(() async {
      await p.ready;
      for (var i = 65; i <= 90; i++) {
        await p.completeAdventure(
            String.fromCharCode(i), List.filled(5, true), 'banner-all-$i');
      }
    });
    await mount(t, p);
    expect(p.recommendedAdventureLetter, isNull);
    expect(text(t, 'home-banner-recommendation'),
        'Your next little step: Review letters');
    await t.pumpWidget(const SizedBox());
    p.dispose();
  });
}
