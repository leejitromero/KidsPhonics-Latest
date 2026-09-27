import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local PIN verification. Authentication is deliberately never persisted.
class ParentAuthService extends ChangeNotifier {
  ParentAuthService(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  bool _authenticated = false;
  bool _disposed = false;
  int _failures = 0;
  DateTime? _lockedUntil;
  bool get hasPin => _prefs.containsKey('parentPinHashV1');
  bool get isAuthenticated => _authenticated;
  int get lockoutSeconds => _lockedUntil == null
      ? 0
      : ((_lockedUntil!.difference(_now()).inMilliseconds / 1000).ceil())
          .clamp(0, 30);

  static String? validatePin(String pin, String confirmation) {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      return 'Enter exactly 4 digits.';
    }
    if (const ['0000', '1111', '1234', '4321'].contains(pin)) {
      return 'Choose a PIN that your child does not know.';
    }
    if (pin != confirmation) return 'PINs do not match.';
    return null;
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> _store(String pin) async {
    final random = Random.secure();
    final salt = base64Encode(List.generate(24, (_) => random.nextInt(256)));
    // One value keeps salt and digest together even if the process is killed.
    if (!await _prefs.setString(
        'parentPinHashV1', '$salt:${_hash(pin, salt)}')) {
      throw StateError('Unable to save Parent PIN. Please try again.');
    }
  }

  Future<String?> setup(String pin, String confirmation) async {
    if (hasPin) return 'A Parent PIN already exists.';
    final error = validatePin(pin, confirmation);
    if (error != null) return error;
    await _store(pin);
    _authenticated = true;
    _changed();
    return null;
  }

  bool _verify(String pin) {
    if (lockoutSeconds > 0) return false;
    final stored = _prefs.get('parentPinHashV1');
    final parts = stored is String ? stored.split(':') : <String>[];
    final valid = parts.length == 2 &&
        RegExp(r'^[0-9]{4}$').hasMatch(pin) &&
        _hash(pin, parts.first) == parts.last;
    if (valid) {
      _failures = 0;
      _lockedUntil = null;
    } else {
      _failures++;
      if (_failures >= 5) {
        _lockedUntil = _now().add(const Duration(seconds: 30));
        _failures = 0;
      }
    }
    return valid;
  }

  String? unlock(String pin) {
    if (!_verify(pin)) {
      _changed();
      return lockoutSeconds > 0
          ? 'Too many attempts. Try again shortly.'
          : 'Incorrect PIN. Try again.';
    }
    _authenticated = true;
    _changed();
    return null;
  }

  void requireSession() {
    if (!_authenticated) throw StateError('Parent authentication required.');
  }

  Future<String?> changePin(
      String current, String pin, String confirmation) async {
    requireSession();
    if (!_verify(current)) {
      _changed();
      return lockoutSeconds > 0
          ? 'Too many attempts. Try again shortly.'
          : 'Incorrect PIN. Try again.';
    }
    final error = validatePin(pin, confirmation);
    if (error != null) return error;
    await _store(pin);
    _changed();
    return null;
  }

  void endSession() {
    _authenticated = false;
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _authenticated = false;
    super.dispose();
  }
}
