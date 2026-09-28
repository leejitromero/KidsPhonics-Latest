import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/kids_ui.dart';

enum GameTutorial { flappyLetters, wordBuilder, memoryFlip }

class GameTutorialHost extends StatefulWidget {
  const GameTutorialHost(
      {super.key, required this.tutorial, required this.builder, this.onOpen});
  final GameTutorial tutorial;
  final Widget Function(BuildContext, VoidCallback) builder;
  final VoidCallback? onOpen;
  @override
  State<GameTutorialHost> createState() => _GameTutorialHostState();
}

class _GameTutorialHostState extends State<GameTutorialHost> {
  bool _open = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstVisit());
  }

  String get _key => 'gameTutorialV1.${widget.tutorial.name}';
  Future<void> _firstVisit() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted ||
        prefs.getBool(_key) == true ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    await _show();
  }

  Future<void> _show() async {
    if (_open) return;
    _open = true;
    widget.onOpen?.call();
    final dismissed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TutorialDialog(tutorial: widget.tutorial));
    if (dismissed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    }
    _open = false;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _show);
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog({required this.tutorial});
  final GameTutorial tutorial;
  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _step = 0;
  List<(IconData, String, String)> get _steps => switch (widget.tutorial) {
        GameTutorial.flappyLetters => [
            (
              Icons.touch_app_rounded,
              'Tap to fly!',
              'Tap the sky to lift your little friend. Keep tapping to stay up.'
            ),
            (
              Icons.compare_arrows_rounded,
              'Fly through the gap',
              'Go between the pipes. Watch out for the edges!'
            ),
            (
              Icons.abc_rounded,
              'Meet A to Z',
              'Pass 26 letter pipes. Listen to each letter with Voice Assistance on.'
            ),
          ],
        GameTutorial.wordBuilder => [
            (
              Icons.volume_up_rounded,
              'Hear the word',
              'Look at the picture. Tap Hear Word to listen.'
            ),
            (
              Icons.touch_app_rounded,
              'Fill the missing letters',
              'Tap a letter to fill the next blank, from left to right.'
            ),
            (
              Icons.auto_awesome_rounded,
              'Build and try again',
              'Green means correct! If a letter is wrong, choose another one.'
            ),
          ],
        GameTutorial.memoryFlip => [
            (
              Icons.touch_app_rounded,
              'Turn over two cards',
              'Tap a card, then tap another to see both pictures.'
            ),
            (
              Icons.copy_rounded,
              'Find the same picture',
              'Matching pictures stay face up. Remember where the others hide!'
            ),
            (
              Icons.stars_rounded,
              'Find every pair',
              'Keep matching until all the pictures are revealed.'
            ),
          ],
      };
  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = _steps[_step];
    return Theme(
        data: KidsUi.theme,
        child: AlertDialog(
          key: const ValueKey('game-tutorial'),
          backgroundColor: const Color(0xFFF7F1FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('How to Play', textAlign: TextAlign.center),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Step ${_step + 1} of ${_steps.length}',
                style: const TextStyle(fontSize: 14, color: KidsUi.muted)),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
                key: ValueKey(_step),
                tween: Tween(begin: .8, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE3D8FC), shape: BoxShape.circle),
                    child:
                        Icon(icon, size: 64, color: const Color(0xFF7052CA)))),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.4)),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Skip')),
            if (_step > 0)
              TextButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back')),
            FilledButton(
                onPressed: () {
                  if (_step == _steps.length - 1) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() => _step++);
                  }
                },
                child:
                    Text(_step == _steps.length - 1 ? "Let's Play" : 'Next')),
          ],
        ));
  }
}
