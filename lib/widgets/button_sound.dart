import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';

/// Apply at the actual button/gesture, not at its containing custom widget.
/// Keeping null callbacks null preserves disabled buttons and accessibility.
VoidCallback? withButtonSound(VoidCallback? action) {
  if (action == null) return null;
  return () {
    unawaited(AudioService().playTap());
    action();
  };
}

ValueChanged<T>? withSelectionSound<T>(ValueChanged<T>? action) {
  if (action == null) return null;
  return (value) {
    unawaited(AudioService().playTap());
    action(value);
  };
}
