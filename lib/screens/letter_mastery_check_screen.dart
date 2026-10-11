import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/adventure_narration.dart';
import '../data/letter_data.dart';
import '../models/letter_adventure.dart';
import '../providers/app_provider.dart';
import '../services/mastery_audio_service.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/completion_celebration.dart';
import '../widgets/quick_check_design.dart';
import '../widgets/quick_choice_art.dart';
import '../widgets/quick_adventure_result.dart';
import 'letter_introduction_screen.dart';
import 'progress_screen.dart';

class LetterMasteryCheckScreen extends StatefulWidget {
  const LetterMasteryCheckScreen({super.key, required this.letter, this.audio});
  final LetterItem letter;
  final MasteryAudio? audio;
  @override
  State<LetterMasteryCheckScreen> createState() =>
      _LetterMasteryCheckScreenState();
}

class _LetterMasteryCheckScreenState extends State<LetterMasteryCheckScreen>
    with WidgetsBindingObserver {
  late AdventureSession _session = AdventureSession(widget.letter.letter);
  late final MasteryAudio _audio = widget.audio ?? LocalMasteryAudio();
  bool _intro = true, _result = false, _review = false, _saving = false;
  bool _playing = false, _foreground = true, _reviewCorrect = false;
  int _step = 0, _request = 0, _xp = 0, _stars = 0;
  String? _picked, _playingKey, _error, _reviewFeedback;
  final _heard = <String>{};
  final _reviewHunted = <int>{};
  final _wrongHunt = <int>{};
  List<int> _reviewOrder = [];
  AdventureSkill get _skill => AdventureSkill.values[_step];
  bool get _active =>
      _foreground &&
      (ModalRoute.isCurrentOf(context) ?? true) &&
      !context.read<AppProvider>().timeLimitReached;
  bool get _canAnswer =>
      !_intro &&
      !_result &&
      !_saving &&
      !_playing &&
      _active &&
      (_review ? !_reviewCorrect : _session.firstAnswers[_step] == null);
  String get _instructionKey => _intro
      ? 'intro'
      : switch (_skill) {
          AdventureSkill.matching => 'match',
          AdventureSkill.sound => 'sound',
          AdventureSkill.spelling => 'spelling',
          AdventureSkill.soundPicture => 'picture-${_session.content.position}',
          AdventureSkill.hunt => 'hunt',
        };
  bool get _answered =>
      _review ? _reviewCorrect : _session.firstAnswers[_step] != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _narrate('intro');
  }

  void _narrate(String key) {
    final request = _request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          request == _request &&
          adventureNarrationAssets.containsKey(key) &&
          context.read<AppProvider>().voiceEnabled) {
        unawaited(_play('adventure-$key'));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<AppProvider>();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (!current ||
        !_foreground ||
        context.read<AppProvider>().timeLimitReached ||
        (!context.read<AppProvider>().voiceEnabled &&
            (_playingKey?.startsWith('adventure-') ?? false))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cancelAudio();
      });
    }
  }

  void _cancelAudio() {
    _request++;
    unawaited(_audio.stop());
    if (mounted) {
      setState(() {
        _playing = false;
        _playingKey = null;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancelAudio();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _request++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_audio.dispose());
    super.dispose();
  }

  Future<void> _play(String key) async {
    if (_playing || !_active || _saving) return;
    final request = ++_request;
    setState(() {
      _playing = true;
      _playingKey = key;
      _error = null;
    });
    final p = context.read<AppProvider>();
    if (key.startsWith('adventure-') && !p.voiceEnabled) {
      _cancelAudio();
      return;
    }
    await _audio.stop();
    if (widget.audio == null) {
      await p.audio.stop();
      await p.phonicsAudio.stop();
    }
    if (!mounted || request != _request || !_active) return;
    final completed = await _audio.play(key);
    if (!mounted || request != _request || !_active) return;
    setState(() {
      _playing = false;
      _playingKey = null;
      if (completed) {
        _heard.add(key);
      } else {
        _error = 'The recording did not finish. Please listen again.';
      }
    });
  }

  void _resetTask() {
    _cancelAudio();
    _picked = null;
    _error = null;
    _reviewFeedback = null;
    _reviewCorrect = false;
    _heard.clear();
    _reviewHunted.clear();
    _wrongHunt.clear();
  }

  void _submit(String picked, bool correct) {
    if (!_canAnswer) return;
    if (_review) {
      setState(() {
        _picked = picked;
        _reviewCorrect = correct;
        _reviewFeedback =
            correct ? 'Nice work!' : 'Good try. Try another answer.';
      });
      final p = context.read<AppProvider>();
      if (correct && _skill == AdventureSkill.spelling && p.voiceEnabled) {
        unawaited(_play(adventureWordKey(_session.content.word)));
      } else {
        unawaited(correct ? p.audio.playCorrect() : p.audio.playWrong());
      }
    } else if (_session.submit(_skill, correct)) {
      setState(() => _picked = picked);
      // Neutral acknowledgement: corrections wait until all first responses.
      unawaited(context.read<AppProvider>().audio.playFlip());
      _narrate('saved');
    }
  }

  void _hunt(int index) {
    if (!_canAnswer) return;
    final found = _review ? _reviewHunted : _session.hunted;
    if (found.contains(index)) return;
    final correct =
        _session.huntLetters[index].toUpperCase() == _session.content.letter;
    setState(() {
      if (_review) {
        if (correct) _reviewHunted.add(index);
        _reviewCorrect = _reviewHunted.length == 4;
      } else {
        _session.hunt(index);
      }
      if (!correct) _wrongHunt.add(index);
    });
    final p = context.read<AppProvider>();
    unawaited(correct ? p.audio.playCorrect() : p.audio.playWrong());
    if (!_review && _session.firstAnswers[AdventureSkill.hunt.index] != null) {
      _narrate('saved');
    }
  }

  Future<void> _next() async {
    if (!_answered || _saving || _playing || !_active) return;
    if (_review) {
      final next = _reviewOrder.indexOf(_step) + 1;
      _resetTask();
      setState(() {
        if (next < _reviewOrder.length) {
          _step = _reviewOrder[next];
        } else {
          _review = false;
          _result = true;
        }
      });
      if (_review) _narrate(_instructionKey);
      return;
    }
    if (_step < 4) {
      _resetTask();
      setState(() => _step++);
      _narrate(_instructionKey);
      return;
    }
    setState(() => _saving = true);
    final rewards = await context.read<AppProvider>().completeAdventure(
        _session.content.letter,
        _session.firstAnswers.cast<bool>(),
        _session.id);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = true;
      _xp = rewards.xp;
      _stars = rewards.stars;
    });
    _narrate(AdventurePolicy.passes(_session.firstAnswers.cast<bool>())
        ? 'mastered'
        : 'practice');
  }

  void _restart() {
    _resetTask();
    setState(() {
      _session = AdventureSession(widget.letter.letter);
      _step = 0;
      _intro = true;
      _result = false;
      _review = false;
      _xp = 0;
      _stars = 0;
    });
    _narrate('intro');
  }

  void _startReview() {
    _reviewOrder = [
      for (var i = 0; i < 5; i++)
        if (_session.firstAnswers[i] == false) i
    ];
    if (_reviewOrder.isEmpty) return;
    _resetTask();
    setState(() {
      _step = _reviewOrder.first;
      _review = true;
      _result = false;
    });
    _narrate(_instructionKey);
  }

  Widget _listen(String key, String label) => QuickAudioButton(
        key: ValueKey('listen-$key'),
        label: label,
        index: label == 'Hear word' ? 1 : 0,
        playing: _playingKey == key,
        onPressed: _playing || _saving || !_active ? null : () => _play(key),
      );
  Widget _listenIcon(String key, String label,
          {int index = 0, bool embedded = false}) =>
      QuickAudioButton(
        key: ValueKey('listen-$key'),
        label: label,
        index: index,
        compact: true,
        embedded: embedded,
        playing: _playingKey == key,
        onPressed: _playing || _saving || !_active ? null : () => _play(key),
      );

  Widget _choice(String value, bool correct,
          {Widget? child,
          bool enabled = true,
          int artIndex = 0,
          bool embedded = false}) =>
      ElevatedButton(
          key: ValueKey('adventure-option-$value'),
          onPressed:
              _canAnswer && enabled ? () => _submit(value, correct) : null,
          style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFFFFF9E9),
                  disabledForegroundColor: const Color(0xFFFFF9E9),
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  minimumSize: const Size(48, 68),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16))
              .copyWith(
                  backgroundBuilder: embedded
                      ? (_, __, content) => content ?? const SizedBox.shrink()
                      : (context, states, content) => QuickChoiceArt(
                          index: artIndex,
                          selected: _picked == value,
                          pressed: states.contains(WidgetState.pressed),
                          focused: states.contains(WidgetState.focused),
                          child: content ?? const SizedBox.shrink())),
          child: child ??
              Text(value,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)));
  Widget _grid(List<Widget> children, {int columns = 2}) => LayoutBuilder(
      builder: (_, box) => Wrap(spacing: 10, runSpacing: 10, children: [
            for (final child in children)
              SizedBox(
                  width: (box.maxWidth - (columns - 1) * 10) / columns,
                  child: child)
          ]));
  Widget _letter(String letter) => QuickLetter(letter: letter);

  Widget _picture(String word, double size) => ExcludeSemantics(
      // The supplied zebra lesson art includes a large Z. Use an unlabelled
      // illustration so it cannot reveal the missing letter or sound answer.
      child: word == 'Zebra'
          ? SizedBox(
              height: size,
              child: Center(
                  child: Text('🦓', style: TextStyle(fontSize: size * .8))))
          : Image.asset(adventurePicture(word), height: size));

  Widget _task(double height) {
    final c = _session.content;
    final pictureSize = (height * .16).clamp(60.0, 112.0);
    switch (_skill) {
      case AdventureSkill.matching:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _letter(c.letter),
            const SizedBox(width: 20),
            DragTarget<String>(
                onWillAcceptWithDetails: (_) => _canAnswer,
                onAcceptWithDetails: (details) => _submit(
                    details.data, details.data == c.letter.toLowerCase()),
                builder: (_, candidates, __) => AnimatedContainer(
                    key: const ValueKey('lowercase-drop'),
                    duration: const Duration(milliseconds: 150),
                    width: 108,
                    height: 105,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: candidates.isEmpty
                            ? Colors.white
                            : Colors.amber.shade100,
                        border: Border.all(
                            color: const Color(0xFF7052CA), width: 3),
                        borderRadius: BorderRadius.circular(18)),
                    child: QuickLetter(letter: _picked ?? '?', size: 64))),
          ]),
          const SizedBox(height: 16),
          _grid([
            for (final value in _session.matchOptions)
              Draggable<String>(
                  data: value,
                  maxSimultaneousDrags: _canAnswer ? 1 : 0,
                  feedback: Material(
                      color: Colors.transparent, child: _letter(value)),
                  childWhenDragging:
                      Opacity(opacity: .25, child: _letter(value)),
                  child: _choice(value, value == c.letter.toLowerCase(),
                      artIndex: _session.matchOptions.indexOf(value)))
          ], columns: 2),
        ]);
      case AdventureSkill.sound:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          QuickLetter(letter: c.letter == 'Q' ? 'Qu' : c.letter, size: 110),
          const SizedBox(height: 14),
          _grid([
            for (var i = 0; i < _session.soundOptions.length; i++)
              QuickChoiceArt(
                  index: i,
                  selected: _picked == _session.soundOptions[i],
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 4, 4, 8),
                      child: Row(children: [
                        _listenIcon('lesson-sound-${_session.soundOptions[i]}',
                            'Listen to sound ${i + 1}',
                            index: i, embedded: true),
                        Expanded(
                            child: _choice(_session.soundOptions[i],
                                _session.soundOptions[i] == c.letter,
                                embedded: true,
                                enabled: _heard.contains(
                                    'lesson-sound-${_session.soundOptions[i]}'),
                                child: const Text('Choose',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)))),
                      ])))
          ]),
        ]);
      case AdventureSkill.spelling:
        final key = adventureWordKey(c.word);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _picture(c.word, pictureSize * 1.3),
          AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(begin: const Offset(0, -.3), end: Offset.zero)
                      .animate(animation),
                  child: FadeTransition(opacity: animation, child: child)),
              child: QuickGlassPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Text(
                      _reviewCorrect ? c.word.toUpperCase() : c.maskedWord,
                      key: ValueKey(_reviewCorrect),
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w900)))),
          _listen(key, 'Hear word'),
          const SizedBox(height: 10),
          _grid([
            for (final value in _session.spellingOptions)
              _choice(value, value == c.letter,
                  enabled: _heard.contains(key),
                  artIndex: _session.spellingOptions.indexOf(value))
          ], columns: 2),
        ]);
      case AdventureSkill.soundPicture:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _listen(c.soundKey, 'Hear sound'),
          const SizedBox(height: 12),
          _grid([
            for (var i = 0; i < _session.pictureOptions.length; i++)
              QuickChoiceArt(
                  index: i,
                  selected: _picked == _session.pictureOptions[i],
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        width: double.infinity,
                        child: _choice(_session.pictureOptions[i],
                            _session.pictureOptions[i] == c.pictureWord,
                            enabled: _heard.contains(c.soundKey),
                            embedded: true,
                            child: Semantics(
                                label: 'Choose picture ${i + 1}',
                                child: _picture(
                                    _session.pictureOptions[i], pictureSize)))),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _listenIcon(
                            adventureWordKey(_session.pictureOptions[i]),
                            'Hear picture ${i + 1}',
                            index: i,
                            embedded: true)),
                  ]))
          ]),
        ]);
      case AdventureSkill.hunt:
        final found = _review ? _reviewHunted : _session.hunted;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _letter('${c.letter} ${c.letter.toLowerCase()}'),
          QuickGlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text('${found.length} / 4 found',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 17))),
          const SizedBox(height: 8),
          _grid([
            for (var i = 0; i < _session.huntLetters.length; i++)
              FilledButton(
                  key: ValueKey('hunt-$i'),
                  onPressed:
                      _canAnswer && !found.contains(i) ? () => _hunt(i) : null,
                  style: quickColorButtonStyle(
                      index: found.contains(i)
                          ? 2
                          : _wrongHunt.contains(i)
                              ? 1
                              : i,
                      selected: found.contains(i),
                      radius: 18,
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                      minimumSize: const Size(48, 58)),
                  child: Text(_session.huntLetters[i],
                      style: const TextStyle(
                          color: Color(0xFFFFF9E9),
                          fontSize: 26,
                          fontWeight: FontWeight.w900)))
          ], columns: 4),
        ]);
    }
  }

  Widget _results() {
    final p = context.watch<AppProvider>();
    final answers = _session.firstAnswers.cast<bool>();
    final passed = AdventurePolicy.passes(answers);
    final retained =
        p.adventureProgress(_session.content.letter).mastered && !passed;
    final next = p.recommendedAdventureLetter;
    return QuickAdventureResult(
        letter: _session.content.letter,
        answers: answers,
        passed: passed,
        retained: retained,
        xp: _xp,
        stars: _stars,
        saveRetry: p.hasUnsavedChanges
            ? TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await p.retrySaving();
                        if (mounted) setState(() => _saving = false);
                      },
                child: const Text('Retry saving progress'))
            : null,
        primary: answers.contains(false) && !passed
            ? FilledButton.icon(
                onPressed: _startReview,
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('Practice these skills'))
            : passed && next != null
                ? FilledButton.icon(
                    onPressed: () => LearnerNavigation.open(context,
                        LetterMasteryCheckScreen(letter: letterContent(next)),
                        replace: true, cloudTransition: true),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text('Continue to Letter $next'))
                : null,
        actions: [
          if (passed && answers.contains(false))
            TextButton(
                onPressed: _startReview,
                child: const Text('Practice these skills')),
          _resultAction(Icons.refresh_rounded, 'Try Again', _restart),
          _resultAction(
              Icons.menu_book_rounded,
              'Review Lesson',
              () => LearnerNavigation.open(context,
                  LetterIntroductionScreen(letter: _session.content.letter))),
          _resultAction(Icons.bar_chart_rounded, 'View My Progress',
              () => LearnerNavigation.open(context, const ProgressScreen())),
          TextButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Home')),
        ]);
  }

  Widget _resultAction(IconData icon, String label, VoidCallback onPressed) =>
      SizedBox(
          width: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 150 : 90,
          child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE8D9FF),
                  foregroundColor: quickPurple,
                  padding: const EdgeInsets.all(6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 24),
                const SizedBox(height: 3),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900)),
              ])));

  Widget? _instructionReplay() =>
      adventureNarrationAssets.containsKey(_instructionKey)
          ? QuickAudioButton(
              label: 'Replay instruction',
              compact: true,
              index: 4,
              playing: _playingKey == 'adventure-$_instructionKey',
              onPressed: !_playing && context.read<AppProvider>().voiceEnabled
                  ? () => _play('adventure-$_instructionKey')
                  : null,
            )
          : null;

  @override
  Widget build(BuildContext context) => QuickCheckPage(
        hasProgress: !_intro && !_result,
        onLeave: _cancelAudio,
        builder: (context, size) => ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: (size.height - 92).clamp(0, double.infinity)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_result) ...[
                    if (!_intro) ...[
                      QuickProgress(
                          current: _step + 1,
                          completed: _session.firstAnswers
                              .where((a) => a != null)
                              .length),
                      const SizedBox(height: 10),
                    ],
                    QuickInstruction(
                        text: adventureInstructions[_instructionKey]!,
                        intro: _intro,
                        replay: _instructionReplay()),
                    const SizedBox(height: 14),
                  ],
                  if (_intro) ...[
                    QuickWoodSign(
                        label: 'Letter ${_session.content.letter} Adventure!'),
                    const SizedBox(height: 14),
                    Center(
                        child: Image.asset(
                            'assets/images/letters/${_session.content.letter.toLowerCase()}.webp',
                            height: (size.height * .24).clamp(88, 190),
                            excludeFromSemantics: true)),
                    const SizedBox(height: 12),
                    QuickGlassPanel(
                        child: Column(children: [
                      Text(
                          'Take five little steps with Letter ${_session.content.letter}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      _progressStars(),
                    ])),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                        key: const ValueKey('start-adventure'),
                        onPressed: !_active || _playing
                            ? null
                            : () {
                                setState(() => _intro = false);
                                _narrate(_instructionKey);
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Adventure')),
                  ] else if (_result) ...[
                    CompletionCelebration(
                        enabled: AdventurePolicy.passes(
                            _session.firstAnswers.cast<bool>()),
                        child: _results()),
                  ] else ...[
                    QuickWoodSign(label: _skill.label),
                    const SizedBox(height: 8),
                    _progressStars(),
                    if (_review)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: QuickGlassPanel(
                              child: Text(
                                  'Guided practice - Score stays ${_session.score}/5',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)))),
                    const SizedBox(height: 16),
                    _task(size.height),
                    const SizedBox(height: 12),
                    if (_error != null)
                      QuickGlassPanel(
                          child: Text(_error!, textAlign: TextAlign.center)),
                    if (_answered || _reviewFeedback != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: QuickGlassPanel(
                              child: Text(
                                  _reviewFeedback ??
                                      (_review
                                          ? 'Nice work!'
                                          : 'Answer saved!'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)))),
                    if (_answered)
                      FilledButton(
                          onPressed: _saving || _playing ? null : _next,
                          child: Text(_saving
                              ? 'Saving...'
                              : _review
                                  ? 'Continue'
                                  : _step == 4
                                      ? 'See Result'
                                      : 'Next Challenge')),
                  ],
                ])),
      );

  Widget _progressStars() {
    final completed = _session.firstAnswers.where((a) => a != null).length;
    return Semantics(
        label: '$completed of 5 challenges answered',
        child: ExcludeSemantics(
            child: Row(
          key: const ValueKey('adventure-progress-stars'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              5,
              (i) => Icon(
                  _session.firstAnswers[i] != null
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _session.firstAnswers[i] != null
                      ? const Color(0xFFFFBE30)
                      : const Color(0xFFA997D4),
                  shadows: const [
                    Shadow(
                        color: Colors.white,
                        offset: Offset(0, -1),
                        blurRadius: 2)
                  ],
                  size: 32)),
        )));
  }
}
