import 'dart:async';

import '../widgets/answer_choice_button.dart';
import '../widgets/button_sound.dart';
import '../widgets/game_design.dart';
import '../data/game_word_data.dart';
import '../data/game_session_order.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/rumbled_words_data.dart';
import '../models/difficulty.dart';
import '../providers/app_provider.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/word_game_layout.dart';
import '../widgets/floating_choice.dart';

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
        instructions: 'Tap letters to spell the word.',
        difficulty: widget.difficulty,
        current: _index + 1,
        total: _words.length,
        progressLabel: 'Word',
        hasProgress:
            (_selected.isNotEmpty || scoredAttempts > 0 || _hintUsed) &&
                !resultOpen,
        child: WordGameLayout(word: _words[_index].word, children: [
          ForestPanel(
              padding: const EdgeInsets.all(8),
              child: WordChoiceGrid(children: [
                for (var slot = 0; slot < _tiles.length; slot++)
                  _tile(
                      key: ValueKey('word-slot-$slot'),
                      label: slot < _selected.length
                          ? _tiles[_selected[slot]]
                          : '_',
                      filled: true,
                      highlightKey: ValueKey('word-highlight-$slot'),
                      highlighted: _readingWord || _activeLetter == slot,
                      onTap: _finished || slot >= _selected.length
                          ? null
                          : () => setState(() {
                                _selected.removeAt(slot);
                                _correct = null;
                              })),
              ])),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(
                key: const ValueKey('word-hint'),
                onPressed: withButtonSound(_hintUsed || _finished
                    ? null
                    : () => setState(() => _hintUsed = true)),
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text('Hint')),
            const SizedBox(width: 8),
            Text(_hintUsed ? 'Hint used' : '1 per word',
                style: const TextStyle(fontSize: 12)),
          ]),
          AudioButton(phrase: _words[_index].audioKey, enabled: !_finished),
          if (_hintUsed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Starts with ${_word[0]}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 6),
          const SizedBox(height: 4),
          Center(child: _eraseButton()),
          const SizedBox(height: 4),
          const Text('Tap a chosen letter to put it back.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          ForestPanel(
              padding: const EdgeInsets.all(10),
              child: WordChoiceGrid(children: [
                for (var i = 0; i < _tiles.length; i++)
                  _tile(
                      key: ValueKey('word-tile-$i'),
                      label: _tiles[i],
                      onTap: _finished || _selected.contains(i)
                          ? null
                          : () => _tapTile(i)),
              ])),
          const SizedBox(height: 6),
          if (_correct != null)
            Text(
                _correct!
                    ? 'Correct!'
                    : 'Try again! Tap Erase or a letter to change it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: _correct!
                        ? const Color(0xFF167769)
                        : const Color(0xFFB45731))),
          const SizedBox(height: 4),
        ]),
      );

  Widget _eraseButton() {
    final enabled = !_finished && _selected.isNotEmpty;
    return CustomPaint(
        foregroundPainter: const ForestLeaves(),
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: enabled
                        ? const [Color(0xFFFFA96B), Color(0xFFD45A39)]
                        : const [Color(0xFFF0DEC9), Color(0xFFCAB7AA)]),
                border: Border.all(color: const Color(0xFFFFE697), width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x443E2118),
                      offset: Offset(0, 3),
                      blurRadius: 4)
                ]),
            child: OutlinedButton.icon(
                key: const ValueKey('word-erase'),
                onPressed: withButtonSound(enabled
                    ? () => setState(() {
                          _selected.removeLast();
                          _correct = null;
                        })
                    : null),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(142, 48),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF625047),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                    side: const BorderSide(color: Color(0xBBFFFFFF)),
                    shape: const StadiumBorder()),
                icon: const Icon(Icons.backspace_rounded),
                label: const Text('Erase'))));
  }

  Widget _tile(
          {required Key key,
          required String label,
          VoidCallback? onTap,
          bool filled = false,
          Key? highlightKey,
          bool highlighted = false}) =>
      AnimatedScale(
        scale:
            highlighted && !MediaQuery.disableAnimationsOf(context) ? 1.1 : 1,
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
          child: SizedBox(
            width: 48,
            height: 48,
            child: FloatingChoice(
                enabled: !filled && onTap != null && !_finished,
                seed: label.codeUnitAt(0),
                child: AnswerChoiceButton(
                  buttonKey: key,
                  onPressed: onTap,
                  variant: label.codeUnitAt(0),
                  selected: highlighted,
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w800)),
                )),
          ),
        ),
      );
}
