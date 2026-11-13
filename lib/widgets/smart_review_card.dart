import 'package:flutter/material.dart';
import '../models/smart_review.dart';
import '../theme/kids_ui.dart';
import 'lesson_frame.dart';

class SmartReviewCard extends StatelessWidget {
  const SmartReviewCard(
      {super.key, required this.suggestion, required this.onPressed});
  final ReviewEvidence suggestion;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => LessonFrame(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFFE69B00)),
            SizedBox(width: 8),
            Expanded(
                child: Text('Smart Review',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: KidsUi.ink))),
          ]),
          const SizedBox(height: 10),
          Text("Let's practice ${suggestion.target.title}.",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: KidsUi.ink)),
          const SizedBox(height: 6),
          const Text('A short review based on your recent answers.'),
          const SizedBox(height: 14),
          FilledButton.icon(
              key: const ValueKey('start-smart-review'),
              onPressed: onPressed,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Review')),
        ],
      ));
}
