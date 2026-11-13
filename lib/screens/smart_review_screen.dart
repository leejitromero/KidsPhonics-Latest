import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/scene_voice_controller.dart';
import '../data/smart_review_catalog.dart';
import '../providers/app_provider.dart';
import '../models/smart_review.dart';
import '../theme/kids_ui.dart';
import '../widgets/lesson_frame.dart';
import '../widgets/school_room_body.dart';

/// A short, unscored session. The question order stays fixed while it is open.
class SmartReviewScreen extends StatefulWidget {
  const SmartReviewScreen({super.key});
  @override
  State<SmartReviewScreen> createState() => _SmartReviewScreenState();
}

class _SmartReviewScreenState extends State<SmartReviewScreen>
    with WidgetsBindingObserver {
  AppProvider? _provider;
  SceneVoiceController? _voice;
  List<ReviewQuestion>? _questions;
  int _index = 0, _request = 0;
  String? _selected;
  bool _heard = false, _cuePlaying = false, _audioFailed = false;
  bool _advancing = false, _foreground = true;
  Future<void> _saved = Future.value();
  bool get _current =>
      mounted && _foreground && (ModalRoute.isCurrentOf(context) ?? true);
  bool get _complete => _questions != null && _index >= _questions!.length;
  ReviewQuestion get _question => _questions![_index];
  bool get _canChoose =>
      _current &&
      !_complete &&
      _selected == null &&
      !_provider!.timeLimitReached &&
      (_heard || _question.target.skill == ReviewSkill.recognition);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.watch<AppProvider>();
    _voice ??= SceneVoiceController(_provider!,
        isCurrent: () => _current, replayOnResume: false);
    if (_provider!.isReady) {
      _questions ??= SmartReviewCatalog.plan(_provider!.smartReviewSuggestions);
    }
    if (!_current || !_provider!.voiceEnabled || _provider!.timeLimitReached) {
      _stopCue();
    }
    _scheduleCue();
  }

  void _stopCue() {
    _request++;
    _cuePlaying = false;
    _voice?.stop(notify: false);
  }

  void _scheduleCue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_current &&
          _questions != null &&
          !_complete &&
          _selected == null &&
          !_heard &&
          !_audioFailed &&
          !_cuePlaying &&
          _provider!.voiceEnabled &&
          !_provider!.timeLimitReached) {
        unawaited(_playCue());
      }
    });
  }

  Future<void> _playCue() async {
    if (!_current ||
        _complete ||
        _selected != null ||
        _cuePlaying ||
        !_provider!.voiceEnabled ||
        _provider!.timeLimitReached) {
      return;
    }
    final request = ++_request;
    final index = _index;
    setState(() {
      _cuePlaying = true;
      _audioFailed = false;
    });
    bool current() =>
        _current &&
        request == _request &&
        index == _index &&
        _selected == null &&
        _provider!.voiceEnabled &&
        !_provider!.timeLimitReached;
    var completed = true;
    for (final phrase in _question.phrases) {
      if (!current()) return;
      if (!await _voice!.play(phrase)) {
        completed = false;
        break;
      }
    }
    if (!current()) return;
    setState(() {
      _cuePlaying = false;
      _heard = _heard || completed;
      _audioFailed = !completed;
    });
  }

  void _choose(String answer) {
    if (!_canChoose) return;
    final question = _question;
    _stopCue();
    setState(() => _selected = answer);
    _saved = _provider!.recordSmartReviewPractice(
        question.target, answer == question.expected);
  }

  Future<void> _next() async {
    if (_advancing ||
        _selected == null ||
        !_current ||
        _provider!.timeLimitReached) {
      return;
    }
    _advancing = true;
    await _saved;
    if (!mounted) return;
    _stopCue();
    setState(() {
      _index++;
      _selected = null;
      _heard = _audioFailed = _advancing = false;
    });
    _scheduleCue();
  }

  void _restart() {
    _stopCue();
    setState(() {
      _questions = SmartReviewCatalog.plan(_provider!.smartReviewSuggestions);
      _index = 0;
      _selected = null;
      _heard = _audioFailed = _advancing = false;
    });
    _scheduleCue();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _stopCue();
    } else {
      _scheduleCue();
    }
  }

  @override
  void dispose() {
    _request++;
    _voice?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Theme(
        data: KidsUi.theme,
        child: Scaffold(
            body: SchoolRoomBody(
          room: SchoolRoom.progress,
          showNavigation: false,
          child: Column(children: [
            Row(children: [
              IconButton(
                  key: const ValueKey('smart-review-back'),
                  tooltip: 'Back to My Journey',
                  onPressed: () => Navigator.maybePop(context),
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: KidsUi.ink)),
              const Expanded(
                  child: Text('Smart Review',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: KidsUi.ink))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 12),
            Expanded(
                child: Center(
                    child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                  key: const ValueKey('smart-review-scroll'),
                  padding: const EdgeInsets.all(5),
                  child: LessonFrame(
                      padding: const EdgeInsets.all(22), child: _content(p))),
            ))),
          ]),
        )));
  }

  Widget _content(AppProvider p) {
    if (!p.isReady || _questions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.timeLimitReached) {
      return const Text('Practice time is finished. Ask a parent for help.',
          textAlign: TextAlign.center);
    }
    final hasItems = _questions!.isNotEmpty;
    if (_complete) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.auto_awesome_rounded,
            size: 56, color: Color(0xFFFFAD19)),
        const SizedBox(height: 12),
        Text(hasItems ? 'Great practicing!' : 'Ready for your next adventure!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: KidsUi.ink)),
        const SizedBox(height: 12),
        Text(
            hasItems
                ? 'You have finished this review. Keep learning at your own pace.'
                : 'Play a game or try Quick Check. Your answers will help choose your review.',
            textAlign: TextAlign.center),
        if (hasItems && p.smartReviewSuggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton(
              key: const ValueKey('smart-review-more'),
              onPressed: _restart,
              child: const Text('Practice More')),
        ],
        const SizedBox(height: 12),
        FilledButton(
            key: const ValueKey('smart-review-done'),
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Back to My Journey')),
        _saveStatus(p),
      ]);
    }
    final question = _question;
    final answered = _selected != null;
    final correct = _selected == question.expected;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('A little practice, just for you!',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Color(0xFF7052CA), fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Text(question.heading,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: KidsUi.ink)),
      const SizedBox(height: 12),
      Text(question.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      if (question.display.isNotEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(question.display,
                    key: const ValueKey('smart-review-display'),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: KidsUi.ink)))),
      const SizedBox(height: 12),
      FilledButton.icon(
          key: const ValueKey('smart-review-audio'),
          onPressed:
              !p.voiceEnabled || _cuePlaying || answered ? null : _playCue,
          icon: Icon(
              _cuePlaying ? Icons.graphic_eq_rounded : Icons.volume_up_rounded),
          label: Text(_cuePlaying ? 'Listening...' : 'Hear Again')),
      if (!p.voiceEnabled &&
          !_heard &&
          question.target.skill != ReviewSkill.recognition) ...[
        const SizedBox(height: 8),
        const Text('Turn Voice on to hear this practice.',
            textAlign: TextAlign.center),
        TextButton(
            onPressed: () => unawaited(p.toggleVoice()),
            child: const Text('Turn Voice On')),
      ],
      if (_audioFailed)
        const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Audio could not play. Tap Hear Again to retry.',
                textAlign: TextAlign.center)),
      const SizedBox(height: 12),
      for (var i = 0; i < question.options.length; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton(
                key: ValueKey('smart-review-choice-$i'),
                onPressed:
                    _canChoose ? () => _choose(question.options[i]) : null,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 58),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    backgroundColor: const [
                      Color(0xFF087F86),
                      Color(0xFF8832BD),
                      Color(0xFFAF581A)
                    ][i % 3],
                    disabledBackgroundColor:
                        answered && question.options[i] == _selected
                            ? correct
                                ? const Color(0xFFD3F2DD)
                                : const Color(0xFFFFE1D7)
                            : const Color(0xFFF0E9F8),
                    disabledForegroundColor: KidsUi.ink,
                    foregroundColor: Colors.white),
                child: Text(question.options[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: _canChoose ? Colors.white : KidsUi.ink)))),
      if (answered) ...[
        Container(
            key: const ValueKey('smart-review-feedback'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color:
                    correct ? const Color(0xFFE1F6E6) : const Color(0xFFFFEACF),
                borderRadius: BorderRadius.circular(18)),
            child: Semantics(
                liveRegion: true,
                child: Text(
                    '${correct ? 'Great job!' : "Let's learn together!"}\n${question.explanation}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: KidsUi.ink)))),
        const SizedBox(height: 12),
        FilledButton(
            key: const ValueKey('smart-review-next'),
            onPressed: _advancing ? null : _next,
            child: Text(
                _index == _questions!.length - 1 ? 'Finish Review' : 'Next')),
      ],
      _saveStatus(p),
    ]);
  }

  Widget _saveStatus(AppProvider p) => !p.hasUnsavedChanges
      ? const SizedBox.shrink()
      : Column(children: [
          const Text('Your latest practice is waiting to save.',
              textAlign: TextAlign.center),
          TextButton(
              onPressed: () => unawaited(p.retrySaving()),
              child: const Text('Retry Saving')),
        ]);
}
