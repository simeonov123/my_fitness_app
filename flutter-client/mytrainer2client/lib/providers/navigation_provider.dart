import 'package:flutter/material.dart';

/// Holds the index of the currently‑selected bottom‑nav item
class NavigationProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int newIndex) {
    if (newIndex != _index) {
      _index = newIndex;
      notifyListeners();
    }
  }
}
