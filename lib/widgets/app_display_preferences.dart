import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// Applies app preferences above the Navigator, including dialogs and new routes.
/// System accessibility choices remain in effect when app preferences are off.
class AppDisplayPreferences extends StatelessWidget {
  const AppDisplayPreferences({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final (multiplier, reduced) = context.select<AppProvider, (double, bool)>(
        (provider) =>
            (provider.textSizeMultiplier, provider.reducedAnimations));
    final media = MediaQuery.of(context);
    return MediaQuery(
        data: media.copyWith(
            textScaler: multiplier == 1
                ? media.textScaler
                : _AdditionalTextScale(media.textScaler, multiplier),
            disableAnimations: media.disableAnimations || reduced),
        child: child);
  }
}

class _AdditionalTextScale extends TextScaler {
  const _AdditionalTextScale(this.system, this.multiplier);
  final TextScaler system;
  final double multiplier;
  @override
  double scale(double fontSize) => system.scale(fontSize) * multiplier;
  @override
  double get textScaleFactor => scale(14) / 14;
}
