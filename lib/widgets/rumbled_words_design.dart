import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'button_sound.dart';
import 'game_design.dart';
import '../models/difficulty.dart';
import 'floating_choice.dart';

class RumbledRoundHeader extends StatelessWidget {
  const RumbledRoundHeader(
      {super.key,
      required this.difficulty,
      required this.current,
      required this.total});
  final Difficulty difficulty;
  final int current, total;
  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      Difficulty.easy => const Color(0xFF167769),
      Difficulty.medium => const Color(0xFF7052CA),
      Difficulty.hard => const Color(0xFFB45731),
    };
    return ForestPanel(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Column(children: [
          SizedBox(
              height: 32,
              child: Row(children: [
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12)),
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(difficulty.label,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))))),
                const SizedBox(width: 8),
                Expanded(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('$current / $total words',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: GameDesign.ink))))
              ])),
          const SizedBox(height: 5),
          Semantics(
              label: 'Word $current of $total',
              child: LinearProgressIndicator(
                  value: current / total,
                  minHeight: 7,
                  color: color,
                  backgroundColor: const Color(0xFFDAD6DF),
                  borderRadius: BorderRadius.circular(12)))
        ]));
  }
}

/// Keeps the whole word readable from left to right without wrapping letters.
class RumbledLetterRow extends StatefulWidget {
  const RumbledLetterRow(
      {super.key,
      required this.maxSide,
      required this.gap,
      required this.tileIds,
      required this.selectedIndex,
      required this.enabled,
      required this.fixedFirst,
      required this.onMove,
      required this.onDraggingChanged,
      required this.children});
  final double maxSide, gap;
  final List<Widget> children;
  final List<int> tileIds;
  final int? selectedIndex;
  final bool enabled, fixedFirst;
  final void Function(int from, int to) onMove;
  final ValueChanged<bool> onDraggingChanged;

  @override
  State<RumbledLetterRow> createState() => _RumbledLetterRowState();
}

class _RumbledLetterRowState extends State<RumbledLetterRow>
    with WidgetsBindingObserver {
  final _boardKey = GlobalKey();
  int? _dragIndex, _hoverIndex;
  Offset _dragPosition = Offset.zero, _grabOffset = Offset.zero;
  bool _validDrop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancelDrag() {
    if (_dragIndex == null) return;
    _dragIndex = _hoverIndex = null;
    _validDrop = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDraggingChanged(false);
    });
  }

  @override
  void didUpdateWidget(RumbledLetterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _cancelDrag();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _dragIndex != null) {
      setState(_cancelDrag);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Offset _local(Offset global) =>
      (_boardKey.currentContext!.findRenderObject() as RenderBox)
          .globalToLocal(global);

  void _finishDrag({bool cancelled = false}) {
    final from = _dragIndex;
    final to = _hoverIndex;
    final accept = !cancelled && widget.enabled && _validDrop;
    setState(() {
      _dragIndex = _hoverIndex = null;
      _validDrop = false;
    });
    widget.onDraggingChanged(false);
    if (from != null && to != null && accept && from != to) {
      widget.onMove(from, to);
    }
  }

  int _previewPosition(int index) {
    final from = _dragIndex, to = _hoverIndex;
    if (from == null || to == null) return index;
    if (from < to && index > from && index <= to) return index - 1;
    if (from > to && index >= to && index < from) return index + 1;
    return index;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        if (widget.children.isEmpty) return const SizedBox.shrink();
        final count = widget.children.length;
        final side = ((box.maxWidth - (count - 1) * widget.gap) / count)
            .clamp(0.0, widget.maxSide);
        final stride = side + widget.gap;
        final left =
            (box.maxWidth - (count * side + (count - 1) * widget.gap)) / 2;
        const top = 10.0;
        final reduced = MediaQuery.disableAnimationsOf(context);
        final duration =
            reduced ? Duration.zero : const Duration(milliseconds: 240);
        final order = [
          for (var i = 0; i < count; i++)
            if (i != _dragIndex) i,
          if (_dragIndex != null) _dragIndex!
        ];
        return SizedBox(
            key: _boardKey,
            height: side + top,
            child: Stack(clipBehavior: Clip.none, children: [
              for (final i in order)
                AnimatedPositioned(
                    key: ValueKey(widget.tileIds[i]),
                    duration: _dragIndex == i ? Duration.zero : duration,
                    curve: Curves.easeInOutCubic,
                    left: _dragIndex == i
                        ? _dragPosition.dx
                        : left + _previewPosition(i) * stride,
                    top: _dragIndex == i ? _dragPosition.dy : top,
                    width: side,
                    height: side,
                    child: GestureDetector(
                        key: ValueKey('word-drag-$i'),
                        behavior: HitTestBehavior.translucent,
                        dragStartBehavior: DragStartBehavior.down,
                        onPanStart: widget.enabled &&
                                widget.selectedIndex == i &&
                                !(widget.fixedFirst && i == 0)
                            ? (details) {
                                // Start from the tile's visible position, even
                                // if a hint or previous drop is still settling.
                                final position =
                                    _local(details.globalPosition) -
                                        details.localPosition;
                                setState(() {
                                  _dragIndex = _hoverIndex = i;
                                  _dragPosition = position;
                                  _grabOffset =
                                      _local(details.globalPosition) - position;
                                  _validDrop = true;
                                });
                                widget.onDraggingChanged(true);
                              }
                            : null,
                        onPanUpdate: widget.enabled && widget.selectedIndex == i
                            ? (details) {
                                if (_dragIndex != i) return;
                                final pointer = _local(details.globalPosition);
                                setState(() {
                                  _dragPosition = pointer - _grabOffset;
                                  _validDrop = pointer.dx >= left - side / 2 &&
                                      pointer.dx <=
                                          box.maxWidth - left + side / 2 &&
                                      pointer.dy >= -side / 2 &&
                                      pointer.dy <= side * 1.5 + top;
                                  _hoverIndex = _validDrop
                                      ? ((pointer.dx - left - side / 2) /
                                              stride)
                                          .round()
                                          .clamp(widget.fixedFirst ? 1 : 0,
                                              count - 1)
                                      : i;
                                });
                              }
                            : null,
                        onPanEnd: widget.enabled && widget.selectedIndex == i
                            ? (_) => _finishDrag()
                            : null,
                        onPanCancel: widget.enabled && widget.selectedIndex == i
                            ? () => _finishDrag(cancelled: true)
                            : null,
                        child: AnimatedSlide(
                            duration: duration,
                            offset: widget.selectedIndex == i && !reduced
                                ? const Offset(0, -.07)
                                : Offset.zero,
                            child: FloatingChoice(
                                enabled: widget.enabled &&
                                    widget.selectedIndex == i &&
                                    _dragIndex != i,
                                seed: widget.tileIds[i],
                                child: widget.children[i])))),
            ]));
      });
}

/// Glossy rounded controls with live labels and the game's original callbacks.
class RumbledActionButton extends StatelessWidget {
  const RumbledActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      required this.height,
      this.purple = false,
      this.cream = false,
      this.buttonKey});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  final bool purple, cream;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Container(
      height: height,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .18, .55, 1],
              colors: cream
                  ? const [
                      Color(0xFFFFFEF6),
                      Color(0xFFFFF5DA),
                      Color(0xFFF4DEB9),
                      Color(0xFFE9C995)
                    ]
                  : purple
                      ? const [
                          Color(0xFFE3A3FF),
                          Color(0xFFB04CFA),
                          Color(0xFF8A2AE2),
                          Color(0xFF6320B9)
                        ]
                      : const [
                          Color(0xFF7CF4CF),
                          Color(0xFF05C8AC),
                          Color(0xFF00A094),
                          Color(0xFF007C82)
                        ]),
          border: Border.all(
              color: purple ? const Color(0xFFD6ACFF) : const Color(0xFFFFE697),
              width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x443D2467), offset: Offset(0, 3), blurRadius: 5)
          ]),
      child: OutlinedButton(
          key: buttonKey,
          onPressed: withButtonSound(onPressed),
          style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              foregroundColor: cream ? GameDesign.ink : Colors.white,
              disabledForegroundColor:
                  cream ? const Color(0xFF6B5782) : const Color(0xFFDDEBEA),
              side: const BorderSide(color: Color(0xBBFFFFFF), width: 2),
              shape: const StadiumBorder()),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 22),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 19,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900))
              ]))));
}
