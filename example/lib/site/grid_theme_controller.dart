import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

import '../screens/_themes.dart';

/// Holds the live-grid styling chosen in the example pages' toolbar
/// (theme preset + accent swatch + mobile-preview toggle). Shared across
/// example pages so the choice persists while browsing.
class GridThemeController extends ChangeNotifier {
  DemoTheme _themeName = DemoTheme.elegant;
  Color? _accent;
  bool _mobilePreview = false;

  DemoTheme get themeName => _themeName;
  Color? get accent => _accent;
  bool get mobilePreview => _mobilePreview;

  GridTheme get theme => themeFor(_themeName, accent: _accent);

  /// A token that changes whenever styling changes — used to re-key the live
  /// grid so it rebuilds with the new theme.
  String get token => '${_themeName.name}:${_accent?.toARGB32()}';

  void setTheme(DemoTheme t) {
    if (_themeName == t) return;
    _themeName = t;
    notifyListeners();
  }

  void setAccent(Color? c) {
    _accent = c;
    notifyListeners();
  }

  void toggleMobile() {
    _mobilePreview = !_mobilePreview;
    notifyListeners();
  }
}

/// App-wide singleton (the showcase has a single shared toolbar state).
final gridThemeController = GridThemeController();
