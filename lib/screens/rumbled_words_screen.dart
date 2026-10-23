import 'dart:async';

import '../widgets/answer_choice_button.dart';
import '../widgets/game_design.dart';
import '../data/game_word_data.dart';
import '../data/game_session_order.dart';
import 'package:flutter/material.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/game_mascot_coach.dart';
import 'package:provider/provider.dart';
import '../data/rumbled_words_data.dart';
import '../models/difficulty.dart';
import '../providers/app_provider.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/word_game_layout.dart';
import '../widgets/floating_choice.dart';
import '../widgets/rumbled_words_design.dart';

class RumbledWordsScreen extends StatefulWidget {
  const RumbledWordsScreen({super.key, this.difficulty = Difficulty.easy});
  final Difficulty difficulty;

  @override
  State<RumbledWordsScreen> createState() => _RumbledWordsScreenState();
}

class _RumbledWordsScreenState extends State<RumbledWordsScreen>
    with GameSessionUi<RumbledWordsScreen> {
  int _index = 0;
  late List<GameWord> _words = _newSession();
  List<GameWord> _newSession() => GameSessionOrder.next(
      'rumbled-${widget.difficulty.name}',
      rumbledWordsFor(widget.difficulty),
      (w) => w.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  late List<String> _tiles;
  final List<int> _selected = [];
  bool _hintUsed = false;
  bool? _correct;
  int _readingStep = 0;
  int _activeLetter = -1;
  bool _readingWord = false;
  bool _runningPlayback = false;
  int _roundGeneration = 0;
  Timer? _resumeTimer, _highlightTimer;
  Completer<void>? _highlightDone;
  bool get _finished => _correct == true || resultOpen;
  String get _word => _words[_index].word.toUpperCase();

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    _roundGeneration++;
    _resumeTimer?.cancel();
    _endHighlightDelay();
    _readingStep = 0;
    _activeLetter = -1;
    _readingWord = false;
    _tiles = _word.split('')..shuffle();
    if (_tiles.join() == _word) _tiles.add(_tiles.removeAt(0));
    _selected.clear();
    _hintUsed = false;
    _correct = null;
  }

  void _tapTile(int index) {
    if (_finished || _selected.contains(index) || !canAdvanceGameFeedback) {
      return;
    }
    setState(() {
      _selected.add(index);
      _correct = null;
    });
    gameNarration.cancel();
    final sound = gameNarration.letterSound(_tiles[index]);
    if (_selected.length == _tiles.length) unawaited(_check(sound));
  }

  Future<void> _check(Future<void> selectionSound) async {
    if (_finished || _selected.length != _tiles.length) return;
    final correct = _selected.map((i) => _tiles[i]).join() == _word;
    setState(() => _correct = correct);
    recordGameAnswer(correct: correct);
    if (correct) {
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
    }
    final round = _roundGeneration;
    final selectionGeneration = gameNarration.generation;
    // Let the final selected tile finish sounding before reading the built word.
    await selectionSound;
    if (!mounted || round != _roundGeneration) return;
    if (correct) {
      unawaited(_readCompletedWord());
    } else if (_correct == false &&
        canAdvanceGameFeedback &&
        selectionGeneration == gameNarration.generation) {
      unawaited(playGameWrong());
    }
  }

  void _endHighlightDelay() {
    _highlightTimer?.cancel();
    final done = _highlightDone;
    _highlightDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _holdHighlight() {
    _endHighlightDelay();
    final done = Completer<void>();
    _highlightDone = done;
    // Still show each step when voice is muted or a recording fails to play.
    _highlightTimer = Timer(const Duration(milliseconds: 400), () {
      if (!done.isCompleted) done.complete();
      if (_highlightDone == done) _highlightDone = null;
    });
    return done.future;
  }

  Future<void> _readCompletedWord() async {
    if (_runningPlayback || !mounted || _correct != true || resultOpen) return;
    _resumeTimer?.cancel();
    _runningPlayback = true;
    final round = _roundGeneration;
    final provider = context.read<AppProvider>();
    bool current() => mounted && round == _roundGeneration && !resultOpen;
    try {
      while (mounted && current() && _readingStep <= _word.length) {
        if (!canAdvanceGameFeedback) return;
        gameNarration.updateEnvironment(
            enabled: provider.voiceEnabled, active: true);
        final wholeWord = _readingStep == _word.length;
        setState(() {
          _activeLetter = wholeWord ? -1 : _readingStep;
          _readingWord = wholeWord;
        });
        final hold = _holdHighlight();
        final playback = wholeWord
            ? gameNarration.word(_words[_index].audioKey)
            : gameNarration.letterSound(_word[_readingStep]);
        final audioGeneration = gameNarration.generation;
        await playback;
        await hold;
        if (!current()) return;
        // Replay the interrupted step after returning, including repeated letters.
        if (!canAdvanceGameFeedback ||
            audioGeneration != gameNarration.generation) {
          return;
        }
        _readingStep++;
      }
      if (current() && canAdvanceGameFeedback) _next();
    } finally {
      _runningPlayback = false;
      if (current() && _correct == true) {
        _resumeTimer = Timer(const Duration(milliseconds: 200), () {
          unawaited(_readCompletedWord());
        });
      }
    }
  }

  void _next() {
    if (_correct != true || resultOpen) return;
    if (_index + 1 < _words.length) {
      setState(() {
        _index++;
        _prepare();
      });
    } else {
      resultOpen = true;
      final p = context.read<AppProvider>();
      p.recordActivityCompleted();
      awardGameXp((15 * widget.difficulty.xpMultiplier).round());
      p.audio.playWin();
      showGameResult(_restart);
    }
  }

  void _restart() => setState(() {
        _index = 0;
        _words = _newSession();
        _prepare();
      });

  @override
  void dispose() {
    _roundGeneration++;
    _resumeTimer?.cancel();
    _endHighlightDelay();
    super.dispose();
  }

  @override
  int get totalGameItems => _words.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        narration: gameNarration,
        fitViewport: true,
        answerResult: _correct,
        title: 'Rumbled Words',
        roundHeader: RumbledRoundHeader(
            difficulty: widget.difficulty,
            current: _index + 1,
            total: _words.length),
        instructions: 'Tap letters to spell the word.',
        instructionPanel: GameMascotCoach(
            title: 'Rumbled Words',
            instructions: 'Tap letters to spell the word.',
            controller: gameNarration,
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).height < 650 ? 220 : 340),
                child: const GameInstructionGuide(gameTitle: 'Rumbled Words'))),
        difficulty: widget.difficulty,
        current: _index + 1,
        total: _words.length,
        progressLabel: 'Word',
        hasProgress:
            (_selected.isNotEmpty || scoredAttempts > 0 || _hintUsed) &&
                !resultOpen,
        child: LayoutBuilder(builder: (context, box) {
          final compact = box.maxHeight < 440;
          final columns =
              _tiles.length <= 5 ? _tiles.length : (_tiles.length / 2).ceil();
          final rows = (_tiles.length / columns).ceil();
          final gap = compact
              ? 3.0
              : rows > 1
                  ? 6.0
                  : 8.0;
          final padding = compact
              ? 2.0
              : rows > 1
                  ? 6.0
                  : 10.0;
          final buttonHeight = compact
              ? 44.0
              : rows > 1
                  ? 48.0
                  : 54.0;
          final extra = (_hintUsed ? 28.0 : 0.0) +
              (_correct != null && !compact ? 44.0 : 0.0);
          final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
          // Short screens keep the same board/control/letters order, with the
          // three controls sharing a row instead of shrinking the entire board.
          final actionSpace = compact
              ? buttonHeight + 40 * textScale
              : 3 * buttonHeight + 24 * textScale;
          final fixed = 4 * padding +
              20 +
              actionSpace +
              36 +
              (compact ? 5 : 7) * gap +
              2 * (rows - 1) * gap +
              extra;
          final widthLimit =
              (box.maxWidth - 2 * padding - 10 - (columns - 1) * gap) / columns;
          final preferredSide = widthLimit.clamp(48.0, 80.0);
          final side = ((box.maxHeight - 60 - fixed) / (2 * rows)).clamp(
              (compact ? 48.0 : 56.0).clamp(0.0, preferredSide), preferredSide);
          final picture = (box.maxHeight - fixed - 2 * rows * side - 6)
              .clamp(compact && rows > 1 ? 32.0 : 64.0, 220.0);
          Widget grid(List<Widget> children) => RumbledTileGrid(
              side: side, columns: columns, gap: gap, children: children);
          Widget action(double width, Widget child) => Center(
              child: SizedBox(
                  width: width.clamp(0.0, box.maxWidth), child: child));
          return WordGameLayout(
              word: _words[_index].word,
              pictureExtent: picture,
              children: [
                ForestPanel(
                    key: const ValueKey('word-answer-board'),
                    padding: EdgeInsets.all(padding),
                    child: grid([
                      for (var slot = 0; slot < _tiles.length; slot++)
                        _tile(
                            key: ValueKey('word-slot-$slot'),
                            label: slot < _selected.length
                                ? _tiles[_selected[slot]]
                                : '_',
                            filled: true,
                            variant: 0,
                            highlightKey: ValueKey('word-highlight-$slot'),
                            highlighted: _readingWord || _activeLetter == slot,
                            onTap: _finished || slot >= _selected.length
                                ? null
                                : () => setState(() {
                                      _selected.removeAt(slot);
                                      _correct = null;
                                    })),
                    ])),
                SizedBox(height: gap),
                if (compact)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        flex: 3,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          RumbledActionButton(
                              buttonKey: const ValueKey('word-hint'),
                              height: buttonHeight,
                              purple: true,
                              label: 'Hint',
                              icon: Icons.lightbulb_outline_rounded,
                              onPressed: _hintUsed || _finished
                                  ? null
                                  : () => setState(() => _hintUsed = true)),
                          SizedBox(
                              height: 18,
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      _hintUsed ? 'Hint used' : '1 per word',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: GameDesign.ink,
                                          fontWeight: FontWeight.w900))))
                        ])),
                    SizedBox(width: gap),
                    Expanded(
                        flex: 4,
                        child: AudioButton(
                            phrase: _words[_index].audioKey,
                            enabled: !_finished,
                            statusBuilder: (message) => SizedBox(
                                height: 18,
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(message,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: GameDesign.ink)))),
                            controlBuilder: (context, onPlay, playing, label) =>
                                RumbledActionButton(
                                    buttonKey: const ValueKey('word-hear'),
                                    label: label,
                                    icon: playing
                                        ? Icons.graphic_eq_rounded
                                        : Icons.volume_up_rounded,
                                    onPressed: onPlay,
                                    height: buttonHeight))),
                    SizedBox(width: gap),
                    Expanded(flex: 3, child: _eraseButton(buttonHeight)),
                  ])
                else ...[
                  action(
                      290,
                      Container(
                          decoration: BoxDecoration(
                              color: GameDesign.cream,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                  color: const Color(0xFFFFD878), width: 2)),
                          child: Row(children: [
                            Expanded(
                                child: RumbledActionButton(
                                    buttonKey: const ValueKey('word-hint'),
                                    height: buttonHeight,
                                    purple: true,
                                    onPressed: _hintUsed || _finished
                                        ? null
                                        : () =>
                                            setState(() => _hintUsed = true),
                                    icon: Icons.lightbulb_outline_rounded,
                                    label: 'Hint')),
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                            _hintUsed
                                                ? 'Hint used'
                                                : '1 per word',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: GameDesign.ink)))))
                          ]))),
                  SizedBox(height: gap),
                  AudioButton(
                      phrase: _words[_index].audioKey,
                      enabled: !_finished,
                      statusBuilder: (message) => SizedBox(
                          height: 18,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(message,
                                  style: const TextStyle(
                                      fontSize: 14, color: GameDesign.ink)))),
                      controlBuilder: (context, onPlay, playing, label) =>
                          action(
                              310,
                              RumbledActionButton(
                                  buttonKey: const ValueKey('word-hear'),
                                  label: label,
                                  icon: playing
                                      ? Icons.graphic_eq_rounded
                                      : Icons.volume_up_rounded,
                                  onPressed: onPlay,
                                  height: buttonHeight))),
                ],
                if (_hintUsed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                        height: 24,
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Starts with ${_word[0]}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)))),
                  ),
                SizedBox(height: gap),
                if (!compact) action(230, _eraseButton(buttonHeight)),
                SizedBox(height: gap),
                if (compact)
                  Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                          color: GameDesign.cream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFFD878), width: 2)),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              _correct == null
                                  ? 'Tap a chosen letter to put it back.'
                                  : _correct!
                                      ? 'Correct!'
                                      : 'Try again! Tap Erase or a letter to change it.',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: GameDesign.ink,
                                  fontWeight: FontWeight.w900))))
                else
                  const ForestPanel(
                      leaves: false,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Tap a chosen letter to put it back.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)))),
                SizedBox(height: gap),
                ForestPanel(
                    key: const ValueKey('word-letter-board'),
                    padding: EdgeInsets.all(padding),
                    child: grid([
                      for (var i = 0; i < _tiles.length; i++)
                        _tile(
                            key: ValueKey('word-tile-$i'),
                            label: _tiles[i],
                            variant: const [4, 2, 3, 1, 0][i % 5],
                            used: _selected.contains(i),
                            onTap: _finished || _selected.contains(i)
                                ? null
                                : () => _tapTile(i)),
                    ])),
                SizedBox(height: gap),
                if (_correct != null && !compact)
                  Text(
                      _correct!
                          ? 'Correct!'
                          : 'Try again! Tap Erase or a letter to change it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _correct!
                              ? const Color(0xFF167769)
                              : const Color(0xFFB45731))),
                const SizedBox(height: 4),
              ]);
        }),
      );

  Widget _eraseButton(double height) {
    final enabled = !_finished && _selected.isNotEmpty;
    return RumbledActionButton(
        buttonKey: const ValueKey('word-erase'),
        label: 'Erase',
        icon: Icons.backspace_rounded,
        height: height,
        cream: true,
        onPressed: enabled
            ? () => setState(() {
                  _selected.removeLast();
                  _correct = null;
                })
            : null);
  }

  Widget _tile(
          {required Key key,
          required String label,
          VoidCallback? onTap,
          bool filled = false,
          bool used = false,
          int variant = 0,
          Key? highlightKey,
          bool highlighted = false}) =>
      AnimatedScale(
        scale:
            highlighted && !MediaQuery.disableAnimationsOf(context) ? 1.04 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: AnimatedContainer(
          key: highlightKey,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          decoration: BoxDecoration(
              color: highlighted ? const Color(0xFFFFE36B) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: highlighted
                      ? const Color(0xFFFFB300)
                      : Colors.transparent,
                  width: 3),
              boxShadow: highlighted
                  ? const [BoxShadow(color: Color(0x99FFD23F), blurRadius: 12)]
                  : const []),
          child: SizedBox.expand(
            child: FloatingChoice(
                enabled: !filled && onTap != null && !_finished,
                seed: label.codeUnitAt(0),
                child: Opacity(
                    opacity: used ? .38 : 1,
                    child: AnswerChoiceButton(
                      buttonKey: key,
                      onPressed: onTap,
                      variant: variant,
                      selected: highlighted,
                      child: LayoutBuilder(
                          builder: (context, box) => FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(label,
                                  style: TextStyle(
                                      color: GameDesign.ink,
                                      fontSize: (box.maxHeight * .9)
                                          .clamp(28.0, 48.0),
                                      fontWeight: FontWeight.w900)))),
                    ))),
          ),
        ),
      );
}
