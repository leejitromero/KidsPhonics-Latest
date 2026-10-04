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
import 'widgets/time_limit_overlay.dart';
import 'widgets/background_music_host.dart';
import 'widgets/adventure_background.dart';

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

  // Immersive mode - hide status/nav bar for full screen experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF08051A),
    systemNavigationBarIconBrightness: Brightness.light,
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
        builder: (_, child) => BackgroundMusicHost(
            child: TimeLimitOverlay(child: child ?? const SizedBox())),
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  Timer? _navigationTimer;
  Timer? _progressTimer;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.elasticOut,
    ));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5),
    ));

    _ctrl.forward();

    final started = Stopwatch()..start();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      final progress = (started.elapsedMilliseconds / 30).floor().clamp(0, 100);
      if (progress != _progress) setState(() => _progress = progress);
      if (progress == 100) {
        timer.cancel();
        started.stop();
        _navigationTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdventureBackground(
        child: SafeArea(
            child: Column(children: [
          Expanded(
              child: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Opacity(
                    opacity: MediaQuery.disableAnimationsOf(context)
                        ? 1
                        : _fadeAnim.value,
                    child: Transform.scale(
                      scale: MediaQuery.disableAnimationsOf(context)
                          ? 1
                          : _scaleAnim.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stars around mascot
                          const Text('✨', style: TextStyle(fontSize: 30)),
                          const SizedBox(height: 8),

                          // Mascot
                          ExcludeSemantics(
                            child: RepaintBoundary(
                              child: Image.asset(
                                MediaQuery.disableAnimationsOf(context)
                                    ? 'assets/images/app_mascot.png'
                                    : 'assets/images/app_mascot.gif',
                                width: 180,
                                height: 180,
                                fit: BoxFit.contain,
                                cacheWidth: (180 *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // App name
                          Text(
                            'KidsPhonics',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 36,
                              color: const Color(0xFF582AA5),
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          const Text(
                            'GRADE 1 · LEARN · PLAY · LEVEL UP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF155B85),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Loading your adventure...',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF582AA5)))),
                    const SizedBox(width: 12),
                    Text('$_progress%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF582AA5))),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: _progress / 100,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFE6DCFF),
                      color: const Color(0xFF00BFA5),
                      semanticsLabel: 'Loading your adventure',
                      semanticsValue: '$_progress',
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ])),
      ),
    );
  }
}
