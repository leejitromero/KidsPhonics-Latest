import '../data/game_word_data.dart';
import '../data/game_session_order.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/rumbled_words_data.dart';
import '../models/difficulty.dart';
import '../providers/app_provider.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/game_word_picture.dart';

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
      showGameResult(() => setState(() {
            _index = 0;
            _words = _newSession();
            _prepare();
          }));
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
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
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Center(
                    child:
                        GameWordPicture(word: _words[_index].word, size: 120))),
            SizedBox(
                width: 90,
                child: Column(children: [
                  FilledButton(
                    key: const ValueKey('word-hint'),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB45731),
                        padding: const EdgeInsets.symmetric(horizontal: 10)),
                    onPressed: _hintUsed || _finished
                        ? null
                        : () => setState(() => _hintUsed = true),
                    child:
                        const Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lightbulb_outline),
                      Text('Hint', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  Text(_hintUsed ? 'Hint used' : '1 per word',
                      style: const TextStyle(fontSize: 12)),
                ])),
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
          const SizedBox(height: 12),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var slot = 0; slot < _tiles.length; slot++)
                  _tile(
                      key: ValueKey('word-slot-$slot'),
                      label: slot < _selected.length
                          ? _tiles[_selected[slot]]
                          : '_',
                      filled: true,
                      onTap: _finished || slot >= _selected.length
                          ? null
                          : () => setState(() {
                                _selected.removeAt(slot);
                                _correct = null;
                              })),
              ]),
          const SizedBox(height: 8),
          const Text('Tap a chosen letter to put it back.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
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
          const SizedBox(height: 12),
          if (_correct != null)
            Text(
                _correct!
                    ? 'Correct!'
                    : 'Try again! Tap a letter to change it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: _correct!
                        ? const Color(0xFF167769)
                        : const Color(0xFFB45731))),
          const SizedBox(height: 8),
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
          child: ElevatedButton(
            key: key,
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              backgroundColor:
                  filled ? const Color(0xFF167769) : const Color(0xFF7052CA),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  filled ? const Color(0xFFD7EEE7) : const Color(0xFFE1DCEF),
              disabledForegroundColor: const Color(0xFF52605C),
              shape: filled
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))
                  : const CircleBorder(),
            ),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          ));
}
