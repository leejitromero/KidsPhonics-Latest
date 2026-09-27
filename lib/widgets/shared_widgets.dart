import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class KidsBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const KidsBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': '🏠', 'label': 'Home'},
      {'icon': '📖', 'label': 'Lessons'},
      {'icon': '🎮', 'label': 'Games'},
      {'icon': '📊', 'label': 'Progress'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF08051A),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(items[i]['icon']!,
                      style: TextStyle(
                        fontSize: 22,
                        shadows: isActive
                            ? [
                                Shadow(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.7),
                                    blurRadius: 8)
                              ]
                            : [],
                      )),
                  const SizedBox(height: 3),
                  Text(
                    items[i]['label']!,
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color:
                          isActive ? AppColors.gold : const Color(0xFF3D2A6E),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Screen header ─────────────────────────────────────────────────────────
class KidsHeader extends StatelessWidget {
  final String title;
  final Gradient gradient;
  final Color textColor;
  final VoidCallback onBack;
  final Widget? trailing;

  const KidsHeader({
    super.key,
    required this.title,
    required this.gradient,
    required this.textColor,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: BoxDecoration(gradient: gradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: GoogleFonts.fredoka(fontSize: 21, color: textColor)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
