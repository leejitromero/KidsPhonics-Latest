import 'package:flutter/material.dart';
import '../data/game_word_data.dart';

class GameWordPicture extends StatefulWidget {
  const GameWordPicture({super.key, required this.word, this.size = 150});
  final String word;
  final double size;
  @override
  State<GameWordPicture> createState() => _GameWordPictureState();
}

class _GameWordPictureState extends State<GameWordPicture>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = gameWordFor(widget.word);
    if (word == null) return Text(widget.word);
    return Semantics(
        image: true,
        label: word.word,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: RepaintBoundary(
              child: AnimatedBuilder(
            animation: _animation,
            builder: (_, __) => Stack(fit: StackFit.expand, children: [
              for (var i = 0; i < word.frames.length; i++)
                Opacity(
                    opacity:
                        i == (_animation.value * word.frames.length).floor()
                            ? 1
                            : 0,
                    child: Image.asset(word.frames[i],
                        fit: BoxFit.contain,
                        cacheWidth: 480,
                        gaplessPlayback: true)),
            ]),
          )),
        ));
  }
}
