import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/adventure_background.dart';
import '../widgets/home_flight_menu.dart';
import '../widgets/learner_widgets.dart';
import 'games_screen.dart';
import 'lessons_screen.dart';
import 'parent_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final next = p.recommendedNextPractice;
    return Theme(
        data: KidsUi.theme,
        child: Scaffold(
          body: AdventureBackground(
              child: SafeArea(
                  child: LayoutBuilder(
            builder: (_, box) => SingleChildScrollView(
              child: Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeFlightMenu(
                          onLessons: () => LearnerNavigation.open(
                              context, const LessonsScreen()),
                          onGames: p.gameAccess
                              ? () => LearnerNavigation.open(
                                  context, const GamesScreen())
                              : null,
                          onProgress: () => LearnerNavigation.open(
                              context, const ProgressScreen()),
                          onParents: () => LearnerNavigation.open(
                              context, const ParentScreen())),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.auto_awesome_rounded,
                                        size: 22,
                                        color: Color(0xFF9E5300),
                                        shadows: _letteringShadows),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            next == null
                                                ? 'All letters mastered! Choose a lesson to explore again.'
                                                : 'Your next little step: Letter ${next.letter}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF582AA5),
                                                shadows: _letteringShadows))),
                                  ]),
                                  const SizedBox(height: 12),
                                  Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 14,
                                      runSpacing: 6,
                                      children: [
                                        _Reward(
                                            icon: Icons.emoji_events_rounded,
                                            color: const Color(0xFF8D4900),
                                            label: 'Level ${p.level}'),
                                        _Reward(
                                            icon: Icons.bolt_rounded,
                                            color: const Color(0xFF582AA5),
                                            label: '${p.xp} XP'),
                                        _Reward(
                                            icon: Icons.star_rounded,
                                            color: const Color(0xFF155B85),
                                            label: '${p.stars} Stars'),
                                        _Reward(
                                            icon: Icons
                                                .local_fire_department_rounded,
                                            color: const Color(0xFFA23734),
                                            label: '${p.streak} Day Streak'),
                                      ]),
                                ]),
                          )),
                    ]),
              )),
            ),
          ))),
        ));
  }
}

// A light outline keeps lettering readable over every frame of the sky.
const _letteringShadows = [
  Shadow(color: Colors.white, offset: Offset(-1.5, -1.5)),
  Shadow(color: Colors.white, offset: Offset(0, -1.5)),
  Shadow(color: Colors.white, offset: Offset(1.5, -1.5)),
  Shadow(color: Colors.white, offset: Offset(-1.5, 0)),
  Shadow(color: Colors.white, offset: Offset(1.5, 0)),
  Shadow(color: Colors.white, offset: Offset(-1.5, 1.5)),
  Shadow(color: Colors.white, offset: Offset(0, 1.5)),
  Shadow(color: Colors.white, offset: Offset(1.5, 1.5)),
  Shadow(color: Color(0x887650AB), offset: Offset(0, 3), blurRadius: 3),
];

class _Reward extends StatelessWidget {
  const _Reward({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 19, color: color, shadows: _letteringShadows),
        const SizedBox(width: 4),
        Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w900,
                    shadows: _letteringShadows))),
      ]);
}
