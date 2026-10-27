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
import '../widgets/rumbled_words_design.dart';
import '../widgets/game_feedback_art.dart';

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
  late List<int> _tileIds;
  int? _selectedTile;
  bool _dragging = false;
  bool _hasMoved = false;
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
  bool get _gameActive =>
      canAdvanceGameFeedback && TickerMode.valuesOf(context).enabled;
  bool get _canEdit => !_finished && _gameActive;
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
    _tileIds = List.generate(_tiles.length, (i) => i);
    _selectedTile = null;
    _dragging = false;
    _hasMoved = false;
    _hintUsed = false;
    _correct = null;
  }

  void _tapTile(int index) {
    if (!_canEdit || _dragging || (_hintUsed && index == 0)) return;
    final deselect = _selectedTile == index;
    final letter = _tiles[index];
    setState(() => _selectedTile = deselect ? null : index);
    gameNarration.cancel();
    if (!deselect) unawaited(gameNarration.letterName(letter));
  }

  void _moveTile(int from, int to) {
    if (!_canEdit || (_hintUsed && (from == 0 || to == 0))) return;
    final before = _tiles.join();
    setState(() {
      _tiles.insert(to, _tiles.removeAt(from));
      _tileIds.insert(to, _tileIds.removeAt(from));
      _selectedTile = null;
      if (_tiles.join() != before) {
        _hasMoved = true;
        _correct = null;
      }
    });
  }

  void _useHint() {
    if (!_canEdit || _dragging || _hintUsed) return;
    gameNarration.cancel();
    setState(() {
      final source = _tiles.indexOf(_word[0]);
      if (source != 0) {
        _tiles[source] = _tiles[0];
        _tiles[0] = _word[0];
        final id = _tileIds[0];
        _tileIds[0] = _tileIds[source];
        _tileIds[source] = id;
        _hasMoved = true;
        _correct = null;
      }
      _hintUsed = true;
      _selectedTile = null;
    });
  }

  void _check() {
    // A new arrangement is required before submitting a failed word again.
    if (!_canEdit || _dragging || _correct != null) return;
    gameNarration.cancel();
    final correct = _tiles.join() == _word;
    setState(() {
      _selectedTile = null;
      _correct = correct;
    });
    recordGameAnswer(correct: correct);
    if (correct) {
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      unawaited(_readCompletedWord());
    } else {
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
        if (!_gameActive) return;
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
            : gameNarration.letterName(_word[_readingStep]);
        final audioGeneration = gameNarration.generation;
        await playback;
        await hold;
        if (!current()) return;
        // Replay the interrupted step after returning, including repeated letters.
        if (!_gameActive || audioGeneration != gameNarration.generation) {
          return;
        }
        _readingStep++;
      }
      if (current() && _gameActive) {
        _next();
      }
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
        instructions: 'Tap a letter, drag it into place, then tap Check Word!',
        instructionPanel: GameMascotCoach(
            title: 'Rumbled Words',
            instructions:
                'Tap a letter, drag it into place, then tap Check Word!',
            controller: gameNarration,
            child: Center(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).height < 650
                            ? 220
                            : 340),
                    child: const GameInstructionGuide(
                        // The supplied recording describes the former tap-to-fill
                        // game. Keep the current drag instructions visible.
                        autoPlay: false,
                        gameTitle: 'Rumbled Words')))),
        difficulty: widget.difficulty,
        current: _index + 1,
        total: _words.length,
        progressLabel: 'Word',
        hasProgress: (_selectedTile != null ||
                _hasMoved ||
                scoredAttempts > 0 ||
                _hintUsed) &&
            !resultOpen,
        child: LayoutBuilder(builder: (context, box) {
          final compact = box.maxHeight < 440;
          final gap = compact ? 4.0 : 10.0;
          final picture =
              (box.maxHeight * (compact ? .30 : .38)).clamp(104.0, 220.0);
          const buttonHeight = 44.0;
          final message = _correct == false
              ? 'Try again! Drag a letter into place.'
              : _selectedTile != null
                  ? 'Drag the floating letter into place.'
                  : _hintUsed
                      ? 'First letter fixed. Keep arranging!'
                      : 'Tap a letter, then drag it.';
          return WordGameLayout(
              word: _words[_index].word,
              pictureExtent: picture,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      flex: 2,
                      child: RumbledActionButton(
                          buttonKey: const ValueKey('word-hint'),
                          height: buttonHeight,
                          purple: true,
                          label: 'Hint',
                          icon: Icons.lightbulb_outline_rounded,
                          onPressed: _hintUsed || !_canEdit || _dragging
                              ? null
                              : _useHint)),
                  SizedBox(width: gap),
                  Expanded(
                      flex: 3,
                      child: AudioButton(
                          phrase: _words[_index].audioKey,
                          enabled: !_finished,
                          statusBuilder: (message) => SizedBox(
                              height: 16,
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12,
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
                ]),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                        height: 16,
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                _hintUsed
                                    ? 'Hint used: first letter fixed'
                                    : '1 hint per word',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: GameDesign.ink,
                                    fontWeight: FontWeight.w800))))),
                SizedBox(height: gap),
                ForestPanel(
                    key: const ValueKey('word-letter-board'),
                    padding: const EdgeInsets.all(6),
                    child: RumbledLetterRow(
                        key: ValueKey('rumbled-board-$_roundGeneration'),
                        maxSide: compact ? 56 : 72,
                        gap: compact || _tiles.length > 7 ? 2 : 4,
                        tileIds: _tileIds,
                        selectedIndex: _selectedTile,
                        enabled: _canEdit,
                        fixedFirst: _hintUsed,
                        onMove: _moveTile,
                        onDraggingChanged: (dragging) {
                          if (mounted && _dragging != dragging) {
                            setState(() => _dragging = dragging);
                          }
                        },
                        children: [
                          for (var i = 0; i < _tiles.length; i++) _tile(i),
                        ])),
                SizedBox(height: gap),
                if (_correct == true)
                  GameCorrectFrame(height: compact ? 28 : 36)
                else
                  Semantics(
                      liveRegion: true,
                      child: SizedBox(
                          height: compact ? 28 : 36,
                          child: ForestPanel(
                              leaves: false,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(message,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: _correct == false
                                              ? const Color(0xFFB45731)
                                              : GameDesign.ink)))))),
                SizedBox(height: gap),
                Center(
                    child: SizedBox(
                        width: 220,
                        child: RumbledActionButton(
                            buttonKey: const ValueKey('word-check'),
                            height: compact ? 44 : 48,
                            label: 'Check Word',
                            icon: Icons.check_circle_rounded,
                            onPressed:
                                _canEdit && !_dragging && _correct == null
                                    ? _check
                                    : null))),
                const SizedBox(height: 4),
              ]);
        }),
      );

  Widget _tile(int index) {
    final fixed = _hintUsed && index == 0;
    final selected = _selectedTile == index;
    final highlighted = _readingWord || _activeLetter == index;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
        label: 'Letter ${_tiles[index]}, position ${index + 1}'
            '${fixed ? ', fixed by hint' : ''}',
        selected: selected,
        child: AnimatedScale(
            scale: highlighted && !reducedMotion ? 1.04 : 1,
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: AnimatedContainer(
                key: ValueKey('word-highlight-$index'),
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                    color: highlighted
                        ? const Color(0xFFFFE36B)
                        : selected
                            ? const Color(0xFFB7F5EE)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected
                            ? const Color(0xFF008A80)
                            : highlighted
                                ? const Color(0xFFFFB300)
                                : Colors.transparent,
                        width: 3)),
                child: Stack(fit: StackFit.expand, children: [
                  AnswerChoiceButton(
                      buttonKey: ValueKey('word-tile-$index'),
                      onPressed:
                          !_canEdit || fixed ? null : () => _tapTile(index),
                      variant: const [4, 2, 3, 1, 0][_tileIds[index] % 5],
                      selected: selected || highlighted,
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_tiles[index],
                              style: const TextStyle(
                                  color: GameDesign.ink,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900)))),
                  if (fixed)
                    const Positioned(
                        top: 0,
                        right: 0,
                        child: IgnorePointer(
                            child: Icon(Icons.lock_rounded,
                                size: 15, color: Color(0xFF167769)))),
                ]))));
  }
}
