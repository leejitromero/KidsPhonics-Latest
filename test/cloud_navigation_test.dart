import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';

class _FrameBundle extends CachingAssetBundle {
  _FrameBundle({this.fail = false});
  final bool fail;
  int reads = 0;
  @override
  Future<ByteData> load(String key) async {
    if (cloudTransitionAssets.contains(key)) {
      reads++;
      if (fail) throw FlutterError('Frame unavailable');
      // The navigation tests exercise timing separately from supplied artwork.
      return ByteData.sublistView(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGN4+vn/fwAJbwPXYdp/uQAAAABJRU5ErkJggg=='));
    }
    return rootBundle.load(key);
  }
}

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('cloud curtain covers navigation and reverse at $size',
        (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final bundle = _FrameBundle();
      var actions = 0;
      Widget app() => DefaultAssetBundle(
          bundle: bundle,
          child: MaterialApp(
              home: Builder(
                  builder: (context) => Scaffold(
                      body: Center(
                          child: TextButton(
                              key: const ValueKey('open-cloud'),
                              child: const Text('Open'),
                              onPressed: () => LearnerNavigation.open(
                                  context,
                                  Scaffold(
                                      body: Center(
                                          child: TextButton(
                                              child: const Text('Destination'),
                                              onPressed: () => actions++))),
                                  cloudTransition: true)))))));
      await t.pumpWidget(app());
      final open = t
          .widget<TextButton>(find.byKey(const ValueKey('open-cloud')))
          .onPressed!;
      open();
      open();
      for (var i = 0;
          i < 100 && find.byType(CloudScreenTransition).evaluate().isEmpty;
          i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump();
      }
      expect(find.byType(CloudScreenTransition), findsOneWidget);
      expect(bundle.reads, 4);
      await t.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const ValueKey('cloud-transition')), findsOneWidget);
      expect(find.text('Destination').hitTestable(), findsNothing);
      final opacity = t.widget<Opacity>(find
          .ancestor(
              of: find.text('Destination'), matching: find.byType(Opacity))
          .first);
      expect(opacity.opacity, 0);
      await t.pump(const Duration(milliseconds: 300));
      final transition =
          t.widget<CloudScreenTransition>(find.byType(CloudScreenTransition));
      expect(transition.animation.value, closeTo(.525, .02));
      expect(find.text('Destination').hitTestable(), findsNothing);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('cloud-transition')), findsNothing);
      await t.tap(find.text('Destination'));
      expect(actions, 1);
      final route = ModalRoute.of(t.element(find.text('Destination')))!;
      expect(route, isA<CloudPageRoute<void>>());
      expect(route.transitionDuration, const Duration(milliseconds: 800));
      expect(
          route.reverseTransitionDuration, const Duration(milliseconds: 800));
      await t.binding.handlePopRoute();
      await t.pump();
      await t.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const ValueKey('cloud-transition')), findsOneWidget);
      expect(find.text('Destination').hitTestable(), findsNothing);
      await t.pumpAndSettle();
      expect(find.text('Open').hitTestable(), findsOneWidget);
      expect(find.text('Destination'), findsNothing);
      expect(t.takeException(), isNull);
      // Returning releases the navigation guard so a new tap can open again.
      await t.tap(find.text('Open'));
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  }

  for (final reduced in [true, false]) {
    testWidgets(
        reduced
            ? 'reduced motion skips the clouds and decode'
            : 'missing frames fall back to normal navigation', (t) async {
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
          t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final bundle = _FrameBundle(fail: true);
      await t.pumpWidget(DefaultAssetBundle(
          bundle: bundle,
          child: MaterialApp(
              home: Builder(
                  builder: (context) => Scaffold(
                      body: TextButton(
                          child: const Text('Open'),
                          onPressed: () => LearnerNavigation.open(context,
                              const Scaffold(body: Text('Destination')),
                              cloudTransition: true)))))));
      await t.tap(find.text('Open'));
      for (var i = 0;
          i < 20 && find.text('Destination').evaluate().isEmpty;
          i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump();
      }
      await t.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
      expect(find.byType(CloudScreenTransition), findsNothing);
      if (reduced) {
        expect(bundle.reads, 0);
        final route = ModalRoute.of(t.element(find.text('Destination')))!;
        expect(route.transitionDuration, Duration.zero);
      } else {
        expect(bundle.reads, 4);
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
