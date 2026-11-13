import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'lesson_introduction_sequence.dart';
import 'scene_voice_controller.dart';

/// One instruction per lesson entry. Browsing and manual audio interrupt it.
mixin LessonInstructionPlayback<T extends StatefulWidget> on State<T> {
  String get lessonInstructionPhrase;

  /// Opt-in automatic playback for the currently displayed letter.
  String? get lessonFeedbackPhrase => null;
  Future<void> onLessonFeedbackPlayed(String phrase) async {}

  Future<void> playLessonFeedback() async {
    final request = _instructionRequest;
    final phrase = lessonFeedbackPhrase;
    if (phrase == null) return;
    final provider = context.read<AppProvider>();
    bool current() =>
        mounted &&
        request == _instructionRequest &&
        phrase == lessonFeedbackPhrase &&
        provider.isReady &&
        provider.voiceEnabled &&
        !provider.timeLimitReached &&
        (ModalRoute.isCurrentOf(context) ?? true);
    // Display the new letter before speaking it, including rapid swipes.
    await WidgetsBinding.instance.endOfFrame;
    if (!current()) return;
    final completed = await _lessonInstruction!.play(phrase);
    if (completed && current()) await onLessonFeedbackPlayed(phrase);
  }

  SceneVoiceController? _lessonInstruction;
  String? _instructionPhrase;
  int _instructionRequest = 0;
  final lessonIntroductionStatus = LessonIntroductionSequence();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (_lessonInstruction == null) {
      final provider = context.read<AppProvider>();
      _lessonInstruction = SceneVoiceController(provider,
          isCurrent: () => mounted && (ModalRoute.isCurrentOf(context) ?? true),
          replayOnResume: false);
      _scheduleInstruction(provider);
    } else if (!current) {
      stopLessonInstruction();
    }
  }

  void _scheduleInstruction(AppProvider provider) {
    final request = ++_instructionRequest;
    final phrase = _instructionPhrase = lessonInstructionPhrase;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(provider.ready.then((_) async {
        if (mounted && provider.isReady && request == _instructionRequest) {
          final completed = await lessonIntroductionStatus.run(
              lesson: phrase,
              play: _lessonInstruction!.play,
              stop: () async => _lessonInstruction?.stop(),
              voiceEnabled: () => provider.voiceEnabled,
              isCurrent: () =>
                  mounted &&
                  request == _instructionRequest &&
                  (ModalRoute.isCurrentOf(context) ?? true) &&
                  !provider.timeLimitReached);
          if (completed && mounted && request == _instructionRequest) {
            await playLessonFeedback();
          }
        }
      }));
    });
  }

  void stopLessonInstruction() {
    _instructionRequest++;
    _lessonInstruction?.stop();
    lessonIntroductionStatus.interrupt();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_instructionPhrase != lessonInstructionPhrase) {
      stopLessonInstruction();
      _scheduleInstruction(context.read<AppProvider>());
    }
  }

  @override
  void dispose() {
    _instructionRequest++;
    _lessonInstruction?.dispose();
    lessonIntroductionStatus.dispose();
    super.dispose();
  }
}
