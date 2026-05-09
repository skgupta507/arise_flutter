import 'dart:async';
import 'package:flutter/foundation.dart';

import '../api/lyrics_api.dart';
import '../models/lyric_line.dart';
import '../models/song_model.dart';
import 'player_provider.dart';

class LyricsProvider extends ChangeNotifier {
  List<LyricLine> _lines = [];
  int _currentIndex = -1;
  bool _loading = false;
  String? _error;
  String? _loadedSongId;

  List<LyricLine> get lines => _lines;
  int get currentIndex => _currentIndex;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasLyrics => _lines.isNotEmpty;

  StreamSubscription<Duration>? _positionSub;

  void attachPlayer(PlayerProvider player) {
    _positionSub?.cancel();
    _positionSub = player.positionStream.listen(_onPosition);
  }

  void _onPosition(Duration pos) {
    if (_lines.isEmpty) return;
    int idx = _lines.length - 1;
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].time > pos) {
        idx = i - 1;
        break;
      }
    }
    final newIdx = idx.clamp(-1, _lines.length - 1);
    if (newIdx != _currentIndex) {
      _currentIndex = newIdx;
      notifyListeners();
    }
  }

  Future<void> loadLyrics(SongModel song) async {
    if (_loadedSongId == song.id) return;
    _loadedSongId = song.id;
    _lines = [];
    _currentIndex = -1;
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final result = await LyricsApi.fetchSynced(
        artist: song.artist,
        title: song.title,
        album: song.album,
        durationSec: song.durationSec,
      );
      if (result != null && result.isNotEmpty) {
        _lines = result;
      } else {
        _error = 'No synced lyrics found';
      }
    } catch (e) {
      _error = 'Failed to load lyrics';
      debugPrint('LyricsProvider.loadLyrics error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _lines = [];
    _currentIndex = -1;
    _loadedSongId = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
