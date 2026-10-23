import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/games_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/progress_screen.dart';
import 'button_sound.dart';
import 'home_guideline_dialog.dart';
import 'scene_controls.dart';
import 'student_character_picker.dart';
import 'main_navigation_scope.dart';

/// A floating menu leaves the category content free of a fixed footer.
class CategoryNavigation extends StatelessWidget {
  const CategoryNavigation({super.key, required this.current});
  final String current;

  Future<void> _openMenu(BuildContext context) async {
    final selection = await showDialog<String>(
        context: context, builder: (_) => _CategoryMenu(current: current));
    if (!context.mounted ||
        selection == null ||
        ModalRoute.isCurrentOf(context) == false) {
      return;
    }
    final p = context.read<AppProvider>();
    if (!p.isReady) return;
    if (selection == 'profile') {
      await showDialog<void>(
          context: context, builder: (_) => const StudentCharacterPicker());
      return;
    }
    if (selection == 'guide') {
      await showDialog<void>(
          context: context,
          builder: (_) => HomeGuidelineDialog(games: current == 'games'));
      return;
    }
    if (selection == current || (selection == 'games' && !p.gameAccess)) return;
    final navigation = MainNavigationScope.maybeOf(context);
    final mainTab = switch (selection) {
      'home' => KidsDestination.home,
      'progress' => KidsDestination.progress,
      'parents' => KidsDestination.parents,
      _ => null,
    };
    if (mainTab != null && navigation != null) {
      await navigation.select(mainTab);
      return;
    }
    if (selection == 'home') {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    final page = switch (selection) {
      'lessons' => const LessonsScreen(),
      'games' => const GamesScreen(),
      'progress' => const ProgressScreen(),
      _ => const ParentScreen(),
    };
    final destination = navigation == null
        ? page
        : MainNavigationScope(controller: navigation, child: page);
    Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => destination,
            transitionDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child)));
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      key: const ValueKey('category-navigation'),
      width: 52,
      height: 52,
      child: IconButton.filled(
          key: const ValueKey('category-menu'),
          tooltip: 'Open navigation menu',
          onPressed: withButtonSound(context.watch<AppProvider>().isReady
              ? () => _openMenu(context)
              : null),
          style: IconButton.styleFrom(
              elevation: 4,
              backgroundColor: const Color(0xFFFFF5DA),
              foregroundColor: const Color(0xFF7445C7),
              side: const BorderSide(color: Color(0xFFE9AC57), width: 2)),
          icon: const Icon(Icons.menu_rounded, size: 28)));
}

class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Dialog(
        backgroundColor: const Color(0xFFFFF5DA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          tooltip: 'Close menu',
                          onPressed:
                              withButtonSound(() => Navigator.pop(context)),
                          icon: const Icon(Icons.close_rounded))),
                  LearnerProfileCard(
                      onTap: p.isReady
                          ? () => Navigator.pop(context, 'profile')
                          : null),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                      builder: (_, box) =>
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final (id, label, icon, color) in [
                              (
                                'home',
                                'Home',
                                Icons.home_rounded,
                                const Color(0xFFDB6A28)
                              ),
                              (
                                'lessons',
                                'Lessons',
                                Icons.auto_stories_rounded,
                                const Color(0xFF7445C7)
                              ),
                              (
                                'games',
                                'Games',
                                Icons.sports_esports_rounded,
                                const Color(0xFF178BD6)
                              ),
                              (
                                'progress',
                                'Progress',
                                Icons.emoji_events_rounded,
                                const Color(0xFFB87800)
                              ),
                              (
                                'parents',
                                'Parents',
                                Icons.family_restroom_rounded,
                                const Color(0xFF21866B)
                              ),
                            ])
                              SizedBox(
                                  width: (box.maxWidth - 8) / 2,
                                  child: Semantics(
                                      selected: current == id,
                                      child: OutlinedButton(
                                          key: ValueKey('category-nav-$id'),
                                          onPressed: withButtonSound(!p
                                                      .isReady ||
                                                  (id == 'games' &&
                                                      !p.gameAccess)
                                              ? null
                                              : () =>
                                                  Navigator.pop(context, id)),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: color,
                                              backgroundColor: current == id
                                                  ? color.withValues(alpha: .12)
                                                  : null,
                                              minimumSize: const Size(48, 64)),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                    id == 'games' &&
                                                            !p.gameAccess
                                                        ? Icons.lock_rounded
                                                        : icon,
                                                    size: 26),
                                                const SizedBox(height: 3),
                                                Text(label,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontFamily: 'Fredoka')),
                                              ])))),
                          ])),
                  if (current == 'lessons' || current == 'games') ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                        key: const ValueKey('category-menu-guide'),
                        onPressed: withButtonSound(
                            () => Navigator.pop(context, 'guide')),
                        icon: const Icon(Icons.help_outline_rounded),
                        label: Text(current == 'games'
                            ? 'How to play'
                            : 'How to learn')),
                  ],
                ]))));
  }
}
