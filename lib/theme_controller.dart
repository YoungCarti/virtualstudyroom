import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void setDark(bool value) {
    final nextMode = value ? ThemeMode.dark : ThemeMode.light;
    if (nextMode == _mode) return;
    _mode = nextMode;
    notifyListeners();
  }

  void toggle() => setDark(!isDark);
}

final ThemeController themeController = ThemeController();

