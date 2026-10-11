import 'package:flutter/material.dart';
import '../data/lesson_example_data.dart';
import 'picture_frame_animation.dart';

/// Plays the supplied frames without changing the artwork.
class LessonPicture extends StatelessWidget {
  const LessonPicture({super.key, required this.example, this.size});
  final LessonExample example;
  final double? size;
  @override
  Widget build(BuildContext context) => Semantics(
      image: true,
      label: example.word,
      child: ExcludeSemantics(
          child: SizedBox(
              height: size ??
                  (MediaQuery.sizeOf(context).height * .20).clamp(120.0, 170.0),
              width: size ?? 190,
              child: PictureFrameAnimation(
                  frames: example.frames,
                  duration: const Duration(milliseconds: 1500),
                  cacheWidth: 640))));
}
