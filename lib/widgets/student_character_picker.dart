import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/character_selection_art.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import 'button_sound.dart';
import 'scene_controls.dart';

class StudentCharacterPicker extends StatefulWidget {
  const StudentCharacterPicker(
      {super.key,
      this.firstSetup = false,
      this.onSaved,
      this.onCharacterSelected,
      this.setupDialogue,
      this.canSave = true,
      this.canSelect = true,
      this.isReadyToSave});
  final bool firstSetup;
  final VoidCallback? onSaved;
  final ValueChanged<String>? onCharacterSelected;
  final Widget? setupDialogue;
  final bool canSave, canSelect;
  final bool Function()? isReadyToSave;
  @override
  State<StudentCharacterPicker> createState() => _StudentCharacterPickerState();
}

class _StudentCharacterPickerState extends State<StudentCharacterPicker> {
  late final _provider = context.read<AppProvider>();
  late final _name = TextEditingController(text: _provider.studentName);
  late String _character = _provider.studentCharacter;
  bool _saving = false;
  late bool _selected = !widget.firstSetup;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !widget.canSave || widget.isReadyToSave?.call() == false) {
      return;
    }
    if (!_selected) {
      setState(() => _error = 'Please choose your character.');
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = widget.firstSetup
          ? await _provider.completeWelcome(_character, _name.text)
          : await _saveProfile();
      if (!mounted) return;
      if (!saved) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Please try again.';
        });
      } else if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Please try again.';
        });
      }
    }
  }

  Future<bool> _saveProfile() async {
    await _provider.setStudentCharacter(_character, _name.text);
    return !_provider.hasUnsavedChanges;
  }

  @override
  Widget build(BuildContext context) => BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Theme(
          data: KidsUi.theme,
          child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Container(
                  key: const ValueKey('character-selection-panel'),
                  width: 460,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFECA0),
                            Color(0xFFFFA921),
                            Color(0xFFFFDA60)
                          ]),
                      border:
                          Border.all(color: const Color(0xFFFFC13B), width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x88320D72),
                            blurRadius: 20,
                            offset: Offset(0, 8)),
                      ]),
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: const Color(0xFFFFF7CB), width: 2),
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFF9E9), Color(0xFFFFEDBC)])),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Semantics(
                            label: 'Choose your character!',
                            header: true,
                            child: AspectRatio(
                                aspectRatio: 3,
                                child: Image.asset(CharacterSelectionArt.banner,
                                    key: const ValueKey(
                                        'character-selection-banner'),
                                    fit: BoxFit.contain,
                                    cacheWidth: 1024,
                                    excludeFromSemantics: true))),
                        Flexible(
                            child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 6),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.setupDialogue != null) ...[
                                        widget.setupDialogue!,
                                        const SizedBox(height: 8),
                                      ],
                                      Row(children: [
                                        Expanded(child: _choice('boy')),
                                        const SizedBox(width: 10),
                                        Expanded(child: _choice('girl')),
                                      ]),
                                      const SizedBox(height: 12),
                                      const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('Enter your name:',
                                              style: TextStyle(
                                                  fontFamily: 'Fredoka',
                                                  fontSize: 18,
                                                  color: Color(0xFF632909)))),
                                      const SizedBox(height: 6),
                                      _nameField(),
                                      if (_error != null)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Semantics(
                                                liveRegion: true,
                                                child: Text(_error!,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFFAD3B52),
                                                        fontWeight:
                                                            FontWeight.w800)))),
                                    ]))),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                            child: Row(children: [
                              if (!widget.firstSetup) ...[
                                Expanded(
                                    flex: 4,
                                    child: _SelectionActionButton(
                                        label: 'Cancel',
                                        primary: false,
                                        onPressed: _saving
                                            ? null
                                            : () => Navigator.pop(context))),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                  flex: 5,
                                  child: _SelectionActionButton(
                                      key: const ValueKey('save-student'),
                                      primary: true,
                                      onPressed: _saving || !widget.canSave
                                          ? null
                                          : _save,
                                      label:
                                          _saving ? 'Saving…' : 'Let’s go!')),
                            ])),
                      ]))))));

  Widget _nameField() => Stack(children: [
        Semantics(
            label: 'Enter your name',
            child: TextField(
                key: const ValueKey('character-selection-name'),
                controller: _name,
                style: const TextStyle(
                    color: Color(0xFF63497F),
                    fontFamily: 'Fredoka',
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                enabled: !_saving,
                maxLength: 24,
                buildCounter: (_,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: const TextStyle(color: Color(0xFFAE98C6)),
                    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
                    filled: true,
                    fillColor: const Color(0xFFF9F5FF),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                            color: Color(0xFFB89BFF), width: 2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                            color: Color(0xFF8246D8), width: 3))))),
        Positioned(
            right: 14,
            bottom: 7,
            child: IgnorePointer(
                child: ExcludeSemantics(
                    child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _name,
                        builder: (_, value, __) => Text(
                            '${value.text.characters.length}/24',
                            key: const ValueKey(
                                'character-selection-name-count'),
                            style: const TextStyle(
                                color: Color(0xFF9B83B7),
                                fontSize: 12,
                                fontWeight: FontWeight.w800)))))),
      ]);

  Widget _choice(String character) {
    final selected = _selected && _character == character;
    final enabled = !_saving && widget.canSelect;
    return Semantics(
        label: character == 'boy' ? 'Boy' : 'Girl',
        key: ValueKey('character-choice-$character'),
        button: true,
        enabled: enabled,
        selected: selected,
        child: InkWell(
            key: ValueKey('choose-$character'),
            onTap: !enabled
                ? null
                : () {
                    setState(() {
                      _character = character;
                      _selected = true;
                      _error = null;
                    });
                    widget.onCharacterSelected?.call(character);
                  },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
                padding: const EdgeInsets.all(6),
                child: AspectRatio(
                    aspectRatio: .75,
                    child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          if (selected)
                            ExcludeSemantics(
                                child: ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                        sigmaX: 3, sigmaY: 3),
                                    child: ColorFiltered(
                                        colorFilter: const ColorFilter.mode(
                                            Color(0xDD9343F1), BlendMode.srcIn),
                                        child: Image.asset(
                                            CharacterSelectionArt.portrait(
                                                character),
                                            fit: BoxFit.contain,
                                            cacheWidth: 600)))),
                          Image.asset(CharacterSelectionArt.portrait(character),
                              key: ValueKey(
                                  'character-selection-$character-art'),
                              fit: BoxFit.contain,
                              cacheWidth: 600,
                              excludeFromSemantics: true),
                        ])))));
  }
}

/// Retains the existing SceneButton contract for onboarding's save gate.
class _SelectionActionButton extends SceneButton {
  const _SelectionActionButton(
      {super.key,
      required super.label,
      required super.onPressed,
      required this.primary});
  final bool primary;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFEE9B), Color(0xFFFFB23A)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55733914), blurRadius: 5, offset: Offset(0, 4))
          ]),
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: primary
                      ? [
                          const Color(0xFFBA55FF),
                          const Color(0xFF7620DD),
                          const Color(0xFF9740ED)
                        ]
                      : [const Color(0xFFFFFEF4), const Color(0xFFFFE5A5)]),
              border: Border.all(
                  color: primary
                      ? const Color(0xFFDD9BFF)
                      : const Color(0xFFFFF9DB),
                  width: 2)),
          child: ElevatedButton(
              onPressed: withButtonSound(onPressed),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor:
                      primary ? Colors.white : const Color(0xFF783008),
                  disabledBackgroundColor: const Color(0x887E68A1),
                  disabledForegroundColor: const Color(0xFFD6CBE4),
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  minimumSize: const Size(48, 52),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23))),
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (primary) ...[
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFD632), size: 23),
                      const SizedBox(width: 4),
                    ],
                    Text(label,
                        maxLines: 1,
                        style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: primary
                                ? Colors.white
                                : const Color(0xFF783008),
                            shadows: primary
                                ? const [
                                    Shadow(
                                        color: Color(0xFF40117E),
                                        blurRadius: 2,
                                        offset: Offset(0, 2))
                                  ]
                                : null)),
                  ])))));
}
