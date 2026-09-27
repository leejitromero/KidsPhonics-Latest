import '../models/learning_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import '../data/lesson_example_data.dart';
import '../widgets/lesson_picture.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/learning_progress_widgets.dart';
import '../theme/kids_ui.dart';
import 'letter_mastery_check_screen.dart';

class LetterSoundsScreen extends StatefulWidget {
  final bool vowelsOnly;
  const LetterSoundsScreen({super.key, this.vowelsOnly = false});
  @override
  State<LetterSoundsScreen> createState() => _LetterSoundsScreenState();
}

class _LetterSoundsScreenState extends State<LetterSoundsScreen> {
  int _currentIndex = 0;
  final _scroll = ScrollController();
  final _gridKey = GlobalKey();
  AppProvider? _provider;
  List<LetterItem> get _letters => widget.vowelsOnly
      ? allLetters
          .where((l) => const ['A', 'E', 'I', 'O', 'U'].contains(l.letter))
          .toList()
      : allLetters;
  LetterItem get _current => _letters[_currentIndex];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().markLetterViewed(_current.letter);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    _provider?.phonicsAudio.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _select(int index) {
    _provider?.phonicsAudio.stop();
    setState(() => _currentIndex = index);
    context.read<AppProvider>().markLetterViewed(_current.letter);
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final status = provider.getLetterStatus(_current.letter);
    final example =
        lessonExamples.firstWhere((e) => e.letter == _current.letter);
    const palette = [
      Color(0xFF7544C4),
      Color(0xFF087F86),
      Color(0xFFBC405D),
      Color(0xFF256AB0),
      Color(0xFF986015)
    ];
    final accent = palette[_currentIndex % palette.length];
    return LearnerPage(
        title: widget.vowelsOnly ? 'Short Vowel Sounds' : 'Letter Sounds',
        scrollController: _scroll,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color.lerp(Colors.white, accent, .10)!
                  ]),
              borderRadius: BorderRadius.circular(32),
              border:
                  Border.all(color: accent.withValues(alpha: .25), width: 2),
              boxShadow: [
                BoxShadow(
                    color: accent.withValues(alpha: .10),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(30)),
                child: Text('Letter ${_currentIndex + 1} of ${_letters.length}',
                    style:
                        TextStyle(color: accent, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              Text('${_current.letter} ${_current.lowercase}',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: accent)),
              ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                      color: Colors.white,
                      child: LessonPicture(
                          key: ValueKey(example.letter), example: example))),
              const SizedBox(height: 8),
              Text(example.example,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: accent)),
              const SizedBox(height: 6),
              Text(_current.sound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: KidsUi.ink)),
              if (example.soundNote != null)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(example.soundNote!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, color: KidsUi.muted))),
              const SizedBox(height: 12),
              LearningStatusBadge(status: status),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Tap, listen & discover!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: KidsUi.ink)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: AudioButton(
                    compact: true,
                    key: ValueKey('letter-${_current.letter}'),
                    phrase: example.letterAudioKey,
                    color: const Color(0xFF7544C4),
                    icon: Icons.abc_rounded,
                    label: 'LETTER')),
            const SizedBox(width: 8),
            Expanded(
                child: AudioButton(
                    compact: true,
                    key: ValueKey('sound-${_current.letter}'),
                    phrase: example.soundAudioKey,
                    color: const Color(0xFF087F86),
                    icon: Icons.graphic_eq_rounded,
                    label: 'SOUND')),
            const SizedBox(width: 8),
            Expanded(
                child: AudioButton(
                    compact: true,
                    key: ValueKey('word-${_current.letter}'),
                    phrase: example.wordAudioKey,
                    color: const Color(0xFFBC405D),
                    icon: Icons.record_voice_over_rounded,
                    label: 'WORD')),
          ]),
          const SizedBox(height: 16),
          if (!widget.vowelsOnly)
            ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDB70),
                    foregroundColor: KidsUi.ink,
                    elevation: 2,
                    minimumSize: const Size(0, 60),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                onPressed: () async {
                  await provider.phonicsAudio.stop();
                  if (!context.mounted) return;
                  await LearnerNavigation.open(
                      context, LetterMasteryCheckScreen(letter: _current));
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Practice This Letter')),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: OutlinedButton(
                    style: _navigationStyle(const Color(0xFF7052CA)),
                    onPressed: () => _select(
                        (_currentIndex - 1 + _letters.length) %
                            _letters.length),
                    child: const Text('Previous'))),
            const SizedBox(width: 6),
            Expanded(
                child: OutlinedButton(
                    style: _navigationStyle(const Color(0xFF167769)),
                    onPressed: () => Scrollable.ensureVisible(
                        _gridKey.currentContext!,
                        duration: const Duration(milliseconds: 180)),
                    child:
                        Text(widget.vowelsOnly ? 'Vowel Grid' : 'A–Z Grid'))),
            const SizedBox(width: 6),
            Expanded(
                child: OutlinedButton(
                    style: _navigationStyle(const Color(0xFF256AB0)),
                    onPressed: () =>
                        _select((_currentIndex + 1) % _letters.length),
                    child: const Text('Next →'))),
          ]),
          const SizedBox(height: 24),
          Text('Choose a letter',
              key: _gridKey,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(
              builder: (_, box) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _letters.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (box.maxWidth / 80).floor().clamp(3, 6),
                      mainAxisExtent:
                          (MediaQuery.textScalerOf(context).scale(28) * 1.5 +
                                  40)
                              .clamp(88.0, double.infinity),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8),
                  itemBuilder: (_, i) {
                    final letter = _letters[i];
                    final s = provider.getLetterStatus(letter.letter);
                    return Semantics(
                        label: 'Choose letter ${letter.letter}, ${s.label}',
                        selected: i == _currentIndex,
                        child: OutlinedButton(
                            onPressed: () => _select(i),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                foregroundColor: i == _currentIndex
                                    ? Colors.white
                                    : palette[i % palette.length],
                                side: BorderSide(
                                    color: palette[i % palette.length]
                                        .withValues(
                                            alpha:
                                                i == _currentIndex ? 1 : .25),
                                    width: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                                backgroundColor: i == _currentIndex
                                    ? palette[i % palette.length]
                                    : Color.lerp(Colors.white,
                                        palette[i % palette.length], .10)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(letter.letter,
                                      style: const TextStyle(fontSize: 28)),
                                  Icon(s.icon,
                                      color: i == _currentIndex
                                          ? Colors.white
                                          : s == LearningStatus.mastered
                                              ? KidsUi.correct
                                              : KidsUi.ink,
                                      size: 20),
                                ])));
                  })),
        ]));
  }

  ButtonStyle _navigationStyle(Color color) => OutlinedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        side: BorderSide.none,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
