import 'button_sound.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/parent_auth_service.dart';
import 'mascot_guide.dart';
import 'parent_pin_design.dart';

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
  final _visiblePins = <TextEditingController>{};
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
      _visiblePins.clear();
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
    if (!widget.changePin) return _referenceForm(setup: setup, locked: locked);
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
              onPressed: withButtonSound(locked || _busy ? null : _submit),
              child: Text(widget.changePin
                  ? 'Save PIN'
                  : setup
                      ? 'Set PIN'
                      : 'Unlock')),
          TextButton(
              onPressed: withButtonSound(_busy ? null : widget.onBack),
              child: const Text('Back')),
        ]),
      ),
    ));
  }

  Widget _referenceForm({required bool setup, required bool locked}) =>
      LayoutBuilder(builder: (context, box) {
        final compact =
            box.maxHeight < 500 || MediaQuery.viewInsetsOf(context).bottom > 0;
        return Center(
            child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 8 : 12),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ParentPinPanel(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          ParentPinHeading(setup: setup, compact: compact),
                          const SizedBox(height: 16),
                          _referenceField(
                              setup ? 'Enter 4-digit PIN' : 'Enter Parent PIN',
                              _pin,
                              allowVisibility: setup),
                          if (setup)
                            _referenceField('Confirm PIN', _confirm,
                                allowVisibility: true),
                          if (locked)
                            Text(
                                'Too many attempts. Try again shortly. (${widget.auth.lockoutSeconds}s)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB12C35))),
                          if (_error != null && !locked)
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB12C35))),
                          const SizedBox(height: 12),
                          Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 310),
                                  child: ParentPinPrimaryButton(
                                      setup: setup,
                                      label: setup ? 'Set PIN' : 'Unlock',
                                      onPressed: withButtonSound(
                                          locked || _busy ? null : _submit)))),
                          const SizedBox(height: 12),
                          Center(
                              child: SizedBox(
                                  width: 168,
                                  child: DecoratedBox(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Color(0xFFFFFFF8), Color(0xFFE1F5D5)]),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Color(0x334D8D39),
                                                blurRadius: 3,
                                                offset: Offset(0, 3))
                                          ]),
                                      child: TextButton(
                                          onPressed: withButtonSound(
                                              _busy ? null : widget.onBack),
                                          style: TextButton.styleFrom(
                                              foregroundColor: parentPinInk,
                                              minimumSize: const Size(48, 48),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 7),
                                              side: const BorderSide(color: Color(0xFFA7DC8B), width: 2),
                                              shape: const StadiumBorder()),
                                          child: const Text('Back', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 20)))))),
                        ])))));
      });

  Widget _referenceField(String label, TextEditingController controller,
      {required bool allowVisibility}) {
    final enabled = !_busy && widget.auth.lockoutSeconds == 0;
    final visible = allowVisibility && _visiblePins.contains(controller);
    return ParentPinFieldPanel(
        label: label,
        child: Semantics(
            label: label,
            child: TextField(
                key: ValueKey(
                    controller == _pin ? 'parent-pin' : 'parent-pin-confirm'),
                controller: controller,
                obscureText: !visible,
                obscuringCharacter: '●',
                enabled: enabled,
                keyboardType: TextInputType.number,
                enableSuggestions: false,
                autocorrect: false,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: const Color(0xFF6FC34F),
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 7,
                    color: parentPinInk),
                decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFFEFFFB),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                            color: Color(0xFFAFE08E), width: 2)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                            color: Color(0xFFAFE08E), width: 2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                            color: Color(0xFF52AD4F), width: 2.5)),
                    suffixIcon: allowVisibility
                        ? IconButton(
                            tooltip: visible ? 'Hide PIN' : 'Show PIN',
                            onPressed: enabled
                                ? () => setState(() {
                                      if (visible) {
                                        _visiblePins.remove(controller);
                                      } else {
                                        _visiblePins.add(controller);
                                      }
                                    })
                                : null,
                            color: const Color(0xFF48665C),
                            icon: Icon(visible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded))
                        : null),
                onSubmitted: (_) => widget.auth.lockoutSeconds == 0 && !_busy
                    ? _submit()
                    : null)));
  }
}
