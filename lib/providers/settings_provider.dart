import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class SettingsProvider extends ChangeNotifier {
  // Safe box accessor — never throws
  Box? get _box {
    try { return Hive.box('arise_settings'); } catch (_) { return null; }
  }

  T _get<T>(String key, T defaultValue) {
    try { return (_box?.get(key, defaultValue: defaultValue) ?? defaultValue) as T; }
    catch (_) { return defaultValue; }
  }

  Future<void> _put(String key, dynamic value) async {
    try { await _box?.put(key, value); } catch (e) { debugPrint('SettingsProvider._put: $e'); }
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  bool   get skipSilence      => _get('skipSilence',      false);
  bool   get normalizeAudio   => _get('normalizeAudio',   false);
  String get downloadQuality  => _get('downloadQuality',  'high');
  bool   get equalizerEnabled => _get('equalizerEnabled', false);

  // ── Setters ───────────────────────────────────────────────────────────────
  Future<void> setSkipSilence(bool v)      async { await _put('skipSilence',      v); notifyListeners(); }
  Future<void> setNormalizeAudio(bool v)   async { await _put('normalizeAudio',   v); notifyListeners(); }
  Future<void> setDownloadQuality(String v)async { await _put('downloadQuality',  v); notifyListeners(); }
  Future<void> setEqualizerEnabled(bool v) async { await _put('equalizerEnabled', v); notifyListeners(); }
}
