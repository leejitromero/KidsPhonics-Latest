import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../controllers/lesson_instruction_playback.dart';
import '../data/lesson_instruction_scripts.dart';
import '../models/learning_progress.dart';
import '../theme/kids_ui.dart';
import 'button_sound.dart';
import 'learner_widgets.dart';
import 'lessons_menu_page.dart';
import 'lesson_control_button.dart';
import 'lesson_frame.dart';

enum LetterLessonAudio { name, sound }

/// Shared A–Z presentation; browsing and listening do not award mastery.
class LetterLessonPage extends StatefulWidget {
  const LetterLessonPage({super.key, required this.audio});
  final LetterLessonAudio audio;

  @override
  State<LetterLessonPage> createState() => _LetterLessonPageState();
}

class _LetterLessonPageState extends State<LetterLessonPage>
    with LessonInstructionPlayback<LetterLessonPage> {
  int _index = 0;
  int _audioVersion = 0;
  bool _gridOpen = false;
  AppProvider? _provider;

  @override
  String get lessonInstructionPhrase => widget.audio == LetterLessonAudio.name
      ? 'lesson-instruction-recognition'
      : 'lesson-instruction-sounds';

  String get _letter => String.fromCharCode(65 + _index);
  String get _audioPhrase => widget.audio == LetterLessonAudio.name
      ? _letter
      : 'lesson-sound-$_letter';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) return;
    _provider = context.read<AppProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_provider!.markLetterViewed(_letter));
    });
  }

  @override
  void dispose() {
    unawaited(_provider?.phonicsAudio.stop());
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 || index > 25 || index == _index) return;
    stopLessonInstruction();
    unawaited(_provider!.phonicsAudio.stop());
    setState(() {
      _index = index;
      _audioVersion++;
    });
    unawaited(_provider!.markLetterViewed(_letter));
  }

  Future<void> _openGrid() async {
    if (_gridOpen) return;
    stopLessonInstruction();
    // Replace the audio control so intentional cancellation isn't an error.
    setState(() {
      _gridOpen = true;
      _audioVersion++;
    });
    unawaited(_provider!.phonicsAudio.stop());
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => Theme(
        data: KidsUi.theme,
        child: AlphabetLetterPicker(selectedIndex: _index),
      ),
    );
    if (!mounted) return;
    setState(() => _gridOpen = false);
    if (selected != null) _select(selected);
  }

  @override
  Widget build(BuildContext context) => LessonsMenuPage(
        title: widget.audio == LetterLessonAudio.name
            ? 'Letter Recognition'
            : 'Letter Sounds',
        introduction: lessonInstructionScripts[lessonInstructionPhrase]!,
        introductionStatus: lessonIntroductionStatus,
        instruction: lessonInstructionDefaults[lessonInstructionPhrase]!,
        child: LayoutBuilder(builder: (context, available) {
          final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
          final minimumHeight = 250 + 62 * scale;
          final content = SizedBox(
              height: math.max(available.maxHeight, minimumHeight),
              child: Column(children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, box) {
                    final side =
                        math.min(480.0, math.min(box.maxWidth, box.maxHeight));
                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: LessonFrame(
                            radius: 32,
                            padding: EdgeInsets.all(side * .08),
                            child: Image.asset(
                              'assets/images/letters/${_letter.toLowerCase()}.webp',
                              key: const ValueKey('recognition-letter'),
                              fit: BoxFit.contain,
                              semanticLabel: 'Letter $_letter',
                              cacheWidth: (side *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                            )),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                AudioButton(
                  key: ValueKey(
                      'letter-${widget.audio.name}-$_index-$_audioVersion'),
                  phrase: _audioPhrase,
                  onBeforePlay: stopLessonInstruction,
                  onPlayed: () => _provider!.recordLetterListening(
                      _letter,
                      widget.audio == LetterLessonAudio.name
                          ? LetterListeningKind.name
                          : LetterListeningKind.sound),
                  label: 'Sound',
                  icon: Icons.volume_up_rounded,
                  color: const Color(0xFF087F86),
                  lessonArt: true,
                ),
                const SizedBox(height: 20),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: _LetterNavigationButton(
                      label: 'Previous',
                      icon: Icons.arrow_back_rounded,
                      onPressed: _index == 0 ? null : () => _select(_index - 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LetterNavigationButton(
                      label: 'A–Z Grid',
                      icon: Icons.grid_view_rounded,
                      primary: true,
                      onPressed: _gridOpen ? null : _openGrid,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LetterNavigationButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed:
                          _index == 25 ? null : () => _select(_index + 1),
                    ),
                  ),
                ]),
              ]));
          return SingleChildScrollView(child: content);
        }),
      );
}

class _LetterNavigationButton extends LessonControlButton {
  const _LetterNavigationButton(
      {required super.label,
      required super.icon,
      required super.onPressed,
      super.primary = false})
      : super(
            art: label == 'Next'
                ? LessonButtonArt.next
                : label == 'Previous'
                    ? LessonButtonArt.previous
                    : label == 'Hear Again'
                        ? LessonButtonArt.sound
                        : null);
}

class AlphabetLetterPicker extends StatelessWidget {
  const AlphabetLetterPicker(
      {super.key,
      required this.selectedIndex,
      this.gridKey = const ValueKey('recognition-grid')});
  final int selectedIndex;
  final Key gridKey;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFFF1EAFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        title: Row(children: [
          const Padding(
              padding: EdgeInsets.only(right: 8),
              child:
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFB87700))),
          const Expanded(
              child: Text('A–Z Grid',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: Color(0xFF51318C)))),
          IconButton(
            tooltip: 'Close grid',
            onPressed: withButtonSound(() => Navigator.pop(context)),
            icon: const Icon(Icons.close_rounded),
          ),
        ]),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        content: SizedBox(
          width: 420,
          height: math.min(490, MediaQuery.sizeOf(context).height * .60),
          child: LayoutBuilder(builder: (context, box) {
            final scale = MediaQuery.textScalerOf(context).scale(24) / 24;
            final columns = (box.maxWidth / (64 * scale)).floor().clamp(2, 6);
            return GridView.builder(
              key: gridKey,
              padding: EdgeInsets.zero,
              itemCount: 26,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: math.max(78, 64 * scale),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final letter = String.fromCharCode(65 + index);
                final selected = index == selectedIndex;
                const colors = [
                  Color(0xFFFFDCE8),
                  Color(0xFFD8F3FF),
                  Color(0xFFFFEDB4),
                  Color(0xFFD5F4E2),
                  Color(0xFFE5DAFF)
                ];
                final color = colors[index % colors.length];
                return Semantics(
                  selected: selected,
                  label: 'Letter $letter',
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: selected
                                ? const [Color(0xFF9A6CE4), Color(0xFF5931B0)]
                                : [Colors.white, color]),
                        boxShadow: [
                          BoxShadow(
                              color: (selected
                                      ? const Color(0xFF5931B0)
                                      : const Color(0xFFB7A4CC))
                                  .withValues(alpha: .35),
                              offset: const Offset(0, 3),
                              blurRadius: 1)
                        ],
                      ),
                      child: OutlinedButton(
                        key: ValueKey('pick-letter-$letter'),
                        onPressed: withButtonSound(
                            () => Navigator.pop(context, index)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          foregroundColor: selected ? Colors.white : KidsUi.ink,
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFFFD76A)
                                : Colors.white,
                            width: selected ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          const Positioned(
                              top: 6,
                              left: 10,
                              right: 10,
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: Color(0x66FFFFFF),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8))),
                                  child: SizedBox(height: 5))),
                          Center(
                              child: Text(letter,
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900))),
                          if (selected)
                            const Positioned(
                                right: 4,
                                bottom: 4,
                                child: Icon(Icons.check_circle_rounded,
                                    size: 16, color: Color(0xFFFFD76A))),
                        ]),
                      )),
                );
              },
            );
          }),
        ),
      );
}
