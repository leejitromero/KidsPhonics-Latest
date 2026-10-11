import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../providers/app_provider.dart';
import '../screens/letter_mastery_check_screen.dart';
import 'learner_widgets.dart';
import 'mastery_illustration.dart';
import 'quick_check_design.dart';

class OverallMasteryPanel extends StatelessWidget {
  const OverallMasteryPanel(
      {super.key,
      this.showLetters = false,
      this.showAchievements = false,
      this.dense = false});
  final bool showLetters, showAchievements, dense;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MasteryIllustration(
          dense: dense,
          compact: showLetters || showAchievements,
          mastered: p.overallMasteredCount,
          completed: p.adventureAssessments),
      if (showLetters || showAchievements)
        QuickGlassPanel(
            padding: EdgeInsets.all(dense ? 8 : 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLetters) ...[
                    SizedBox(height: dense ? 4 : 12),
                    ExpansionTile(
                        key: const ValueKey('adventure-letter-selector'),
                        dense: dense,
                        tilePadding: EdgeInsets.zero,
                        title: Text('Choose a letter adventure',
                            style:
                                dense ? const TextStyle(fontSize: 14) : null),
                        children: [
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            for (final item in allLetters)
                              Tooltip(
                                  message:
                                      '${item.letter}: ${p.adventureProgress(item.letter).status}',
                                  child: OutlinedButton(
                                      key: ValueKey(
                                          'overall-letter-${item.letter}'),
                                      onPressed: () => LearnerNavigation.open(
                                          context,
                                          LetterMasteryCheckScreen(
                                              letter: item),
                                          cloudTransition: true),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(item.letter,
                                                style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            const SizedBox(width: 4),
                                            Icon(
                                                p
                                                        .adventureProgress(
                                                            item.letter)
                                                        .mastered
                                                    ? Icons.star
                                                    : p
                                                                .adventureProgress(
                                                                    item.letter)
                                                                .completed >
                                                            0
                                                        ? Icons.edit
                                                        : Icons.star_border,
                                                size: 16),
                                          ])))
                          ])
                        ]),
                  ],
                  if (showAchievements) ...[
                    SizedBox(height: dense ? 4 : 12),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final milestone in AppProvider.adventureMilestones)
                        Chip(
                            visualDensity: dense ? VisualDensity.compact : null,
                            materialTapTargetSize:
                                dense ? MaterialTapTargetSize.shrinkWrap : null,
                            padding: dense ? EdgeInsets.zero : null,
                            labelPadding: dense
                                ? const EdgeInsets.symmetric(horizontal: 4)
                                : null,
                            avatar: Icon(
                                p.overallMasteredCount >= milestone
                                    ? Icons.emoji_events
                                    : Icons.lock_outline,
                                size: dense ? 16 : null),
                            label: Text(
                                '$milestone ${milestone == 1 ? 'letter' : 'letters'} mastered',
                                style: dense
                                    ? const TextStyle(fontSize: 12)
                                    : null))
                    ]),
                  ],
                ])),
    ]);
  }
}
