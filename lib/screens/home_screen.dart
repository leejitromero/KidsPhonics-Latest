import '../widgets/mascot_guide.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/learner_widgets.dart';
import 'lessons_screen.dart';
import 'games_screen.dart';
import 'parent_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return LearnerPage(
      title: 'KidsPhonics',
      showBack: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('BIG ADVENTURES FOR LITTLE LEARNERS',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: KidsUi.muted)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7543CD),
                  Color(0xFF5145AF),
                  Color(0xFF196F83)
                ]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF7052CA).withValues(alpha: .22),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Hello, superstar!',
                        style: TextStyle(
                            color: Color(0xFFFFE6A0),
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('Let\'s learn\nand play!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.15,
                            fontWeight: FontWeight.w900)),
                  ])),
              SizedBox(
                width: 116,
                height: 136,
                child: Stack(children: [
                  Positioned(
                      top: 0,
                      left: 0,
                      child: MascotPortrait(
                          mascot: LearningMascot.wigloo, size: 78)),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: MascotPortrait(
                          mascot: LearningMascot.boopli, size: 78)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            const Text(
                'Discover letters, explore sounds, and shine a little brighter.',
                style:
                    TextStyle(color: Colors.white, fontSize: 17, height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                onPressed: () =>
                    LearnerNavigation.open(context, const LessonsScreen()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDB75),
                    foregroundColor: const Color(0xFF39235E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Learning')),
          ]),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8DE), Color(0xFFFFEACD)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF2CE84), width: 2)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Your Rewards',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _Reward(
                  icon: Icons.emoji_events_rounded,
                  label: 'Level ${p.level}',
                  color: const Color(0xFF7052CA)),
              _Reward(
                  icon: Icons.bolt_rounded,
                  label: '${p.xp} XP',
                  color: const Color(0xFF167769)),
              _Reward(
                  icon: Icons.star_rounded,
                  label: '${p.stars} Stars',
                  color: const Color(0xFF936015)),
              _Reward(
                  icon: Icons.local_fire_department_rounded,
                  label: '${p.streak} Day Streak',
                  color: const Color(0xFFBB4C37)),
            ]),
            const SizedBox(height: 18),
            LinearProgressIndicator(
                value: (p.xp % 200) / 200,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: const Color(0xFFF0EAFB),
                color: const Color(0xFF8461D6)),
            const SizedBox(height: 10),
            Text('${200 - p.xp % 200} XP to the next reward level',
                style: const TextStyle(fontSize: 14, color: KidsUi.muted)),
          ]),
        ),
        const SizedBox(height: 28),
        const Text('Choose your adventure',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('A little practice. A lot of discovery.',
            style: TextStyle(color: KidsUi.muted, fontSize: 16)),
        const SizedBox(height: 18),
        LearnerActivityCard(
            title: 'Lessons',
            mascot: LearningMascot.wigloo,
            description: 'Meet letters and discover their sounds.',
            icon: Icons.menu_book_rounded,
            actionLabel: 'Learn',
            onPressed: () =>
                LearnerNavigation.open(context, const LessonsScreen())),
        LearnerActivityCard(
            title: 'Game Zone',
            mascot: LearningMascot.boopli,
            description: p.gameAccess
                ? 'Play, practice, and collect happy wins!'
                : 'Games are turned off by a parent.',
            icon: p.gameAccess
                ? Icons.sports_esports_rounded
                : Icons.lock_outline,
            accent: const Color(0xFF167769),
            onPressed: p.gameAccess
                ? () => LearnerNavigation.open(context, const GamesScreen())
                : null),
        LearnerActivityCard(
            title: 'Progress',
            mascot: LearningMascot.zoplet,
            description: 'Look at how much you have learned!',
            icon: Icons.auto_graph_rounded,
            accent: const Color(0xFFB45731),
            actionLabel: 'Explore',
            onPressed: () =>
                LearnerNavigation.open(context, const ProgressScreen())),
        LearnerActivityCard(
            title: 'Parents',
            mascot: LearningMascot.jitjit,
            description: 'Controls and learning goals.',
            icon: Icons.family_restroom_rounded,
            accent: const Color(0xFF3D681E),
            actionLabel: 'View',
            onPressed: () =>
                LearnerNavigation.open(context, const ParentScreen())),
      ]),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 6),
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color))),
        ]),
      );
}
