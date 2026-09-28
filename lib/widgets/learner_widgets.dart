import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/difficulty.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../services/phonics_audio_service.dart';
import '../theme/kids_ui.dart';
import 'learning_progress_widgets.dart';
import 'adventure_background.dart';
import 'mascot_guide.dart';
import 'game_tutorial.dart';

class LearnerActivityCard extends StatelessWidget {
  const LearnerActivityCard(
      {super.key,
      required this.title,
      required this.description,
      required this.icon,
      required this.onPressed,
      this.detail,
      this.status,
      this.progress,
      this.mascot,
      this.compactFloating = false,
      this.stackedHeader = false,
      this.accent = const Color(0xFF7052CA),
      this.actionLabel = 'Play'});
  final Color accent;
  final bool compactFloating;
  final bool stackedHeader;
  final LearningMascot? mascot;
  final String actionLabel;
  final String title, description;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? detail, status;
  final double? progress;
  @override
  Widget build(BuildContext context) => compactFloating
      ? _compactCard(context)
      : Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Color.lerp(Colors.white, accent, .12),
          elevation: 4,
          shadowColor: accent.withValues(alpha: .22),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KidsUi.radius),
              side: BorderSide(color: accent.withValues(alpha: .3), width: 2)),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(KidsUi.radius),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        if (mascot != null)
                          MascotPortrait(mascot: mascot!, size: 80)
                        else
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .8),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Icon(icon,
                                  color:
                                      onPressed == null ? KidsUi.muted : accent,
                                  size: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)))
                      ]),
                      const SizedBox(height: 8),
                      Text(description),
                      if (detail != null) ...[
                        const SizedBox(height: 12),
                        Text(detail!)
                      ],
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                            value: progress!.clamp(0, 1),
                            minHeight: 8,
                            color: accent,
                            borderRadius: BorderRadius.circular(8))
                      ],
                      if (status != null)
                        Text(status!,
                            style: const TextStyle(
                                fontSize: 18, color: KidsUi.muted)),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                              onPressed: onPressed,
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: accent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18)),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(actionLabel))),
                    ])),
          ));

  Widget _compactCard(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(6, 2, 6, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: .16),
                blurRadius: 20,
                spreadRadius: -3,
                offset: const Offset(0, 9)),
            BoxShadow(
                color: Colors.white.withValues(alpha: .8),
                blurRadius: 4,
                offset: const Offset(-2, -2)),
          ],
        ),
        child: Material(
          color: Color.lerp(Colors.white, accent, .07),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: accent.withValues(alpha: .2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flex(
                        direction:
                            stackedHeader ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: stackedHeader
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13)),
                            child: Icon(icon, size: 24, color: accent),
                          ),
                          if (stackedHeader) ...[
                            const SizedBox(height: 8),
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: KidsUi.ink)),
                          ] else ...[
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(title,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: KidsUi.ink))),
                          ],
                        ]),
                    const SizedBox(height: 6),
                    Text(description,
                        style:
                            const TextStyle(fontSize: 15, color: KidsUi.muted)),
                    if (detail != null) ...[
                      const SizedBox(height: 8),
                      Text(detail!,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: accent)),
                    ],
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                          value: progress!.clamp(0, 1),
                          minHeight: 5,
                          color: accent,
                          backgroundColor: accent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8)),
                    ],
                    const SizedBox(height: 6),
                    if (stackedHeader)
                      TextButton(
                        onPressed: onPressed,
                        style: TextButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        child: Text(actionLabel),
                      )
                    else
                      Row(children: [
                        if (status != null)
                          Expanded(
                              child: Text(status!,
                                  style: const TextStyle(
                                      fontSize: 14, color: KidsUi.muted)))
                        else
                          const Spacer(),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onPressed,
                          style: TextButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(actionLabel),
                        ),
                      ]),
                  ]),
            ),
          ),
        ),
      );
}

Future<Difficulty?> chooseGameDifficulty(
    BuildContext context, String title, String Function(Difficulty) detail,
    {LearningMascot mascot = LearningMascot.boopli, bool lessonStyle = false}) {
  var chosen = false;
  return showDialog<Difficulty>(
      context: context,
      builder: (ctx) => Theme(
          data: KidsUi.theme,
          child: AlertDialog(
              backgroundColor: lessonStyle ? const Color(0xFFF7F3FF) : null,
              contentPadding:
                  lessonStyle ? const EdgeInsets.fromLTRB(16, 8, 16, 0) : null,
              title: Text(title),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    MascotGuide(
                        mascot: mascot,
                        message: 'Choose your difficulty',
                        compact: lessonStyle),
                    const SizedBox(height: 16),
                    for (final d in Difficulty.values)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OutlinedButton(
                              style: lessonStyle
                                  ? OutlinedButton.styleFrom(
                                      backgroundColor: [
                                        const Color(0xFF167769),
                                        const Color(0xFF7052CA),
                                        const Color(0xFFB45731)
                                      ][d.index],
                                      foregroundColor: Colors.white,
                                      side: BorderSide.none,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    )
                                  : null,
                              onPressed: () {
                                if (chosen) return;
                                chosen = true;
                                Navigator.pop(ctx, d);
                              },
                              child: Padding(
                                  padding: EdgeInsets.all(lessonStyle ? 4 : 12),
                                  child: Column(children: [
                                    Text(d.label,
                                        style: TextStyle(
                                            fontSize: lessonStyle ? 18 : 22,
                                            fontWeight: FontWeight.bold)),
                                    Text(detail(d),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: lessonStyle ? 14 : 18)),
                                  ])))),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'))
              ])));
}

/// Keeps rapid taps from stacking routes. The guard lasts until return.
class LearnerNavigation {
  static final Set<Object> _opening = {};
  static Future<void> open(BuildContext context, Widget page,
      {bool replace = false}) async {
    final navigator = Navigator.of(context);
    final Object source = context;
    if (!_opening.add(source)) return;
    try {
      final route = MaterialPageRoute<void>(builder: (_) => page);
      if (replace) {
        await navigator.pushReplacement(route);
      } else {
        await navigator.push(route);
      }
    } finally {
      _opening.remove(source);
    }
  }
}

class LearnerPage extends StatelessWidget {
  const LearnerPage(
      {super.key,
      required this.title,
      required this.child,
      this.onBack,
      this.onHelp,
      this.showBack = true,
      this.fitViewport = false,
      this.answerResult,
      this.bottom,
      this.scrollController});
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final bool showBack;
  final bool fitViewport;
  final bool? answerResult;
  final Widget? bottom;
  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context) => Theme(
      data: KidsUi.theme,
      child: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFFEEE9FF),
          appBar: AppBar(
              actions: [
                if (onHelp != null)
                  IconButton(
                      tooltip: 'How to Play',
                      onPressed: onHelp,
                      icon: const Icon(Icons.help_outline_rounded))
              ],
              backgroundColor: const Color(0xFFEEE9FF),
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              foregroundColor: KidsUi.ink,
              title: Text(title,
                  style: const TextStyle(
                      fontSize: KidsUi.titleSize, fontWeight: FontWeight.bold)),
              automaticallyImplyLeading: false,
              leading: !showBack
                  ? null
                  : IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: onBack ?? () => Navigator.maybePop(ctx))),
          body: AdventureBackground(
              answerResult: answerResult,
              child: SafeArea(
                  top: false,
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: fitViewport
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: child)
                              : SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(KidsUi.padding),
                                  child: child))))),
          bottomNavigationBar:
              bottom == null ? null : SafeArea(top: false, child: bottom!),
        ),
      ));
}

class GameProgressHeader extends StatelessWidget {
  const GameProgressHeader(
      {super.key,
      required this.current,
      required this.total,
      this.label = 'Question'});
  final int current, total;
  final String label;
  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const Text('Content unavailable.');
    final value = current.clamp(0, total);
    return Semantics(
        label: '$label $value of $total',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('$label $value of $total',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: value / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 16),
        ]));
  }
}

class GameChoiceGrid extends StatelessWidget {
  const GameChoiceGrid({super.key, required this.children});
  final List<GameAnswerButton> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final detailed = children
            .any((choice) => choice.visual != null || choice.label.length > 6);
        final minimum = (detailed ? 112.0 : 80.0) * scale;
        final columns =
            ((box.maxWidth + 12) / (minimum + 12)).floor().clamp(1, 3);
        final diameter = ((box.maxWidth - 12 * (columns - 1)) / columns)
            .clamp(0.0, detailed ? 160.0 * scale : 112.0 * scale);
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                  width: diameter,
                  height:
                      children[i].visual != null ? diameter * 1.08 : diameter,
                  child: _CircularChoiceStyle(
                      color: const [
                        Color(0xFF7052CA),
                        Color(0xFF167769),
                        Color(0xFFB45731),
                      ][i % 3],
                      child: children[i])),
          ],
        );
      });
}

class _CircularChoiceStyle extends InheritedWidget {
  const _CircularChoiceStyle({required this.color, required super.child});
  final Color color;
  @override
  bool updateShouldNotify(_CircularChoiceStyle oldWidget) =>
      color != oldWidget.color;
}

class GameAnswerButton extends StatelessWidget {
  const GameAnswerButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.result,
      this.visual,
      this.selected = false,
      this.accent,
      this.buttonKey});
  final Color? accent;
  final String label;
  final VoidCallback? onPressed;
  final bool? result;
  final Widget? visual;
  final bool selected;
  final Key? buttonKey;
  @override
  Widget build(BuildContext context) {
    final circle =
        context.dependOnInheritedWidgetOfExactType<_CircularChoiceStyle>();
    final color = result == true
        ? KidsUi.correct
        : result == false
            ? KidsUi.incorrect
            : circle?.color ?? accent ?? KidsUi.ink;
    if (circle != null) {
      return Semantics(
        selected: selected,
        label: result == null
            ? label
            : '$label, ${result! ? 'Correct' : 'Nice try'}',
        child: ElevatedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.all(12),
            backgroundColor: color,
            disabledBackgroundColor: color,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visual != null ? 24 : 80),
                side: BorderSide(
                    color: selected || result != null
                        ? Colors.white
                        : color.withValues(alpha: .3),
                    width: 3)),
            elevation: 4,
            shadowColor: color.withValues(alpha: .4),
          ),
          child: LayoutBuilder(
              builder: (_, box) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (visual != null)
                        SizedBox(
                            width: box.maxWidth * .88,
                            height: box.maxHeight * .68,
                            child: FittedBox(
                                child: SizedBox(
                                    width: 64, height: 64, child: visual!))),
                      Flexible(
                          child: Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: visual != null || label.length > 3
                                      ? 16
                                      : 26,
                                  fontWeight: FontWeight.w800))),
                      if (result != null)
                        Icon(
                            result!
                                ? Icons.check_circle
                                : Icons.refresh_rounded,
                            size: 16),
                    ]),
                  )),
        ),
      );
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: KidsUi.gap),
        child: Semantics(
          selected: selected,
          label: result == null
              ? label
              : '$label, ${result! ? 'Correct' : 'Nice try'}',
          child: ElevatedButton(
            key: buttonKey,
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                padding: const EdgeInsets.all(16),
                foregroundColor: color,
                disabledForegroundColor: color,
                backgroundColor: result == null
                    ? (accent == null
                        ? Colors.white
                        : Color.lerp(Colors.white, accent, .12))
                    : color.withValues(alpha: .10),
                disabledBackgroundColor: result == null
                    ? (accent == null
                        ? Colors.white
                        : Color.lerp(Colors.white, accent, .12))
                    : color.withValues(alpha: .10),
                side: BorderSide(color: color.withValues(alpha: .35)),
                shape: accent == null
                    ? null
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                elevation: accent == null ? 0 : 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (visual != null) ...[
                SizedBox(width: 64, child: visual!),
                const SizedBox(height: 8)
              ],
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: KidsUi.answerSize,
                            fontWeight: FontWeight.bold))),
                if (result != null) ...[
                  const SizedBox(width: 8),
                  Icon(result! ? Icons.check_circle : Icons.cancel_outlined)
                ],
              ]),
            ]),
          ),
        ));
  }
}

class GameFeedback extends StatelessWidget {
  const GameFeedback({super.key, required this.correct, this.detail});
  final bool correct;
  final String? detail;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(correct ? Icons.check_circle : Icons.favorite_outline,
              color: correct ? KidsUi.correct : KidsUi.incorrect),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  '${correct ? 'Correct!' : 'Nice try! Keep practicing.'}${detail == null ? '' : '\n$detail'}',
                  style: TextStyle(
                      fontSize: 20,
                      color: correct ? KidsUi.correct : KidsUi.incorrect))),
        ]),
      ));
}

/// Future images need only provide an asset path; no game logic changes.
class GameImageCard extends StatelessWidget {
  const GameImageCard({super.key, this.emoji, this.assetPath, this.label});
  final String? emoji, assetPath, label;
  Widget _fallback() => Center(
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(emoji ?? 'Content unavailable.',
              style: TextStyle(
                  fontSize: emoji == null ? 18 : 56, color: KidsUi.ink),
              textAlign: TextAlign.center)));
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFEEE8FA),
                  borderRadius: BorderRadius.circular(KidsUi.radius)),
              child: assetPath == null
                  ? _fallback()
                  : Image.asset(assetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _fallback()),
            ),
          )));
}

class LearningStatusBadge extends StatelessWidget {
  const LearningStatusBadge({super.key, required this.status});
  final LearningStatus status;
  @override
  Widget build(BuildContext context) => Chip(
      avatar: Icon(status.icon,
          color:
              status == LearningStatus.mastered ? KidsUi.correct : KidsUi.ink),
      label: Text(status.label, style: const TextStyle(fontSize: 18)),
      backgroundColor: status.color.withValues(alpha: .15));
}

class AudioButton extends StatefulWidget {
  const AudioButton(
      {super.key,
      required this.phrase,
      this.label = 'Hear Word',
      this.color,
      this.icon = Icons.volume_up,
      this.compact = false,
      this.enabled = true});
  final String phrase, label;
  final Color? color;
  final IconData icon;
  final bool enabled;
  final bool compact;
  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  bool _playing = false;
  int _attempt = 0;
  AppProvider? _provider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    if (_playing) unawaited(_provider?.phonicsAudio.stop());
    super.dispose();
  }

  @override
  void didUpdateWidget(AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrase != widget.phrase) {
      _attempt++;
      if (_playing) unawaited(_provider?.phonicsAudio.stop());
      _playing = false;
      _message = null;
    }
  }

  String? _message;
  Future<void> _play() async {
    if (_playing) return;
    final attempt = ++_attempt;
    final p = context.read<AppProvider>();
    setState(() {
      _playing = true;
      _message = null;
    });
    await p.voiceFeedback.stop();
    await p.audio.stop();
    if (!mounted || attempt != _attempt) return;
    final success = await p.phonicsAudio.playInstruction(widget.phrase);
    if (!mounted || attempt != _attempt) return;
    setState(() {
      _playing = false;
      if (!success) _message = 'Audio unavailable. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && context.watch<AppProvider>().voiceEnabled;
    final available = PhonicsAudioService.assetForPhrase(widget.phrase) != null;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
          label: '${widget.label}: ${widget.phrase}',
          child: widget.compact
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: widget.color ?? const Color(0xFF087F86),
                      foregroundColor: Colors.white,
                      side: BorderSide.none,
                      minimumSize: const Size(0, 64),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed:
                        !enabled || _playing || !available ? null : _play,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_playing ? Icons.graphic_eq : widget.icon, size: 22),
                      const SizedBox(height: 4),
                      Text(widget.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: widget.color ?? const Color(0xFF087F86),
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                    minimumSize: const Size(96, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 3,
                    shadowColor: (widget.color ?? const Color(0xFF087F86))
                        .withValues(alpha: .35),
                  ),
                  onPressed: !enabled || _playing || !available ? null : _play,
                  icon: Icon(_playing ? Icons.graphic_eq : widget.icon),
                  label: Text(_playing ? 'Playing…' : widget.label))),
      if (!enabled)
        const Text('Audio is turned off.', style: TextStyle(fontSize: 16)),
      if (!available || _message != null)
        Text(_message ?? 'Audio unavailable.',
            style: const TextStyle(fontSize: 16)),
    ]);
  }
}

class GameResultDialog extends StatefulWidget {
  const GameResultDialog(
      {super.key,
      required this.correct,
      required this.attempts,
      required this.earnedXp,
      required this.earnedStars,
      required this.onAgain,
      required this.onBack,
      this.backLabel = 'Back to Games'});
  final int correct, attempts, earnedXp, earnedStars;
  final VoidCallback onAgain, onBack;
  final String backLabel;
  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> {
  bool _used = false;
  void _act(VoidCallback action) {
    if (_used) return;
    setState(() => _used = true);
    action();
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: KidsUi.theme,
      child: PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFFF8F3FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
              widget.attempts > 0 && widget.correct / widget.attempts >= .8
                  ? 'Amazing work!'
                  : 'Every try helps you grow!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: KidsUi.ink)),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const MascotPortrait(mascot: LearningMascot.zoplet, size: 100),
            const SizedBox(height: 12),
            const Text('Round complete!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Score: ${widget.correct} / ${widget.attempts}',
                style: const TextStyle(fontSize: 24)),
            Text(
                'Activity Accuracy: ${widget.attempts == 0 ? 'No attempts yet' : '${(widget.correct / widget.attempts * 100).round()}%'}'),
            const Text('Scored attempts, including retries.',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 14),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEEC6),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFF99600E), size: 36),
                  Text('XP Earned: +${widget.earnedXp}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('Stars Earned: +${widget.earnedStars}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ])),
            const SizedBox(height: 12),
            const Text(
                'Ready for another little adventure? You can also take a break.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7052CA),
                        foregroundColor: Colors.white),
                    onPressed: _used ? null : () => _act(widget.onAgain),
                    child: const Text('Play Again'))),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: _used ? null : () => _act(widget.onBack),
                    child: Text(widget.backLabel == 'Back to Games'
                        ? 'Choose Next Game'
                        : widget.backLabel))),
          ])),
        ),
      ));
}

class GameScaffold extends StatefulWidget {
  const GameScaffold(
      {super.key,
      required this.title,
      required this.instructions,
      required this.child,
      required this.hasProgress,
      this.instructionPanel,
      this.tutorial,
      this.answerResult,
      this.current,
      this.total,
      this.progressLabel = 'Question',
      this.difficulty,
      this.mascot = LearningMascot.boopli,
      this.compactGuide = false,
      this.fitViewport = false,
      this.onLeave});
  final bool compactGuide;
  final bool fitViewport;
  final LearningMascot mascot;
  final String title, instructions, progressLabel;
  final Widget? instructionPanel;
  final GameTutorial? tutorial;
  final bool? answerResult;
  final Widget child;
  final bool hasProgress;
  final int? current, total;
  final Difficulty? difficulty;
  final VoidCallback? onLeave;
  @override
  State<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends State<GameScaffold> {
  bool _leaving = false, _allowPop = false;
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final leave = !widget.hasProgress ||
        await showDialog<bool>(
                context: context,
                builder: (ctx) => Theme(
                    data: KidsUi.theme,
                    child: AlertDialog(
                        title: const Text('Leave this game?'),
                        content: const Text('Your current round will end.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Leave')),
                        ]))) ==
            true;
    if (!mounted) return;
    if (leave) {
      widget.onLeave?.call();
      final p = context.read<AppProvider>();
      await p.phonicsAudio.stop();
      await p.voiceFeedback.stop();
      if (!mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.tutorial == null
      ? _page(context, null)
      : GameTutorialHost(tutorial: widget.tutorial!, builder: _page);

  Widget _page(BuildContext context, VoidCallback? onHelp) => PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: LearnerPage(
            onHelp: onHelp,
            answerResult: widget.answerResult,
            title: widget.title,
            onBack: _leave,
            fitViewport: widget.fitViewport,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  if (widget.difficulty != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: switch (widget.difficulty!) {
                          Difficulty.easy => const Color(0xFF167769),
                          Difficulty.medium => const Color(0xFF7052CA),
                          Difficulty.hard => const Color(0xFFB45731),
                        },
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(widget.difficulty!.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(width: 12),
                  if (widget.current != null && widget.total != null)
                    Expanded(
                        child: Text(
                            '${widget.current} / ${widget.total} ${widget.progressLabel.toLowerCase()}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 8),
                widget.instructionPanel ??
                    Text(widget.instructions,
                        style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                if (widget.fitViewport)
                  Expanded(child: widget.child)
                else
                  widget.child,
              ],
            )),
      );
}

/// A per-play display ledger mirrors existing reward/answer writes unchanged.
/// No progress, streak, time-limit or reward formula is calculated here.
mixin GameSessionUi<T extends StatefulWidget> on State<T> {
  AppProvider? _audioProvider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    unawaited(_audioProvider?.phonicsAudio.stop());
    unawaited(_audioProvider?.audio.stop());
    super.dispose();
  }

  int earnedXp = 0, earnedStars = 0, scoredAttempts = 0, correctAttempts = 0;
  bool resultOpen = false;
  Future<void> _saved = Future.value();

  /// Completion lets callers await the actual persisted reward writes.
  Future<void> get rewardsSaved => _saved;
  void awardGameXp(int value) {
    earnedXp += value;
    final p = context.read<AppProvider>();
    _saved = _saved.then((_) => p.addXP(value, announce: false));
  }

  void awardGameStar() {
    earnedStars++;
    final p = context.read<AppProvider>();
    _saved = _saved.then((_) => p.addStar());
  }

  void recordGameAnswer({required bool correct}) {
    scoredAttempts++;
    if (correct) correctAttempts++;
    context.read<AppProvider>().recordDailyAnswer(correct: correct);
  }

  void clearGameLedger() {
    earnedXp = 0;
    earnedStars = 0;
    scoredAttempts = 0;
    correctAttempts = 0;
    resultOpen = false;
  }

  Future<void> showGameResult(VoidCallback restart,
      {String backLabel = 'Back to Games'}) async {
    final navigator = Navigator.of(context);
    await _saved;
    if (!mounted) return;
    await context.read<AppProvider>().phonicsAudio.stop();
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameResultDialog(
            correct: correctAttempts,
            attempts: scoredAttempts,
            earnedXp: earnedXp,
            earnedStars: earnedStars,
            backLabel: backLabel,
            onAgain: () {
              navigator.pop();
              clearGameLedger();
              restart();
            },
            onBack: () {
              navigator.pop();
              navigator.pop();
            }));
  }
}
