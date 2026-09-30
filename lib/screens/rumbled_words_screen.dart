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
  bool get _finished => _correct == true || resultOpen;
  String get _word => _words[_index].word.toUpperCase();

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    _tiles = _word.split('')..shuffle();
    if (_tiles.join() == _word) _tiles.add(_tiles.removeAt(0));
    _selected.clear();
    _hintUsed = false;
    _correct = null;
  }

  void _check() {
    if (_finished || _selected.length != _tiles.length) return;
    final correct = _selected.map((i) => _tiles[i]).join() == _word;
    setState(() => _correct = correct);
    recordGameAnswer(correct: correct);
    final p = context.read<AppProvider>();
    if (correct) {
      p.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
    } else {
      p.audio.playWrong();
      // Keep the attempted word visible, but require an edit before checking again.
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
  int get totalGameItems => _words.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        fitViewport: true,
        answerResult: _correct,
        title: 'Rumbled Words',
        instructions: 'Look at the picture. Tap letters to spell the word.',
        difficulty: widget.difficulty,
        current: _index + 1,
        total: _words.length,
        progressLabel: 'Word',
        hasProgress:
            (_selected.isNotEmpty || scoredAttempts > 0 || _hintUsed) &&
                !resultOpen,
        child: WordGameLayout(word: _words[_index].word, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(
                key: const ValueKey('word-hint'),
                onPressed: _hintUsed || _finished
                    ? null
                    : () => setState(() => _hintUsed = true),
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text('Hint')),
            const SizedBox(width: 8),
            Text(_hintUsed ? 'Hint used' : '1 per word',
                style: const TextStyle(fontSize: 12)),
          ]),
          AudioButton(phrase: _words[_index].audioKey),
          if (_hintUsed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Starts with ${_word[0]}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 6),
          WordChoiceGrid(children: [
            for (var slot = 0; slot < _tiles.length; slot++)
              _tile(
                  key: ValueKey('word-slot-$slot'),
                  label:
                      slot < _selected.length ? _tiles[_selected[slot]] : '_',
                  filled: true,
                  onTap: _finished || slot >= _selected.length
                      ? null
                      : () => setState(() {
                            _selected.removeAt(slot);
                            _correct = null;
                          })),
          ]),
          const SizedBox(height: 4),
          Center(
            child: OutlinedButton.icon(
              key: const ValueKey('word-erase'),
              onPressed: _finished || _selected.isEmpty
                  ? null
                  : () => setState(() {
                        _selected.removeLast();
                        _correct = null;
                      }),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 48),
                foregroundColor: const Color(0xFFB45731),
              ),
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Erase'),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Tap a chosen letter to put it back.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          WordChoiceGrid(children: [
            for (var i = 0; i < _tiles.length; i++)
              _tile(
                  key: ValueKey('word-tile-$i'),
                  label: _tiles[i],
                  onTap: _finished || _selected.contains(i)
                      ? null
                      : () => setState(() {
                            _selected.add(i);
                            _correct = null;
                          })),
          ]),
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
          FilledButton(
            onPressed: _correct == true
                ? _next
                : _selected.length == _tiles.length &&
                        _correct == null &&
                        !resultOpen
                    ? _check
                    : null,
            child: Text(_correct == true ? 'Next' : 'Check'),
          ),
        ]),
      );

  Widget _tile(
          {required Key key,
          required String label,
          VoidCallback? onTap,
          bool filled = false}) =>
      SizedBox(
          width: 48,
          height: 48,
          child: FloatingChoice(
              enabled: !filled && onTap != null && !_finished,
              seed: label.codeUnitAt(0),
              child: ElevatedButton(
                key: key,
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  backgroundColor:
                      filled ? const Color(0xFF167769) : choiceBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: filled
                      ? const Color(0xFFD7EEE7)
                      : const Color(0xFFDDECF3),
                  disabledForegroundColor: const Color(0xFF52605C),
                  shape: filled
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: Color(0x99FFFFFF), width: 1.5)),
                ),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w800)),
              )));
}
