import '../widgets/lesson_control_button.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/blending_lesson_controller.dart';
import '../data/blending_lesson_data.dart';
import '../providers/app_provider.dart';
import '../services/background_music_service.dart';
import '../theme/kids_ui.dart';
import '../widgets/blending_puzzle_piece.dart';
import '../widgets/button_sound.dart';
import '../widgets/cvc_word_picture.dart';
import '../widgets/lessons_menu_page.dart';
import '../widgets/mascot_guide.dart';

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
  AppProvider? _provider;
  bool _holdingMusic = false;
  final _pieceKeys = List.generate(3, (_) => GlobalKey());
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
    if (_lesson != null) return;
    _provider = context.read<AppProvider>();
    _lesson = (widget.controller ??
        BlendingLessonController(
          voiceEnabled: _provider!.voiceEnabled,
          play: _provider!.phonicsAudio.playInstruction,
          stop: _provider!.phonicsAudio.stop,
        ))
      ..addListener(_changed);
    _provider!.addListener(_settingsChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lesson!.introduce();
    });
  }

  void _settingsChanged() => _lesson!.setVoiceEnabled(_provider!.voiceEnabled);
  void _changed() {
    if (!mounted) return;
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
                          letter: letter, filled: true, position: piece),
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
    _clearDrag();
    _returnAnimation.dispose();
    unawaited(BackgroundMusicService.instance.release(this));
    super.dispose();
  }

  String get _message {
    final lesson = _lesson!;
    if (lesson.tryAnother) return 'Try another spot!';
    return switch (lesson.phase) {
      BlendingPhase.intro => 'Let’s blend some sounds!',
      BlendingPhase.puzzle => 'Drag the letters to build the word!',
      BlendingPhase.blending => 'Blend the sounds!',
      BlendingPhase.complete => lesson.word.praise,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LessonsMenuPage(
        child: Column(children: [
      Expanded(child: LayoutBuilder(builder: (context, bounds) {
        final pictureHeight = (bounds.maxHeight - 335).clamp(80.0, 200.0);
        return SingleChildScrollView(
          key: const ValueKey('blending-content'),
          child: Column(children: [
            Semantics(
                liveRegion: true,
                child: MascotGuide(
                    mascot: LearningMascot.wigloo,
                    compact: true,
                    message: _message)),
            const SizedBox(height: 8),
            if (lesson.phase != BlendingPhase.intro)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: KidsUi.cardSurface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 2)),
                child: Column(children: [
                  const Text('Blending Sounds',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: KidsUi.ink)),
                  SizedBox(
                      height: pictureHeight,
                      width: double.infinity,
                      child: CvcWordPicture(word: lesson.word)),
                  LayoutBuilder(builder: (context, box) {
                    final side = math.min(100.0, (box.maxWidth - 16) / 3);
                    return Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var slot = 0; slot < 3; slot++) ...[
                              if (slot > 0)
                                AnimatedContainer(
                                    duration: reducedMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 500),
                                    width: lesson.joined ? 0 : 8),
                              SizedBox(
                                  width: side,
                                  height: side,
                                  child: DragTarget<int>(
                                    onWillAcceptWithDetails: (details) =>
                                        _dragEpoch == _epoch &&
                                        lesson.canPlace(details.data, slot),
                                    onAcceptWithDetails: (details) =>
                                        lesson.place(details.data, slot),
                                    builder: (context, candidates, rejected) =>
                                        BlendingPuzzlePiece(
                                      key: ValueKey('blend-slot-$slot'),
                                      position: slot,
                                      letter: lesson.slots[slot] == null
                                          ? null
                                          : lesson.word.word[slot],
                                      filled: lesson.slots[slot] != null,
                                      active: lesson.highlighted == slot ||
                                          candidates.isNotEmpty,
                                      label: lesson.slots[slot] == null
                                          ? 'Empty slot ${slot + 1}. Place selected letter'
                                          : '${lesson.word.word[slot]}, slot ${slot + 1}',
                                      onPressed: lesson.selected == null
                                          ? null
                                          : withButtonSound(() => lesson.place(
                                              lesson.selected!, slot)),
                                    ),
                                  )),
                            ],
                          ]),
                      const SizedBox(height: 12),
                      if (!lesson.complete)
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final piece in lesson.order)
                                SizedBox(
                                  key: _pieceKeys[piece],
                                  width: side,
                                  height: side,
                                  child: lesson.used(piece)
                                      ? const SizedBox.shrink()
                                      : Draggable<int>(
                                          key: ValueKey('blend-piece-$piece'),
                                          data: piece,
                                          maxSimultaneousDrags:
                                              _dragging != null ||
                                                      _returning != null
                                                  ? 0
                                                  : 1,
                                          feedback: Material(
                                              type: MaterialType.transparency,
                                              child: SizedBox(
                                                  width: side,
                                                  height: side,
                                                  child: BlendingPuzzlePiece(
                                                      position: piece,
                                                      letter: lesson
                                                          .word.word[piece],
                                                      active: true,
                                                      filled: true))),
                                          childWhenDragging:
                                              const SizedBox.shrink(),
                                          onDragStarted: () => setState(() {
                                            _dragEpoch = _epoch;
                                            _dragging = piece;
                                          }),
                                          onDragEnd: (_) {
                                            if (mounted) {
                                              setState(() => _dragging = null);
                                            }
                                          },
                                          onDraggableCanceled: (_, offset) =>
                                              unawaited(_returnPiece(
                                                  piece, offset, side)),
                                          child: Opacity(
                                              opacity:
                                                  _returning == piece ? 0 : 1,
                                              child: BlendingPuzzlePiece(
                                                position: piece,
                                                letter: lesson.word.word[piece],
                                                filled: true,
                                                active:
                                                    lesson.selected == piece,
                                                label:
                                                    'Select ${lesson.word.word[piece]}',
                                                onPressed: withButtonSound(
                                                    () => lesson.choose(piece)),
                                              )),
                                        ),
                                ),
                            ])
                      else
                        Semantics(
                            liveRegion: true,
                            child: AnimatedScale(
                              scale: lesson.phase == BlendingPhase.complete &&
                                      !reducedMotion
                                  ? 1.08
                                  : 1,
                              duration: reducedMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (lesson.phase == BlendingPhase.complete)
                                      const Icon(Icons.auto_awesome,
                                          color: Color(0xFFAD6900)),
                                    Flexible(
                                        child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                                lesson.joined
                                                    ? lesson.word.word
                                                    : lesson.word.word
                                                        .split('')
                                                        .join(' · '),
                                                key: const ValueKey(
                                                    'blend-whole-word'),
                                                style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w900,
                                                    color: KidsUi.ink)))),
                                    if (lesson.phase == BlendingPhase.complete)
                                      const Icon(Icons.auto_awesome,
                                          color: Color(0xFFAD6900)),
                                  ]),
                            )),
                    ]);
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
                      style: const TextStyle(fontSize: 14, color: KidsUi.ink))),
            const SizedBox(height: 8),
          ]),
        );
      })),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _Control(
                label: 'Hear Again',
                icon: Icons.volume_up_rounded,
                primary: true,
                onPressed: () => _navigate(lesson.hearAgain))),
        const SizedBox(width: 6),
        Expanded(
            child: _Control(
                label: 'Try Again',
                icon: Icons.replay_rounded,
                onPressed: () => _navigate(lesson.reset))),
        const SizedBox(width: 6),
        Expanded(
            child: _Control(
                label: 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: lesson.index == blendingLessonWords.length - 1
                    ? null
                    : () => _navigate(lesson.next))),
      ]),
    ]));
  }
}

class _Control extends LessonControlButton {
  const _Control(
      {required super.label,
      required super.icon,
      required super.onPressed,
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
