import '../widgets/lesson_control_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cvc_lesson_controller.dart';
import '../controllers/lesson_introduction_sequence.dart';
import '../data/lesson_instruction_scripts.dart';
import '../data/cvc_lesson_data.dart';
import '../data/lesson_word_order.dart';
import '../providers/app_provider.dart';
import '../models/word_lesson_progress.dart';
import '../services/background_music_service.dart';
import '../theme/kids_ui.dart';
import '../widgets/cvc_word_board.dart';
import '../widgets/lessons_menu_page.dart';
import '../widgets/lesson_swipe_navigation.dart';

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
  LessonWordSession<CvcLessonWord>? _wordSession;
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
    if (widget.controller == null) {
      _wordSession =
          LessonWordOrder.open('cvc', cvcLessonWords, (word) => word.word);
    }
    _lesson = (widget.controller ??
        CvcLessonController(
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
    if (_lesson!.phase != CvcPhase.intro) {
      _wordSession?.show(_lesson!.index);
    }
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
    final VoidCallback? previous = lesson.index == 0
        ? null
        : () => _navigate(() => lesson.select(lesson.index - 1));
    final VoidCallback? next = lesson.index == lesson.words.length - 1
        ? null
        : () => _navigate(() => lesson.select(lesson.index + 1));
    return LessonsMenuPage(
        title: 'CVC Words',
        introduction: lessonInstructionScripts['cvc-intro']!,
        introductionStatus: _introduction,
        instruction: lessonInstructionDefaults['cvc-intro']!,
        child: LessonSwipeNavigation(
            navigationKey: lesson.index,
            onPrevious: previous,
            onNext: next,
            child: Column(children: [
              Expanded(child: LayoutBuilder(builder: (context, box) {
                return SingleChildScrollView(
                  key: const ValueKey('cvc-content'),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (lesson.phase != CvcPhase.intro)
                            CvcWordBoard(
                                lesson: lesson,
                                availableHeight: box.maxHeight -
                                    16 -
                                    (!lesson.voiceEnabled ||
                                            lesson.audioUnavailable
                                        ? 12 +
                                            MediaQuery.textScalerOf(context)
                                                .scale(32)
                                        : 0)),
                          if (!lesson.voiceEnabled || lesson.audioUnavailable)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                !lesson.voiceEnabled
                                    ? 'Audio is turned off.'
                                    : 'Audio unavailable. Tap Hear Again.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: KidsUi.ink, fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              })),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _CvcControl(
                        label: 'Previous',
                        icon: Icons.arrow_back_rounded,
                        onPressed: previous)),
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
                        onPressed: next)),
              ]),
            ])));
  }
}

class _CvcControl extends LessonControlButton {
  const _CvcControl(
      {required super.label,
      required super.icon,
      required super.onPressed,
      super.primary = false})
      : super(
            fitLabel: true,
            art: label == 'Next'
                ? LessonButtonArt.next
                : label == 'Previous'
                    ? LessonButtonArt.previous
                    : label == 'Hear Again'
                        ? LessonButtonArt.sound
                        : null);
}
