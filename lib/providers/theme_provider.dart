import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true; // safe default — dark theme

  bool get isDark  => _isDark;
  bool get isLight => !_isDark;

  String get themeLabel => _isDark ? 'Demon 🔥' : 'Angel ✨';
  String get themeMotto => _isDark
      ? '✦ Rise from the Shadows ✦'
      : '✦ Hear the Divine ✦';

  ThemeProvider() {
    // Read persisted preference synchronously — box is already open in main()
    try {
      final box = Hive.box('arise_settings');
      _isDark = box.get('isDark', defaultValue: true) as bool;
    } catch (e) {
      debugPrint('ThemeProvider init error (using default dark): $e');
      _isDark = true;
    }
  }

  void toggleTheme() {
    _isDark = !_isDark;
    _persist();
    notifyListeners();
  }

  void setDark()  { _isDark = true;  _persist(); notifyListeners(); }
  void setLight() { _isDark = false; _persist(); notifyListeners(); }

  void _persist() {
    try {
      Hive.box('arise_settings').put('isDark', _isDark);
    } catch (e) {
      debugPrint('ThemeProvider._persist error: $e');
    }
  }
}
