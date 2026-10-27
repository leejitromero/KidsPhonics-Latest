import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../models/learning_progress.dart';
import '../models/letter_adventure.dart';
import '../models/progress_badge.dart';
import '../models/word_lesson_progress.dart';
import '../providers/app_provider.dart';
import '../screens/blending_sounds_screen.dart';
import '../screens/cvc_words_screen.dart';
import '../screens/letter_mastery_check_screen.dart';
import '../screens/letter_sounds_screen.dart';
import '../theme/kids_ui.dart';
import 'button_sound.dart';
import 'learner_widgets.dart';
import 'learning_progress_widgets.dart';
import 'progress_collection_design.dart';
import 'progress_design.dart';
import 'progress_reference_design.dart';
import 'progress_letter_frame_design.dart';
import 'progress_phonics_skills_frame.dart';
import 'progress_journey_frames.dart';
import 'progress_rewards_frames.dart';
import 'recommended_practice_card.dart';
import 'school_room_body.dart';

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

  void _selectTab(int tab) {
    setState(() => _tab = tab);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _open(Widget page) {
    final provider = context.read<AppProvider>();
    // Recheck at activation too: a limit can be reached while a detail dialog
    // is open, after its button was first built.
    if (!provider.isReady || provider.timeLimitReached) return;
    LearnerNavigation.open(context, page,
        cloudTransition: true, endParentSession: true);
  }

  void _practice(String letter) =>
      _open(LetterMasteryCheckScreen(letter: letterContent(letter)));

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Theme(
        data: KidsUi.theme,
        child: Scaffold(
            body: SchoolRoomBody(
                room: SchoolRoom.progress,
                child: Column(children: [
                  _tabs(),
                  const SizedBox(height: 10),
                  Expanded(
                      child: !p.isReady
                          ? Center(
                              child: p.hasLoadError
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          const Text(
                                              'Your saved progress could not be opened.'),
                                          TextButton(
                                              onPressed: p.retryLoading,
                                              child: const Text('Try Again')),
                                        ])
                                  : const CircularProgressIndicator())
                          : ListView(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(3, 0, 3, 14),
                              children: [
                                  ProgressTitleBanner(
                                      title: [
                                        'My Journey',
                                        'My Letters',
                                        'My Rewards'
                                      ][_tab],
                                      subtitle: [
                                        "See how much you've learned!",
                                        'Explore, practice, and master the letters!',
                                        'Keep learning and earn badges!'
                                      ][_tab],
                                      asset: _tab == 2
                                          ? 'assets/images/home_banner/trophy.png'
                                          : _tab == 1
                                              ? 'assets/images/lesson_logos/letter_recognition.webp'
                                              : 'assets/images/game_words/star-0.webp'),
                                  const SizedBox(height: 10),
                                  if (p.hasUnsavedChanges) ...[
                                    ProgressSurface(
                                        child: Column(children: [
                                      const Text(
                                          'Your latest progress is waiting to save.'),
                                      TextButton(
                                          onPressed: p.retrySaving,
                                          child: const Text(
                                              'Retry saving progress')),
                                    ])),
                                    const SizedBox(height: 10),
                                  ],
                                  ...switch (_tab) {
                                    1 => _letters(p),
                                    2 => _rewards(p),
                                    _ => _journey(p)
                                  },
                                  const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(
                                          'Your progress is saved on this device.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: progressInk))),
                                ])),
                ]))));
  }

  Widget _tabs() => IntrinsicHeight(
          child: Row(children: [
        for (final (index, title, icon) in [
          (0, 'My Journey', Icons.auto_stories_rounded),
          (1, 'My Letters', Icons.abc_rounded),
          (2, 'My Rewards', Icons.star_rounded),
        ]) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
              child: Semantics(
                  selected: _tab == index,
                  button: true,
                  child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _tab == index
                                  ? [
                                      const Color(0xFFB46AF8),
                                      const Color(0xFF7120E9)
                                    ]
                                  : [Colors.white, const Color(0xFFFFF8ED)]),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                              color: _tab == index ? const Color(0xFFE6CBFF) : Colors.white,
                              width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x35643B62),
                                offset: Offset(0, 3),
                                blurRadius: 4)
                          ]),
                      child: TextButton(
                          key: ValueKey('progress-tab-$index'),
                          onPressed: withButtonSound(() => _selectTab(index)),
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 64),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 7),
                              foregroundColor:
                                  _tab == index ? Colors.white : progressInk,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25))),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(icon,
                                color: index == 1
                                    ? const Color(0xFF25B7F0)
                                    : const Color(0xFFFFCD32),
                                size: 26),
                            const SizedBox(height: 3),
                            Text(title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w900)),
                          ]))))),
        ],
      ]));

  List<Widget> _journey(AppProvider p) => [
        ProgressPhonicsSkillsFrame(children: [
          for (final (id, title, unit, count, total, color, icon, action) in [
            (
              'letters',
              'Letters',
              'mastered',
              p.overallMasteredCount,
              26,
              progressPurple,
              Icons.abc_rounded,
              () => _selectTab(1)
            ),
            (
              'sounds',
              'Letter Sounds',
              'explored',
              p.exploredSoundCount,
              26,
              const Color(0xFF19A8EB),
              Icons.volume_up_rounded,
              () => _open(const LetterSoundsScreen())
            ),
            (
              'vowels',
              'Vowels',
              'mastered',
              p.quickCheckVowelsMastered,
              5,
              const Color(0xFF27BC64),
              Icons.record_voice_over_rounded,
              () => _open(const LetterSoundsScreen(vowelsOnly: true))
            ),
            (
              'cvc',
              'CVC Words',
              'practiced',
              p.wordLessonProgress(WordLesson.cvc).completed.length,
              WordLesson.cvc.words.length,
              const Color(0xFFFF9D24),
              Icons.menu_book_rounded,
              () => _open(const CvcWordsScreen())
            ),
            (
              'blending',
              'Blending Sounds',
              'completed',
              p.wordLessonProgress(WordLesson.blending).completed.length,
              WordLesson.blending.words.length,
              const Color(0xFFEF46B6),
              Icons.extension_rounded,
              () => _open(const BlendingSoundsScreen())
            ),
          ])
            ProgressSkillRow(
                key: ValueKey('journey-skill-$id'),
                title: title,
                unit: unit,
                current: count,
                total: total,
                color: color,
                icon: icon,
                onPressed: p.timeLimitReached ? null : action),
        ]),
        const SizedBox(height: 10),
        _recommendation(p),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (_, box) {
          final streak = ProgressStreakFrame(days: p.streak);
          final summary = ProgressLearningSummaryFrame(
              exploredLetters: p.exploredLetterCount,
              practicedLessons: p.practicedLessonCount,
              stars: p.stars);
          return box.maxWidth < 480 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3
              ? Column(children: [streak, const SizedBox(height: 10), summary])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: streak),
                  const SizedBox(width: 10),
                  Expanded(flex: 3, child: summary)
                ]);
        }),
      ];

  Widget _recommendation(AppProvider p) {
    final letter = p.recommendedAdventureLetter;
    return RecommendedPracticeCard(
        leading: letter == null
            ? const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFFBC23), size: 44)
            : Text(letter,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF14890))),
        title: letter == null
            ? 'All 26 letters mastered!'
            : 'Practice Letter $letter',
        description: letter == null
            ? 'Keep exploring and practicing.'
            : p.adventureProgress(letter).completed > 0
                ? 'Try this Quick Check again.'
                : 'Take your next Quick Check.',
        actionKey: const ValueKey('progress-start-quick-check'),
        onPressed: p.timeLimitReached
            ? null
            : withButtonSound(
                () => letter == null ? _selectTab(1) : _practice(letter)),
        buttonIcon:
            letter == null ? Icons.abc_rounded : Icons.play_arrow_rounded,
        buttonLabel: letter == null ? 'Choose a Letter' : 'Start Quick Check');
  }

  Color _statColor(String label) => switch (label) {
        'New' => const Color(0xFF827294),
        'Explored' => const Color(0xFF0789D4),
        'Practiced' => const Color(0xFFD37B16),
        'Mastered' => progressGreen,
        'stars earned' || 'earned' => const Color(0xFFE9A414),
        _ => progressPurple,
      };

  List<Widget> _letters(AppProvider p) {
    final letters = p.quickCheckLetters;
    final shown =
        letters.where((l) => _filter == null || l.status == _filter).toList();
    return [
      ProgressLetterSummaryFrame(
          key: const ValueKey('progress-letter-summary'),
          masteredCount: p.overallMasteredCount,
          values: [
            for (final status in LearningStatus.values)
              (
                '${p.quickCheckStatusCount(status)}',
                collectionStatusName(status),
                collectionStatusIcon(status),
                _statColor(collectionStatusName(status))
              )
          ]),
      const SizedBox(height: 8),
      LayoutBuilder(
          builder: (_, box) => Wrap(spacing: 5, runSpacing: 3, children: [
                for (final status in [null, ...LearningStatus.values])
                  ProgressLetterFilterButton(
                    width: (box.maxWidth - 10) / 3,
                    label: status == null
                        ? 'All 26'
                        : '${status == LearningStatus.notStarted ? 'New' : collectionStatusName(status)} (${p.quickCheckStatusCount(status)})',
                    selected: _filter == status,
                    onSelected: (_) => setState(() => _filter = status),
                  ),
              ])),
      const SizedBox(height: 8),
      if (shown.isEmpty)
        const ProgressSurface(
            child: Column(children: [
          Icon(Icons.explore_outlined, color: progressPurple, size: 32),
          Text('No letters here yet.',
              style: TextStyle(fontWeight: FontWeight.w900)),
          Text('Tap All 26 to choose your next letter.'),
        ]))
      else
        LayoutBuilder(builder: (_, box) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final columns = (box.maxWidth / (64 * scale)).floor().clamp(2, 6);
          return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .86,
              children: [
                for (final letter in shown)
                  ProgressLetterTile(
                      letter: letter, onPressed: () => _letterDetail(letter))
              ]);
        }),
      const SizedBox(height: 12),
      _recommendation(p),
    ];
  }

  void _letterDetail(LetterProgress letter) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFFFFFCF6),
        builder: (ctx) => SafeArea(
            top: false,
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Letter ${letter.letter}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: progressPurple)),
                      Text(collectionStatusName(letter.status),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              color: collectionStatusColor(letter.status))),
                      const SizedBox(height: 10),
                      _detail(
                          'Latest Quick Check score',
                          letter.completedAssessments == 0
                              ? 'Not tried yet'
                              : '${letter.correctAnswers} / 5'),
                      _detail(
                          'Best Quick Check',
                          letter.completedAssessments == 0
                              ? 'Not tried yet'
                              : '${letter.bestAssessmentScore} / 5'),
                      _detail('Completed Quick Checks',
                          '${letter.completedAssessments}'),
                      _detail(
                          'Latest Quick Check accuracy',
                          letter.completedAssessments == 0
                              ? 'No attempts yet'
                              : accuracyLabel(letter.accuracy)),
                      if (letter.completedAssessments > 0) ...[
                        const SizedBox(height: 10),
                        const Text('Latest skill results',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        ..._skillResults(letter.letter),
                      ],
                      const SizedBox(height: 8),
                      _detail(
                          'Letter recordings heard', '${letter.nameListens}'),
                      _detail(
                          'Sound recordings heard', '${letter.soundListens}'),
                      _detail('Word recordings heard', '${letter.wordListens}'),
                      const Text(
                          'Listening shows practice. Mastery comes from a completed Quick Check: at least 4/5, '
                          'with Letter sounds and Sounds in words both correct.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF6C5A86))),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          key: const ValueKey('progress-practice-letter'),
                          onPressed:
                              context.read<AppProvider>().timeLimitReached
                                  ? null
                                  : withButtonSound(() {
                                      Navigator.pop(ctx);
                                      _practice(letter.letter);
                                    }),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text('Practice ${letter.letter}')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Back to my letters')),
                    ]))));
  }

  List<Widget> _skillResults(String letter) {
    final answers =
        context.read<AppProvider>().adventureProgress(letter).lastAnswers;
    return [
      for (final skill in AdventureSkill.values)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(
                  answers[skill.index]
                      ? Icons.check_circle_rounded
                      : Icons.favorite_rounded,
                  size: 20,
                  color: answers[skill.index]
                      ? progressGreen
                      : const Color(0xFFEF9443)),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      Text(skill.label, style: const TextStyle(fontSize: 13))),
              Text(answers[skill.index] ? 'Got it!' : 'Practice',
                  style: const TextStyle(fontSize: 12)),
            ]))
    ];
  }

  Widget _detail(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 8),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900))),
      ]));

  List<Widget> _rewards(AppProvider p) {
    final badges = p.progressBadges;
    return [
      ProgressRewardsHeader(
          earned: badges.where((b) => b.earned).length, total: badges.length),
      const SizedBox(height: 10),
      for (var i = 0; i < badges.length; i++) ...[
        if (badges[i].milestone && (i == 0 || !badges[i - 1].milestone))
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ProgressRewardsHeader()),
        ProgressBadgeCard(
            badge: badges[i],
            index: i,
            onPressed: () => _badgeDetail(badges[i])),
        const SizedBox(height: 8),
      ],
      ProgressTreasureFrame(
          level: p.level,
          stars: p.stars,
          xp: p.xp,
          progressBar: ProgressValueBar(
              current: p.xp % 200, total: 200, color: progressPurple)),
    ];
  }

  void _badgeDetail(ProgressBadge badge) {
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(badge.title),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(badge.description),
                      const SizedBox(height: 12),
                      Text('${badge.count} / ${badge.target}'),
                      const SizedBox(height: 6),
                      Text(badge.earned ? 'You earned it!' : 'Keep exploring!'),
                      if (badge.id == '3-Day Streak')
                        const Text(
                            'This badge remembers your best streak, even after a break.'),
                    ])),
                actions: [
                  if (!badge.earned)
                    TextButton(
                        onPressed: context.read<AppProvider>().timeLimitReached
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                if (badge.id == 'CVC Explorer') {
                                  _open(const CvcWordsScreen());
                                } else if (badge.id == 'Blending Champion') {
                                  _open(const BlendingSoundsScreen());
                                } else if (badge.id == 'Vowel Star') {
                                  final p = context.read<AppProvider>();
                                  _practice('AEIOU'.split('').firstWhere(
                                      (l) => !p.adventureProgress(l).mastered));
                                } else {
                                  _practice(context
                                          .read<AppProvider>()
                                          .recommendedAdventureLetter ??
                                      'A');
                                }
                              },
                        child: const Text('Start Practice')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close')),
                ]));
  }
}
