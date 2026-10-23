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

  Widget _listen(String key, String label) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: FilledButton(
            key: ValueKey('listen-$key'),
            style: quickColorButtonStyle(
                index: label == 'Hear word' ? 1 : 0,
                radius: 100,
                minimumSize: const Size(48, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            onPressed:
                _playing || _saving || !_active ? null : () => _play(key),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                  _playingKey == key
                      ? Icons.graphic_eq_rounded
                      : Icons.volume_up_rounded,
                  size: 26),
              const SizedBox(width: 4),
              Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(label))),
            ]),
          )));
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
                  minimumSize: const Size(48, 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.all(6))
              .copyWith(
                  backgroundBuilder: embedded
                      ? (_, __, content) => content ?? const SizedBox.shrink()
                      : (context, states, content) => QuickChoiceArt(
                          index: artIndex,
                          selected: _picked == value,
                          pressed: states.contains(WidgetState.pressed),
                          focused: states.contains(WidgetState.focused),
                          child: content ?? const SizedBox.shrink())),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child:
                  child ?? Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900))));
  Widget _grid(List<Widget> children,
      {int columns = 2, double rowHeight = 76, double maxWidth = 340}) {
    final rows = (children.length / columns).ceil();
    return Center(
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: rows * rowHeight + (rows - 1) * 8),
            child: Column(children: [
              for (var row = 0; row < rows; row++) ...[
                if (row > 0) const SizedBox(height: 8),
                Expanded(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) const SizedBox(width: 8),
                        Expanded(
                            child: row * columns + column < children.length
                                ? children[row * columns + column]
                                : const SizedBox()),
                      ],
                    ])),
              ],
            ])));
  }

  Widget _letter(String letter) =>
      FittedBox(fit: BoxFit.scaleDown, child: QuickLetter(letter: letter));

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
    // Keep the activity together instead of stretching choices to fill a tablet
    // or a tall phone. Short screens can still use all the available height.
    final preferredHeight = switch (_skill) {
      AdventureSkill.matching => 320.0,
      AdventureSkill.sound => 300.0,
      AdventureSkill.spelling => 320.0,
      AdventureSkill.soundPicture => 320.0,
      AdventureSkill.hunt => 260.0,
    };
    return Center(
        child: SizedBox(
            height: height.clamp(0.0, preferredHeight),
            child: _taskContent(height.clamp(0.0, preferredHeight))));
  }

  Widget _taskContent(double height) {
    final c = _session.content;
    final pictureSize = (height * .35).clamp(48.0, 140.0);
    switch (_skill) {
      case AdventureSkill.matching:
        return Column(children: [
          Expanded(
              flex: 2,
              child: Center(
                  child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 280, maxHeight: 120),
                      child: Row(children: [
                        Expanded(child: _letter(c.letter)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Center(
                                child: AspectRatio(
                                    aspectRatio: 1,
                                    child: DragTarget<String>(
                                        onWillAcceptWithDetails: (_) =>
                                            _canAnswer,
                                        onAcceptWithDetails: (details) =>
                                            _submit(
                                                details.data,
                                                details.data ==
                                                    c.letter.toLowerCase()),
                                        builder: (_, candidates, __) => AnimatedContainer(
                                            key: const ValueKey(
                                                'lowercase-drop'),
                                            duration: const Duration(
                                                milliseconds: 150),
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                                color: candidates.isEmpty
                                                    ? Colors.white
                                                    : Colors.amber.shade100,
                                                border: Border.all(
                                                    color: const Color(0xFF7052CA),
                                                    width: 3),
                                                borderRadius: BorderRadius.circular(18)),
                                            child: _letter(_picked ?? '?')))))),
                      ])))),
          const SizedBox(height: 6),
          Expanded(
              flex: 3,
              child: _grid([
                for (final value in _session.matchOptions)
                  Draggable<String>(
                      data: value,
                      maxSimultaneousDrags: _canAnswer ? 1 : 0,
                      feedback: Material(
                          color: Colors.transparent,
                          child: QuickLetter(letter: value)),
                      childWhenDragging:
                          Opacity(opacity: .25, child: _letter(value)),
                      child: SizedBox.expand(
                          child: _choice(value, value == c.letter.toLowerCase(),
                              artIndex: _session.matchOptions.indexOf(value))))
              ])),
        ]);
      case AdventureSkill.sound:
        return Column(children: [
          Expanded(flex: 2, child: _letter(c.letter == 'Q' ? 'Qu' : c.letter)),
          const SizedBox(height: 6),
          Expanded(
              flex: 3,
              child: _grid([
                for (var i = 0; i < _session.soundOptions.length; i++)
                  QuickChoiceArt(
                      index: i,
                      selected: _picked == _session.soundOptions[i],
                      child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Row(children: [
                            _listenIcon(
                                'lesson-sound-${_session.soundOptions[i]}',
                                'Listen to sound ${i + 1}',
                                index: i,
                                embedded: true),
                            Expanded(
                                child: SizedBox.expand(
                                    child: _choice(_session.soundOptions[i],
                                        _session.soundOptions[i] == c.letter,
                                        embedded: true,
                                        enabled: _heard.contains(
                                            'lesson-sound-${_session.soundOptions[i]}'),
                                        child: const Text('Choose',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w900))))),
                          ])))
              ])),
        ]);
      case AdventureSkill.spelling:
        final key = adventureWordKey(c.word);
        return Column(children: [
          Expanded(
              flex: 2,
              child: Row(children: [
                Expanded(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _picture(c.word, pictureSize))),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(children: [
                  Expanded(
                      child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) => SlideTransition(
                              position:
                                  Tween(begin: const Offset(0, -.3), end: Offset.zero)
                                      .animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child)),
                          child: QuickGlassPanel(
                              key: ValueKey(_reviewCorrect),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child:
                                      Text(_reviewCorrect ? c.word.toUpperCase() : c.maskedWord,
                                          style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900)))))),
                  const SizedBox(height: 4),
                  SizedBox(height: 48, child: _listen(key, 'Hear word')),
                ])),
              ])),
          const SizedBox(height: 6),
          Expanded(
              flex: 3,
              child: _grid([
                for (final value in _session.spellingOptions)
                  _choice(value, value == c.letter,
                      enabled: _heard.contains(key),
                      artIndex: _session.spellingOptions.indexOf(value))
              ])),
        ]);
      case AdventureSkill.soundPicture:
        return Column(children: [
          SizedBox(height: 48, child: _listen(c.soundKey, 'Hear sound')),
          const SizedBox(height: 6),
          Expanded(
              child: _grid([
            for (var i = 0; i < _session.pictureOptions.length; i++)
              QuickChoiceArt(
                  index: i,
                  selected: _picked == _session.pictureOptions[i],
                  child: Row(children: [
                    Expanded(
                        child: SizedBox.expand(
                            child: _choice(_session.pictureOptions[i],
                                _session.pictureOptions[i] == c.pictureWord,
                                enabled: _heard.contains(c.soundKey),
                                embedded: true,
                                child: Semantics(
                                    label: 'Choose picture ${i + 1}',
                                    child: _picture(_session.pictureOptions[i],
                                        pictureSize))))),
                    _listenIcon(adventureWordKey(_session.pictureOptions[i]),
                        'Hear picture ${i + 1}',
                        index: i, embedded: true),
                  ]))
          ], rowHeight: 112, maxWidth: 360)),
        ]);
      case AdventureSkill.hunt:
        final found = _review ? _reviewHunted : _session.hunted;
        return Column(children: [
          Expanded(
              child: Row(children: [
            Expanded(child: _letter('${c.letter} ${c.letter.toLowerCase()}')),
            const SizedBox(width: 8),
            Flexible(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: QuickGlassPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Text('${found.length} / 4 found',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15))))),
          ])),
          const SizedBox(height: 6),
          Expanded(
              flex: 4,
              child: _grid([
                for (var i = 0; i < _session.huntLetters.length; i++)
                  FilledButton(
                      key: ValueKey('hunt-$i'),
                      onPressed: _canAnswer && !found.contains(i)
                          ? () => _hunt(i)
                          : null,
                      style: quickColorButtonStyle(
                          index: found.contains(i)
                              ? 2
                              : _wrongHunt.contains(i)
                                  ? 1
                                  : i,
                          selected: found.contains(i),
                          radius: 18,
                          padding: const EdgeInsets.all(2),
                          minimumSize: const Size(48, 48)),
                      child: Text(_session.huntLetters[i],
                          style: const TextStyle(
                              color: Color(0xFFFFF9E9),
                              fontSize: 24,
                              fontWeight: FontWeight.w900)))
              ], columns: 4, rowHeight: 56, maxWidth: 320)),
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
                label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Practice these skills')))
            : passed && next != null
                ? FilledButton.icon(
                    onPressed: () => LearnerNavigation.open(context,
                        LetterMasteryCheckScreen(letter: letterContent(next)),
                        replace: true, cloudTransition: true),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Continue to Letter $next')))
                : null,
        actions: [
          if (passed && answers.contains(false))
            _resultAction(
                Icons.favorite_rounded, 'Practice these skills', _startReview),
          _resultAction(Icons.refresh_rounded, 'Try Again', _restart),
          _resultAction(
              Icons.menu_book_rounded,
              'Review Lesson',
              () => LearnerNavigation.open(context,
                  LetterIntroductionScreen(letter: _session.content.letter))),
          _resultAction(Icons.bar_chart_rounded, 'View My Progress',
              () => LearnerNavigation.open(context, const ProgressScreen())),
          _resultAction(Icons.home_rounded, 'Back to Home',
              () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]);
  }

  Widget _resultAction(IconData icon, String label, VoidCallback onPressed) =>
      TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE8D9FF),
              foregroundColor: quickPurple,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.all(4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22))),
          child: Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: 3),
            Expanded(
                child: LayoutBuilder(
                    builder: (_, box) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                            width: box.maxWidth,
                            child: Text(label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)))))),
          ]));

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
        builder: (context, size) {
          if (_result) {
            return CompletionCelebration(
                enabled:
                    AdventurePolicy.passes(_session.firstAnswers.cast<bool>()),
                child: _results());
          }
          final compact = size.height < 500;
          final gap = compact ? 4.0 : 10.0;
          final instructionHeight = compact ? 64.0 : 80.0;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_intro)
                  QuickGlassPanel(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Column(children: [
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                'Take five little steps with Letter ${_session.content.letter}!',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900))),
                        _progressStars(),
                      ]))
                else
                  QuickProgress(
                      compact: compact,
                      current: _step + 1,
                      completed:
                          _session.firstAnswers.where((a) => a != null).length,
                      trailing: _progressStars(size: compact ? 18 : 22)),
                SizedBox(height: gap),
                SizedBox(
                    height: instructionHeight,
                    child: QuickInstruction(
                        text: adventureInstructions[_instructionKey]!,
                        intro: _intro,
                        replay: _instructionReplay())),
                SizedBox(height: gap),
                SizedBox(
                    height: compact ? 30 : 36,
                    child: QuickWoodSign(
                        label: _intro
                            ? 'Letter ${_session.content.letter} Adventure!'
                            : _skill.label)),
                SizedBox(height: gap),
                if (_review) ...[
                  _compactNotice(
                      'Guided practice - Score stays ${_session.score}/5'),
                  SizedBox(height: gap),
                ],
                Expanded(
                    child: _intro
                        ? Center(
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: 220, maxHeight: 220),
                                child: Image.asset(
                                    'assets/images/letters/${_session.content.letter.toLowerCase()}.webp',
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true)))
                        : LayoutBuilder(
                            builder: (_, task) => _task(task.maxHeight))),
                if (_error != null || _answered || _reviewFeedback != null) ...[
                  SizedBox(height: gap),
                  _compactNotice([
                    if (_error != null) _error!,
                    if (_answered || _reviewFeedback != null)
                      _reviewFeedback ??
                          (_review ? 'Nice work!' : 'Answer saved!'),
                  ].join(' ')),
                ],
                if (_intro || _answered) ...[
                  SizedBox(height: gap),
                  Center(
                      child: SizedBox(
                          width: 300,
                          height: compact ? 48 : 52,
                          child: _intro
                              ? FilledButton.icon(
                                  key: const ValueKey('start-adventure'),
                                  onPressed: !_active || _playing
                                      ? null
                                      : () {
                                          setState(() => _intro = false);
                                          _narrate(_instructionKey);
                                        },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Start Adventure'))
                              : FilledButton(
                                  onPressed: _saving || _playing ? null : _next,
                                  child: Text(_saving
                                      ? 'Saving...'
                                      : _review
                                          ? 'Continue'
                                          : _step == 4
                                              ? 'See Result'
                                              : 'Next Challenge')))),
                ],
              ]);
        },
      );

  Widget _compactNotice(String text) => SizedBox(
      height: 24,
      child: QuickGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w900)))));

  Widget _progressStars({double size = 32}) {
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
                  size: size)),
        )));
  }
}
