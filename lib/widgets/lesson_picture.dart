import 'package:flutter/material.dart';
import '../data/lesson_example_data.dart';

/// Plays the artist's three original frames in order, without morphing artwork.
class LessonPicture extends StatefulWidget {
  const LessonPicture({super.key, required this.example, this.size});
  final LessonExample example;
  final double? size;

  @override
  State<LessonPicture> createState() => _LessonPictureState();
}

class _LessonPictureState extends State<LessonPicture>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LessonPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.example != widget.example) _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: widget.example.word,
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: SizedBox(
              height: widget.size ??
                  (MediaQuery.sizeOf(context).height * .20).clamp(120.0, 170.0),
              width: widget.size ?? 190,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final frames = widget.example.frames;
                  final frame = (_controller.value * frames.length)
                      .floor()
                      .clamp(0, frames.length - 1);
                  // Keep all three decoded frames mounted to avoid flashes.
                  return Stack(fit: StackFit.expand, children: [
                    for (var i = 0; i < frames.length; i++)
                      Opacity(
                        opacity: i == frame ? 1 : 0,
                        child: Image.asset(widget.example.frames[i],
                            fit: BoxFit.contain,
                            cacheWidth: 640,
                            gaplessPlayback: true),
                      ),
                  ]);
                },
              ),
            ),
          ),
        ),
      );
}
