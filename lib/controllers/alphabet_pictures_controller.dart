import 'package:flutter/foundation.dart';
import '../data/alphabet_picture_data.dart';

/// Cancels the previous sentence when browsing and records completed listening.
class AlphabetPicturesController extends ChangeNotifier {
  AlphabetPicturesController(
      {required this.play,
      required this.stopAudio,
      required this.enabled,
      required this.available,
      required this.beforePlay,
      required this.onViewed,
      required this.onListened});
  final Future<bool> Function(String) play;
  final VoidCallback stopAudio;
  final bool Function() enabled;
  final bool Function(String) available;
  final Future<void> Function() beforePlay;
  final ValueChanged<String> onViewed;
  final Future<void> Function(String) onListened;
  int index = 0;
  int _request = 0;
  bool _disposed = false, playing = false;
  String? message;
  AlphabetPicture get entry => alphabetPictures[index];
  bool get hasRecording => available(entry.phrase);

  Future<void> select(int next, {bool initial = false}) async {
    if (_disposed ||
        next < 0 ||
        next >= alphabetPictures.length ||
        (!initial && next == index)) {
      return;
    }
    stop(notify: false);
    index = next;
    message = null;
    onViewed(entry.letter);
    notifyListeners();
    await replay();
  }

  Future<void> replay() async {
    if (_disposed) return;
    stop(notify: false);
    final request = _request;
    final selected = entry;
    message = null;
    if (!hasRecording) {
      message = 'Audio unavailable.';
      notifyListeners();
      return;
    }
    if (!enabled()) {
      notifyListeners();
      return;
    }
    playing = true;
    notifyListeners();
    bool current() => !_disposed && request == _request && enabled();
    var completed = false;
    try {
      await beforePlay();
      if (!current()) return;
      completed = await play(selected.phrase);
      if (!current()) return;
      if (completed) await onListened(selected.letter);
    } catch (_) {
      completed = false;
    } finally {
      if (!_disposed && request == _request) {
        playing = false;
        if (!completed && enabled()) {
          message = 'Audio unavailable. Please try again.';
        }
        notifyListeners();
      }
    }
  }

  void stop({bool notify = true}) {
    _request++;
    playing = false;
    stopAudio();
    if (notify && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    stop(notify: false);
    _disposed = true;
    super.dispose();
  }
}
