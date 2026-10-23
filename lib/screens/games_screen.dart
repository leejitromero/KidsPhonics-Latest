import '../widgets/game_design.dart';
import '../data/games_menu_art.dart';
import '../data/game_session_order.dart';
import '../widgets/game_zone_card.dart';
import '../widgets/games_menu_header.dart';
import '../widgets/main_navigation_scope.dart';
import '../widgets/main_navigation_shell.dart';
import '../widgets/student_character_picker.dart';
import '../theme/kids_ui.dart';
import 'package:flutter/material.dart';
import '../widgets/school_room_body.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../data/phonics_activity_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

import 'sound_match_screen.dart';
import 'memory_game_screen.dart';
import 'flappy_letters_screen.dart';
import 'phonics_quiz_screen.dart';
import 'word_builder_screen.dart';
import 'voice_recognition_screen.dart';
import 'alphabet_order_screen.dart';
import 'missing_vowel_screen.dart';
import 'picture_word_match_screen.dart';
import 'rumbled_words_screen.dart';
import 'rhyming_words_screen.dart';
import '../data/rumbled_words_data.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool _opening = false;
  String _category = 'All Games';
  final _scroll = ScrollController();
  final Map<String, double> _scrollPositions = {};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _filter(String category) {
    if (_opening || category == _category) return;
    _scrollPositions[_category] = _scroll.hasClients ? _scroll.offset : 0;
    setState(() => _category = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo((_scrollPositions[category] ?? 0)
            .clamp(0, _scroll.position.maxScrollExtent));
      }
    });
  }

  Future<void> _editProfile() async {
    if (_opening || !context.read<AppProvider>().isReady) return;
    setState(() => _opening = true);
    await showDialog<void>(
        context: context, builder: (_) => const StudentCharacterPicker());
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _back() async {
    if (_opening) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      await navigateKidsTab(context, KidsDestination.home);
    }
  }

  static String _categoryFor(String title) => switch (title) {
        'Flappy Letters' || 'Alphabet Order' => 'Letters',
        'Sound Match' || 'Phonics Quiz' || 'Speak & Recognize' => 'Sounds',
        _ => 'Words',
      };
  Future<void> _play(String title, Widget Function(Difficulty) builder,
      String Function(Difficulty) detail) async {
    final p = context.read<AppProvider>();
    if (_opening || !p.isReady || !p.gameAccess || p.timeLimitReached) {
      return;
    }
    setState(() => _opening = true);
    try {
      final difficulty =
          await chooseGameDifficulty(context, title, detail, lessonStyle: true);
      if (!mounted ||
          difficulty == null ||
          !p.isReady ||
          !p.gameAccess ||
          p.timeLimitReached) {
        return;
      }
      await LearnerNavigation.open(context, builder(difficulty),
          fadeTransition: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _card(
          String title,
          String description,
          IconData icon,
          Widget Function(Difficulty) builder,
          String Function(Difficulty) detail) =>
      GameZoneCard(
          key: ValueKey(title),
          imageAsset: gamesMenuArt[title]!,
          character: context.read<AppProvider>().studentCharacter,
          completed: title == 'Rhyming Words' &&
              context.read<AppProvider>().rhymingWordsDone,
          accent: switch (title) {
            'Flappy Letters' || 'Speak & Recognize' => const Color(0xFFFF408F),
            'Sound Match' || 'Missing Vowel' => const Color(0xFF00ABED),
            'Memory Flip' || 'Picture Match' => const Color(0xFFFFB900),
            'Word Builder' || 'Rumbled Words' => const Color(0xFF20C775),
            _ => const Color(0xFF8B4CF5),
          },
          title: title,
          description: description,
          onPressed: _opening ||
                  !context.read<AppProvider>().isReady ||
                  context.read<AppProvider>().timeLimitReached
              ? null
              : () => _play(title, builder, detail));
  @override
  Widget build(BuildContext context) {
    if (!context.watch<AppProvider>().gameAccess) {
      return _zonePage(child: const Text('Games are turned off by a parent.'));
    }
    return _zonePage(
        child: Column(children: [
      _categories(),
      const SizedBox(height: 10),
      Expanded(
          child: _gameRows([
        _card(
            'Flappy Letters',
            'Fly through A\u2013Z!',
            Icons.flight_rounded,
            (d) => FlappyLettersScreen(difficulty: d),
            (d) => switch (d) {
                  Difficulty.easy => 'Slow speed - 26 letters',
                  Difficulty.medium => 'Normal speed - 26 letters',
                  Difficulty.hard => 'Faster speed - 26 letters',
                }),
        _card(
            'Sound Match',
            'Match the sound!',
            Icons.hearing,
            (d) => SoundMatchScreen(difficulty: d),
            (d) =>
                '${soundRoundsForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} rounds - 3 choices'),
        _card(
            'Memory Flip',
            'Match pairs!',
            Icons.grid_view,
            (d) => MemoryGameScreen(difficulty: d),
            (d) => '${memoryPairsForDifficulty(d).length} pairs'),
        _card(
            'Phonics Quiz',
            'Listen and choose!',
            Icons.quiz_outlined,
            (d) => PhonicsQuizScreen(difficulty: d),
            (d) =>
                '${quizQuestionsForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} questions'),
        _card(
            'Word Builder',
            'Build a word!',
            Icons.extension_outlined,
            (d) => WordBuilderScreen(difficulty: d),
            (d) =>
                '${wordPuzzlesForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} words - Fill missing letters'),
        _card(
            'Speak & Recognize',
            'Say the word!',
            Icons.mic_none,
            (d) => VoiceRecognitionScreen(difficulty: d),
            (d) =>
                '${voiceWords[d]!.length.clamp(0, GameSessionOrder.roundLength(d))} words'),
        _card(
            'Alphabet Order',
            'Put letters in order!',
            Icons.sort_by_alpha,
            (d) => AlphabetOrderScreen(difficulty: d),
            (d) => switch (d) {
                  Difficulty.easy => 'A-F - 6 letters',
                  Difficulty.medium => 'A-M - 13 letters',
                  Difficulty.hard => 'A-Z - 26 letters'
                }),
        _card(
            'Missing Vowel',
            'Find the vowel!',
            Icons.text_fields,
            (d) => MissingVowelScreen(difficulty: d),
            (d) =>
                '${vowelPuzzlesFor(d).length.clamp(0, GameSessionOrder.roundLength(d))} words'),
        _card(
            'Picture Match',
            'Match the picture!',
            Icons.image_outlined,
            (d) => PictureWordMatchScreen(difficulty: d),
            (d) =>
                '${pictureRoundsFor(d).length.clamp(0, GameSessionOrder.roundLength(d))} words - ${pictureRoundsFor(d).first.options.length} pictures'),
        _card(
            'Rumbled Words',
            'Arrange the letters!',
            Icons.shuffle_rounded,
            (d) => RumbledWordsScreen(difficulty: d),
            (d) =>
                '${rumbledWordsFor(d).length.clamp(0, GameSessionOrder.roundLength(d))} words - ${rumbledWordLengthLabel(d)} - 1 hint per word'),
        _card(
            'Rhyming Words',
            'Find rhyming words!',
            Icons.music_note_rounded,
            (d) => RhymingWordsScreen(difficulty: d),
            (d) =>
                '${GameSessionOrder.roundLength(d)} jars - 3 rhymes per jar'),
      ])),
    ]));
  }

  Widget _zonePage({required Widget child}) => Theme(
      data: KidsUi.theme,
      child: GameDesign(
          child: Scaffold(
              body: SchoolRoomBody(
                  room: SchoolRoom.games,
                  navigationDestination: KidsDestination.home,
                  navigationOnRoute: true,
                  child: LayoutBuilder(
                      builder: (context, box) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GamesMenuHeader(
                                    compact: box.maxHeight < 340,
                                    character: context
                                        .watch<AppProvider>()
                                        .studentCharacter,
                                    onBack: _opening ? null : _back,
                                    onEdit: _opening ? null : _editProfile),
                                const SizedBox(height: 8),
                                Expanded(child: child),
                              ]))))));

  Widget _categories() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final entry in const {
          'All Games': Icons.sports_esports_rounded,
          'Letters': Icons.star_rounded,
          'Sounds': Icons.volume_up_rounded,
          'Words': Icons.menu_book_rounded,
        }.entries)
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  selected: _category == entry.key,
                  showCheckmark: false,
                  avatar: Icon(entry.value,
                      color: _category == entry.key
                          ? Colors.white
                          : const Color(0xFF7542DE)),
                  label: Text(entry.key),
                  labelStyle: TextStyle(
                      color: _category == entry.key
                          ? Colors.white
                          : const Color(0xFF5930B0),
                      fontWeight: FontWeight.w800),
                  selectedColor: const Color(0xFF8245EC),
                  backgroundColor: const Color(0xFFF5F0FF),
                  side: const BorderSide(color: Color(0xFFE3D8FF)),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
                  key: ValueKey('games-filter-${entry.key}'),
                  onSelected: _opening ? null : (_) => _filter(entry.key))),
      ]));

  Widget _gameRows(List<Widget> allCards) {
    final cards = allCards
        .where((card) =>
            _category == 'All Games' ||
            _categoryFor((card as GameZoneCard).title) == _category)
        .toList();
    return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GridView.builder(
                    key: const PageStorageKey('games-grid'),
                    controller: _scroll,
                    padding: const EdgeInsets.only(top: 2, bottom: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: GamesFrameArt.cardAspectRatio),
                    itemCount: cards.length,
                    itemBuilder: (_, index) => cards[index]))));
  }
}
