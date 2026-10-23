import '../widgets/lesson_control_button.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cvc_lesson_controller.dart';
import '../controllers/lesson_introduction_sequence.dart';
import '../data/lesson_instruction_scripts.dart';
import '../data/cvc_lesson_data.dart';
import '../providers/app_provider.dart';
import '../models/word_lesson_progress.dart';
import '../services/background_music_service.dart';
import '../theme/kids_ui.dart';
import '../widgets/button_sound.dart';
import '../widgets/cvc_word_picture.dart';
import '../widgets/lessons_menu_page.dart';
import '../widgets/lesson_frame.dart';

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
  final _introduction = LessonIntroductionSequence();

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
    _lesson = (widget.controller ??
        CvcLessonController(
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
        unawaited(_provider!.startWordLesson(WordLesson.cvc));
        unawaited(_lesson!.start(introduction: true));
      }
    });
  }

  Future<bool> _playIntroduction() => _introduction.run(
      lesson: 'cvc-intro',
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

  void _navigate(VoidCallback action) {
    _introduction.interrupt();
    action();
  }

  void _changed() {
    if (!mounted) return;
    if (_lesson!.phase != CvcPhase.intro && !_introduction.finished) {
      _introduction.interrupt();
    }
    if (_lesson!.phase == CvcPhase.complete && !_lesson!.running) {
      unawaited(_provider!
          .completeWordLessonWord(WordLesson.cvc, _lesson!.word.word));
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _introduction.interrupt();
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
    unawaited(BackgroundMusicService.instance.release(this));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson!;
    final word = lesson.word;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LessonsMenuPage(
        title: 'CVC Words',
        introduction: lessonInstructionScripts['cvc-intro']!,
        introductionStatus: _introduction,
        instruction: lessonInstructionDefaults['cvc-intro']!,
        child: Column(children: [
          Expanded(child: LayoutBuilder(builder: (context, box) {
            final pictureHeight = (box.maxHeight - 270).clamp(80.0, 220.0);
            return SingleChildScrollView(
              key: const ValueKey('cvc-content'),
              child: Column(children: [
                if (lesson.phase != CvcPhase.intro)
                  LessonFrame(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Column(children: [
                      Text('Short ${word.vowel}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: KidsUi.muted,
                              fontWeight: FontWeight.w800)),
                      SizedBox(
                          height: pictureHeight,
                          child: CvcWordPicture(
                              key: ValueKey(word.word), word: word)),
                      AnimatedScale(
                        scale:
                            lesson.phase == CvcPhase.complete && !reducedMotion
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
                        final cardHeight = 50 + 38 * scale;
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
                                              milliseconds: lesson.phase ==
                                                      CvcPhase.fastBlend
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
                                            backgroundColor: lesson
                                                        .highlighted ==
                                                    i
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
                                                const Icon(
                                                    Icons.volume_up_rounded,
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
                          style: const TextStyle(
                              color: KidsUi.ink, fontSize: 14))),
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
                        : () =>
                            _navigate(() => lesson.select(lesson.index - 1)))),
            const SizedBox(width: 6),
            Expanded(
                child: _CvcControl(
                    label: 'Hear Again',
                    icon: Icons.replay_rounded,
                    primary: true,
                    onPressed: () => _navigate(() => lesson.start()))),
            const SizedBox(width: 6),
            Expanded(
                child: _CvcControl(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: lesson.index == cvcLessonWords.length - 1
                        ? null
                        : () =>
                            _navigate(() => lesson.select(lesson.index + 1)))),
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
