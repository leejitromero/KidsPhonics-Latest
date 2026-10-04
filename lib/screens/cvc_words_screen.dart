import '../widgets/lesson_control_button.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cvc_lesson_controller.dart';
import '../data/cvc_lesson_data.dart';
import '../providers/app_provider.dart';
import '../services/background_music_service.dart';
import '../theme/kids_ui.dart';
import '../widgets/button_sound.dart';
import '../widgets/cvc_word_picture.dart';
import '../widgets/lessons_menu_page.dart';
import '../widgets/mascot_guide.dart';

class CvcWordsScreen extends StatefulWidget {
  const CvcWordsScreen({super.key, this.controller});

  /// The screen owns and disposes the controller, including an injected one.
  final CvcLessonController? controller;
  @override
  State<CvcWordsScreen> createState() => _CvcWordsScreenState();
}

class _CvcWordsScreenState extends State<CvcWordsScreen>
    with WidgetsBindingObserver {
  CvcLessonController? _lesson;
  AppProvider? _provider;
  bool _holdingMusic = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lesson != null) return;
    _provider = context.read<AppProvider>();
    _lesson = (widget.controller ??
        CvcLessonController(
          voiceEnabled: _provider!.voiceEnabled,
          play: _provider!.phonicsAudio.playInstruction,
          stop: _provider!.phonicsAudio.stop,
        ))
      ..addListener(_changed);
    _provider!.addListener(_settingsChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_lesson!.start(introduction: true));
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _lesson?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider?.removeListener(_settingsChanged);
    _lesson?.removeListener(_changed);
    _lesson?.dispose();
    unawaited(BackgroundMusicService.instance.release(this));
    super.dispose();
  }

  String get _message => switch (_lesson!.phase) {
        CvcPhase.intro => 'Let’s learn CVC words!',
        CvcPhase.picture => 'Listen to the word.',
        CvcPhase.individual => 'Listen to each sound.',
        CvcPhase.slowBlend => 'Blend slowly.',
        CvcPhase.fastBlend => 'Now together!',
        CvcPhase.complete => _lesson!.word.praise,
      };

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson!;
    final word = lesson.word;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LessonsMenuPage(
        child: Column(children: [
      Expanded(child: LayoutBuilder(builder: (context, box) {
        final pictureHeight = (box.maxHeight - 270).clamp(80.0, 220.0);
        return SingleChildScrollView(
          key: const ValueKey('cvc-content'),
          child: Column(children: [
            Semantics(
                liveRegion: true,
                child: MascotGuide(
                    mascot: LearningMascot.wigloo,
                    compact: lesson.phase != CvcPhase.intro,
                    message: _message)),
            const SizedBox(height: 10),
            if (lesson.phase != CvcPhase.intro)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: KidsUi.cardSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(children: [
                  Text('Short ${word.vowel}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: KidsUi.muted,
                          fontWeight: FontWeight.w800)),
                  SizedBox(
                      height: pictureHeight,
                      child:
                          CvcWordPicture(key: ValueKey(word.word), word: word)),
                  AnimatedScale(
                    scale: lesson.phase == CvcPhase.complete && !reducedMotion
                        ? 1.08
                        : 1,
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Sparkle(
                              visible: lesson.phase == CvcPhase.complete,
                              reducedMotion: reducedMotion),
                          Flexible(
                              child: Text(word.word,
                                  key: const ValueKey('cvc-whole-word'),
                                  style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: KidsUi.ink))),
                          _Sparkle(
                              visible: lesson.phase == CvcPhase.complete,
                              reducedMotion: reducedMotion),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (context, bounds) {
                    final scale =
                        MediaQuery.textScalerOf(context).scale(32) / 32;
                    final cardWidth =
                        math.min(100.0, (bounds.maxWidth - 24) / 3);
                    final cardHeight = 42 + 38 * scale;
                    final gap = 12 * (1 - lesson.blend);
                    final joinedWidth = math.max(48.0, 32 * scale + 12);
                    final animatedWidth = cardWidth -
                        lesson.blend * math.max(0, cardWidth - joinedWidth);
                    return SizedBox(
                        height: cardHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0)
                                AnimatedContainer(
                                    width: gap,
                                    duration: reducedMotion
                                        ? Duration.zero
                                        : Duration(
                                            milliseconds: lesson.phase ==
                                                    CvcPhase.fastBlend
                                                ? 180
                                                : 700)),
                              AnimatedContainer(
                                  duration: reducedMotion
                                      ? Duration.zero
                                      : Duration(
                                          milliseconds:
                                              lesson.phase == CvcPhase.fastBlend
                                                  ? 180
                                                  : 700),
                                  width: animatedWidth,
                                  height: cardHeight,
                                  child: Semantics(
                                    label: 'Hear ${word.word[i]} sound',
                                    child: OutlinedButton(
                                      key: ValueKey('cvc-letter-$i'),
                                      onPressed: withButtonSound(
                                          () => lesson.hearLetter(i)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        backgroundColor: lesson.highlighted == i
                                            ? const Color(0xFFFFD45C)
                                            : i == 1
                                                ? const Color(0xFFF7DDF0)
                                                : const Color(0xFFDEF5FF),
                                        foregroundColor: KidsUi.ink,
                                        side: BorderSide(
                                            color: lesson.highlighted == i
                                                ? const Color(0xFFAA6800)
                                                : const Color(0xFFB9A9D8),
                                            width: lesson.highlighted == i
                                                ? 3
                                                : 1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(word.word[i],
                                                style: const TextStyle(
                                                    fontFamily: 'Nunito',
                                                    fontSize: 32,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            const Icon(Icons.volume_up_rounded,
                                                size: 24),
                                          ]),
                                    ),
                                  )),
                            ]
                          ],
                        ));
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
                      style: const TextStyle(color: KidsUi.ink, fontSize: 14))),
            const SizedBox(height: 8),
          ]),
        );
      })),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _CvcControl(
                label: 'Previous',
                icon: Icons.arrow_back_rounded,
                onPressed: lesson.index == 0
                    ? null
                    : () => lesson.select(lesson.index - 1))),
        const SizedBox(width: 6),
        Expanded(
            child: _CvcControl(
                label: 'Hear Again',
                icon: Icons.replay_rounded,
                primary: true,
                onPressed: () => lesson.start())),
        const SizedBox(width: 6),
        Expanded(
            child: _CvcControl(
                label: 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: lesson.index == cvcLessonWords.length - 1
                    ? null
                    : () => lesson.select(lesson.index + 1))),
      ]),
    ]));
  }
}

class _CvcControl extends LessonControlButton {
  const _CvcControl(
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

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.visible, required this.reducedMotion});
  final bool visible, reducedMotion;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: visible ? 1 : 0,
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFAD6900), size: 24)),
      );
}
