import 'package:flutter/material.dart';

import 'category_navigation.dart';
import 'day_cycle_background.dart';
import 'kids_navigation_bar.dart';
import 'main_navigation_scope.dart';
import 'main_navigation_shell.dart';

enum SchoolRoom {
  lessons('Lessons', 'lesson'),
  games('Games', 'games'),
  progress('Progress', 'progress'),
  parents('Parents', 'parent');

  const SchoolRoom(this.title, this.category);
  final String title, category;
  String get asset => DayCycleBackground.framesFor(category).first;
}

class SchoolRoomBody extends StatelessWidget {
  const SchoolRoomBody(
      {super.key,
      required this.room,
      required this.child,
      this.navigationOnRoute = false,
      this.navigationDestination});
  final SchoolRoom room;
  final Widget child;
  final KidsDestination? navigationDestination;
  final bool navigationOnRoute;

  @override
  Widget build(BuildContext context) {
    final section = navigationDestination ??
        switch (room) {
          SchoolRoom.progress => KidsDestination.progress,
          SchoolRoom.parents => KidsDestination.parents,
          _ => null,
        };
    final media = MediaQuery.of(context);
    final footer = section == null
        ? 0.0
        : KidsNavigationGeometry.reservedHeight(media.size, media.padding);
    final navigation = MainNavigationScope.maybeOf(context);
    return Stack(fit: StackFit.expand, children: [
      DayCycleBackground(
          key: ValueKey('room-${room.name}-background'),
          fit: navigationOnRoute &&
                  (room == SchoolRoom.lessons || room == SchoolRoom.games)
              ? BoxFit.cover
              : null,
          category: room.category),
      SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, footer),
                      child: Padding(
                          key: ValueKey('room-${room.name}-content'),
                          padding: EdgeInsets.zero,
                          child: child))))),
      if (section != null && (navigation == null || navigationOnRoute))
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KidsNavigationBar(
                current: section,
                onSelected: (tab) => navigateKidsTab(context, tab))),
      if (section == null)
        Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(child: CategoryNavigation(current: room.name))),
    ]);
  }
}
