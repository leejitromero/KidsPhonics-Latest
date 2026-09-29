// lib/screens/memory_game_screen.dart
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../data/game_word_data.dart';
import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/game_tutorial.dart';

class _MemCard {
  final String id;
  bool isFlipped = false;
  bool isMatched = false;
  _MemCard(this.id);
}

class MemoryGameScreen extends StatefulWidget {
  final Difficulty difficulty;
  const MemoryGameScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with GameSessionUi<MemoryGameScreen> {
  late List<_MemCard> _cards;
  List<_MemCard> _flipped = [];
  Set<_MemCard> _wrongCardIds = {}; // tracks cards showing red flash
  int _matchCount = 0;
  bool _locked = false;
  bool? _answerResult;

  @override
  void initState() {
    super.initState();
    _initCards();
  }

  void _initCards() {
    final pairs = GameSessionOrder.next('memory-${widget.difficulty.name}',
        gameWordsFor(widget.difficulty), (w) => w.word,
        count: memoryPairsForDifficulty(widget.difficulty).length);
    final cards = <_MemCard>[];
    for (final p in pairs) {
      cards.add(_MemCard(p.word));
      cards.add(_MemCard(p.word));
    }
    cards.shuffle();
    setState(() {
      _cards = cards;
      _flipped = [];
      _wrongCardIds = {};
      _matchCount = 0;
      _locked = false;
      _answerResult = null;
    });
  }

  int get _totalPairs => memoryPairsForDifficulty(widget.difficulty).length;

  void _tapCard(_MemCard card) async {
    if (_locked || card.isFlipped || card.isMatched) return;
    final provider = context.read<AppProvider>();
    setState(() => _answerResult = null);
    provider.audio.playFlip();
    setState(() {
      card.isFlipped = true;
      _flipped.add(card);
    });

    if (_flipped.length == 2) {
      _locked = true;
      await Future.delayed(const Duration(milliseconds: 750));

      if (!mounted) return;
      final a = _flipped[0], b = _flipped[1];
      final isMatch = a.id == b.id;
      setState(() => _answerResult = isMatch);
      recordGameAnswer(correct: isMatch);

      if (isMatch) {
        a.isMatched = true;
        b.isMatched = true;
        _matchCount++;
        if (provider.voiceEnabled) provider.phonicsAudio.tryPlay(a.id);
        awardGameXp((5 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
        if (_matchCount == _totalPairs) {
          provider.recordActivityCompleted();
          provider.audio.playWin();
          awardGameXp((10 * widget.difficulty.xpMultiplier).round());
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) _showWinDialog();
        }
        if (!mounted) return;
        setState(() {
          _flipped = [];
          _locked = false;
        });
      } else {
        // Show red flash on mismatched cards — wrong.mp3 only, no voice
        provider.audio.playWrong();
        if (!mounted) return;
        setState(() {
          _wrongCardIds = {a, b};
        });
        // Hold red flash for 800ms then flip back
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          a.isFlipped = false;
          b.isFlipped = false;
          if (!mounted) return;
          setState(() {
            _wrongCardIds = {};
            _answerResult = null;
            _flipped = [];
            _locked = false;
          });
        }
      }
    }
  }

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    showGameResult(_initCards);
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        tutorial: GameTutorial.memoryFlip,
        canOpenTutorial: () => !_locked && !resultOpen,
        answerResult: _answerResult,
        title: 'Memory Flip',
        instructions: 'Tap two cards. Match the same pictures!',
        fitViewport: true,
        difficulty: widget.difficulty,
        current: _matchCount,
        total: _totalPairs,
        progressLabel: 'Pairs matched',
        hasProgress: (scoredAttempts > 0 || _flipped.isNotEmpty) && !resultOpen,
        child: LayoutBuilder(builder: (_, box) {
          final columns = box.maxWidth > box.maxHeight
              ? 4
              : widget.difficulty == Difficulty.easy
                  ? 2
                  : 4;
          final rows = (_cards.length / columns).ceil();
          const gap = 8.0;
          final width = (box.maxWidth - gap * (columns - 1)) / columns;
          final height = (box.maxHeight - gap * (rows - 1)) / rows;
          final side = width < height ? width : height;
          return Center(
            child: SizedBox(
              width: side * columns + gap * (columns - 1),
              height: side * rows + gap * (rows - 1),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                ),
                itemCount: _cards.length,
                itemBuilder: (_, index) => _buildCard(index),
              ),
            ),
          );
        }),
      );

  Widget _buildCard(int index) {
    final card = _cards[index];
    final shown = card.isFlipped || card.isMatched;
    final wrong = _wrongCardIds.contains(card);
    final color = card.isMatched
        ? const Color(0xFF167769)
        : wrong
            ? const Color(0xFFB63D50)
            : shown
                ? const Color(0xFF7052CA)
                : const Color(0xFF5267C8);
    return Semantics(
      label: shown
          ? '${card.id}${card.isMatched ? ', matched' : ''}'
          : 'Hidden card ${index + 1}',
      child: ElevatedButton(
        key: ValueKey('memory-$index'),
        onPressed: _locked || card.isMatched || card.isFlipped || resultOpen
            ? null
            : () => _tapCard(card),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(6),
          minimumSize: Size.zero,
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 3,
          shadowColor: color.withValues(alpha: .35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side:
                BorderSide(color: Colors.white.withValues(alpha: .5), width: 2),
          ),
        ),
        child: ExcludeSemantics(
          child: shown
              ? FittedBox(child: GameWordPicture(word: card.id, size: 100))
              : Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .3)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: .18),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white70, size: 24),
                ),
        ),
      ),
    );
  }
}
