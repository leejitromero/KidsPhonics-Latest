import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/time_limit_overlay.dart';
import 'widgets/app_display_preferences.dart';
import 'widgets/background_music_host.dart';
import 'widgets/loading_screen_art.dart';
import 'widgets/school_home_scene.dart';
import 'widgets/day_cycle_background.dart';
import 'widgets/home_progress_banner.dart';
import 'widgets/kids_navigation_bar.dart';
import 'widgets/student_wave.dart';
import 'widgets/cloud_page_route.dart';
import 'data/home_narration.dart';
import 'data/updated_scene.dart';
import 'data/character_selection_art.dart';
import 'services/phonics_audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['nunito', 'fredoka']) {
      yield LicenseEntryWithLineBreaks([family],
          await rootBundle.loadString('assets/fonts/$family-OFL.txt'));
    }
  });

  // Lock to portrait mode (mobile app for kids)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Artwork reaches the screen edges; interactive controls keep safe insets.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  ));

  runApp(const KidsPhonicsApp());
}

class KidsPhonicsApp extends StatelessWidget {
  const KidsPhonicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'KidsPhonics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (_, child) => AppDisplayPreferences(
            child: BackgroundMusicHost(
                child: TimeLimitOverlay(child: child ?? const SizedBox()))),
        home: const SplashScreen(),
      ),
    );
  }
}

// ── Splash / Loading screen ───────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;
  Timer? _progressTimer;
  int _progress = 0;
  bool _scenePrepared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scenePrepared) return;
    _scenePrepared = true;
    final frameWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 512);
    final art = <String, int>{
      for (final asset in DayCycleBackground.framesFor('home')) asset: 942,
      for (final asset in KidsNavigationArt.assets)
        if (asset != KidsNavigationArt.base) asset: 384,
      for (final asset in HomeBannerArt.assets)
        asset: asset == HomeBannerArt.logo
            ? 1350
            : asset == HomeBannerArt.panel
                ? 1235
                : 156,
      for (final character in ['boy', 'girl'])
        HomeBannerArt.portrait(character): 256,
      for (final asset in CharacterSelectionArt.assets)
        asset: asset == CharacterSelectionArt.banner ? 1024 : 600,
      for (final asset in SchoolHomeScene.buttonAssets) asset: 512,
      SchoolHomeScene.guideArrow: 256,
      '$sceneAssets/kids.png': 1086,
      '$sceneAssets/lessin_signage.png': 512,
      '$sceneAssets/games_signage.png': 512,
      for (var i = 1; i <= 4; i++) '$sceneAssets/dialogue_box_$i.png': 942,
      for (final asset in [
        ...mascotTalkingFrames(false),
        ...mascotTalkingFrames(true)
      ])
        asset: frameWidth,
      for (final character in ['boy', 'girl']) ...{
        StudentWave.assetFor(character): 2172,
        '$sceneAssets/${character}_1.png': 512,
        for (final asset in [
          ...studentWalkingFrames(character, left: true),
          ...studentWalkingFrames(character, left: false)
        ])
          asset: frameWidth,
      },
      for (final asset in cloudTransitionAssets) asset: 640,
    };
    for (final entry in art.entries) {
      unawaited(precacheImage(
          ResizeImage(AssetImage(entry.key), width: entry.value), context,
          onError: (_, __) {}));
    }
    for (final key in homeNarrationAssets.keys.where((key) =>
        key == 'title' ||
        key.contains('intro-') ||
        key.startsWith('profile-') ||
        key.startsWith('boy-') ||
        key.startsWith('girl-'))) {
      unawaited(PhonicsAudioService.prepareInstruction('home-$key'));
    }
  }

  @override
  void initState() {
    super.initState();
    final started = Stopwatch()..start();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      final progress = (started.elapsedMilliseconds / 30).floor().clamp(0, 100);
      if (progress != _progress) setState(() => _progress = progress);
      if (progress == 100) {
        timer.cancel();
        started.stop();
        _navigationTimer = Timer(const Duration(milliseconds: 250), () async {
          final provider = context.read<AppProvider>();
          await provider.ready;
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => provider.welcomeCompleted
                    ? const HomeScreen(announceTitle: true)
                    : const WelcomeScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LoadingScreenArt(progress: _progress),
      );
}
