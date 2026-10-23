import 'package:flutter/material.dart';

enum KidsDestination { home, progress, parents, settings }

/// Shared with activity routes so menu links return to the same retained tabs.
class MainNavigationController extends ChangeNotifier {
  MainNavigationController({required this.onSelect});
  final Future<void> Function(KidsDestination) onSelect;
  KidsDestination current = KidsDestination.home;
  bool transitioning = false;

  Future<void> select(KidsDestination destination) => onSelect(destination);
  void update(KidsDestination destination, {required bool busy}) {
    current = destination;
    transitioning = busy;
    notifyListeners();
  }
}

class MainNavigationScope extends InheritedNotifier<MainNavigationController> {
  const MainNavigationScope(
      {super.key,
      required MainNavigationController controller,
      required super.child})
      : super(notifier: controller);

  static MainNavigationController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MainNavigationScope>()
      ?.notifier;
}
