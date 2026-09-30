import 'package:flutter/material.dart';
import 'game_word_picture.dart';

/// Shared picture and control sizing for the word games, within the viewport.
class WordGameLayout extends StatelessWidget {
  const WordGameLayout({super.key, required this.word, required this.children});
  final String word;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final imageSize = (box.maxHeight * .38).clamp(130.0, 220.0);
        return Column(children: [
          SizedBox(
              height: imageSize,
              child:
                  Center(child: GameWordPicture(word: word, size: imageSize))),
          const SizedBox(height: 6),
          Expanded(
              child: LayoutBuilder(
                  builder: (_, controls) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                              width: controls.maxWidth,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: children)),
                        ),
                      ))),
        ]);
      });
}

class WordChoiceGrid extends StatelessWidget {
  const WordChoiceGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final side = ((box.maxWidth - 32) / 5).clamp(0.0, 60.0);
        final columns = children.length.clamp(1, 5);
        return Center(
            child: SizedBox(
          width: side * columns + 8 * (columns - 1),
          child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: children
                  .map((child) =>
                      SizedBox(width: side, height: side, child: child))
                  .toList()),
        ));
      });
}
