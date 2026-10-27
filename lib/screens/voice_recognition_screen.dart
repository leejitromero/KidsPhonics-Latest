import '../widgets/button_sound.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/game_mascot_coach.dart';
import '../widgets/game_design.dart';
import '../widgets/speech_practice_design.dart';
import '../data/game_session_order.dart';
// lib/screens/voice_recognition_screen.dart
import 'package:flutter/material.dart';
import '../services/background_music_service.dart';

import 'package:provider/provider.dart';
import 'dart:async';
import '../services/speech_practice_service.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

class VoiceRecognitionScreen extends StatefulWidget {
  final Difficulty difficulty;
  final SpeechPracticeService? speech;
  const VoiceRecognitionScreen(
      {super.key, this.difficulty = Difficulty.easy, this.speech});

  @override
  State<VoiceRecognitionScreen> createState() => _VoiceRecognitionScreenState();
}

class _VoiceRecognitionScreenState extends State<VoiceRecognitionScreen>
    with GameSessionUi<VoiceRecognitionScreen>, WidgetsBindingObserver {
  late final SpeechPracticeService _speech;
  AppProvider? _accessProvider;
  bool _routeActive = true;
  bool _foreground = true;
  String? _locale;
  String? _speechMessage;
  bool _settingsRequired = false;
  bool _requestingPermission = false;
  bool _evaluatedThisListen = false;
  bool _isAvailable = false;
  bool _isListening = false;
  int _listenGeneration = 0;
  bool _isInitialized = false;
  bool _isSpelling = false;
  int _spellingIndex = -1;
  bool _readingWord = false;
  int _spellGeneration = 0;
  Timer? _spellingTimer;
  Completer<void>? _spellingHold;

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
    _speech = widget.speech ?? DeviceSpeechPracticeService();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    // Keep the whole speech activity quiet, including permission and retries.
    BackgroundMusicService.instance.hold(this);
  }

  bool get _canListen =>
      mounted &&
      _foreground &&
      _routeActive &&
      !resultOpen &&
      (_accessProvider?.gameAccess ?? false) &&
      !(_accessProvider?.timeLimitReached ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeActive = ModalRoute.isCurrentOf(context) ?? true;
    if (_accessProvider == null) {
      _accessProvider = context.read<AppProvider>();
      _accessProvider!.addListener(_accessChanged);
    }
    if (!_routeActive &&
        (_isListening || _requestingPermission || _isSpelling)) {
      _interrupt();
    }
  }

  void _accessChanged() {
    if (!_canListen && (_isListening || _requestingPermission || _isSpelling)) {
      _interrupt();
    } else if (_isSpelling && !(_accessProvider?.voiceEnabled ?? false)) {
      _cancelSpelling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // A system permission prompt may make the app inactive. Allow its result,
    // but never start listening until foreground and route checks pass again.
    if (!_foreground && (_isListening || _isSpelling)) _interrupt();
  }

  void _interrupt() {
    _cancelSpelling(notify: false);
    _listenGeneration++;
    _isListening = false;
    _requestingPermission = false;
    unawaited(_stopSpeech());
    if (mounted) setState(() {});
  }

  void _finishSpellingHold() {
    _spellingTimer?.cancel();
    final hold = _spellingHold;
    _spellingHold = null;
    if (hold != null && !hold.isCompleted) hold.complete();
  }

  Future<void> _holdSpellingLetter() {
    _finishSpellingHold();
    final hold = Completer<void>();
    _spellingHold = hold;
    _spellingTimer = Timer(const Duration(milliseconds: 400), () {
      if (!hold.isCompleted) hold.complete();
      if (_spellingHold == hold) _spellingHold = null;
    });
    return hold.future;
  }

  void _cancelSpelling({bool notify = true}) {
    _spellGeneration++;
    _finishSpellingHold();
    gameNarration.cancel();
    _isSpelling = false;
    _spellingIndex = -1;
    _readingWord = false;
    if (notify && mounted) setState(() {});
  }

  Future<void> _hearWord() async {
    final provider = _accessProvider;
    if (provider == null ||
        !provider.voiceEnabled ||
        !_canListen ||
        _isSpelling ||
        _isListening ||
        _requestingPermission) {
      return;
    }
    final request = ++_spellGeneration;
    final word = _current['word']!;
    setState(() => _isSpelling = true);
    bool current() =>
        mounted &&
        request == _spellGeneration &&
        _canListen &&
        provider.voiceEnabled;
    try {
      await provider.audio.stop();
      await provider.phonicsAudio.stop();
      if (!current()) return;
      gameNarration.updateEnvironment(enabled: true, active: true);
      for (var index = 0; index < word.length; index++) {
        final letter = word[index].toUpperCase();
        if (!RegExp(r'^[A-Z]$').hasMatch(letter)) continue;
        if (!current()) return;
        setState(() => _spellingIndex = index);
        final sound = gameNarration.letterName(letter);
        final audioGeneration = gameNarration.generation;
        await Future.wait([sound, _holdSpellingLetter()]);
        if (!current() || audioGeneration != gameNarration.generation) return;
      }
      if (!current()) return;
      setState(() {
        _spellingIndex = -1;
        _readingWord = true;
      });
      await Future.wait([gameNarration.word(word), _holdSpellingLetter()]);
    } finally {
      if (mounted && request == _spellGeneration) {
        _finishSpellingHold();
        setState(() {
          _isSpelling = false;
          _spellingIndex = -1;
          _readingWord = false;
        });
      }
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await _speech.stop();
    } catch (_) {/* Device already unavailable. */}
  }

  Future<void> _initSpeech(int request) async {
    try {
      final permission = await _speech.requestPermission();
      if (!mounted || request != _listenGeneration) return;
      _settingsRequired =
          permission == SpeechMicrophonePermission.settingsRequired;
      if (permission != SpeechMicrophonePermission.granted) {
        _isAvailable = false;
        _speechMessage = _settingsRequired
            ? 'Ask a parent to enable microphone access in device settings.'
            : 'Microphone access was declined. You can try again.';
        setState(() => _isInitialized = true);
        return;
      }
      for (var attempt = 0; attempt < 2; attempt++) {
        if (!mounted || request != _listenGeneration) return;
        _isAvailable = await _speech.initialize(
          onStatus: (status) {
            if (mounted && (status == 'done' || status == 'notListening')) {
              final noSpeech = _isListening &&
                  !_evaluatedThisListen &&
                  _recognized.trim().isEmpty;
              setState(() {
                _isListening = false;
                if (noSpeech) _speechMessage = 'No speech detected. Try again.';
              });
            }
          },
          onError: (error) {
            if (!mounted || !_canListen) return;
            if (error == 'error_no_match' || error == 'error_speech_timeout') {
              if (!_evaluatedThisListen) {
                _listenGeneration++;
                setState(() {
                  _isListening = false;
                  _requestingPermission = false;
                  _speechMessage = 'No speech detected. Try again.';
                });
              }
              return;
            }
            _listenGeneration++;
            setState(() {
              _isListening = false;
              _isAvailable = false;
              _requestingPermission = false;
              _speechMessage =
                  'Could not hear the word. Try again, or ask a parent to check speech settings.';
            });
          },
        ).timeout(const Duration(seconds: 6), onTimeout: () => false);
        if (!mounted || request != _listenGeneration) return;
        if (_isAvailable) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (_isAvailable) {
        _locale = englishSpeechLocale(await _speech.locales());
        if (!mounted || request != _listenGeneration) return;
        _isAvailable = _locale != null;
      }
      _speechMessage = _isAvailable
          ? null
          : 'English speech recognition is unavailable. Ask a parent to check the recognition service and installed English language support, then retry.';
    } catch (_) {
      if (!mounted || request != _listenGeneration) return;
      _isAvailable = false;
      _speechMessage = 'Speech recognition could not start. Please try again.';
    }
    if (mounted && request == _listenGeneration) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _listen() async {
    if (_requestingPermission ||
        _isSpelling ||
        _isCorrect == true ||
        !_canListen) {
      return;
    }
    if (!_isInitialized || !_isAvailable) {
      gameNarration.updateEnvironment(
          enabled: context.read<AppProvider>().voiceEnabled, active: false);
      setState(() => _requestingPermission = true);
      final request = ++_listenGeneration;
      await _initSpeech(request);
      if (!mounted || request != _listenGeneration) return;
      setState(() => _requestingPermission = false);
    }
    if (!_isAvailable || !_canListen) return;
    if (_isListening) {
      _interrupt();
      return;
    }
    setState(() {
      _recognized = '';
      _evaluatedThisListen = false;
      _isCorrect = null;
      _isListening = true;
      _speechMessage = null;
    });
    final generation = ++_listenGeneration;
    final p = context.read<AppProvider>();
    gameNarration.updateEnvironment(enabled: p.voiceEnabled, active: false);
    await p.phonicsAudio.stop();
    await p.audio.stop();
    if (!_canListen || generation != _listenGeneration || !_isListening) return;
    try {
      await _speech.listen(
          onResult: (words, finalResult) {
            if (_canListen && generation == _listenGeneration) {
              setState(() => _recognized = words);
              if (finalResult) _evaluate(words);
            }
          },
          localeId: _locale!);
    } catch (_) {
      if (mounted && generation == _listenGeneration) {
        setState(() {
          _isListening = false;
          _isAvailable = false;
          _speechMessage = 'Speech recognition stopped. Please try again.';
        });
      }
    }
  }

  void _evaluate(String recognized) async {
    if (!_canListen || _evaluatedThisListen) return;
    if (recognized.trim().isEmpty) {
      setState(() {
        _isListening = false;
        _speechMessage = 'No speech detected. Try again.';
      });
      return;
    }
    _evaluatedThisListen = true;
    final target = _current['word']!.toLowerCase().trim();
    final heard = recognized.toLowerCase().trim();

    final isCorrect = matchesSpokenWord(target, heard,
        strict: widget.difficulty == Difficulty.hard);

    setState(() {
      _isCorrect = isCorrect;
      _isListening = false;
      _speechMessage = null;
    });

    scoredAttempts++;
    if (isCorrect) correctAttempts++;
    final request = ++_listenGeneration;
    final provider = context.read<AppProvider>();
    unawaited(provider.recordSpeechPractice(correct: isCorrect));
    await _stopSpeech();
    if (!mounted || !_canListen || request != _listenGeneration) return;
    gameNarration.updateEnvironment(
        enabled: provider.voiceEnabled,
        active: (ModalRoute.isCurrentOf(context) ?? true) &&
            (WidgetsBinding.instance.lifecycleState == null ||
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed));
    if (isCorrect) {
      awardGameXp((10 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      playGameCorrect();
    } else {
      playGameWrong();
    }
  }

  void _nextWord() {
    if (_isCorrect == null || _isListening || _isSpelling || resultOpen) return;
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
    context.read<AppProvider>().recordSpeechCompletion();
    awardGameXp(15);
    context.read<AppProvider>().audio.playWin();
    showGameResult(() => setState(() {
          _wordIndex = 0;
          _words = _newSession();
          _recognized = '';
          _evaluatedThisListen = false;
          _isCorrect = null;
        }));
  }

  @override
  void dispose() {
    _cancelSpelling(notify: false);
    WidgetsBinding.instance.removeObserver(this);
    _accessProvider?.removeListener(_accessChanged);
    _listenGeneration++;
    _stopSpeech().then((_) => BackgroundMusicService.instance.release(this),
        onError: (Object _) => BackgroundMusicService.instance.release(this));

    super.dispose();
  }

  @override
  int get totalGameItems => _words.length;

  @override
  Widget build(BuildContext context) {
    final voiceEnabled = context.watch<AppProvider>().voiceEnabled;
    return GameScaffold(
      narration: gameNarration,
      narrationEnabled: !_isListening && !_requestingPermission && !resultOpen,
      fitViewport: true,
      answerResult: _isCorrect,
      title: 'Speak & Recognize',
      instructions: 'Listen, then say the word.',
      instructionPanel: GameMascotCoach(
          title: 'Speak & Recognize',
          instructions: 'Listen, then say the word.',
          controller: gameNarration,
          enabled: !_isListening && !_requestingPermission && !resultOpen,
          child: GameInstructionGuide(
              gameTitle: 'Speak & Recognize',
              enabled: !_isListening &&
                  !_requestingPermission &&
                  !_isSpelling &&
                  !resultOpen)),
      difficulty: widget.difficulty,
      current: _wordIndex + 1,
      total: _words.length,
      hasProgress:
          (scoredAttempts > 0 || _isListening || _isSpelling) && !resultOpen,
      onLeave: _interrupt,
      child: LayoutBuilder(builder: (_, box) {
        final cardHeight = (box.maxHeight * .40).clamp(160.0, 280.0);
        return SingleChildScrollView(
          key: const ValueKey('speech-content-scroll'),
          // Keep scrolling pictures and controls below the instruction bubble.
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SpeechPictureCard(
                word: _current['word']!,
                height: cardHeight,
                spelling: _isSpelling,
                activeLetter: _spellingIndex,
                readingWord: _readingWord),
            const SizedBox(height: 8),
            Center(
                child: FractionallySizedBox(
                    widthFactor: .72,
                    child: ForestAudioButton(
                        key: const ValueKey('speech-hear-word'),
                        label: 'Hear Word',
                        icon: Icons.volume_up_rounded,
                        onPressed: voiceEnabled &&
                                !_isListening &&
                                !_requestingPermission &&
                                !_isSpelling &&
                                !resultOpen
                            ? _hearWord
                            : null))),
            if (!voiceEnabled || _isSpelling)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_rounded,
                            size: 15, color: Color(0xFF806A92)),
                        const SizedBox(width: 6),
                        Flexible(
                            child: Text(
                                !voiceEnabled
                                    ? 'Audio is turned off.'
                                    : _readingWord
                                        ? 'Listen to the whole word.'
                                        : 'Listen to the spelling.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF806A92),
                                    fontWeight: FontWeight.w700))),
                      ])),
            if (voiceEnabled && !_isSpelling) const SizedBox(height: 8),
            SpeechMicrophoneButton(
                listening: _isListening,
                onPressed: _requestingPermission ||
                        _isSpelling ||
                        _isCorrect == true ||
                        resultOpen
                    ? null
                    : _listen,
                label: _requestingPermission
                    ? 'Getting Ready...'
                    : _isListening
                        ? 'Listening...'
                        : _isInitialized && !_isAvailable
                            ? 'Try Microphone Again'
                            : 'Start Listening'),
            if (_speechMessage != null) ...[
              const SizedBox(height: 8),
              ForestPanel(
                  glass: true,
                  accent: const Color(0xFFED92AC),
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.info_rounded, color: Color(0xFF806A92)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_speechMessage!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: GameDesign.ink,
                                  fontWeight: FontWeight.w700))),
                    ]),
                    if (_settingsRequired)
                      TextButton.icon(
                          onPressed: withButtonSound(() async {
                            _interrupt();
                            await _speech.openSettings();
                            if (mounted) setState(() => _isAvailable = false);
                          }),
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('Open Device Settings')),
                  ])),
            ],
            const SizedBox(height: 8),
            SpeechHeardCard(heard: _recognized, correct: _isCorrect),
            if (_isCorrect != null) ...[
              const SizedBox(height: 8),
              Center(
                  child: ForestAudioButton(
                      key: const ValueKey('speech-next-word'),
                      label: 'Next Word',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _isListening || _isSpelling || resultOpen
                          ? null
                          : _nextWord)),
            ],
          ]),
        );
      }),
    );
  }
}
