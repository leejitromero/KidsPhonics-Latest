import 'package:flutter/material.dart';
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
import 'mascot_guide.dart';

const _purple = Color(0xFF7052CA);
const _teal = Color(0xFF167769);

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

  void _practice(String letter) => LearnerNavigation.open(
      context, LetterMasteryCheckScreen(letter: letterContent(letter)));

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
                appBar: AppBar(
                  title: const Text('My Progress',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  backgroundColor: const Color(0xFFF4F0FF),
                  foregroundColor: KidsUi.ink,
                  surfaceTintColor: Colors.transparent,
                ),
                body: SafeArea(
                  top: false,
                  child: Center(
                      child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: LayoutBuilder(
                            builder: (_, box) => Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final (index, title, icon) in [
                                      (0, 'My Journey', Icons.route_rounded),
                                      (1, 'My Letters', Icons.abc_rounded),
                                      (2, 'My Rewards', Icons.star_rounded),
                                    ])
                                      SizedBox(
                                        width: (box.maxWidth - 12) / 3,
                                        child: Semantics(
                                          selected: _tab == index,
                                          child: TextButton(
                                            key:
                                                ValueKey('progress-tab-$index'),
                                            onPressed: () => _selectTab(index),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 4),
                                              foregroundColor: _tab == index
                                                  ? Colors.white
                                                  : _purple,
                                              backgroundColor: _tab == index
                                                  ? _purple
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18)),
                                            ),
                                            child: Column(children: [
                                              Icon(icon, size: 26),
                                              const SizedBox(height: 4),
                                              Text(title,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ]),
                                          ),
                                        ),
                                      ),
                                  ],
                                )),
                      ),
                      Expanded(
                          child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          ...switch (_tab) {
                            1 => _letters(p, themedContext),
                            2 => _rewards(p),
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
                bottomNavigationBar: NavigationBar(
                  selectedIndex: 3,
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFE6DDFB),
                  onDestinationSelected: (index) {
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
                  },
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.home_rounded), label: 'Home'),
                    NavigationDestination(
                        icon: Icon(Icons.menu_book_rounded), label: 'Lessons'),
                    NavigationDestination(
                        icon: Icon(Icons.sports_esports_rounded),
                        label: 'Games'),
                    NavigationDestination(
                        icon: Icon(Icons.auto_graph_rounded),
                        label: 'Progress'),
                  ],
                ),
              )),
    );
  }

  List<Widget> _journey(AppProvider p) {
    final next = p.recommendedNextPractice;
    return [
      _card(
        tint: const Color(0xFFFFF1CD),
        child: Row(children: [
          const MascotPortrait(mascot: LearningMascot.zoplet, size: 76),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _title('Look how you grow!'),
                const SizedBox(height: 4),
                const Text('One little step at a time with Zoplet.',
                    style: TextStyle(fontSize: 15, color: KidsUi.muted)),
              ])),
        ]),
      ),
      _card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(Icons.auto_awesome_rounded, 'My alphabet adventure'),
        const SizedBox(height: 16),
        Text('${p.masteredLetterCount} of 26 letters mastered',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: _purple)),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: p.masteryPercentage / 100,
          minHeight: 14,
          borderRadius: BorderRadius.circular(12),
          backgroundColor: const Color(0xFFEDE6FA),
          color: _purple,
          semanticsLabel: 'Letters mastered',
        ),
        const SizedBox(height: 12),
        Text(
            p.masteredLetterCount == 26
                ? 'You did it! The whole alphabet!'
                : p.masteredLetterCount == 0
                    ? 'Your adventure starts with one letter.'
                    : 'Keep going! Every letter is a step forward.',
            style: const TextStyle(fontSize: 15, color: KidsUi.muted)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _badge(Icons.edit_rounded, '${p.practicedLetterCount} practiced',
              const Color(0xFF995019)),
          _badge(Icons.visibility_rounded, '${p.viewedLetterCount} explored',
              const Color(0xFF256AB0)),
          _badge(Icons.auto_awesome_rounded,
              '${p.masteredVowelCount} / 5 vowels mastered', _teal),
        ]),
        const SizedBox(height: 10),
        TextButton.icon(
            onPressed: () => _selectTab(1),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('See my letters')),
      ])),
      _card(
          tint: const Color(0xFFE8F5F0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _heading(Icons.play_circle_outline_rounded, 'My next little step',
                color: _teal),
            const SizedBox(height: 10),
            Text(
                next == null
                    ? 'All letters mastered!'
                    : 'Let’s practice ${next.letter}!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                next == null
                    ? 'Choose a favorite letter and keep exploring.'
                    : 'Listen, choose, and give it a go.',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: next == null
                  ? () => _selectTab(1)
                  : () => _practice(next.letter),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                  next == null ? 'Choose a letter' : 'Practice ${next.letter}'),
              style: FilledButton.styleFrom(
                  backgroundColor: _teal, minimumSize: const Size(0, 48)),
            ),
          ])),
      _card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(Icons.local_fire_department_rounded, 'Keep the learning going',
            color: const Color(0xFFAB5620)),
        const SizedBox(height: 12),
        Text('${p.streak}-day learning streak',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('A little practice each day adds up!',
            style: TextStyle(fontSize: 15, color: KidsUi.muted)),
      ])),
    ];
  }

  List<Widget> _letters(AppProvider p, BuildContext themedContext) {
    final letters = p.allLetterProgress
        .where((l) => _filter == null || l.status == _filter)
        .toList();
    return [
      _card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(Icons.abc_rounded, 'My letter collection'),
        const SizedBox(height: 6),
        const Text('Tap a letter to see your progress and practice.',
            style: TextStyle(fontSize: 16, color: KidsUi.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(
              label: const Text('All 26'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null)),
          for (final status in LearningStatus.values)
            ChoiceChip(
              avatar: Icon(status.icon, size: 18, color: _statusColor(status)),
              label: Text(
                  '${_statusName(status)} (${p.allLetterProgress.where((l) => l.status == status).length})'),
              selected: _filter == status,
              onSelected: (_) => setState(() => _filter = status),
            ),
        ]),
      ])),
      if (letters.isEmpty)
        _card(
            child: const Column(children: [
          Icon(Icons.explore_outlined, size: 42, color: _purple),
          SizedBox(height: 10),
          Text('No letters here yet.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Tap All 26 to choose your next letter.',
              textAlign: TextAlign.center),
        ]))
      else
        LayoutBuilder(builder: (_, box) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final count = (box.maxWidth / (94 * scale)).floor().clamp(2, 6);
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: count,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .82,
            children: [
              for (final letter in letters)
                Semantics(
                  label: '${letter.letter}: ${_statusName(letter.status)}',
                  button: true,
                  child: Tooltip(
                      message: _statusName(letter.status),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          key: ValueKey('progress-letter-${letter.letter}'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _letterDetail(themedContext, letter),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _statusColor(letter.status)
                                        .withValues(alpha: .4),
                                    width: 2)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(letter.letter,
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: _statusColor(letter.status))),
                                  const SizedBox(height: 4),
                                  Icon(letter.status.icon,
                                      color: _statusColor(letter.status),
                                      size: 24),
                                ]),
                          ),
                        ),
                      )),
                ),
            ],
          );
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Letter ${letter.letter}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _purple)),
                  const SizedBox(height: 10),
                  Center(
                      child: _badge(
                          letter.status.icon,
                          _statusName(letter.status),
                          _statusColor(letter.status))),
                  const SizedBox(height: 20),
                  _detailRow(Icons.check_circle_outline, 'Correct answers',
                      '${letter.correctAnswers} / ${letter.attempts}'),
                  _detailRow(
                      Icons.flag_outlined,
                      'Best Quick Check',
                      letter.completedAssessments == 0
                          ? 'Not tried yet'
                          : '${letter.bestAssessmentScore} / 5'),
                  _detailRow(Icons.auto_graph_rounded, 'Practice accuracy',
                      accuracyLabel(letter.accuracy)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('progress-practice-letter'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _practice(letter.letter);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Practice ${letter.letter}'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  ),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Back to my letters')),
                ]),
          )),
    );
  }

  List<Widget> _rewards(AppProvider p) => [
        _card(
            tint: const Color(0xFFFFF1CD),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _heading(Icons.emoji_events_rounded, 'My treasure shelf',
                  color: const Color(0xFF985018)),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _badge(Icons.emoji_events_rounded, 'Level ${p.level}',
                    const Color(0xFF985018)),
                _badge(Icons.star_rounded, '${p.stars} stars',
                    const Color(0xFF985018)),
                _badge(Icons.bolt_rounded, '${p.xp} XP', _purple),
              ]),
              const SizedBox(height: 12),
              const Text('Stars and XP celebrate your practice!',
                  style: TextStyle(fontSize: 16)),
            ])),
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _title(
                'My badges · ${p.unlockedAchievementCount} / ${p.learningAchievements.length}')),
        for (final badge in p.learningAchievements)
          _card(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: badge.unlocked
                        ? const Color(0xFFFFF1CD)
                        : const Color(0xFFF0EDF5),
                    shape: BoxShape.circle),
                child: Icon(
                    badge.unlocked
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_outline_rounded,
                    size: 30,
                    color: badge.unlocked
                        ? const Color(0xFF985018)
                        : KidsUi.muted)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(badge.title,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(badge.description,
                      style:
                          const TextStyle(fontSize: 15, color: KidsUi.muted)),
                  const SizedBox(height: 6),
                  Text(badge.unlocked ? 'You earned it!' : 'Keep exploring!',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: badge.unlocked ? _teal : _purple)),
                ])),
          ])),
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
Widget _title(String title) => Text(title,
    style: const TextStyle(
        fontSize: 22, fontWeight: FontWeight.w900, color: KidsUi.ink));
Widget _heading(IconData icon, String title, {Color color = _purple}) =>
    Row(children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(width: 10),
      Expanded(child: _title(title)),
    ]);
Widget _badge(IconData icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
Widget _card({required Widget child, Color tint = Colors.white}) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6DEF2)),
          boxShadow: [
            BoxShadow(
                color: _purple.withValues(alpha: .07),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ]),
      child: child,
    );
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
