import 'progress_design.dart';
import 'overall_mastery_panel.dart';
import 'quick_check_recommendation.dart';
import 'mastery_illustration.dart';
import 'progress_collection_design.dart';
import 'button_sound.dart';
import 'package:flutter/material.dart';
import 'adventure_background.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../screens/games_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/letter_mastery_check_screen.dart';
import '../theme/kids_ui.dart';
import 'learner_widgets.dart';
import 'learning_progress_widgets.dart';

const _purple = progressPurple;
const _teal = progressGreen;

class ProgressJourneyView extends StatefulWidget {
  const ProgressJourneyView({super.key});
  @override
  State<ProgressJourneyView> createState() => _ProgressJourneyViewState();
}

class _ProgressJourneyViewState extends State<ProgressJourneyView> {
  int _tab = 0;
  LearningStatus? _filter;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _selectTab(int value) {
    setState(() => _tab = value);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _practice(String letter) {
    LearnerNavigation.open(
        context, LetterMasteryCheckScreen(letter: letterContent(letter)),
        cloudTransition: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Theme(
      data: KidsUi.theme.copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 18),
          ),
        ),
      ),
      child: Builder(
          builder: (themedContext) => Scaffold(
                backgroundColor: const Color(0xFFF4F0FF),
                body: AdventureBackground(
                  child: SafeArea(
                    top: true,
                    child: Center(
                        child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(children: [
                        const ProgressHeader(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (index, title, icon, color) in [
                                  (
                                    0,
                                    'My Journey',
                                    Icons.map_rounded,
                                    const Color(0xFFFFCB39)
                                  ),
                                  (
                                    1,
                                    'My Letters',
                                    Icons.abc_rounded,
                                    const Color(0xFF16A8E9)
                                  ),
                                  (
                                    2,
                                    'My Rewards',
                                    Icons.star_rounded,
                                    const Color(0xFFFFBE19)
                                  ),
                                ]) ...[
                                  if (index > 0) const SizedBox(width: 8),
                                  Expanded(
                                      child: Semantics(
                                          selected: _tab == index,
                                          child: DecoratedBox(
                                              decoration: _tab == index
                                                  ? progressGloss(_purple)
                                                  : progressGloss(
                                                      const Color(0xFFFFFAF0)),
                                              child: TextButton(
                                                key: ValueKey(
                                                    'progress-tab-$index'),
                                                onPressed: withButtonSound(
                                                    () => _selectTab(index)),
                                                style: TextButton.styleFrom(
                                                    foregroundColor: _tab ==
                                                            index
                                                        ? Colors.white
                                                        : progressInk,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 3,
                                                        vertical: 6),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        24))),
                                                child: Column(children: [
                                                  if (index == 1)
                                                    Image.asset(
                                                        'assets/images/lesson_logos/letter_recognition.webp',
                                                        width: 28,
                                                        height: 24,
                                                        excludeFromSemantics:
                                                            true)
                                                  else
                                                    Icon(icon,
                                                        size: 24,
                                                        color: color,
                                                        shadows: const [
                                                          Shadow(
                                                              color: Color(
                                                                  0x44725116),
                                                              offset:
                                                                  Offset(0, 2),
                                                              blurRadius: 2)
                                                        ]),
                                                  const SizedBox(height: 2),
                                                  Text(title,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w900)),
                                                ]),
                                              )))),
                                ],
                              ]),
                        ),
                        Expanded(
                            child: ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 16),
                          children: [
                            ...switch (_tab) {
                              1 => _letters(p, themedContext),
                              2 => _rewards(p, themedContext),
                              _ => _journey(p),
                            },
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                  'Your progress is saved on this device.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: KidsUi.muted)),
                            ),
                          ],
                        )),
                      ]),
                    )),
                  ),
                ),
                bottomNavigationBar: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: NavigationBar(
                      selectedIndex: 3,
                      labelTextStyle: WidgetStateProperty.resolveWith(
                          (states) => TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: states.contains(WidgetState.selected)
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: states.contains(WidgetState.selected)
                                  ? _purple
                                  : const Color(0xFF55505C))),
                      backgroundColor: Colors.white,
                      indicatorColor: const Color(0xFFE6DDFB),
                      onDestinationSelected: withSelectionSound((index) {
                        if (ModalRoute.of(context)?.isCurrent != true ||
                            index == 3) {
                          return;
                        }
                        if (index == 0) {
                          Navigator.maybePop(context);
                        } else {
                          LearnerNavigation.open(
                              context,
                              index == 1
                                  ? const LessonsScreen()
                                  : const GamesScreen(),
                              replace: true);
                        }
                      }),
                      destinations: const [
                        NavigationDestination(
                            icon: Icon(Icons.home_rounded), label: 'Home'),
                        NavigationDestination(
                            icon: Icon(Icons.menu_book_rounded),
                            label: 'Lessons'),
                        NavigationDestination(
                            icon: Icon(Icons.sports_esports_rounded),
                            label: 'Games'),
                        NavigationDestination(
                            icon: Icon(Icons.bar_chart_rounded),
                            selectedIcon:
                                Icon(Icons.bar_chart_rounded, color: _purple),
                            label: 'Progress'),
                      ],
                    )),
              )),
    );
  }

  List<Widget> _journey(AppProvider p) {
    return [
      const QuickCheckRecommendation(),
      const SizedBox(height: 8),
      const OverallMasteryPanel(dense: true),
      const ProgressGrowthIllustration(),
      ProgressMasteryCard(
          letters: p.quickCheckLetters,
          title: 'My alphabet',
          color: _purple,
          icon: Icons.menu_book_rounded,
          onOpen: () => _selectTab(1)),
      ProgressMasteryCard(
          letters: p.quickCheckLetters
              .where((l) => 'AEIOU'.contains(l.letter))
              .toList(),
          title: 'Vowel Adventures',
          color: _teal,
          icon: Icons.star_rounded,
          vowels: true,
          onOpen: () => _selectTab(1)),
      LayoutBuilder(builder: (_, box) {
        final practice = _card(
            tint: const Color(0xFFFFF5DF),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ProgressHeading('Practice', Icons.edit_rounded,
                  color: Color(0xFFE8A421)),
              const SizedBox(height: 6),
              _badge(
                  Icons.menu_book_rounded,
                  '${p.quickCheckStatusCount(LearningStatus.practiced)} practiced',
                  const Color(0xFFBE540E)),
              const SizedBox(height: 5),
              _badge(
                  Icons.visibility_rounded,
                  '${p.quickCheckStatusCount(LearningStatus.viewed)} explored',
                  const Color(0xFF167BDC)),
            ]));
        final streak = _card(
            tint: const Color(0xFFFFEFF1),
            child: Column(children: [
              const ProgressHeading(
                  'My streak', Icons.local_fire_department_rounded,
                  color: Color(0xFFE95666)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 26, color: Color(0xFFFF7131)),
                const SizedBox(width: 5),
                Text('${p.streak}',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD92942))),
              ]),
              Text('${p.streak}-day learning streak',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: KidsUi.muted)),
              const SizedBox(height: 4),
              const Text('Practice a little each day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: KidsUi.muted)),
            ]));
        if (box.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(16) > 21) {
          return Column(children: [
            SizedBox(width: double.infinity, child: practice),
            SizedBox(width: double.infinity, child: streak)
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: practice),
          const SizedBox(width: 8),
          Expanded(child: streak),
        ]);
      }),
    ];
  }

  List<Widget> _letters(AppProvider p, BuildContext themedContext) {
    final letters = p.quickCheckLetters
        .where((l) => _filter == null || l.status == _filter)
        .toList();
    return [
      const OverallMasteryPanel(showLetters: true, dense: true),
      ProgressCollectionHeader(
          letters: p.quickCheckLetters,
          selected: _filter,
          onSelected: (status) => setState(() => _filter = status)),
      if (letters.isEmpty)
        _card(
            child: const Column(children: [
          Icon(Icons.explore_outlined, size: 30, color: _purple),
          SizedBox(height: 6),
          Text('No letters here yet.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Tap All 26 to choose your next letter.',
              textAlign: TextAlign.center),
        ]))
      else
        LayoutBuilder(builder: (_, box) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final count = (box.maxWidth / (80 * scale)).floor().clamp(2, 8);
          return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
              children: [
                for (final letter in letters)
                  ProgressLetterTile(
                      letter: letter,
                      onPressed: () => _letterDetail(themedContext, letter))
              ]);
        }),
    ];
  }

  void _letterDetail(BuildContext sheetContext, LetterProgress letter) {
    showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Letter ${letter.letter}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _purple)),
                  const SizedBox(height: 10),
                  Center(
                      child: _badge(
                          letter.status.icon,
                          _statusName(letter.status),
                          _statusColor(letter.status))),
                  const SizedBox(height: 12),
                  _detailRow(Icons.check_circle_outline, 'Correct answers',
                      '${letter.correctAnswers} / ${letter.attempts}'),
                  _detailRow(
                      Icons.flag_outlined,
                      'Best Quick Check',
                      letter.completedAssessments == 0
                          ? 'Not tried yet'
                          : '${letter.bestAssessmentScore} / 5'),
                  _detailRow(
                      Icons.auto_graph_rounded,
                      'Latest Quick Check accuracy',
                      accuracyLabel(letter.accuracy)),
                  _detailRow(Icons.abc_rounded, 'Letter recordings heard',
                      '${letter.nameListens}'),
                  _detailRow(Icons.hearing_rounded, 'Sound recordings heard',
                      '${letter.soundListens}'),
                  _detailRow(Icons.image_rounded, 'Word recordings heard',
                      '${letter.wordListens}'),
                  const Text(
                      'Listening counts show practice, not sound mastery. Quick Check covers letters and words.',
                      style: TextStyle(color: KidsUi.muted)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('progress-practice-letter'),
                    onPressed: withButtonSound(() {
                      Navigator.pop(ctx);
                      _practice(letter.letter);
                    }),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Practice ${letter.letter}'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  ),
                  TextButton(
                      onPressed: withButtonSound(() => Navigator.pop(ctx)),
                      child: const Text('Back to my letters')),
                ]),
          )),
    );
  }

  List<Widget> _rewards(AppProvider p, BuildContext themedContext) => [
        const OverallMasteryPanel(showAchievements: true, dense: true),
        ProgressTreasureShelf(level: p.level, stars: p.stars, xp: p.xp),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text(
                'My Badges \u00b7 ${p.quickCheckAchievements.where((a) => a.unlocked).length} / ${p.quickCheckAchievements.length}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: progressInk,
                    shadows: [
                      Shadow(
                          color: Colors.white,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ]))),
        for (final badge in p.quickCheckAchievements)
          ProgressAchievementCard(
              achievement: badge,
              onPressed: () => showDialog<void>(
                  context: themedContext,
                  builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFFFFFEF5),
                          title: Text(badge.title,
                              style: const TextStyle(
                                  color: progressInk,
                                  fontWeight: FontWeight.w900)),
                          content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(badge.description),
                                const SizedBox(height: 12),
                                Text(
                                    badge.unlocked
                                        ? 'You earned it!'
                                        : 'Keep exploring!',
                                    style: TextStyle(
                                        color: badge.unlocked ? _teal : _purple,
                                        fontWeight: FontWeight.w900)),
                              ]),
                          actions: [
                            TextButton(
                                onPressed:
                                    withButtonSound(() => Navigator.pop(ctx)),
                                child: const Text('Close'))
                          ]))),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Quick Checks show which letters you have mastered.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: KidsUi.muted))),
      ];
}

String _statusName(LearningStatus status) => switch (status) {
      LearningStatus.notStarted => 'New',
      LearningStatus.viewed => 'Explored',
      LearningStatus.practiced => 'Practiced',
      LearningStatus.mastered => 'Mastered',
    };
Color _statusColor(LearningStatus status) => switch (status) {
      LearningStatus.notStarted => const Color(0xFF6B6079),
      LearningStatus.viewed => const Color(0xFF256AB0),
      LearningStatus.practiced => const Color(0xFF995019),
      LearningStatus.mastered => _teal,
    };
Widget _badge(IconData icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)))
      ]),
    );
Widget _card({required Widget child, Color tint = const Color(0xFFFFFAEF)}) =>
    ProgressCard(tint: tint, child: child);
Widget _detailRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _purple),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: KidsUi.muted)),
          Text(value,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
