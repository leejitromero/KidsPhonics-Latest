import '../widgets/button_sound.dart';
import '../widgets/game_design.dart';
import '../widgets/activity_prompt.dart';
import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
// lib/screens/voice_recognition_screen.dart
import 'package:flutter/material.dart';
import '../services/background_music_service.dart';

import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

class VoiceRecognitionScreen extends StatefulWidget {
  final Difficulty difficulty;
  const VoiceRecognitionScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<VoiceRecognitionScreen> createState() => _VoiceRecognitionScreenState();
}

class _VoiceRecognitionScreenState extends State<VoiceRecognitionScreen>
    with GameSessionUi<VoiceRecognitionScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _requestingPermission = false;
  bool _evaluatedThisListen = false;
  bool _isAvailable = false;
  bool _isListening = false;
  int _listenGeneration = 0;
  bool _isInitialized = false;

  String _recognized = '';
  bool? _isCorrect;
  int _wordIndex = 0;

  late List<Map<String, String>> _words = _newSession();
  List<Map<String, String>> _newSession() => GameSessionOrder.next(
      'voice-${widget.difficulty.name}',
      voiceWords[widget.difficulty]!,
      (w) => w['word']!,
      count: GameSessionOrder.roundLength(widget.difficulty));

  Map<String, String> get _current => _words[_wordIndex];

  @override
  void initState() {
    super.initState();
    // Keep the whole speech activity quiet, including permission and retries.
    BackgroundMusicService.instance.hold(this);
  }

  Future<void> _initSpeech() async {
    try {
      // Step 1: Explicitly request microphone permission first
      final status = await Permission.microphone.request();
      if (!mounted) return;

      if (status.isDenied || status.isPermanentlyDenied) {
        // Permission refused — mark as unavailable and show message
        if (mounted) {
          setState(() {
            _isAvailable = false;
            _isInitialized = true;
          });
        }
        return;
      }

      // Step 2: Permission granted — initialize speech_to_text
      // Retry up to 2 times in case the first attempt fails on some devices
      for (int attempt = 0; attempt < 2; attempt++) {
        if (!mounted) return;
        _isAvailable = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (error) {
            if (mounted) setState(() => _isListening = false);
          },
        ).timeout(const Duration(seconds: 6), onTimeout: () => false);

        if (_isAvailable) break;
        // Short delay before retry
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {
      _isAvailable = false;
    }
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _listen() async {
    if (_requestingPermission || _isCorrect == true) return;
    if (!_isInitialized) {
      setState(() => _requestingPermission = true);
      await _initSpeech();
      if (!mounted) return;
      setState(() => _requestingPermission = false);
    }
    if (!_isAvailable) return;
    if (_isListening) {
      _listenGeneration++;
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _recognized = '';
      _evaluatedThisListen = false;
      _isCorrect = null;
      _isListening = true;
    });

    final generation = ++_listenGeneration;
    final p = context.read<AppProvider>();
    await p.phonicsAudio.stop();
    await p.audio.stop();
    if (!mounted || generation != _listenGeneration || !_isListening) return;
    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted && generation == _listenGeneration && !resultOpen) {
            setState(() => _recognized = result.recognizedWords);
            if (result.finalResult) {
              _evaluate(result.recognizedWords);
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 2),
          localeId: 'en_US',
        ),
      );
    } catch (_) {
      if (mounted && generation == _listenGeneration) {
        setState(() {
          _isListening = false;
          _isAvailable = false;
        });
      }
    }
  }

  void _evaluate(String recognized) async {
    if (_evaluatedThisListen || recognized.trim().isEmpty) {
      if (mounted) setState(() => _isListening = false);
      return;
    }
    _evaluatedThisListen = true;
    final target = _current['word']!.toLowerCase().trim();
    final heard = recognized.toLowerCase().trim();

    // Difficulty-based matching:
    // Easy   — loose: target appears anywhere in heard, or levenshtein ≤ 1
    // Medium — moderate: must contain target exactly, or levenshtein ≤ 1
    //          (removed target.contains(heard) so short heard can't match long words)
    // Hard   — strict: exact match or levenshtein ≤ 1 only (no substring tricks)
    bool isCorrect;
    final lev = _levenshtein(target, heard);
    switch (widget.difficulty) {
      case Difficulty.easy:
        isCorrect =
            heard.contains(target) || target.contains(heard) || lev <= 1;
        break;
      case Difficulty.medium:
        isCorrect = heard.contains(target) || lev <= 1;
        break;
      case Difficulty.hard:
        isCorrect = heard == target || lev <= 1;
        break;
    }

    setState(() {
      _isCorrect = isCorrect;
      _isListening = false;
    });

    final provider = context.read<AppProvider>();
    scoredAttempts++;
    if (isCorrect) correctAttempts++;
    if (isCorrect) {
      awardGameXp((10 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      provider.audio.playCorrect();
      // No AI voice — correct.mp3 tone is sufficient feedback
    } else {
      provider.audio.playWrong();
      // No AI voice — wrong.mp3 tone + result card shows "I heard: ..." feedback
    }
  }

  void _nextWord() {
    if (_isCorrect == null || _isListening || resultOpen) return;
    _listenGeneration++;
    if (_wordIndex < _words.length - 1) {
      setState(() {
        _wordIndex++;
        _recognized = '';
        _evaluatedThisListen = false;
        _isCorrect = null;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    awardGameXp(15);
    context.read<AppProvider>().audio.playWin();
    showGameResult(() => setState(() {
          _wordIndex = 0;
          _words = _newSession();
          _recognized = '';
          _isCorrect = null;
        }));
  }

  /// Simple Levenshtein distance for fuzzy matching (≤1 typo = accept)
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final matrix =
        List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return matrix[a.length][b.length];
  }

  @override
  void dispose() {
    _listenGeneration++;
    _speech.stop().then((_) => BackgroundMusicService.instance.release(this),
        onError: (Object _) => BackgroundMusicService.instance.release(this));

    super.dispose();
  }

  @override
  int get totalGameItems => _words.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
      answerResult: _isCorrect,
      title: 'Speak & Recognize',
      instructions: 'Listen, then say the word.',
      difficulty: widget.difficulty,
      current: _wordIndex + 1,
      total: _words.length,
      hasProgress: scoredAttempts > 0 && !resultOpen,
      onLeave: () => _speech.stop(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ActivityPrompt(
          accent: const Color(0xFF7052CA),
          picture: GameWordPicture(word: _current['word']!, size: 180),
          title: _current['word'] ?? 'Content unavailable.',
        ),
        const SizedBox(height: 12),
        AudioButton(phrase: _current['word'] ?? '', enabled: !_isListening),
        const SizedBox(height: 16),
        if (!_isInitialized) ...[
          const ForestPanel(
              child: Row(children: [
            Icon(Icons.mic_rounded, color: Color(0xFF8847DB), size: 32),
            SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      'KidsPhonics uses the microphone only for Speak & Recognize.'),
                  Text('Your voice is used to recognize the word you say.'),
                ])),
          ])),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: _isListening
                    ? const Color(0xFFB45731)
                    : const Color(0xFF7052CA),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 3),
            onPressed: withButtonSound(
                _requestingPermission || _isCorrect == true || resultOpen
                    ? null
                    : _listen),
            icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic),
            label: Text(_requestingPermission
                ? 'Getting Ready…'
                : _isListening
                    ? 'Listening…'
                    : 'Start Listening')),
        if (_isInitialized && !_isAvailable)
          const Text(
              'Microphone or speech recognition is unavailable. Ask a parent to check device settings.'),
        if (_recognized.isNotEmpty)
          Text('I heard: $_recognized', style: const TextStyle(fontSize: 22)),
        if (_isCorrect != null)
          Text(_isCorrect! ? 'Recognized' : 'Try Again',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        if (_isCorrect != null) GameFeedback(correct: _isCorrect!),
        if (_isCorrect != null)
          ElevatedButton(
              onPressed: withButtonSound(
                  _isListening || resultOpen ? null : _nextWord),
              child: const Text('Next Word')),
      ]));
}
