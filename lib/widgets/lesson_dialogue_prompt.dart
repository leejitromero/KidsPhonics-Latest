import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/lesson_instruction_scripts.dart';

/// The whole sentence stays visible until its actual recording completes.
/// No reading timer or layout-driven page change can advance spoken text.
class LessonDialoguePrompt extends StatelessWidget {
  const LessonDialoguePrompt(
      {super.key,
      required this.message,
      required this.introduction,
      required this.status,
      required this.builder});
  final String message;
  final List<String> introduction;
  final ValueListenable<LessonIntroductionStatus>? status;
  final Widget Function(String text) builder;

  @override
  Widget build(BuildContext context) {
    final playback = status;
    if (playback == null || introduction.isEmpty) return builder(message);
    return ValueListenableBuilder<LessonIntroductionStatus>(
        valueListenable: playback,
        builder: (_, value, __) => builder(switch (value) {
              LessonIntroductionStatus.pending => introduction.first,
              LessonIntroductionStatus.second => introduction[1],
              _ => message,
            }));
  }
}
