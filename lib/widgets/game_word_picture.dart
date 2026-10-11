import 'package:flutter/material.dart';
import '../data/game_word_data.dart';
import 'picture_frame_animation.dart';

class GameWordPicture extends StatelessWidget {
  const GameWordPicture({super.key, required this.word, this.size = 150});
  final String word;
  final double size;
  @override
  Widget build(BuildContext context) {
    final content = gameWordFor(word);
    if (content == null) return Text(word);
    return Semantics(
        image: true,
        label: content.word,
        child: SizedBox(
            width: size,
            height: size,
            child: PictureFrameAnimation(
                frames: content.frames,
                duration: const Duration(milliseconds: 1400),
                cacheWidth: 480)));
  }
}
