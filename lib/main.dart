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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Carefree — Kevin MacLeod'],
        await rootBundle.loadString('assets/audio/carefree-LICENSE.txt'));
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

    _navigationTimer = Timer(const Duration(seconds: 3), () {
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

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B0A4F),
              Color(0xFF0F0A2E),
              Color(0xFF071530),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
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
                          cacheWidth:
                              (180 * MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App name
                    Text(
                      'KidsPhonics',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 36,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.5),
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
                        color: Color(0xFF9B6FC4),
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Loading dots
                    _LoadingDots(),

                    const SizedBox(height: 16),
                    const Text(
                      'Loading your adventure...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A3FA0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final _colors = [
    const Color(0xFFFF6B9D),
    const Color(0xFFFFD700),
    const Color(0xFF00BFA5),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(
          reverse: true,
          period: Duration(milliseconds: 600 + i * 200),
        ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -8 * _controllers[i].value),
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: _colors[i],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _colors[i].withValues(alpha: 0.5),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
