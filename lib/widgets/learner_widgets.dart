import 'answer_choice_button.dart';
import 'game_design.dart';
import 'game_feedback_art.dart';
import 'game_leave_dialog.dart';
import 'cloud_page_route.dart';
import 'main_navigation_scope.dart';
import 'game_theme_background.dart';
import 'game_difficulty_dialog.dart';
import 'lesson_control_button.dart';
import 'button_sound.dart';
import 'activity_round_header.dart';
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
import 'game_mascot_coach.dart';
import 'completion_celebration.dart';
import '../controllers/game_narration_controller.dart';
import 'floating_choice.dart';
import 'quick_choice_art.dart';

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
      this.imageAsset,
      this.compactFloating = false,
      this.stackedHeader = false,
      this.accent = const Color(0xFF7052CA),
      this.actionLabel = 'Play'});
  final Color accent;
  final bool compactFloating;
  final bool stackedHeader;
  final LearningMascot? mascot;
  final String? imageAsset;
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
          color: Color.lerp(Colors.white, accent, .12)!
              .withValues(alpha: KidsUi.cardOpacity),
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: accent.withValues(alpha: .22),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KidsUi.radius),
              side: BorderSide(color: accent.withValues(alpha: .3), width: 2)),
          child: InkWell(
            onTap: withButtonSound(onPressed),
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
                              onPressed: withButtonSound(onPressed),
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
        margin: EdgeInsets.fromLTRB(6, 2, 6, imageAsset == null ? 18 : 10),
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
          color: Color.lerp(Colors.white, accent, .07)!
              .withValues(alpha: KidsUi.cardOpacity),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: accent.withValues(alpha: .2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: withButtonSound(onPressed),
            child: Padding(
              padding: EdgeInsets.all(imageAsset == null ? 12 : 10),
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
                          if (imageAsset != null)
                            SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(colors: [
                                      Colors.white,
                                      accent.withValues(alpha: .06),
                                    ]),
                                    borderRadius: BorderRadius.circular(16)),
                                child: Image.asset(imageAsset!,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                    cacheWidth: (80 *
                                            MediaQuery.devicePixelRatioOf(
                                                context))
                                        .ceil()),
                              ),
                            )
                          else
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
                                textAlign: imageAsset == null
                                    ? TextAlign.start
                                    : TextAlign.center,
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
                        textAlign: imageAsset == null
                            ? TextAlign.start
                            : TextAlign.center,
                        style: TextStyle(
                            fontSize: imageAsset == null ? 15 : 13,
                            height: 1.25,
                            color: KidsUi.muted)),
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
                        onPressed: withButtonSound(onPressed),
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
                          onPressed: withButtonSound(onPressed),
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
          child: GameDifficultyDialog(
              title: title,
              detail: detail,
              onSelected: (difficulty) {
                if (chosen) return;
                chosen = true;
                Navigator.pop(ctx, difficulty);
              })));
}

/// Keeps rapid taps from stacking routes. The guard lasts until return.
class LearnerNavigation {
  static final Set<Object> _opening = {};
  static Future<void> open(BuildContext context, Widget page,
      {bool replace = false,
      bool cloudTransition = false,
      Duration curtainDuration = const Duration(milliseconds: 800),
      bool fadeTransition = false,
      bool endParentSession = false}) async {
    final navigator = Navigator.of(context);
    final Object source = context;
    if (!_opening.add(source)) return;
    try {
      final navigation = MainNavigationScope.maybeOf(context);
      if (navigation != null) {
        page = MainNavigationScope(controller: navigation, child: page);
      }
      Route<void> route = MaterialPageRoute<void>(builder: (_) => page);
      if (fadeTransition) {
        final duration = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300);
        route = PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => page,
            transitionDuration: duration,
            reverseTransitionDuration: duration,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child));
      }
      if (cloudTransition) {
        final images = cloudTransitionImages(context);
        final reduced = MediaQuery.disableAnimationsOf(context);
        var ready = false;
        if (!reduced) {
          ready = await prepareCloudTransition(context, images);
        }
        if (!context.mounted ||
            !navigator.mounted ||
            ModalRoute.isCurrentOf(context) == false) {
          return;
        }
        if (MediaQuery.disableAnimationsOf(context)) {
          route = PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) => page,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero);
        } else if (ready) {
          route = CloudPageRoute<void>(
              page: page, frames: images, duration: curtainDuration);
        }
      }
      // A learner activity must count toward the daily limit, including when
      // a parent launches it. Clear authentication immediately before pushing
      // so rebuilding the Parent PIN screen cannot cancel cloud preparation.
      if (endParentSession) {
        context.read<AppProvider>().parentAuth.endSession();
      }
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

/// Compact floating controls on the page background.
class LearnerHeader extends StatelessWidget {
  const LearnerHeader(
      {super.key,
      required this.title,
      this.onBack,
      this.onHelp,
      this.helpEnabled = true,
      this.showBack = true,
      this.trailing});
  final String title;
  final VoidCallback? onBack, onHelp;
  final bool helpEnabled, showBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: Row(children: [
          if (showBack)
            IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: withButtonSound(
                    onBack ?? () => Navigator.maybePop(context)),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xDD263858),
                    foregroundColor: Colors.white)),
          const SizedBox(width: 6),
          Expanded(
              child: Center(
                  child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xF0263858), Color(0xE048427D)]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFB7ADD9))),
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ))),
          const SizedBox(width: 6),
          if (onHelp != null)
            IconButton.filledTonal(
                tooltip: 'How to Play',
                onPressed: withButtonSound(helpEnabled ? onHelp : null),
                icon: const Icon(Icons.help_outline_rounded))
          else if (showBack && trailing == null)
            const SizedBox(width: 48),
          if (trailing != null) trailing!,
        ]),
      );
}

class LearnerPage extends StatelessWidget {
  const LearnerPage(
      {super.key,
      required this.title,
      required this.child,
      this.gameTheme = false,
      this.onBack,
      this.onHelp,
      this.helpEnabled = true,
      this.showBack = true,
      this.fitViewport = false,
      this.showHeader = true,
      this.answerResult,
      this.bottom,
      this.scrollController});
  final bool gameTheme;
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final bool helpEnabled;
  final bool showBack;
  final bool fitViewport;
  final bool showHeader;
  final bool? answerResult;
  final Widget? bottom;
  final ScrollController? scrollController;
  Widget _background({required Widget child, bool? answerResult}) => gameTheme
      ? GameThemeBackground(
          answerResult: answerResult, showBanner: showHeader, child: child)
      : AdventureBackground(answerResult: answerResult, child: child);
  @override
  Widget build(BuildContext context) => Theme(
      data: KidsUi.theme,
      child: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFFEEE9FF),
          body: _background(
              answerResult: answerResult,
              child: SafeArea(
                  child: Column(children: [
                if (showHeader)
                  LearnerHeader(
                      title: title,
                      showBack: showBack,
                      onBack: onBack ?? () => Navigator.maybePop(ctx),
                      onHelp: onHelp,
                      helpEnabled: helpEnabled),
                Expanded(
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: fitViewport
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                    child: child)
                                : SingleChildScrollView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 4, 12, 12),
                                    child: child)))),
              ]))),
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
  const GameChoiceGrid(
      {super.key, required this.children, this.compact = false, this.columns});
  final List<GameAnswerButton> children;
  final bool compact;
  final int? columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final detailed = children
            .any((choice) => choice.visual != null || choice.label.length > 6);
        final minimum = (compact
                ? 80.0
                : detailed
                    ? 112.0
                    : 80.0) *
            scale;
        final columns = this.columns ??
            ((box.maxWidth + 12) / (minimum + 12)).floor().clamp(1, 3);
        final diameter = ((box.maxWidth - 12 * (columns - 1)) / columns).clamp(
            0.0,
            compact
                ? 100.0 * scale
                : detailed
                    ? 160.0 * scale
                    : 112.0 * scale);
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
                  child: _FramedChoiceStyle(variant: i, child: children[i])),
          ],
        );
      });
}

class _FramedChoiceStyle extends InheritedWidget {
  const _FramedChoiceStyle({required this.variant, required super.child});
  final int variant;
  @override
  bool updateShouldNotify(_FramedChoiceStyle oldWidget) =>
      variant != oldWidget.variant;
}

class GameAnswerButton extends StatelessWidget {
  const GameAnswerButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.result,
      this.visual,
      this.selected = false,
      this.compact = false,
      this.showLabel = true,
      this.floating = true,
      this.leaves = true,
      this.labelStyle,
      this.accent,
      this.colorIndex,
      this.buttonKey});
  final int? colorIndex;
  final Color? accent;
  final String label;
  final VoidCallback? onPressed;
  final bool? result;
  final Widget? visual;
  final bool selected;
  final bool compact;
  final bool showLabel;
  final bool floating;
  final bool leaves;
  final TextStyle? labelStyle;
  final Key? buttonKey;
  @override
  Widget build(BuildContext context) => FloatingChoice(
        enabled: floating && onPressed != null && result == null,
        seed: label.codeUnits.fold(0, (a, b) => a + b),
        child: _button(context),
      );

  Widget _button(BuildContext context) {
    if (colorIndex != null) {
      return Semantics(
          selected: selected,
          label: result == null
              ? label
              : '$label, ${result! ? 'Correct' : 'Try again'}',
          child: ElevatedButton(
              key: buttonKey,
              onPressed: withButtonSound(onPressed),
              style: quickColorButtonStyle(
                  index: colorIndex!,
                  radius: 22,
                  selected: selected,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(48, 48)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label,
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900)))),
                    if (result != null)
                      Icon(
                          result! ? Icons.star_rounded : Icons.favorite_rounded,
                          size: 18,
                          color: const Color(0xFFFFE478)),
                  ])));
    }
    final grid =
        context.dependOnInheritedWidgetOfExactType<_FramedChoiceStyle>();
    final button = Semantics(
      selected: selected,
      label: result == null
          ? label
          : '$label, ${result! ? 'Correct' : 'Nice try'}',
      child: AnswerChoiceButton(
        buttonKey: buttonKey,
        onPressed: onPressed,
        selected: selected,
        result: result,
        leaves: leaves,
        variant: grid?.variant ?? label.codeUnits.fold<int>(0, (a, b) => a + b),
        child: LayoutBuilder(
            builder: (_, box) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (visual != null)
                      Expanded(
                          flex: 2,
                          child: FittedBox(
                              child: SizedBox(
                                  width: 64, height: 64, child: visual))),
                    if (showLabel)
                      Flexible(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: compact
                                              ? 20
                                              : visual != null ||
                                                      label.length > 3
                                                  ? 18
                                                  : 28,
                                          fontWeight: FontWeight.w900)
                                      .merge(labelStyle)))),
                  ],
                )),
      ),
    );
    if (compact || grid != null) return button;
    return Padding(
        padding: const EdgeInsets.only(bottom: KidsUi.gap),
        child: SizedBox(height: 100, child: button));
  }
}

class GameFeedback extends StatelessWidget {
  const GameFeedback({super.key, required this.correct, this.detail});
  final bool correct;
  final String? detail;
  @override
  Widget build(BuildContext context) => correct
      ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GameCorrectFrame(detail: detail))
      : Semantics(
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
      this.lessonArt = false,
      this.controlBuilder,
      this.statusBuilder,
      this.semanticLabel,
      this.onBeforePlay,
      this.onPlayed,
      this.enabled = true});
  final VoidCallback? onPlayed;
  final VoidCallback? onBeforePlay;

  /// Allows a game to share one playback operation across an illustration and
  /// its labelled control, including the same busy and unavailable states.
  final Widget Function(BuildContext, VoidCallback?, bool, String)?
      controlBuilder;

  /// Optional compact presentation for the same playback status message.
  final Widget Function(String)? statusBuilder;
  final String? semanticLabel;
  final String phrase, label;
  final Color? color;
  final IconData icon;
  final bool enabled;
  final bool compact;
  final bool lessonArt;
  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> with WidgetsBindingObserver {
  bool _playing = false;
  bool _heard = false;
  bool _foreground = true;
  int _attempt = 0;
  AppProvider? _provider;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  bool get _environmentAvailable =>
      _foreground &&
      (ModalRoute.isCurrentOf(context) ?? true) &&
      TickerMode.valuesOf(context).enabled &&
      (_provider?.voiceEnabled ?? false) &&
      !(_provider?.timeLimitReached ?? true) &&
      (!GameDesign.active(context) || (_provider?.gameAccess ?? false));

  void _cancelPlayback({String? phrase}) {
    if (!_playing) return;
    _attempt++;
    _playing = false;
    _message = null;
    // A selected letter or another speaker may already own the shared channel.
    if (_provider?.phonicsAudio.currentPhrase == (phrase ?? widget.phrase)) {
      unawaited(_provider?.phonicsAudio.stop());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.watch<AppProvider>();
    if (!_environmentAvailable) {
      _cancelPlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    setState(() {
      _foreground = foreground;
      if (!foreground) _cancelPlayback();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelPlayback();
    super.dispose();
  }

  @override
  void didUpdateWidget(AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrase != widget.phrase) {
      _cancelPlayback(phrase: oldWidget.phrase);
      _attempt++;
      _playing = false;
      _heard = false;
      _message = null;
    }
    if (!widget.enabled) _cancelPlayback();
  }

  String? _message;
  Future<void> _play() async {
    if (_playing || !widget.enabled || !_environmentAvailable) {
      return;
    }
    widget.onBeforePlay?.call();
    final attempt = ++_attempt;
    final p = context.read<AppProvider>();
    setState(() {
      _playing = true;
      _message = null;
    });
    await p.audio.stop();
    if (!mounted || attempt != _attempt) return;
    if (!_environmentAvailable) {
      setState(() => _cancelPlayback());
      return;
    }
    final success = await p.phonicsAudio.playInstruction(widget.phrase);
    if (!mounted || attempt != _attempt) return;
    setState(() {
      _playing = false;
      _heard = success;
      if (!success) _message = 'Audio unavailable. Please try again.';
    });
    if (success) widget.onPlayed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final voiceEnabled = context.watch<AppProvider>().voiceEnabled;
    final enabled = widget.enabled && voiceEnabled && _environmentAvailable;
    final available = PhonicsAudioService.assetForPhrase(widget.phrase) != null;
    final label = _playing
        ? 'Listening…'
        : _heard
            ? 'Listen Again'
            : widget.label;
    final icon = _playing
        ? Icons.graphic_eq_rounded
        : _heard
            ? Icons.replay_rounded
            : widget.icon;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
          liveRegion: true,
          label: widget.semanticLabel ?? '$label: ${widget.phrase}',
          child: widget.controlBuilder != null
              ? widget.controlBuilder!(
                  context,
                  !enabled || _playing || !available ? null : _play,
                  _playing,
                  label)
              : GameDesign.active(context) &&
                      !widget.compact &&
                      !widget.lessonArt
                  ? ForestAudioButton(
                      label: label,
                      icon: icon,
                      onPressed:
                          !enabled || _playing || !available ? null : _play)
                  : widget.lessonArt
                      ? SizedBox(
                          width: 150,
                          child: LessonControlButton(
                              label: label,
                              icon: icon,
                              art: LessonButtonArt.sound,
                              onPressed: !enabled || _playing || !available
                                  ? null
                                  : _play))
                      : widget.compact
                          ? SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      widget.color ?? const Color(0xFF087F86),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      _playing ? const Color(0xFFFFDF88) : null,
                                  disabledForegroundColor:
                                      _playing ? const Color(0xFF49315D) : null,
                                  side: BorderSide.none,
                                  minimumSize: const Size(0, 64),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: withButtonSound(
                                    !enabled || _playing || !available
                                        ? null
                                        : _play),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 22),
                                      const SizedBox(height: 4),
                                      Text(label,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900)),
                                    ]),
                              ),
                            )
                          : OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    widget.color ?? const Color(0xFF087F86),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _playing ? const Color(0xFFFFDF88) : null,
                                disabledForegroundColor:
                                    _playing ? const Color(0xFF49315D) : null,
                                side: BorderSide.none,
                                minimumSize: const Size(96, 48),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 3,
                                shadowColor:
                                    (widget.color ?? const Color(0xFF087F86))
                                        .withValues(alpha: .35),
                              ),
                              onPressed: withButtonSound(
                                  !enabled || _playing || !available
                                      ? null
                                      : _play),
                              icon: Icon(icon),
                              label: Text(label))),
      if (!voiceEnabled)
        widget.statusBuilder?.call('Audio is turned off.') ??
            const Text('Audio is turned off.', style: TextStyle(fontSize: 16)),
      if (!available || _message != null)
        widget.statusBuilder?.call(_message ?? 'Audio unavailable.') ??
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
      this.onReview,
      this.reviewCount = 0,
      this.accuracyNote = 'Accuracy includes retries.',
      this.totalItems,
      this.correctItems,
      this.backLabel = 'Back to Games'});
  final int correct, attempts, earnedXp, earnedStars;
  final int? totalItems, correctItems;
  final VoidCallback onAgain, onBack;
  final VoidCallback? onReview;
  final int reviewCount;
  final String accuracyNote;
  final String backLabel;
  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> {
  int get _total => widget.totalItems ?? widget.attempts;
  int get _score => widget.correctItems ?? widget.correct;
  bool _used = false;
  void _act(VoidCallback action) {
    if (_used) return;
    setState(() => _used = true);
    action();
  }

  @override
  Widget build(BuildContext context) => CompletionCelebration(
      child: Theme(
          data: KidsUi.theme,
          child: PopScope(
            canPop: false,
            child: AlertDialog(
              constraints: const BoxConstraints(maxWidth: 360),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              clipBehavior: Clip.antiAlias,
              backgroundColor: const Color(0xFFF8F3FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFD7C8F3), width: 1.5)),
              title: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF7052CA), Color(0xFF398EAA)])),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFFFFDF88), size: 22),
                          SizedBox(width: 8),
                          Flexible(
                              child: Text('Round complete!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900))),
                        ]),
                    const SizedBox(height: 8),
                    Image.asset(GameMascotCoach.mascotAsset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        cacheWidth: 192,
                        excludeFromSemantics: true),
                    const SizedBox(height: 4),
                    Text(
                        widget.attempts > 0 &&
                                widget.correct / widget.attempts >= .8
                            ? 'Amazing work!'
                            : 'Every try helps you grow!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ])),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Score: $_score / $_total',
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: _total == 0 ? 0 : (_score / _total).clamp(0.0, 1.0),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFF398EAA),
                    backgroundColor: const Color(0xFFE3DAF3)),
                const SizedBox(height: 6),
                Text(
                    'Activity Accuracy: ${widget.attempts == 0 ? 'No attempts yet' : '${(widget.correct / widget.attempts * 100).round()}%'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                    'Attempts: ${widget.attempts} • Wrong attempts: ${widget.attempts - widget.correct}\n${widget.accuracyNote}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: KidsUi.muted)),
                const SizedBox(height: 10),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFEEC6), Color(0xFFFFE2AC)]),
                        border: Border.all(color: const Color(0xFFF0D18A)),
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: Color(0xFF99600E), size: 28),
                          const SizedBox(width: 10),
                          Flexible(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                Text('XP Earned: +${widget.earnedXp}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                                Text('Stars Earned: +${widget.earnedStars}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                              ])),
                        ])),
                const SizedBox(height: 8),
                const Text('Play again or take a little break.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: KidsUi.muted)),
              ])),
              actions: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onReview != null &&
                          widget.reviewCount > 0) ...[
                        SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                                key: const ValueKey('quiz-review-mistakes'),
                                onPressed: withButtonSound(_used
                                    ? null
                                    : () => _act(widget.onReview!)),
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(
                                    'Review Mistakes (${widget.reviewCount})'))),
                        const SizedBox(height: 6),
                      ],
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800),
                                  backgroundColor: const Color(0xFF7052CA),
                                  foregroundColor: Colors.white),
                              onPressed: withButtonSound(
                                  _used ? null : () => _act(widget.onAgain)),
                              child: const Text('Play Again'))),
                      const SizedBox(height: 6),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                              onPressed: withButtonSound(
                                  _used ? null : () => _act(widget.onBack)),
                              child: Text(widget.backLabel == 'Back to Games'
                                  ? 'Choose Next Game'
                                  : widget.backLabel))),
                    ])
              ],
            ),
          )));
}

class GameLives extends StatelessWidget {
  const GameLives({super.key, required this.lives});
  final int lives;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$lives of 3 lives remaining',
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Icon(i < lives ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: i < lives
                      ? const Color(0xFFB63D50)
                      : const Color(0xFF746B80)),
          ]),
        ),
      );
}

class GameScaffold extends StatefulWidget {
  const GameScaffold(
      {super.key,
      required this.title,
      required this.instructions,
      required this.child,
      required this.hasProgress,
      this.instructionPanel,
      this.roundHeader,
      this.tutorial,
      this.canOpenTutorial,
      this.answerResult,
      this.current,
      this.total,
      this.progressLabel = 'Question',
      this.difficulty,
      this.mascot = LearningMascot.boopli,
      this.compactGuide = false,
      this.fitViewport = false,
      this.showHeader = false,
      this.narration,
      this.narrationEnabled = true,
      this.onLeave});
  final GameNarrationController? narration;
  final bool narrationEnabled;
  final bool compactGuide;
  final bool fitViewport;
  final bool showHeader;
  final LearningMascot mascot;
  final String title, instructions, progressLabel;
  final Widget? instructionPanel;
  final Widget? roundHeader;
  final GameTutorial? tutorial;
  final bool Function()? canOpenTutorial;
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
                barrierColor: const Color(0xB8253040),
                builder: (ctx) => Theme(
                    data: KidsUi.theme, child: const GameLeaveDialog())) ==
            true;
    if (!mounted) return;
    if (leave) {
      widget.onLeave?.call();
      final p = context.read<AppProvider>();
      await p.phonicsAudio.stop();
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
  Widget build(BuildContext context) =>
      widget.showHeader ? _body(context) : GameDesign(child: _body(context));

  GameTutorial? get _tutorial =>
      widget.tutorial ?? GameTutorial.forTitle(widget.title);
  Widget _body(BuildContext context) => _tutorial == null
      ? _page(context, null)
      : GameTutorialHost(
          tutorial: _tutorial!,
          canOpen: widget.canOpenTutorial,
          builder: _page);

  Widget _page(BuildContext context, VoidCallback? onHelp) => PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: LearnerPage(
            gameTheme: true,
            showHeader: widget.showHeader,
            onHelp: onHelp,
            helpEnabled: widget.canOpenTutorial?.call() ?? true,
            answerResult: widget.answerResult,
            title: widget.title,
            onBack: _leave,
            fitViewport: widget.fitViewport,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  if (!widget.showHeader)
                    ForestIconButton(
                        tooltip: 'Back',
                        onPressed: _leave,
                        icon: Icons.arrow_back_rounded),
                  if (!widget.showHeader) const SizedBox(width: 8),
                  Expanded(
                      child: widget.roundHeader ??
                          ActivityRoundHeader(
                            difficulty: widget.difficulty,
                            current: widget.current,
                            total: widget.total,
                            label: widget.progressLabel,
                          )),
                  if (!widget.showHeader && onHelp != null)
                    Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ForestIconButton(
                            tooltip: 'How to Play',
                            purple: true,
                            onPressed: (widget.canOpenTutorial?.call() ?? true)
                                ? onHelp
                                : null,
                            icon: Icons.help_outline_rounded)),
                ]),
                const SizedBox(height: 8),
                widget.instructionPanel ??
                    (widget.narration != null
                        ? GameMascotCoach(
                            title: widget.title,
                            instructions: widget.instructions,
                            controller: widget.narration!,
                            enabled: widget.narrationEnabled)
                        : widget.showHeader
                            ? Text(widget.instructions,
                                style: const TextStyle(fontSize: 14))
                            : GameInstruction(text: widget.instructions)),
                const SizedBox(height: 12),
                if (widget.fitViewport)
                  Expanded(child: widget.child)
                else
                  widget.child,
              ],
            )),
      );
}

/// Tracks per-play rewards and answers without changing reward formulas.
mixin GameSessionUi<T extends StatefulWidget> on State<T> {
  AppProvider? _audioProvider;

  /// Keep task feedback visible until the learner can interact with the game.
  bool get canAdvanceGameFeedback {
    if (!mounted || resultOpen || ModalRoute.isCurrentOf(context) == false) {
      return false;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return false;
    }
    final provider = _audioProvider;
    return provider != null &&
        provider.gameAccess &&
        !provider.timeLimitReached;
  }

  late final gameNarration = GameNarrationController(play: (phrase) async {
    final provider = _audioProvider;
    if (provider == null || !provider.voiceEnabled) return false;
    return provider.phonicsAudio.playInstruction(phrase);
  }, stop: () async {
    await _audioProvider?.phonicsAudio.stop();
  });

  Future<void> playGameCorrect() async {
    gameNarration.cancel();
    await context.read<AppProvider>().audio.playCorrect();
  }

  Future<void> playGameWrong() {
    gameNarration.cancel();
    return context.read<AppProvider>().audio.playWrong();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    gameNarration.dispose();
    unawaited(_audioProvider?.phonicsAudio.stop());
    unawaited(_audioProvider?.audio.stop());
    super.dispose();
  }

  int earnedXp = 0, earnedStars = 0, scoredAttempts = 0, correctAttempts = 0;
  bool resultOpen = false;
  int get totalGameItems;
  int get correctGameItems => correctAttempts;

  Future<void> _saved = Future.value();

  /// Completion lets callers await the actual persisted reward writes.
  Future<void> get rewardsSaved => _saved;
  void awardGameXp(int value) {
    earnedXp += value;
    final p = context.read<AppProvider>();
    _saved = _saved.then((_) => p.addXP(value));
  }

  void awardGameStar() {
    earnedStars++;
    final p = context.read<AppProvider>();
    _saved = _saved.then((_) => p.addStar());
  }

  void recordGameAnswer({required bool correct}) {
    if (resultOpen) return;
    scoredAttempts++;
    if (correct) correctAttempts++;
    context.read<AppProvider>().recordDailyAnswer(correct: correct);
  }

  void clearGameLedger() {
    gameNarration.resetRound();
    earnedXp = 0;
    earnedStars = 0;
    scoredAttempts = 0;
    correctAttempts = 0;
    resultOpen = false;
  }

  Future<void> showGameResult(VoidCallback restart,
      {String backLabel = 'Back to Games',
      VoidCallback? onReview,
      int reviewCount = 0,
      String accuracyNote = 'Accuracy includes retries.'}) async {
    final navigator = Navigator.of(context);
    await _saved;
    if (!mounted) return;
    await context.read<AppProvider>().phonicsAudio.stop();
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameResultDialog(
            totalItems: totalGameItems,
            correctItems: correctGameItems,
            correct: correctAttempts,
            attempts: scoredAttempts,
            earnedXp: earnedXp,
            earnedStars: earnedStars,
            backLabel: backLabel,
            reviewCount: reviewCount,
            accuracyNote: accuracyNote,
            onReview: onReview == null
                ? null
                : () {
                    navigator.pop();
                    onReview();
                  },
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
