import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/button_sound.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/lesson_control_button.dart';
import '../widgets/lessons_menu_page.dart';

class VowelSoundsScreen extends StatefulWidget {
  const VowelSoundsScreen({super.key});
  @override
  State<VowelSoundsScreen> createState() => _VowelSoundsScreenState();
}

class _VowelSoundsScreenState extends State<VowelSoundsScreen> {
  static const _vowels = ['A', 'E', 'I', 'O', 'U'];
  int _index = 0;
  AppProvider? _provider;
  String get _letter => _vowels[_index];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) return;
    _provider = context.read<AppProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_provider!.markLetterViewed(_letter));
    });
  }

  void _select(int index) {
    if (index == _index || index < 0 || index >= _vowels.length) return;
    unawaited(_provider!.phonicsAudio.stop());
    setState(() => _index = index);
    unawaited(_provider!.markLetterViewed(_letter));
  }

  @override
  void dispose() {
    unawaited(_provider?.phonicsAudio.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LessonsMenuPage(
          child: Column(children: [
        Expanded(child: LayoutBuilder(builder: (context, box) {
          final pictureHeight = (box.maxHeight - 240).clamp(120.0, 330.0);
          return SingleChildScrollView(
              child: Column(children: [
            const Text('Short Vowel Sounds',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: KidsUi.ink)),
            const Text('Meet the Vowels!',
                style: TextStyle(fontSize: 15, color: KidsUi.ink)),
            const SizedBox(height: 10),
            Row(children: [
              for (var i = 0; i < _vowels.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                        selected: i == _index,
                        label: 'Choose vowel ${_vowels[i]}',
                        child: OutlinedButton(
                          key: ValueKey('vowel-tab-${_vowels[i]}'),
                          onPressed: withButtonSound(() => _select(i)),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(48, 54),
                              backgroundColor: i == _index
                                  ? const Color(0xFF7052CA)
                                  : KidsUi.cardSurface,
                              foregroundColor:
                                  i == _index ? Colors.white : KidsUi.ink,
                              side: BorderSide(
                                  color: i == _index
                                      ? const Color(0xFFFFD76A)
                                      : Colors.white,
                                  width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: Column(children: [
                            Text(_vowels[i],
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                            Container(
                                height: 3,
                                width: 18,
                                decoration: BoxDecoration(
                                    color: i == _index
                                        ? const Color(0xFFFFD76A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(3))),
                          ]),
                        )),
                  ),
                )
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: pictureHeight,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: KidsUi.cardSurface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x26335C7D),
                        blurRadius: 20,
                        offset: Offset(0, 8))
                  ]),
              child: Semantics(
                  label:
                      'Uppercase $_letter, lowercase ${_letter.toLowerCase()}',
                  child: ExcludeSemantics(
                      child: Column(children: [
                    Expanded(
                        child: Image.asset(
                            'assets/images/letters/${_letter.toLowerCase()}.png',
                            key: const ValueKey('vowel-letter'),
                            fit: BoxFit.contain,
                            cacheWidth: 480)),
                    SizedBox(
                        height: 42,
                        child: FittedBox(
                            child: Text(_letter.toLowerCase(),
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: KidsUi.ink)))),
                  ]))),
            ),
            const SizedBox(height: 10),
            const Text('Hear the vowel sound',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: KidsUi.ink)),
            AudioButton(
                key: ValueKey('vowel-sound-$_letter'),
                phrase: 'lesson-sound-$_letter',
                label: '/${_letter.toLowerCase()}/',
                lessonArt: true),
            const SizedBox(height: 8),
          ]));
        })),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: LessonControlButton(
                  label: 'Previous',
                  icon: Icons.arrow_back_rounded,
                  art: LessonButtonArt.previous,
                  onPressed: _index == 0 ? null : () => _select(_index - 1))),
          const SizedBox(width: 24),
          Expanded(
              child: LessonControlButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  art: LessonButtonArt.next,
                  onPressed: _index == 4 ? null : () => _select(_index + 1))),
        ]),
      ]));
}
