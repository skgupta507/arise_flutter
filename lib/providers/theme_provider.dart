import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  late Box _box;
  bool _isDark = true;

  bool get isDark  => _isDark;
  bool get isLight => !_isDark;

  String get themeLabel => _isDark ? 'Demon 🔥' : 'Angel ✨';
  String get themeMotto => _isDark
      ? '✦ Rise from the Shadows ✦'
      : '✦ Hear the Divine ✦';

  ThemeProvider() { _init(); }

  Future<void> _init() async {
    _box    = Hive.box('arise_settings');
    _isDark = _box.get('isDark', defaultValue: true) as bool;
    notifyListeners();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    _box.put('isDark', _isDark);
    notifyListeners();
  }

  void setDark()  { _isDark = true;  _box.put('isDark', true);  notifyListeners(); }
  void setLight() { _isDark = false; _box.put('isDark', false); notifyListeners(); }
}
