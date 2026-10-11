import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../providers/app_provider.dart';
import '../screens/letter_mastery_check_screen.dart';
import 'learner_widgets.dart';
import 'home_recommendation_panel.dart';

/// The same saved recommendation and Quick Check entry point on every dashboard.
class QuickCheckRecommendation extends StatelessWidget {
  const QuickCheckRecommendation({super.key, this.onStart});
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final letter = p.recommendedAdventureLetter;
    return HomeRecommendationPanel(
        letter: letter,
        review: letter != null && p.adventureProgress(letter).completed > 0,
        onStart: onStart ??
            () => LearnerNavigation.open(context,
                LetterMasteryCheckScreen(letter: letterContent(letter ?? 'A')),
                cloudTransition: true, endParentSession: true));
  }
}
