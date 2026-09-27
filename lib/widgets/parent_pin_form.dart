import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/parent_auth_service.dart';
import 'mascot_guide.dart';

class ParentPinForm extends StatefulWidget {
  const ParentPinForm(
      {super.key,
      required this.auth,
      required this.onBack,
      this.changePin = false,
      this.onSuccess});
  final ParentAuthService auth;
  final VoidCallback onBack;
  final VoidCallback? onSuccess;
  final bool changePin;
  @override
  State<ParentPinForm> createState() => _ParentPinFormState();
}

class _ParentPinFormState extends State<ParentPinForm> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  final _current = TextEditingController();
  Timer? _timer;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pin.dispose();
    _confirm.dispose();
    _current.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || widget.auth.lockoutSeconds > 0) return;
    setState(() => _busy = true);
    String? error;
    try {
      if (widget.changePin) {
        error = await widget.auth
            .changePin(_current.text, _pin.text, _confirm.text);
      } else if (!widget.auth.hasPin) {
        error = await widget.auth.setup(_pin.text, _confirm.text);
      } else {
        error = widget.auth.unlock(_pin.text);
      }
    } catch (_) {
      error = 'Unable to save changes. Please try again.';
    }
    if (!mounted) return;
    _pin.clear();
    _confirm.clear();
    _current.clear();
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) widget.onSuccess?.call();
  }

  Widget _field(String label, TextEditingController controller) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: controller,
          obscureText: true,
          enabled: !_busy && widget.auth.lockoutSeconds == 0,
          keyboardType: TextInputType.number,
          enableSuggestions: false,
          autocorrect: false,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, counterText: ''),
          onSubmitted: (_) =>
              widget.auth.lockoutSeconds == 0 && !_busy ? _submit() : null,
        ),
      );
  @override
  Widget build(BuildContext context) {
    final setup = !widget.auth.hasPin;
    final locked = widget.auth.lockoutSeconds > 0;
    return Center(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!widget.changePin) ...[
            const MascotPortrait(mascot: LearningMascot.jitjit, size: 112),
            const SizedBox(height: 12),
          ],
          const Icon(Icons.lock_outline, size: 32),
          Text(
              widget.changePin
                  ? 'Change Parent PIN'
                  : setup
                      ? 'Set Up Parent PIN'
                      : 'Parent Access',
              style: Theme.of(context).textTheme.headlineSmall),
          if (setup || widget.changePin)
            const Text('Choose a PIN that your child does not know.'),
          if (widget.changePin) _field('Current PIN', _current),
          _field(
              widget.changePin
                  ? 'New PIN'
                  : setup
                      ? 'Enter 4-digit PIN'
                      : 'Enter Parent PIN',
              _pin),
          if (setup || widget.changePin)
            _field(
                widget.changePin ? 'Confirm New PIN' : 'Confirm PIN', _confirm),
          if (locked)
            Text(
                'Too many attempts. Try again shortly. (${widget.auth.lockoutSeconds}s)'),
          if (_error != null && !locked)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: locked || _busy ? null : _submit,
              child: Text(widget.changePin
                  ? 'Save PIN'
                  : setup
                      ? 'Set PIN'
                      : 'Unlock')),
          TextButton(
              onPressed: _busy ? null : widget.onBack,
              child: const Text('Back')),
        ]),
      ),
    ));
  }
}
