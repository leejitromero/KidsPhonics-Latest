import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/home_village.dart';
import '../data/updated_scene.dart';
import 'animated_screen_art.dart';
import 'button_sound.dart';
import 'student_wave.dart';
import 'scene_dialogue.dart';
import 'day_cycle_background.dart';
import 'home_character_visit.dart';
import 'home_progress_banner.dart';
import 'home_scene_layout.dart';
import 'kids_navigation_bar.dart';

class SchoolHomeScene extends StatelessWidget {
  const SchoolHomeScene(
      {super.key,
      required this.character,
      required this.name,
      required this.letter,
      required this.gameAccess,
      required this.busy,
      required this.visit,
      required this.onSelect,
      required this.onCharacter,
      required this.onSettings,
      required this.onContinue,
      required this.progressLabel,
      required this.level,
      required this.stars,
      required this.xp,
      this.selected,
      this.streak = 0,
      this.showStudent = true,
      this.introduction = false,
      this.showGuideArrow = false,
      this.speakingMascot,
      this.dialogueSpeaker,
      this.dialogue,
      this.dialogueControls,
      this.reserveNavigation = false,
      this.studentSpeech});
  static const lessonsButton = 'assets/images/home_buttons/button_lessons.png';
  static const gamesButton = 'assets/images/home_buttons/button_games.png';
  static const practiceButton =
      'assets/images/home_buttons/practice_letters_button.png';
  static const guideArrow =
      'assets/images/home_buttons/yellow_guide_arrow_v1.png';
  static const buttonAssets = [lessonsButton, practiceButton, gamesButton];
  final String character, name, progressLabel;
  final int level, stars, xp, streak;
  final String? letter;
  final bool gameAccess, busy, showStudent;
  final bool introduction, showGuideArrow;
  final Animation<double> visit;
  final HomeCategory? selected, speakingMascot, dialogueSpeaker;
  final Widget? dialogue, dialogueControls, studentSpeech;
  final bool reserveNavigation;
  final ValueChanged<HomeCategory> onSelect;
  final VoidCallback onCharacter, onSettings, onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final fullInsets = MediaQuery.paddingOf(context);
        final footer = !reserveNavigation
            ? 0.0
            : KidsNavigationGeometry.reservedHeight(
                Size(width, box.maxHeight), fullInsets);
        final height = math.max(1.0, box.maxHeight - footer);
        final insets =
            !reserveNavigation ? fullInsets : fullInsets.copyWith(bottom: 0);
        final side = math.max(12.0, math.max(insets.left, insets.right));
        final homeLayout = HomeSceneLayout.layout(Size(width, box.maxHeight),
            contentHeight: height, insets: insets);
        final originalStudent = HomeCharacterGeometry.idle(Size(width, height));
        final studentRect = introduction ? originalStudent : homeLayout.student;
        final banner = HomeBannerGeometry.layout(Size(width, height), insets,
            characterTop:
                introduction ? height * .27 + 28 : originalStudent.top,
            logoWidthFraction: introduction ? .76 : .62);
        final studentHeight = studentRect.height;
        final studentHead = Rect.fromLTRB(
            studentRect.left,
            studentRect.top + studentHeight * .04,
            studentRect.right,
            studentRect.bottom);
        Rect mascotRect(HomeCategory category) {
          if (!introduction) {
            return homeLayout.mascot(
                category == HomeCategory.games, Size(width, height));
          }
          final size =
              math.min(width * .29, height * (introduction ? .18 : .23));
          return Rect.fromLTWH(
              width * (category == HomeCategory.games ? .74 : .27) - size / 2,
              height * (introduction ? .73 : .724) - size,
              size,
              size);
        }

        Rect mascotHead(HomeCategory category) {
          final rect = mascotRect(category);
          return Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
        }

        Rect activityRect(Rect fractions) {
          final targetHeight = math.max(48.0, height * fractions.height);
          final top = math.min(height * fractions.top,
              height - insets.bottom - targetHeight - 4);
          return Rect.fromLTWH(fractions.left * width, top,
              fractions.width * width, targetHeight);
        }

        Widget activity(Rect rect, Key key, String label, VoidCallback? action,
            {bool locked = false, Widget? child}) {
          return Positioned.fromRect(
              rect: rect,
              child: _ReferenceActivityButton(
                  buttonKey: key,
                  label: label,
                  onPressed: action,
                  locked: locked,
                  child: child));
        }

        final guide = dialogueSpeaker ?? speakingMascot ?? HomeCategory.lessons;
        Rect guideArrowRect() {
          final games = guide == HomeCategory.games;
          final target = activityRect(games
              ? const Rect.fromLTWH(.526, .700, .430, .180)
              : const Rect.fromLTWH(.058, .700, .445, .180));
          // Aim at the painted book/controller, including on wide screens where
          // BoxFit.contain leaves extra space around the PNG's clickable area.
          final artwork = Alignment.center.inscribe(
              applyBoxFit(BoxFit.contain, const Size(1536, 1024), target.size)
                  .destination,
              target);
          final size = math.min(width * .18, height * .09);
          final tipX = games
              ? artwork.right - artwork.width * .08
              : artwork.left + artwork.width * .08;
          final left = (tipX - size * (games ? .12 : .88))
              .clamp(side, math.max(side, width - side - size));
          final top = (artwork.top + artwork.height * .45 - size * .88).clamp(
              banner.panel.bottom + 8,
              math.max(banner.panel.bottom + 8, height - insets.bottom - size));
          return Rect.fromLTWH(left.toDouble(), top.toDouble(), size, size);
        }

        final canPractice = !busy && showStudent;
        final practiceLabel = showStudent && letter == null
            ? 'Review letters'
            : 'Practice This Letter ${letter ?? 'A'}';
        final minSpeechTop = math.max(insets.top + 8, banner.panel.bottom + 8);
        return Stack(fit: StackFit.expand, children: [
          DayCycleBackground(
              key: const ValueKey('school-background'),
              category: 'home',
              child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(clipBehavior: Clip.hardEdge, children: [
                        if (showStudent)
                          AnimatedBuilder(
                              animation: visit,
                              builder: (_, __) {
                                final approaching = selected?.hasHouse ?? false;
                                final t = approaching ? visit.value : 0.0;
                                final walking =
                                    HomeCharacterVisitTiming.walking(t);
                                final left = selected == HomeCategory.lessons;
                                final stop = approaching
                                    ? HomeCharacterGeometry.approach(
                                        studentRect, mascotRect(selected!),
                                        left: left)
                                    : studentRect;
                                final rect = Rect.lerp(studentRect, stop,
                                    HomeCharacterVisitTiming.movement(t))!;
                                return Positioned.fromRect(
                                    rect: rect,
                                    child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned.fill(
                                              child: Opacity(
                                                  key: const ValueKey(
                                                      'home-student-visibility'),
                                                  opacity: 1,
                                                  child: Semantics(
                                                      button: true,
                                                      enabled: !busy,
                                                      label:
                                                          'Change student character',
                                                      child: GestureDetector(
                                                          key: const ValueKey(
                                                              'home-student'),
                                                          onTap: busy
                                                              ? null
                                                              : onCharacter,
                                                          child: walking
                                                              ? AnimatedScreenArt(
                                                                  key: ValueKey(
                                                                      'walk-$character-$left'),
                                                                  frames: studentWalkingFrames(
                                                                      character,
                                                                      left:
                                                                          left),
                                                                  maxDecodeWidth:
                                                                      512,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  frameDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              130))
                                                              : StudentWave(character: character, animate: !busy || t > 0 && !walking))))),
                                        ]));
                              }),
                        // The student always paints behind the guides.
                        for (final category in [
                          HomeCategory.lessons,
                          HomeCategory.games
                        ])
                          Positioned.fromRect(
                              rect: mascotRect(category),
                              child: Semantics(
                                  button: true,
                                  enabled: !busy &&
                                      (category != HomeCategory.games ||
                                          gameAccess),
                                  label: '${category.title} guide',
                                  child: GestureDetector(
                                      key: ValueKey(
                                          'home-${category.name}-mascot'),
                                      onTap: busy ||
                                              (category == HomeCategory.games &&
                                                  !gameAccess)
                                          ? null
                                          : () => onSelect(category),
                                      child: _HomeMascot(
                                          games: category == HomeCategory.games,
                                          speaking:
                                              speakingMascot == category)))),
                      ])))),
          Positioned.fill(
              child: HomeProgressBanner(
                  geometry: banner,
                  character: character,
                  name: name,
                  letter: letter,
                  level: level,
                  xp: xp,
                  stars: stars,
                  streak: streak,
                  showProfile: showStudent,
                  onProfile: busy ? null : onCharacter)),
          activity(
              introduction
                  ? activityRect(const Rect.fromLTWH(.058, .700, .445, .180))
                  : homeLayout.lessons,
              const ValueKey('home-lessons'),
              'Lessons',
              busy ? null : () => onSelect(HomeCategory.lessons),
              child: Image.asset(lessonsButton,
                  key: const ValueKey('home-lessons-art'),
                  fit: BoxFit.contain,
                  cacheWidth: 512,
                  gaplessPlayback: true,
                  excludeFromSemantics: true)),
          activity(
              introduction
                  ? activityRect(const Rect.fromLTWH(.526, .700, .430, .180))
                  : homeLayout.games,
              const ValueKey('home-games'),
              'Games',
              busy || !gameAccess ? null : () => onSelect(HomeCategory.games),
              locked: !gameAccess,
              child: Image.asset(gamesButton,
                  key: const ValueKey('home-games-art'),
                  fit: BoxFit.contain,
                  cacheWidth: 512,
                  gaplessPlayback: true,
                  excludeFromSemantics: true)),
          if (showStudent)
            activity(
                homeLayout.practice,
                const ValueKey('home-start-adventure'),
                practiceLabel,
                canPractice ? onContinue : null,
                child: Semantics(
                    key: const ValueKey('home-practice-label'),
                    label: practiceLabel,
                    child: _PracticeLetterButton(letter: letter))),
          if (introduction && showGuideArrow)
            Positioned.fromRect(
                rect: guideArrowRect(),
                child: IgnorePointer(
                    child: ExcludeSemantics(
                        child: Transform.flip(
                            key: const ValueKey('home-guide-arrow-direction'),
                            flipX: guide == HomeCategory.games,
                            child: Image.asset(guideArrow,
                                key: const ValueKey('home-guide-arrow'),
                                fit: BoxFit.contain,
                                cacheWidth: 256,
                                gaplessPlayback: true))))),
          if (dialogue != null)
            Positioned.fromRect(
                rect: introduction
                    ? SceneSpeechGeometry.introduction(
                        scene: Size(width, height),
                        speaker: mascotHead(guide),
                        art:
                            'dialogue_box_${guide == HomeCategory.games ? 1 : 2}.png',
                        minTop: minSpeechTop,
                        sideInset: side)
                    : SceneSpeechGeometry.aboveHead(
                        scene: Size(width, height),
                        speaker: mascotHead(guide),
                        art:
                            'dialogue_box_${guide == HomeCategory.games ? 1 : 2}.png',
                        flip: guide == HomeCategory.games,
                        preferredWidth: math.min(
                            width * (introduction ? .90 : .84),
                            introduction ? 600 : 460),
                        minTop: minSpeechTop,
                        sideInset: side),
                child: dialogue!),
          if (studentSpeech != null)
            Positioned.fromRect(
                rect: SceneSpeechGeometry.aboveHead(
                    scene: Size(width, height),
                    speaker: studentHead,
                    art: 'dialogue_box_${character == 'girl' ? 4 : 1}.png',
                    preferredWidth: math.min(width * .56, 320),
                    minTop: minSpeechTop,
                    sideInset: side),
                child: studentSpeech!),
          if (dialogueControls != null)
            Positioned(
                left: introduction ? side : width * .15,
                right: introduction ? side : width * .15,
                bottom: insets.bottom + 4,
                height: introduction
                    ? math.max(64, math.min(88, height * .09))
                    : math.max(48, height * .075),
                child: dialogueControls!),
        ]);
      });
}

class _ReferenceActivityButton extends StatelessWidget {
  const _ReferenceActivityButton(
      {required this.buttonKey,
      required this.label,
      required this.onPressed,
      this.locked = false,
      this.child});
  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final bool locked;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  key: buttonKey,
                  borderRadius: BorderRadius.circular(24),
                  splashColor: const Color(0x40FFF5CF),
                  highlightColor: const Color(0x18FFF5CF),
                  onTap: withButtonSound(onPressed),
                  child: Stack(fit: StackFit.expand, children: [
                    if (child != null) child!,
                    if (locked)
                      LayoutBuilder(
                          builder: (_, box) => Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox.square(
                                  dimension: (box.biggest.shortestSide * .48)
                                      .clamp(32.0, 60.0),
                                  child: Image.asset(
                                      'assets/images/games_locl.png',
                                      key:
                                          const ValueKey('home-games-lock-art'),
                                      fit: BoxFit.contain,
                                      cacheWidth: 192,
                                      excludeFromSemantics: true)))),
                  ])))));
}

/// All wording is live Flutter text on the supplied blank wooden panel.
class _PracticeLetterButton extends StatelessWidget {
  const _PracticeLetterButton({required this.letter});
  final String? letter;
  @override
  Widget build(BuildContext context) => Center(
      child: AspectRatio(
          aspectRatio: 2,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(SchoolHomeScene.practiceButton,
                key: const ValueKey('home-practice-art'),
                fit: BoxFit.contain,
                cacheWidth: 512,
                gaplessPlayback: true,
                excludeFromSemantics: true),
            LayoutBuilder(
                builder: (context, box) => Padding(
                    padding: EdgeInsets.fromLTRB(
                        box.maxWidth * .13,
                        box.maxHeight * .26,
                        box.maxWidth * .13,
                        box.maxHeight * .22),
                    child: Row(children: [
                      Expanded(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(letter == null ? 'Review' : 'Practice',
                                        style: const TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 24,
                                            color: Color(0xFF713216))),
                                    Text(
                                        letter == null
                                            ? 'Letters'
                                            : 'Letter $letter',
                                        key: const ValueKey(
                                            'home-practice-letter-text'),
                                        style: const TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 34,
                                            color: Color(0xFF592210))),
                                  ]))),
                      SizedBox(width: box.maxWidth * .04),
                      Container(
                          width: box.maxHeight * .38,
                          height: box.maxHeight * .38,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFCE60FF),
                                    Color(0xFF7200DF)
                                  ]),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x55602D14),
                                    offset: Offset(0, 2),
                                    blurRadius: 2)
                              ]),
                          child: Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: box.maxHeight * .3)),
                    ]))),
          ])));
}

class _HomeMascot extends StatefulWidget {
  const _HomeMascot({required this.games, required this.speaking});
  final bool games, speaking;
  @override
  State<_HomeMascot> createState() => _HomeMascotState();
}

class _HomeMascotState extends State<_HomeMascot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));
  bool _foreground = true, _motion = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _sync() {
    if (_foreground && _motion) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      _breath.stop();
      if (!_motion) _breath.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: AnimatedBuilder(
          animation: _breath,
          child: AnimatedScreenArt(
              frames: widget.speaking
                  ? mascotTalkingFrames(widget.games)
                  : [mascotTalkingFrames(widget.games).first],
              fit: BoxFit.contain,
              maxDecodeWidth: 384,
              frameDuration: const Duration(milliseconds: 240)),
          builder: (_, child) => Transform.translate(
              key: ValueKey(
                  'home-${widget.games ? 'games' : 'lessons'}-idle-motion'),
              offset: Offset(0, -3 * Curves.easeInOut.transform(_breath.value)),
              child: Transform.scale(
                  scale: 1 + .02 * _breath.value,
                  alignment: Alignment.bottomCenter,
                  child: child))));
}
