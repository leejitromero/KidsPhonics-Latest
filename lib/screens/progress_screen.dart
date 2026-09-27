import '../widgets/learner_widgets.dart';
import '../widgets/mascot_guide.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/learning_progress_widgets.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/shared_widgets.dart';
import 'lessons_screen.dart';
import 'games_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF43264A),
                  Color(0xFF502D26),
                  Color(0xFF302044)
                ],
              ),
            ),
            child: Column(children: [
              KidsHeader(
                  title: 'Your Progress',
                  gradient: const LinearGradient(
                      colors: [Color(0xFF99501B), Color(0xFF713425)]),
                  textColor: AppColors.textLight,
                  onBack: () => Navigator.pop(context)),
              Expanded(
                  child: Center(
                      child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: const [
                      _ZopletWelcome(),
                      DashboardSection(
                          title: 'Learning Progress',
                          child: LearningProgressSummary(detailed: false)),
                      DashboardSection(
                          title: 'Recommended Next',
                          child: RecommendedPractice()),
                      DashboardSection(
                          title: 'Your Letters', child: LetterProgressGrid()),
                      DashboardSection(
                          title: 'Rewards',
                          child: RewardsSummary(showAchievements: true)),
                      DashboardSection(
                          title: 'Activity', child: LearningStreak()),
                      Text('Your progress is saved on this device.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ]),
              ))),
              SafeArea(
                  top: false,
                  child: KidsBottomNav(
                      currentIndex: 3,
                      onTap: (i) {
                        if (!context.mounted ||
                            ModalRoute.of(context)?.isCurrent != true) {
                          return;
                        }
                        if (i == 0) Navigator.pop(context);
                        if (i == 1) {
                          LearnerNavigation.open(context, const LessonsScreen(),
                              replace: true);
                        }
                        if (i == 2) {
                          LearnerNavigation.open(context, const GamesScreen(),
                              replace: true);
                        }
                      })),
            ])),
      );
}

class _ZopletWelcome extends StatelessWidget {
  const _ZopletWelcome();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3CB), Color(0xFFFFCE87)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFFFDC87), width: 2),
        ),
        child: const Column(children: [
          Text('Every step is progress!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF62351D),
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          SizedBox(height: 12),
          MascotPortrait(mascot: LearningMascot.zoplet, size: 160),
          SizedBox(height: 8),
          Text('Walk with Zoplet',
              style: TextStyle(
                  color: Color(0xFF62351D),
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Look at what you have learned, one little step at a time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF62351D), fontSize: 17, height: 1.4)),
        ]),
      );
}
