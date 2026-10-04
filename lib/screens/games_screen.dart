import '../widgets/game_design.dart';
import '../data/game_session_order.dart';
import '../widgets/game_zone_card.dart';
import '../widgets/game_zone_welcome.dart';
import '../theme/kids_ui.dart';
import 'package:flutter/material.dart';
import '../widgets/game_theme_background.dart';
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

  static String _categoryFor(String title) => switch (title) {
        'Flappy Letters' || 'Alphabet Order' => 'Letters',
        'Sound Match' || 'Phonics Quiz' || 'Speak & Recognize' => 'Sounds',
        _ => 'Words',
      };
  Future<void> _play(String title, Widget Function(Difficulty) builder,
      String Function(Difficulty) detail) async {
    if (_opening || !context.read<AppProvider>().gameAccess) {
      return;
    }
    setState(() => _opening = true);
    try {
      final difficulty =
          await chooseGameDifficulty(context, title, detail, lessonStyle: true);
      if (!mounted ||
          difficulty == null ||
          !context.read<AppProvider>().gameAccess) {
        return;
      }
      await LearnerNavigation.open(context, builder(difficulty));
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
          imageAsset: title == 'Rhyming Words'
              ? 'assets/images/lesson_logos/rhyming_words.png'
              : 'assets/images/game_logos/${switch (title) {
                  'Speak & Recognize' => 'speak_and_recognize',
                  _ => title.toLowerCase().replaceAll(' ', '_'),
                }}.png',
          accent: switch (title) {
            'Flappy Letters' || 'Speak & Recognize' => const Color(0xFFFF408F),
            'Sound Match' || 'Missing Vowel' => const Color(0xFF00ABED),
            'Memory Flip' || 'Picture Match' => const Color(0xFFFFB900),
            'Word Builder' || 'Rumbled Words' => const Color(0xFF20C775),
            _ => const Color(0xFF8B4CF5),
          },
          title: title,
          description: description,
          onPressed: _opening ? null : () => _play(title, builder, detail));
  @override
  Widget build(BuildContext context) {
    if (!context.watch<AppProvider>().gameAccess) {
      return _zonePage(child: const Text('Games are turned off by a parent.'));
    }
    return _zonePage(
        child: Column(children: [
      _categories(),
      const SizedBox(height: 16),
      _gameRows([
        _card(
            'Flappy Letters',
            'Fly through A–Z!',
            Icons.flight_rounded,
            (d) => FlappyLettersScreen(difficulty: d),
            (d) => switch (d) {
                  Difficulty.easy => 'Slow speed · 26 letters',
                  Difficulty.medium => 'Normal speed · 26 letters',
                  Difficulty.hard => 'Faster speed · 26 letters',
                }),
        _card(
            'Sound Match',
            'Match the sound.',
            Icons.hearing,
            (d) => SoundMatchScreen(difficulty: d),
            (d) =>
                '${soundRoundsForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} rounds · ${soundRoundsForDifficulty(d).first.options.length} choices'),
        _card(
            'Memory Flip',
            'Match pairs.',
            Icons.grid_view,
            (d) => MemoryGameScreen(difficulty: d),
            (d) => '${memoryPairsForDifficulty(d).length} pairs'),
        _card(
            'Phonics Quiz',
            'Listen and choose.',
            Icons.quiz_outlined,
            (d) => PhonicsQuizScreen(difficulty: d),
            (d) =>
                '${quizQuestionsForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} questions'),
        _card(
            'Word Builder',
            'Build a word.',
            Icons.extension_outlined,
            (d) => WordBuilderScreen(difficulty: d),
            (d) =>
                '${wordPuzzlesForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} words · Fill missing letters'),
        _card(
            'Speak & Recognize',
            'Say the word.',
            Icons.mic_none,
            (d) => VoiceRecognitionScreen(difficulty: d),
            (d) =>
                '${voiceWords[d]!.length.clamp(0, GameSessionOrder.roundLength(d))} words'),
        _card(
            'Alphabet Order',
            'Put letters in order.',
            Icons.sort_by_alpha,
            (d) => AlphabetOrderScreen(difficulty: d),
            (d) => switch (d) {
                  Difficulty.easy => 'A–F · 6 letters',
                  Difficulty.medium => 'A–M · 13 letters',
                  Difficulty.hard => 'A–Z · 26 letters'
                }),
        _card(
            'Missing Vowel',
            'Find the vowel.',
            Icons.text_fields,
            (d) => MissingVowelScreen(difficulty: d),
            (d) =>
                '${vowelPuzzlesFor(d).length.clamp(0, GameSessionOrder.roundLength(d))} words'),
        _card(
            'Picture Match',
            'Match the picture.',
            Icons.image_outlined,
            (d) => PictureWordMatchScreen(difficulty: d),
            (d) =>
                '${pictureRoundsFor(d).length.clamp(0, GameSessionOrder.roundLength(d))} words · ${pictureRoundsFor(d).first.options.length} pictures'),
        _card(
            'Rumbled Words',
            'Put letters together.',
            Icons.shuffle_rounded,
            (d) => RumbledWordsScreen(difficulty: d),
            (d) =>
                '${rumbledWordsFor(d).length.clamp(0, GameSessionOrder.roundLength(d))} words · 1 hint per word'),
        _card(
            'Rhyming Words',
            'Find words that rhyme.',
            Icons.music_note_rounded,
            (d) => RhymingWordsScreen(difficulty: d),
            (d) =>
                '${rhymeRoundsForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} words'),
      ]),
    ]));
  }

  Widget _zonePage({required Widget child}) => Theme(
      data: KidsUi.theme,
      child: GameDesign(
          child: Scaffold(
              backgroundColor: const Color(0xFFF9F6FF),
              body: GameThemeBackground(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  ForestIconButton(
                                      tooltip: 'Back',
                                      icon: Icons.arrow_back_rounded,
                                      onPressed: () =>
                                          Navigator.maybePop(context)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                      child: GameZoneWelcome(showTitle: false)),
                                ]),
                                const SizedBox(height: 8),
                                child,
                              ])),
                    ),
                  ),
                ),
              ))));

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
                  onSelected: (_) => setState(() => _category = entry.key))),
      ]));

  Widget _gameRows(List<Widget> allCards) {
    final cards = allCards
        .where((card) =>
            _category == 'All Games' ||
            _categoryFor((card as GameZoneCard).title) == _category)
        .toList();
    return LayoutBuilder(builder: (context, box) {
      final oneColumn =
          box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(16) > 24;
      if (oneColumn) return Column(children: cards);
      final columns = box.maxWidth >= 600 ? 3 : 2;
      return Column(
        children: [
          for (var i = 0; i < cards.length; i += columns)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: 12),
                    Expanded(
                        child: i + j < cards.length
                            ? cards[i + j]
                            : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }
}
