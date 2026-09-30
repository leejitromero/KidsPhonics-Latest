// lib/screens/memory_game_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../data/game_word_data.dart';
import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/floating_choice.dart';

class _MemoryFireworks extends CustomPainter {
  _MemoryFireworks(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFFB52E),
      Color(0xFF7052CA),
      Color(0xFF167769),
      Color(0xFFE65D89)
    ];
    for (var burst = 0; burst < 5; burst++) {
      final t = ((progress - burst * .09) / .64).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final center = Offset(size.width * (.18 + (burst % 3) * .32),
          size.height * (.2 + (burst % 2) * .4));
      final paint = Paint()
        ..color = colors[burst % colors.length].withValues(alpha: 1 - t);
      for (var ray = 0; ray < 16; ray++) {
        final angle = ray * math.pi * 2 / 16;
        final radius = t * math.min(size.width, size.height) * .25;
        final point = center +
            Offset(math.cos(angle) * radius,
                math.sin(angle) * radius + 22 * t * t);
        canvas.drawCircle(point, 2 + 2 * (1 - t), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MemoryFireworks oldDelegate) =>
      oldDelegate.progress != progress;
}

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
    with TickerProviderStateMixin, GameSessionUi<MemoryGameScreen> {
  late List<_MemCard> _cards;
  List<_MemCard> _flipped = [];
  Set<_MemCard> _wrongCardIds = {}; // tracks cards showing red flash
  int _matchCount = 0;
  bool _locked = false;
  bool? _answerResult;
  final List<String> _collected = [];
  final Map<int, GlobalKey> _cardKeys = {}, _collectionKeys = {};
  late final AnimationController _flight, _fireworks;
  OverlayEntry? _flightEntry;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fireworks = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _initCards();
  }

  @override
  void dispose() {
    _flightEntry?.remove();
    _flight.dispose();
    _fireworks.dispose();
    super.dispose();
  }

  Future<void> _collect(_MemCard card) async {
    if (!MediaQuery.disableAnimationsOf(context)) {
      final overlay = Overlay.of(context);
      final root = overlay.context.findRenderObject() as RenderBox;
      final source = _cardKeys[_cards.indexOf(card)]!
          .currentContext!
          .findRenderObject() as RenderBox;
      final target = _collectionKeys[_collected.length]!
          .currentContext!
          .findRenderObject() as RenderBox;
      final start =
          source.localToGlobal(Offset.zero, ancestor: root) & source.size;
      final end =
          target.localToGlobal(Offset.zero, ancestor: root) & target.size;
      _flightEntry = OverlayEntry(
          builder: (_) => AnimatedBuilder(
              animation: _flight,
              builder: (_, __) {
                final t = Curves.easeInOutCubic.transform(_flight.value);
                final rect = Rect.lerp(start, end, t)!;
                return Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                        child: ExcludeSemantics(
                            child: Material(
                                color: Colors.transparent,
                                child: GameWordPicture(
                                    key:
                                        const ValueKey('memory-flying-picture'),
                                    word: card.id,
                                    size: rect.width)))));
              }));
      overlay.insert(_flightEntry!);
      try {
        await _flight.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
      _flightEntry?.remove();
      _flightEntry = null;
    }
    if (mounted) setState(() => _collected.add(card.id));
  }

  Future<void> _celebrate() async {
    setState(() => _celebrating = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _fireworks.value = .5;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    } else {
      try {
        await _fireworks.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted) {
      setState(() => _celebrating = false);
      _showWinDialog();
    }
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
      _collected.clear();
      _celebrating = false;
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
        setState(() {
          a.isMatched = true;
          b.isMatched = true;
          _matchCount++;
        });
        if (provider.voiceEnabled) provider.phonicsAudio.tryPlay(a.id);
        awardGameXp((5 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
        await _collect(a);
        if (!mounted) return;
        if (_matchCount == _totalPairs) {
          provider.recordActivityCompleted();
          provider.audio.playWin();
          awardGameXp((10 * widget.difficulty.xpMultiplier).round());
          await _celebrate();
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
  int get totalGameItems => _totalPairs;

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
        child: Stack(children: [
          Column(children: [
            const Text('Your matches',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            SizedBox(
                height: 88,
                child: Center(
                    child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                      _totalPairs,
                      (i) => Container(
                            key: _collectionKeys.putIfAbsent(
                                i, () => GlobalKey()),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: i < _collected.length
                                    ? const Color(0xFFD7EEE7)
                                    : const Color(0xFFE9E2F4),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFBCAAD5))),
                            child: i < _collected.length
                                ? GameWordPicture(
                                    key: ValueKey('memory-collected-$i'),
                                    word: _collected[i],
                                    size: 36)
                                : const Icon(Icons.help_outline,
                                    color: Color(0xFF8A72B6), size: 20),
                          )),
                ))),
            const SizedBox(height: 6),
            Expanded(child: LayoutBuilder(builder: (_, box) {
              const columns = 4;
              final rows = (_cards.length / columns).ceil();
              // Use Medium's sizing for Easy too, even when height limits the grid.
              final sizingRows = widget.difficulty == Difficulty.easy
                  ? (memoryPairsForDifficulty(Difficulty.medium).length *
                          2 /
                          columns)
                      .ceil()
                  : rows;
              const gap = 8.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              final height =
                  (box.maxHeight - gap * (sizingRows - 1)) / sizingRows;
              final side = width < height ? width : height;
              return Center(
                child: SizedBox(
                  width: side * columns + gap * (columns - 1),
                  height: side * rows + gap * (rows - 1),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (_, index) => _buildCard(index),
                  ),
                ),
              );
            })),
          ]),
          if (_celebrating)
            Positioned.fill(
                child: IgnorePointer(
              child: AnimatedBuilder(
                  animation: _fireworks,
                  builder: (_, __) => CustomPaint(
                        key: const ValueKey('memory-fireworks'),
                        painter: _MemoryFireworks(_fireworks.value),
                        child: const Center(
                            child: Text('All pairs found!',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF167769)))),
                      )),
            )),
        ]),
      );

  Widget _buildCard(int index) {
    final card = _cards[index];
    final shown = card.isFlipped || card.isMatched;
    final wrong = _wrongCardIds.contains(card);
    final color = card.isMatched
        ? const Color(0xFF167769)
        : wrong
            ? const Color(0xFFB63D50)
            : choiceBlue;
    return FloatingChoice(
        enabled: !_locked && !shown && !resultOpen,
        seed: index,
        child: Semantics(
          key: _cardKeys.putIfAbsent(index, () => GlobalKey()),
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
                side: BorderSide(
                    color: Colors.white.withValues(alpha: .5), width: 2),
              ),
            ),
            child: ExcludeSemantics(
              child: shown
                  ? FittedBox(child: GameWordPicture(word: card.id, size: 100))
                  : Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .3)),
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
        ));
  }
}
