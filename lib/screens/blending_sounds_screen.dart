import '../widgets/lesson_control_button.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/blending_lesson_controller.dart';
import '../controllers/lesson_introduction_sequence.dart';
import '../data/lesson_instruction_scripts.dart';
import '../data/blending_lesson_data.dart';
import '../data/lesson_word_order.dart';
import '../providers/app_provider.dart';
import '../models/word_lesson_progress.dart';
import '../services/background_music_service.dart';
import '../theme/kids_ui.dart';
import '../widgets/blending_puzzle_piece.dart';
import '../widgets/button_sound.dart';
import '../widgets/cvc_word_picture.dart';
import '../widgets/lessons_menu_page.dart';
import '../widgets/lesson_swipe_navigation.dart';
import '../widgets/lesson_frame.dart';

class BlendingSoundsScreen extends StatefulWidget {
  const BlendingSoundsScreen({super.key, this.controller});

  /// The screen owns and disposes the controller, including an injected one.
  final BlendingLessonController? controller;
  @override
  State<BlendingSoundsScreen> createState() => _BlendingSoundsScreenState();
}

class _BlendingSoundsScreenState extends State<BlendingSoundsScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  BlendingLessonController? _lesson;
  LessonWordSession<BlendingLessonWord>? _wordSession;
  AppProvider? _provider;
  bool _holdingMusic = false;
  final _introduction = LessonIntroductionSequence();
  List<GlobalKey> _pieceKeys = [];
  int? _dragging, _returning;
  int _epoch = 0, _dragEpoch = 0;
  OverlayEntry? _returnOverlay;
  late final AnimationController _returnAnimation;

  @override
  void initState() {
    super.initState();
    _returnAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lesson != null) {
      if (ModalRoute.isCurrentOf(context) == false) {
        _introduction.interrupt();
        _lesson!.pause();
      }
      return;
    }
    _provider = context.read<AppProvider>();
    if (widget.controller == null) {
      _wordSession = LessonWordOrder.open(
          'blending', blendingLessonWords, (word) => word.word);
    }
    _lesson = (widget.controller ??
        BlendingLessonController(
          words: _wordSession!.words,
          voiceEnabled: _provider!.voiceEnabled,
          play: _provider!.phonicsAudio.playInstruction,
          stop: _provider!.phonicsAudio.stop,
        ))
      ..playIntroduction = _playIntroduction
      ..addListener(_changed);
    _provider!.addListener(_settingsChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_provider!.startWordLesson(WordLesson.blending));
        _lesson!.introduce();
      }
    });
  }

  Future<bool> _playIntroduction() => _introduction.run(
      lesson: 'blend-intro',
      play: _lesson!.play,
      stop: _lesson!.stop,
      voiceEnabled: () => _lesson!.voiceEnabled,
      isCurrent: () =>
          mounted &&
          (ModalRoute.isCurrentOf(context) ?? true) &&
          !_provider!.timeLimitReached);

  void _settingsChanged() {
    if (_lesson!.voiceEnabled != _provider!.voiceEnabled) {
      _introduction.interrupt();
    }
    _lesson!.setVoiceEnabled(_provider!.voiceEnabled);
  }

  void _changed() {
    if (!mounted) return;
    if (_lesson!.phase != BlendingPhase.intro) {
      _wordSession?.show(_lesson!.index);
    }
    if (_lesson!.phase != BlendingPhase.intro && !_introduction.finished) {
      _introduction.interrupt();
    }
    if (_lesson!.phase == BlendingPhase.complete &&
        !_lesson!.running &&
        WordLesson.blending.words.contains(_lesson!.word.word)) {
      unawaited(_provider!
          .completeWordLessonWord(WordLesson.blending, _lesson!.word.word));
    }
    if (_holdingMusic != _lesson!.running) {
      _holdingMusic = _lesson!.running;
      if (_holdingMusic) {
        unawaited(BackgroundMusicService.instance.hold(this));
      } else {
        unawaited(BackgroundMusicService.instance.release(this));
      }
    }
    setState(() {});
  }

  void _clearDrag() {
    _epoch++;
    _returnAnimation.stop();
    _returnOverlay?.remove();
    _returnOverlay?.dispose();
    _returnOverlay = null;
    _dragging = _returning = null;
  }

  void _navigate(VoidCallback action) {
    _introduction.interrupt();
    _clearDrag();
    action();
  }

  Future<void> _returnPiece(int piece, Offset offset, double side) async {
    if (!mounted || _dragEpoch != _epoch) return;
    _lesson!.reject();
    final box =
        _pieceKeys[piece].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || MediaQuery.disableAnimationsOf(context)) return;
    final target = box.localToGlobal(Offset.zero);
    final epoch = _epoch;
    final letter = _lesson!.word.word[piece];
    setState(() => _returning = piece);
    _returnOverlay = OverlayEntry(
        builder: (context) => AnimatedBuilder(
              animation: _returnAnimation,
              builder: (context, _) {
                final location = Offset.lerp(offset, target,
                    Curves.easeOutCubic.transform(_returnAnimation.value))!;
                return Positioned(
                    left: location.dx,
                    top: location.dy,
                    width: side,
                    height: side,
                    child: IgnorePointer(
                        child: Material(
                      type: MaterialType.transparency,
                      child: BlendingPuzzlePiece(
                          letter: letter,
                          filled: true,
                          position: piece,
                          pieceCount: _lesson!.word.word.length),
                    )));
              },
            ));
    Overlay.of(context, rootOverlay: true).insert(_returnOverlay!);
    try {
      await _returnAnimation.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || epoch != _epoch) return;
    _returnOverlay?.remove();
    _returnOverlay?.dispose();
    _returnOverlay = null;
    setState(() => _returning = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _introduction.interrupt();
      _clearDrag();
      _lesson?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider?.removeListener(_settingsChanged);
    _lesson?.removeListener(_changed);
    _lesson?.dispose();
    _introduction.dispose();
    _clearDrag();
    _returnAnimation.dispose();
    unawaited(BackgroundMusicService.instance.release(this));
    super.dispose();
  }

  String get _message {
    final lesson = _lesson!;
    if (lesson.tryAnother) return 'Try another spot!';
    return lessonInstructionDefaults['blend-intro']!;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson!;
    final count = lesson.word.word.length;
    if (_pieceKeys.length != count) {
      _pieceKeys = List.generate(count, (_) => GlobalKey());
    }
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final VoidCallback? previous =
        lesson.index == 0 ? null : () => _navigate(lesson.previous);
    final VoidCallback? next = lesson.index == lesson.words.length - 1
        ? null
        : () => _navigate(lesson.next);
    return LessonsMenuPage(
        title: 'Blending Sounds',
        introduction: lessonInstructionScripts['blend-intro']!,
        introductionStatus: _introduction,
        instruction: _message,
        child: LessonSwipeNavigation(
            navigationKey: lesson.index,
            enabled: _dragging == null && _returning == null,
            onNext: next,
            onPrevious: previous,
            child: Column(children: [
              Expanded(child: LayoutBuilder(builder: (context, bounds) {
                final pictureHeight =
                    (bounds.maxHeight - 335).clamp(80.0, 200.0);
                return SingleChildScrollView(
                  key: const ValueKey('blending-content'),
                  child: Column(children: [
                    if (lesson.phase != BlendingPhase.intro)
                      LessonFrame(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          SizedBox(
                              height: pictureHeight,
                              width: double.infinity,
                              child: CvcWordPicture(word: lesson.word)),
                          LayoutBuilder(builder: (context, box) {
                            final gap = count > 3 ? 4.0 : 8.0;
                            final fittingSide = math.min(100.0,
                                (box.maxWidth - gap * (count - 1)) / count);
                            // Keep all seven columns visible in one row on a
                            // phone; shorter puzzles retain their usual sizing.
                            final side =
                                math.max(count == 7 ? 1.0 : 48.0, fittingSide);
                            final rowWidth = math.max(
                                box.maxWidth, count * side + gap * (count - 1));
                            final content = SizedBox(
                                width: rowWidth,
                                child: Column(children: [
                                  Row(
                                      key: ValueKey(
                                          'blend-slot-row-${lesson.word.word}'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (var slot = 0;
                                            slot < count;
                                            slot++) ...[
                                          if (slot > 0)
                                            AnimatedContainer(
                                                duration: reducedMotion
                                                    ? Duration.zero
                                                    : const Duration(
                                                        milliseconds: 500),
                                                width: lesson.joined ? 0 : gap),
                                          SizedBox(
                                              width: side,
                                              height: side,
                                              child: DragTarget<int>(
                                                onWillAcceptWithDetails:
                                                    (details) =>
                                                        _dragEpoch == _epoch &&
                                                        lesson.canPlace(
                                                            details.data, slot),
                                                onAcceptWithDetails:
                                                    (details) => lesson.place(
                                                        details.data, slot),
                                                builder: (context, candidates,
                                                        rejected) =>
                                                    BlendingPuzzlePiece(
                                                  key: ValueKey(
                                                      'blend-slot-$slot'),
                                                  position: slot,
                                                  pieceCount: count,
                                                  letter: lesson.slots[slot] ==
                                                          null
                                                      ? null
                                                      : lesson.word.word[slot],
                                                  filled: lesson.slots[slot] !=
                                                      null,
                                                  active: lesson
                                                          .highlightedLetters
                                                          .contains(slot) ||
                                                      candidates.isNotEmpty,
                                                  label: lesson.slots[slot] ==
                                                          null
                                                      ? 'Empty slot ${slot + 1}. Place selected letter'
                                                      : '${lesson.word.word[slot]}, slot ${slot + 1}',
                                                  onPressed: lesson.selected ==
                                                          null
                                                      ? null
                                                      : withButtonSound(() =>
                                                          lesson.place(
                                                              lesson.selected!,
                                                              slot)),
                                                ),
                                              )),
                                        ],
                                      ]),
                                  const SizedBox(height: 12),
                                  if (!lesson.complete)
                                    Row(
                                        key: ValueKey(
                                            'blend-bank-row-${lesson.word.word}'),
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          for (final (column, piece)
                                              in lesson.order.indexed) ...[
                                            if (count == 7 && column > 0)
                                              SizedBox(width: gap),
                                            SizedBox(
                                              key: _pieceKeys[piece],
                                              width: side,
                                              height: side,
                                              child: lesson.used(piece)
                                                  ? const SizedBox.shrink()
                                                  : Draggable<int>(
                                                      key: ValueKey(
                                                          'blend-piece-$piece'),
                                                      data: piece,
                                                      maxSimultaneousDrags:
                                                          _dragging != null ||
                                                                  _returning !=
                                                                      null
                                                              ? 0
                                                              : 1,
                                                      feedback: Material(
                                                          type: MaterialType
                                                              .transparency,
                                                          child: SizedBox(
                                                              width: side,
                                                              height: side,
                                                              child: BlendingPuzzlePiece(
                                                                  position:
                                                                      piece,
                                                                  pieceCount:
                                                                      count,
                                                                  letter: lesson
                                                                          .word
                                                                          .word[
                                                                      piece],
                                                                  active: true,
                                                                  filled:
                                                                      true))),
                                                      childWhenDragging:
                                                          const SizedBox
                                                              .shrink(),
                                                      onDragStarted: () =>
                                                          setState(() {
                                                        _dragEpoch = _epoch;
                                                        _dragging = piece;
                                                      }),
                                                      onDragEnd: (_) {
                                                        if (mounted) {
                                                          setState(() =>
                                                              _dragging = null);
                                                        }
                                                      },
                                                      onDraggableCanceled:
                                                          (_, offset) =>
                                                              unawaited(
                                                                  _returnPiece(
                                                                      piece,
                                                                      offset,
                                                                      side)),
                                                      child: Opacity(
                                                          opacity: _returning ==
                                                                  piece
                                                              ? 0
                                                              : 1,
                                                          child:
                                                              BlendingPuzzlePiece(
                                                            position: piece,
                                                            pieceCount: count,
                                                            letter: lesson.word
                                                                .word[piece],
                                                            filled: true,
                                                            active: lesson
                                                                    .selected ==
                                                                piece,
                                                            label:
                                                                'Select ${lesson.word.word[piece]}',
                                                            onPressed:
                                                                withButtonSound(
                                                                    () => lesson
                                                                        .choose(
                                                                            piece)),
                                                          )),
                                                    ),
                                            ),
                                          ],
                                        ])
                                  else
                                    Semantics(
                                        liveRegion: true,
                                        child: AnimatedScale(
                                          scale: lesson.phase ==
                                                      BlendingPhase.complete &&
                                                  !reducedMotion
                                              ? 1.08
                                              : 1,
                                          duration: reducedMotion
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 450),
                                          curve: Curves.easeOutBack,
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (lesson.phase ==
                                                    BlendingPhase.complete)
                                                  const Icon(Icons.auto_awesome,
                                                      color: Color(0xFFAD6900)),
                                                Flexible(
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8),
                                                        child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                                lesson.joined
                                                                    ? lesson
                                                                        .word
                                                                        .word
                                                                    : lesson
                                                                        .word
                                                                        .word
                                                                        .split(
                                                                            '')
                                                                        .join(
                                                                            ' · '),
                                                                key: const ValueKey(
                                                                    'blend-whole-word'),
                                                                maxLines: 1,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        32,
                                                                    fontWeight:
                                                                        FontWeight.w900,
                                                                    color: KidsUi.ink))))),
                                                if (lesson.phase ==
                                                    BlendingPhase.complete)
                                                  const Icon(Icons.auto_awesome,
                                                      color: Color(0xFFAD6900)),
                                              ]),
                                        )),
                                ]));
                            if (rowWidth > box.maxWidth + .1) {
                              return SingleChildScrollView(
                                key: ValueKey(
                                    'blend-puzzle-horizontal-${lesson.index}'),
                                scrollDirection: Axis.horizontal,
                                child: content,
                              );
                            }
                            return content;
                          }),
                        ]),
                      ),
                    if (!lesson.voiceEnabled || lesson.audioUnavailable)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              !lesson.voiceEnabled
                                  ? 'Audio is turned off.'
                                  : 'Audio unavailable. Tap Hear Again.',
                              style: const TextStyle(
                                  fontSize: 14, color: KidsUi.ink))),
                    const SizedBox(height: 8),
                  ]),
                );
              })),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _Control(
                        label: 'Hear Again',
                        fitLabel: count > 3,
                        icon: Icons.volume_up_rounded,
                        primary: true,
                        onPressed: () => _navigate(lesson.hearAgain))),
                const SizedBox(width: 6),
                Expanded(
                    child: _Control(
                        label: 'Try Again',
                        fitLabel: count > 3,
                        icon: Icons.replay_rounded,
                        onPressed: () => _navigate(lesson.reset))),
                const SizedBox(width: 6),
                Expanded(
                    child: _Control(
                        label: 'Next',
                        fitLabel: count > 3,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: next)),
              ]),
            ])));
  }
}

class _Control extends LessonControlButton {
  const _Control(
      {required super.label,
      required super.icon,
      required super.onPressed,
      super.fitLabel = false,
      super.primary = false})
      : super(
            art: label == 'Next'
                ? LessonButtonArt.next
                : label == 'Previous'
                    ? LessonButtonArt.previous
                    : label == 'Hear Again'
                        ? LessonButtonArt.sound
                        : null);
}
