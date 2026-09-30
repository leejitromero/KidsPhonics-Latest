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
import 'letter_mastery_check_screen.dart';
import '../data/letter_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final next = p.recommendedNextPractice;
    return LearnerPage(
      title: 'KidsPhonics',
      showBack: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('BIG ADVENTURES FOR LITTLE LEARNERS',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
                color: KidsUi.muted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('Let\'s learn\nand play!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.15,
                            fontWeight: FontWeight.w900)),
                  ])),
              SizedBox(
                width: 80,
                height: 88,
                child: Stack(children: [
                  Positioned(
                      top: 0,
                      left: 0,
                      child: MascotPortrait(
                          mascot: LearningMascot.wigloo, size: 52)),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: MascotPortrait(
                          mascot: LearningMascot.boopli, size: 52)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            const Text(
                'Discover letters, explore sounds, and shine a little brighter.',
                style:
                    TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
            const SizedBox(height: 10),
            Text(
                next == null
                    ? 'All letters mastered! Choose a lesson to explore again.'
                    : 'Your next little step: Letter ${next.letter}',
                style: const TextStyle(
                    color: Color(0xFFFFE6A0),
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
                key: const ValueKey('continue-learning'),
                onPressed: () => LearnerNavigation.open(
                    context,
                    next == null
                        ? const LessonsScreen()
                        : LetterMasteryCheckScreen(
                            letter: letterContent(next.letter))),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDB75),
                    foregroundColor: const Color(0xFF39235E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                    next == null ? 'Explore Lessons' : 'Continue Learning')),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
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
            const SizedBox(height: 10),
            LinearProgressIndicator(
                value: (p.xp % 200) / 200,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: const Color(0xFFF0EAFB),
                color: const Color(0xFF8461D6)),
            const SizedBox(height: 10),
            Text('${200 - p.xp % 200} XP to the next reward level',
                style: const TextStyle(fontSize: 14, color: KidsUi.muted)),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('Choose your adventure',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('A little practice. A lot of discovery.',
            style: TextStyle(color: KidsUi.muted, fontSize: 13)),
        const SizedBox(height: 10),
        _HomeCategory(
            title: 'Lessons',
            mascot: LearningMascot.wigloo,
            description: 'Meet letters and discover their sounds.',
            icon: Icons.menu_book_rounded,
            actionLabel: 'Learn',
            onPressed: () =>
                LearnerNavigation.open(context, const LessonsScreen())),
        _HomeCategory(
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
        _HomeCategory(
            title: 'Progress',
            mascot: LearningMascot.zoplet,
            description: 'Look at how much you have learned!',
            icon: Icons.auto_graph_rounded,
            accent: const Color(0xFFB45731),
            actionLabel: 'Explore',
            onPressed: () =>
                LearnerNavigation.open(context, const ProgressScreen())),
        _HomeCategory(
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

class _HomeCategory extends StatelessWidget {
  const _HomeCategory(
      {required this.title,
      required this.description,
      required this.mascot,
      required this.icon,
      required this.onPressed,
      this.accent = const Color(0xFF7052CA),
      this.actionLabel = 'Play'});
  final String title, description, actionLabel;
  final LearningMascot mascot;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Color.lerp(Colors.white, accent, .08),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: accent.withValues(alpha: .2))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(children: [
                ExcludeSemantics(
                    child: MascotPortrait(mascot: mascot, size: 48)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(description,
                          style: const TextStyle(
                              fontSize: 12, color: KidsUi.muted)),
                    ])),
                const SizedBox(width: 6),
                Semantics(
                    label: actionLabel,
                    child: Icon(
                        onPressed == null ? icon : Icons.chevron_right_rounded,
                        color: onPressed == null ? KidsUi.muted : accent,
                        size: 24)),
              ]),
            ),
          ),
        ),
      );
}

class _Reward extends StatelessWidget {
  const _Reward({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color))),
        ]),
      );
}
