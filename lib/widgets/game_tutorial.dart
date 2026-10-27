import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/kids_ui.dart';
import '../data/lesson_example_data.dart';
import 'game_tutorial_design.dart';
import 'game_design.dart';
import 'flappy_bird_sprite.dart';

enum GameTutorial {
  flappyLetters,
  wordBuilder,
  memoryFlip,
  soundMatch,
  phonicsQuiz,
  speechPractice,
  alphabetOrder,
  missingVowel,
  pictureMatch,
  rumbledWords,
  rhymingWords,
  soundPosition;

  static GameTutorial? forTitle(String title) => switch (title) {
        'Flappy Letters' => flappyLetters,
        'Word Builder' => wordBuilder,
        'Memory Flip' => memoryFlip,
        'Sound Match' => soundMatch,
        'Phonics Quiz' => phonicsQuiz,
        'Speak & Recognize' => speechPractice,
        'Alphabet Order' => alphabetOrder,
        'Missing Vowel' => missingVowel,
        'Picture Match' => pictureMatch,
        'Rumbled Words' => rumbledWords,
        'Rhyming Words' => rhymingWords,
        'Sound Position' => soundPosition,
        _ => null,
      };
  bool get showOnFirstVisit =>
      this == flappyLetters || this == wordBuilder || this == memoryFlip;
}

class GameTutorialHost extends StatefulWidget {
  const GameTutorialHost(
      {super.key,
      required this.tutorial,
      required this.builder,
      this.onOpen,
      this.canOpen});
  final GameTutorial tutorial;
  final Widget Function(BuildContext, VoidCallback) builder;
  final VoidCallback? onOpen;
  final bool Function()? canOpen;
  @override
  State<GameTutorialHost> createState() => _GameTutorialHostState();
}

class _GameTutorialHostState extends State<GameTutorialHost> {
  bool _open = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstVisit());
  }

  String get _key => 'gameTutorialV1.${widget.tutorial.name}';
  Future<void> _firstVisit() async {
    if (!widget.tutorial.showOnFirstVisit) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted ||
        prefs.getBool(_key) == true ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    await _show();
  }

  Future<void> _show() async {
    if (_open ||
        !mounted ||
        widget.canOpen?.call() == false ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _open = true;
    widget.onOpen?.call();
    final dismissed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TutorialDialog(tutorial: widget.tutorial));
    if (dismissed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    }
    _open = false;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _show);
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog({required this.tutorial});
  final GameTutorial tutorial;
  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _step = 0;
  bool _dismissed = false;
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    Navigator.pop(context, true);
  }

  List<(IconData, String, String)> get _steps => switch (widget.tutorial) {
        GameTutorial.flappyLetters => [
            (
              Icons.touch_app_rounded,
              'Tap to fly!',
              'Tap the sky to lift your little friend. Keep tapping to stay up.'
            ),
            (
              Icons.compare_arrows_rounded,
              'Fly through the gap',
              'Go between the pipes. You have 3 lives. Each crash costs one!'
            ),
            (
              Icons.abc_rounded,
              'Meet A to Z',
              'Pass 26 letter pipes. Listen to each letter with Voice Assistance on.'
            ),
          ],
        GameTutorial.wordBuilder => [
            (
              Icons.volume_up_rounded,
              'Hear the word',
              'Look at the picture. Tap Hear Word to listen.'
            ),
            (
              Icons.touch_app_rounded,
              'Fill the missing letters',
              'Tap a letter to fill the next blank, from left to right.'
            ),
            (
              Icons.auto_awesome_rounded,
              'Build and try again',
              'Green means correct! If a letter is wrong, choose another one.'
            ),
          ],
        GameTutorial.memoryFlip => [
            (
              Icons.touch_app_rounded,
              'Turn over two cards',
              'Remember the pictures during the 3-second preview. Then tap two hidden cards.'
            ),
            (
              Icons.copy_rounded,
              'Find the same picture',
              'Matching pictures stay face up. Remember where the others hide!'
            ),
            (
              Icons.stars_rounded,
              'Find every pair',
              'Matched pictures fly into your collection. Find them all for a fireworks celebration!'
            ),
          ],
        GameTutorial.soundMatch => [
            (
              Icons.volume_up_rounded,
              'Listen first',
              'Tap the magical orb or Hear Sound to listen to the letter sound.'
            ),
            (
              Icons.touch_app_rounded,
              'Choose a letter',
              'Tap the letter that makes the sound you heard.'
            ),
            (
              Icons.check_circle_rounded,
              'Learn and continue',
              'Try again if you need to. When you find the letter, the next sound appears!'
            ),
          ],
        GameTutorial.phonicsQuiz => [
            (
              Icons.volume_up_rounded,
              'Listen first',
              'Listen to the word and the beginning, middle, or ending sound question. Use the speakers to listen again.'
            ),
            (
              Icons.touch_app_rounded,
              'Choose, then check',
              'Hear the letter sounds, choose your answer, then tap Check Answer. Only your submitted answer is scored.'
            ),
            (
              Icons.check_circle_rounded,
              'Learn and continue',
              'See and hear the correct sound before the next question. Review Mistakes at the end is practice and keeps your original score.'
            ),
          ],
        GameTutorial.speechPractice => [
            (
              Icons.volume_up_rounded,
              'Hear the word',
              'Tap Hear Word. Watch each letter grow as you hear its name, then listen to the whole word.'
            ),
            (
              Icons.mic_rounded,
              'Say the whole word',
              'Tap Start Listening, then say the picture word clearly.'
            ),
            (
              Icons.hearing_rounded,
              'See what was heard',
              'Read the recognized word. Try again if needed. This activity recognizes words; it does not score pronunciation.'
            ),
          ],
        GameTutorial.alphabetOrder => [
            (
              Icons.abc_rounded,
              'Look at the letters',
              'Put the letters in alphabet order. Start with A.'
            ),
            (
              Icons.touch_app_rounded,
              'Tap letters in order',
              'Tap A, then B, then C. Each correct letter moves into its space.'
            ),
            (
              Icons.check_circle_rounded,
              'Keep going',
              'Fill every space in order to finish the round and celebrate!'
            ),
          ],
        GameTutorial.rumbledWords => [
            (
              Icons.volume_up_rounded,
              'Hear the picture word',
              'Look at the picture and listen to the word. Hint fixes the first letter once per word.'
            ),
            (
              Icons.swipe_rounded,
              'Drag into place',
              'Tap a letter to make it float, then drag it into place. The other letters slide aside. Tap the selected letter again to cancel.'
            ),
            (
              Icons.auto_awesome_rounded,
              'Check your word',
              'Tap Check Word when ready. Keep arranging if it is wrong. A correct word lights up and plays before the next task starts.'
            ),
          ],
        GameTutorial.missingVowel => [
            (
              Icons.volume_up_rounded,
              'Hear the picture word',
              'Look at the picture and listen to the word.'
            ),
            (
              Icons.touch_app_rounded,
              'Build the word',
              'Choose A, E, I, O, or U to fill the missing vowel.'
            ),
            (
              Icons.check_circle_rounded,
              'Check your word',
              'Use the feedback to try again or continue.'
            ),
          ],
        GameTutorial.pictureMatch => [
            (
              Icons.volume_up_rounded,
              'Hear the word',
              'Tap the speaker and listen.'
            ),
            (
              Icons.image_rounded,
              'Choose its picture',
              'Tap the picture that matches the word.'
            ),
            (
              Icons.check_circle_rounded,
              'Check and continue',
              'Watch the feedback before continuing.'
            ),
          ],
        GameTutorial.rhymingWords => [
            (
              Icons.volume_up_rounded,
              'Hear the word',
              'Listen to the word on the jar.'
            ),
            (
              Icons.music_note_rounded,
              'Find the same ending',
              'Tap three different words with the same ending sound. Each correct answer fills the jar with energy.'
            ),
            (
              Icons.check_circle_rounded,
              'Check the rhyme',
              'When the jar is full, watch the words appear and listen to them. The jar word is spoken first.'
            ),
          ],
        GameTutorial.soundPosition => [
            (
              Icons.volume_up_rounded,
              'Hear the word',
              'Listen for the target sound.'
            ),
            (
              Icons.compare_arrows_rounded,
              'Find its place',
              'Choose beginning, middle, or end.'
            ),
            (
              Icons.check_circle_rounded,
              'Check and continue',
              'Watch the feedback before continuing.'
            ),
          ],
      };
  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = _steps[_step];
    return Theme(
        data: KidsUi.theme,
        child: GameTutorialDesign(
            step: _step,
            total: _steps.length,
            title: title,
            detail: detail,
            example: _VisualExample(
                tutorial: widget.tutorial, step: _step, icon: icon),
            onSkip: _dismiss,
            onBack: _step == 0
                ? null
                : () {
                    if (!_dismissed) setState(() => _step--);
                  },
            onNext: () {
              if (_dismissed) return;
              if (_step == _steps.length - 1) {
                _dismiss();
              } else {
                setState(() => _step++);
              }
            }));
  }
}

class _VisualExample extends StatelessWidget {
  const _VisualExample(
      {required this.tutorial, required this.step, required this.icon});
  final GameTutorial tutorial;
  final int step;
  final IconData icon;

  Widget picture(String word, {double size = 58}) => Image.asset(
      practiceExamples
          .firstWhere((example) => example.word == word)
          .frames
          .first,
      width: size,
      height: size,
      cacheWidth: 192,
      fit: BoxFit.contain,
      excludeFromSemantics: true);

  Widget pictures(List<String> words) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final word in words)
          Flexible(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ForestPanel(
                      leaves: false,
                      accent: step == 2
                          ? const Color(0xFF28BC7D)
                          : const Color(0xFFFFB135),
                      padding: const EdgeInsets.all(5),
                      child: picture(word))))
      ]);

  @override
  Widget build(BuildContext context) {
    final completed = step == 2;
    final visual = switch (tutorial) {
      GameTutorial.flappyLetters =>
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const FlappyBirdSprite(size: 72, frame: 1, tilt: -.1),
          const SizedBox(width: 16),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 35,
                height: 20,
                decoration: const BoxDecoration(
                    color: Color(0xFF56B845),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(5)))),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(step == 2 ? 'Z' : 'A',
                    style: const TextStyle(
                        fontSize: 28,
                        color: GameDesign.ink,
                        fontWeight: FontWeight.w900))),
            Container(
                width: 35,
                height: 20,
                decoration: const BoxDecoration(
                    color: Color(0xFF56B845),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(5)))),
          ])
        ]),
      GameTutorial.memoryFlip => pictures(['Cat', 'Cat']),
      GameTutorial.pictureMatch =>
        pictures(step == 1 ? ['Cat', 'Dog'] : ['Cat']),
      GameTutorial.speechPractice =>
        Column(mainAxisSize: MainAxisSize.min, children: [
          picture('Cat'),
          const SizedBox(height: 5),
          TutorialExampleTiles(
              letters: const ['C', 'A', 'T'],
              selected: step == 0 ? 0 : -1,
              complete: completed)
        ]),
      GameTutorial.rhymingWords =>
        Column(mainAxisSize: MainAxisSize.min, children: [
          pictures(['Cat', 'Hat']),
          const SizedBox(height: 5),
          TutorialExampleTiles(
              letters: const ['CAT', 'HAT'], complete: completed)
        ]),
      GameTutorial.rumbledWords =>
        Column(mainAxisSize: MainAxisSize.min, children: [
          picture('Cat'),
          const SizedBox(height: 5),
          TutorialExampleTiles(
              letters: step < 2 ? const ['C', 'T', 'A'] : const ['C', 'A', 'T'],
              selected: step == 1 ? 2 : -1,
              complete: completed),
          if (step == 1) const Icon(Icons.swipe_rounded, color: GameDesign.ink),
        ]),
      GameTutorial.wordBuilder ||
      GameTutorial.missingVowel =>
        Column(mainAxisSize: MainAxisSize.min, children: [
          picture('Cat'),
          const SizedBox(height: 5),
          TutorialExampleTiles(
              letters: ['C', step == 0 ? '_' : 'A', 'T'],
              selected: step == 1 ? 1 : -1,
              complete: completed)
        ]),
      GameTutorial.alphabetOrder => TutorialExampleTiles(
          letters: ['A', 'B', step == 0 ? '_' : 'C'],
          selected: step == 1 ? 2 : -1,
          complete: completed),
      GameTutorial.soundPosition =>
        const TutorialExampleTiles(letters: ['B', 'A', 'T'], selected: 0),
      GameTutorial.soundMatch ||
      GameTutorial.phonicsQuiz =>
        Column(mainAxisSize: MainAxisSize.min, children: [
          if (tutorial == GameTutorial.phonicsQuiz) picture('Cat'),
          if (tutorial == GameTutorial.phonicsQuiz) const SizedBox(height: 5),
          TutorialExampleTiles(
              letters: const ['C', 'B', 'A'], selected: step > 0 ? 0 : -1)
        ]),
    };
    return Semantics(
        label: 'Example only: ${tutorial.name}',
        child: ExcludeSemantics(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFE251), size: 23),
            const SizedBox(width: 10),
            if (tutorial == GameTutorial.alphabetOrder)
              const _AlphabetEmblem()
            else
              Icon(icon,
                  color: completed ? const Color(0xFF087D5A) : Colors.white,
                  size: 32),
            const SizedBox(width: 10),
            const Icon(Icons.star_rounded, color: Color(0xFFFFE251), size: 23),
          ]),
          const SizedBox(height: 10),
          visual,
        ])));
  }
}

class _AlphabetEmblem extends StatelessWidget {
  const _AlphabetEmblem();
  static const style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 40,
      fontWeight: FontWeight.w900,
      height: 1.1);
  @override
  Widget build(BuildContext context) => Stack(children: [
        Text('ABC',
            textScaler: TextScaler.noScaling,
            style: style.copyWith(
                foreground: Paint()
                  ..color = Colors.white
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 5)),
        Text.rich(
            const TextSpan(children: [
              TextSpan(text: 'A', style: TextStyle(color: Color(0xFFFF3192))),
              TextSpan(text: 'B', style: TextStyle(color: Color(0xFF0077EE))),
              TextSpan(text: 'C', style: TextStyle(color: Color(0xFFFFB51C))),
            ]),
            textScaler: TextScaler.noScaling,
            style: style.copyWith(shadows: const [
              Shadow(color: Color(0x443E126C), offset: Offset(0, 2))
            ])),
      ]);
}
