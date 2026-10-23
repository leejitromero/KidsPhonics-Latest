import 'package:flutter/material.dart';

/// The reference's cream star slots, with glossy violet and gold edges.
class AlphabetSlotFrame extends StatelessWidget {
  const AlphabetSlotFrame(
      {super.key, required this.child, this.placed = false});
  final Widget child;
  final bool placed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final radius = box.maxWidth * .16;
        return DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: placed
                        ? const [
                            Color(0xFFA3EAB4),
                            Color(0xFF2BAB85),
                            Color(0xFF167769)
                          ]
                        : const [
                            Color(0xFFE4C2FF),
                            Color(0xFFBC7AFF),
                            Color(0xFF893FE5)
                          ]),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x554D2575),
                      blurRadius: 4,
                      offset: Offset(0, 3))
                ]),
            child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius * .85),
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFEF6), Color(0xFFFFF0D5)]),
                    border: Border.all(color: Colors.white, width: 1.5)),
                child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius * .7),
                        border:
                            Border.all(color: const Color(0xFFFFDA80), width: 1.5)),
                    child: Center(child: child))));
      });
}
