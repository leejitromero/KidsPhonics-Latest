import 'package:flutter/material.dart';
import 'game_design.dart';
import 'word_game_layout.dart';

/// A glossy letter tray. Empty places retain their size as tiles move out.
class WordBuilderChoiceFrame extends StatelessWidget {
  const WordBuilderChoiceFrame({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD399FF),
                Color(0xFF9044DE),
                Color(0xFF5428A4)
              ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x44502482), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFFFDE80), width: 2),
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFEF5), Color(0xFFF1E8FF)]),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB56AEF), Color(0xFF7134BF)]),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  ExcludeSemantics(
                      child: Icon(Icons.star_rounded,
                          color: Color(0xFFFFDD58), size: 21)),
                  SizedBox(width: 6),
                  Flexible(
                      child: Text('Choose a letter',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white))),
                  SizedBox(width: 6),
                  ExcludeSemantics(
                      child: Icon(Icons.star_rounded,
                          color: Color(0xFFFFDD58), size: 21)),
                ]),
              ),
            ),
            const SizedBox(height: 9),
            LayoutBuilder(builder: (context, box) {
              final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
              final fitting = ((box.maxWidth + 8) / (48 * scale + 8))
                  .floor()
                  .clamp(1, children.length);
              // Prefer balanced rows (3+2 or 2+2) on narrower screens.
              final columns = children.length == 5 && fitting == 4
                  ? 3
                  : children.length == 4 && fitting == 3
                      ? 2
                      : fitting;
              return WordChoiceGrid(columns: columns, children: children);
            }),
          ]),
        ),
      );
}

class WordBuilderEmptyPlace extends StatelessWidget {
  const WordBuilderEmptyPlace({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6C7ED), width: 1.5),
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8DFF4), GameDesign.cream]),
          ),
        ),
      );
}
