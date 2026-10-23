import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/alphabet_pictures_controller.dart';
import '../controllers/lesson_introduction_sequence.dart';
import '../controllers/scene_voice_controller.dart';
import '../data/lesson_instruction_scripts.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../services/phonics_audio_service.dart';
import '../theme/kids_ui.dart';
import '../widgets/animated_screen_art.dart';
import '../widgets/letter_lesson_page.dart' show AlphabetLetterPicker;
import '../widgets/lesson_control_button.dart';
import '../widgets/lesson_frame.dart';
import '../widgets/lessons_menu_page.dart';

class AlphabetPicturesScreen extends StatefulWidget {
  const AlphabetPicturesScreen({super.key});
  @override
  State<AlphabetPicturesScreen> createState() => _AlphabetPicturesScreenState();
}

class _AlphabetPicturesScreenState extends State<AlphabetPicturesScreen> {
  static const _introPhrase = 'lesson-instruction-alphabet-pictures';
  final _introduction = LessonIntroductionSequence();
  int _entryRequest = 0;
  SceneVoiceController? _voice;
  AlphabetPicturesController? _lesson;
  AppProvider? _provider;
  bool _gridOpen = false;
  bool get _current =>
      mounted && !_gridOpen && (ModalRoute.isCurrentOf(context) ?? true);

  Future<void> _paintEntry() {
    final painted = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => painted.complete());
    WidgetsBinding.instance.scheduleFrame();
    return painted.future;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) {
      if (!_current) {
        _stopIntroduction();
        _lesson!.stop(notify: false);
      }
      return;
    }
    final p = _provider = context.read<AppProvider>();
    _voice = SceneVoiceController(p,
        isCurrent: () => _current, replayOnResume: false);
    _lesson = AlphabetPicturesController(
        play: _voice!.play,
        stopAudio: () => _voice!.stop(notify: false),
        enabled: () =>
            _current && p.isReady && p.voiceEnabled && !p.timeLimitReached,
        available: (phrase) =>
            PhonicsAudioService.assetForPhrase(phrase) != null,
        beforePlay: _paintEntry,
        onViewed: (letter) => unawaited(p.markLetterViewed(letter)),
        onListened: (letter) =>
            p.recordLetterListening(letter, LetterListeningKind.word));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_introduce(_entryRequest));
    });
  }

  Future<void> _introduce(int request) async {
    final p = _provider!;
    await p.ready;
    bool current() =>
        _current && request == _entryRequest && !p.timeLimitReached;
    if (!current()) return;
    unawaited(p.markLetterViewed(_lesson!.entry.letter));
    final completed = await _introduction.run(
        lesson: _introPhrase,
        play: _voice!.play,
        stop: () async => _voice?.stop(notify: false),
        voiceEnabled: () => p.voiceEnabled,
        isCurrent: current);
    if (completed && current()) await _lesson!.replay();
  }

  void _stopIntroduction() {
    _entryRequest++;
    if (!_introduction.finished) _introduction.interrupt();
  }

  void _select(int index) {
    _stopIntroduction();
    unawaited(_lesson!.select(index));
  }

  void _replay() {
    _stopIntroduction();
    unawaited(_lesson!.replay());
  }

  Future<void> _openGrid() async {
    if (_gridOpen) return;
    _stopIntroduction();
    _lesson!.stop();
    setState(() => _gridOpen = true);
    final index = await showDialog<int>(
        context: context,
        builder: (_) => Theme(
            data: KidsUi.theme,
            child: AlphabetLetterPicker(
                selectedIndex: _lesson!.index,
                gridKey: const ValueKey('alphabet-pictures-grid'))));
    if (!mounted) return;
    setState(() => _gridOpen = false);
    if (index != null) _select(index);
  }

  @override
  void dispose() {
    _entryRequest++;
    _introduction.dispose();
    _lesson?.dispose();
    _voice?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final lesson = _lesson!;
    return LessonsMenuPage(
        title: 'Alphabet & Pictures',
        instruction: lessonInstructionDefaults[_introPhrase]!,
        introduction: lessonInstructionScripts[_introPhrase]!,
        introductionStatus: _introduction,
        child: ListenableBuilder(
            listenable: lesson,
            builder: (_, __) {
              final entry = lesson.entry;
              final enabled = p.isReady && !p.timeLimitReached && !_gridOpen;
              return LayoutBuilder(builder: (context, available) {
                final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
                return SingleChildScrollView(
                    child: SizedBox(
                        height:
                            math.max(available.maxHeight, 310 + 100 * scale),
                        child: Column(children: [
                          Expanded(child: LayoutBuilder(builder: (_, box) {
                            final side = math.min(
                                480.0, math.min(box.maxWidth, box.maxHeight));
                            return Center(
                                child: SizedBox(
                                    width: side,
                                    height: side,
                                    child: LessonFrame(
                                        radius: 32,
                                        padding: EdgeInsets.all(side * .06),
                                        child: Semantics(
                                            label: entry.sentence,
                                            image: true,
                                            child: AnimatedScreenArt(
                                                key: ValueKey(
                                                    'alphabet-picture-${entry.letter}'),
                                                frames: entry.frames,
                                                fit: BoxFit.contain,
                                                maxDecodeWidth: 720,
                                                frameDuration: const Duration(
                                                    milliseconds: 450))))));
                          })),
                          const SizedBox(height: 8),
                          Text(entry.sentence,
                              key: const ValueKey('alphabet-picture-caption'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: KidsUi.ink)),
                          const SizedBox(height: 8),
                          SizedBox(
                              width: 150,
                              child: LessonControlButton(
                                  key: const ValueKey('alphabet-picture-sound'),
                                  label:
                                      lesson.playing ? 'Listening...' : 'Sound',
                                  icon: Icons.volume_up_rounded,
                                  art: LessonButtonArt.sound,
                                  onPressed: enabled &&
                                          p.voiceEnabled &&
                                          lesson.hasRecording &&
                                          !lesson.playing
                                      ? _replay
                                      : null)),
                          if (!p.voiceEnabled || lesson.message != null)
                            Text(
                                !p.voiceEnabled
                                    ? 'Audio is turned off.'
                                    : lesson.message!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12, color: KidsUi.ink)),
                          const SizedBox(height: 16),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: LessonControlButton(
                                        label: 'Previous',
                                        icon: Icons.arrow_back_rounded,
                                        art: LessonButtonArt.previous,
                                        onPressed: !enabled || lesson.index == 0
                                            ? null
                                            : () => _select(lesson.index - 1))),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: LessonControlButton(
                                        label: 'A\u2013Z Grid',
                                        icon: Icons.grid_view_rounded,
                                        primary: true,
                                        onPressed: enabled ? _openGrid : null)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: LessonControlButton(
                                        label: 'Next',
                                        icon: Icons.arrow_forward_rounded,
                                        art: LessonButtonArt.next,
                                        onPressed: !enabled ||
                                                lesson.index == 25
                                            ? null
                                            : () => _select(lesson.index + 1))),
                              ])
                        ])));
              });
            }));
  }
}
