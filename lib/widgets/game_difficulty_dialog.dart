import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../data/game_word_data.dart';
import '../theme/kids_ui.dart';
import 'button_sound.dart';

class GameDifficultyDialog extends StatelessWidget {
  const GameDifficultyDialog(
      {super.key,
      required this.title,
      required this.detail,
      required this.onSelected});
  final String title;
  final String Function(Difficulty) detail;
  final ValueChanged<Difficulty> onSelected;
  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFCED), Color(0xFFFFECCD)]),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: const Color(0xFF6ECFFF), width: 5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55402413),
                        blurRadius: 24,
                        offset: Offset(0, 10))
                  ]),
              child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            height: 68,
                            child: Image.asset(gameWordFor('DOG')!.frames.first,
                                fit: BoxFit.contain,
                                cacheWidth: 180,
                                excludeFromSemantics: true)),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF4B75C),
                                      Color(0xFFB9652C)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: const Color(0xFF914817), width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x44844717),
                                      offset: Offset(0, 4))
                                ]),
                            child: Text(title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFF8DC),
                                    shadows: [
                                      Shadow(
                                          color: Color(0xFF733108),
                                          offset: Offset(0, 2),
                                          blurRadius: 2)
                                    ]))),
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Choose a level',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF54270B)))),
                        for (final difficulty in Difficulty.values)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LevelOption(
                                  difficulty: difficulty,
                                  detail: detail(difficulty),
                                  onPressed: () => onSelected(difficulty))),
                        TextButton(
                            onPressed:
                                withButtonSound(() => Navigator.pop(context)),
                            style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFB7E6FF),
                                foregroundColor: const Color(0xFF095BA4),
                                minimumSize: const Size(150, 48),
                                side: const BorderSide(
                                    color: Color(0xFF51A9E6), width: 2)),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900))),
                      ]))),
            )),
      );
}

class _LevelOption extends StatelessWidget {
  const _LevelOption(
      {required this.difficulty,
      required this.detail,
      required this.onPressed});
  final Difficulty difficulty;
  final String detail;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final (light, dark, icon) = switch (difficulty) {
      Difficulty.easy => (
          const Color(0xFF77E72D),
          const Color(0xFF219D13),
          Icons.star_rounded
        ),
      Difficulty.medium => (
          const Color(0xFFB46CFF),
          const Color(0xFF7424CB),
          Icons.extension_rounded
        ),
      Difficulty.hard => (
          const Color(0xFFFFAA38),
          const Color(0xFFE7620A),
          Icons.emoji_events_rounded
        ),
    };
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [light, dark]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: dark, width: 3),
          boxShadow: [
            BoxShadow(
                color: dark.withValues(alpha: .4),
                offset: const Offset(0, 4),
                blurRadius: 2)
          ]),
      child: OutlinedButton(
          onPressed: withButtonSound(onPressed),
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(double.infinity, 88),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25))),
          child: Row(children: [
            Icon(icon,
                size: 44,
                color: const Color(0xFFFFE376),
                shadows: const [
                  Shadow(color: Color(0x66372100), offset: Offset(0, 3))
                ]),
            const SizedBox(width: 10),
            Expanded(
                child: Column(children: [
              Text(difficulty.label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0x6630214F), offset: Offset(0, 3))
                      ])),
              const SizedBox(height: 4),
              Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .83),
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: KidsUi.ink))),
            ])),
          ])),
    );
  }
}
