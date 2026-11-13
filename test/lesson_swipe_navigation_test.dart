import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/lesson_swipe_navigation.dart';

void main() {
  const surface = ValueKey('swipe-surface');
  Widget page(
          {VoidCallback? next,
          VoidCallback? previous,
          Widget? child,
          Object index = 0,
          bool enabled = true}) =>
      MaterialApp(
        home: Scaffold(
            body: LessonSwipeNavigation(
          navigationKey: index,
          enabled: enabled,
          onNext: next,
          onPrevious: previous,
          child: SizedBox.expand(
              key: surface,
              child: ColoredBox(color: Colors.transparent, child: child)),
        )),
      );

  testWidgets('a long swipe advances once on release; right swipe goes back',
      (t) async {
    var next = 0, previous = 0;
    await t.pumpWidget(page(next: () => next++, previous: () => previous++));
    final pointer = await t.startGesture(const Offset(600, 250));
    for (var i = 0; i < 6; i++) {
      await pointer.moveBy(const Offset(-60, 0));
      await t.pump();
      expect(next, 0);
    }
    await pointer.up();
    await t.pump();
    expect(next, 1);
    await t.drag(find.byKey(surface), const Offset(220, 0));
    expect(previous, 1);
  });

  testWidgets(
      'taps, short horizontal movements and vertical scroll do not navigate',
      (t) async {
    var calls = 0;
    final scroll = ScrollController();
    await t.pumpWidget(page(
        next: () => calls++,
        previous: () => calls++,
        child: SingleChildScrollView(
            controller: scroll,
            child: const SizedBox(height: 2000, width: double.infinity))));
    await t.tap(find.byKey(surface));
    await t.drag(find.byKey(surface), const Offset(-40, 0));
    await t.drag(find.byKey(surface), const Offset(8, -220));
    await t.pumpAndSettle();
    expect(calls, 0);
    expect(scroll.offset, greaterThan(0));
    await t.pumpWidget(const SizedBox());
    scroll.dispose();
  });

  testWidgets('disabled directions remain unavailable at a lesson boundary',
      (t) async {
    var next = 0;
    await t.pumpWidget(page(next: () => next++));
    await t.drag(find.byKey(surface), const Offset(220, 0));
    expect(next, 0);
    await t.drag(find.byKey(surface), const Offset(-220, 0));
    expect(next, 1);
    await t.pumpWidget(page());
    await t.drag(find.byKey(surface), const Offset(-220, 0));
    expect(next, 1);
  });

  for (final interruption in [
    'page change',
    'disabled',
    'ticker',
    'background',
    'dialog'
  ]) {
    testWidgets(
        '$interruption cancels an unfinished swipe even after restoring the page',
        (t) async {
      var calls = 0, index = 0;
      var enabled = true, ticking = true;
      final updates = ValueNotifier(0);
      late BuildContext routeContext;
      await t.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        routeContext = context;
        return ValueListenableBuilder<int>(
            valueListenable: updates,
            builder: (_, __, ___) => TickerMode(
                enabled: ticking,
                child: LessonSwipeNavigation(
                    navigationKey: index,
                    enabled: enabled,
                    onNext: () => calls++,
                    child: const SizedBox.expand(
                        key: surface,
                        child: ColoredBox(color: Colors.transparent)))));
      })));
      final pointer = await t.startGesture(const Offset(600, 250));
      await pointer.moveBy(const Offset(-220, 0));
      await t.pump();
      if (interruption == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      } else if (interruption == 'dialog') {
        showDialog<void>(
            context: routeContext,
            builder: (_) => const AlertDialog(title: Text('Covered')));
        await t.pumpAndSettle();
        Navigator.pop(routeContext);
        await t.pumpAndSettle();
      } else {
        if (interruption == 'page change') index++;
        if (interruption == 'disabled') enabled = false;
        if (interruption == 'ticker') ticking = false;
        updates.value++;
        await t.pump();
        enabled = ticking = true;
        updates.value++;
        await t.pump();
      }
      await pointer.up();
      await t.pump();
      expect(calls, 0);
      await t.drag(find.byKey(surface), const Offset(-220, 0));
      expect(calls, 1);
      await t.pumpWidget(const SizedBox());
      updates.dispose();
    });
  }

  testWidgets('dragging a child piece to its target does not navigate',
      (t) async {
    var next = 0, accepted = 0;
    await t.pumpWidget(page(
        next: () => next++,
        child: Row(children: [
          const Draggable<int>(
              data: 1,
              feedback: SizedBox(width: 60, height: 60),
              child: SizedBox(
                  key: ValueKey('piece'),
                  width: 80,
                  height: 80,
                  child: ColoredBox(color: Colors.blue))),
          const Spacer(),
          DragTarget<int>(
              onAcceptWithDetails: (_) => accepted++,
              builder: (_, __, ___) => const SizedBox(
                  key: ValueKey('target'), width: 100, height: 100)),
        ])));
    await t.dragFrom(
        t.getCenter(find.byKey(const ValueKey('piece'))),
        t.getCenter(find.byKey(const ValueKey('target'))) -
            t.getCenter(find.byKey(const ValueKey('piece'))));
    await t.pump();
    expect(accepted, 1);
    expect(next, 0);
  });
}
