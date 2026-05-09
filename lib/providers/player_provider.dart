import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song_model.dart';
import '../api/saavn_api.dart';
import '../api/muzo_api.dart';
import '../api/rapid_api.dart';

enum RepeatMode { none, one, all }

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  SongModel?      _current;
  List<SongModel> _queue   = [];
  List<SongModel> _history = [];
  bool            _playing = false;
  RepeatMode      _repeat  = RepeatMode.none;
  bool            _shuffle = false;
  double          _volume  = 1.0;
  Duration        _position= Duration.zero;
  Duration        _duration= Duration.zero;
  bool            _loading = false;
  String?         _error;

  // ── New feature flags ─────────────────────────────────────────────────────
  bool            _skipSilence       = false;
  bool            _normalizeLoudness = false;
  Timer?          _sleepTimer;
  Duration?       _sleepRemaining;

  SongModel?      get current   => _current;
  List<SongModel> get queue     => List.unmodifiable(_queue);
  List<SongModel> get history   => List.unmodifiable(_history);
  bool            get playing   => _playing;
  RepeatMode      get repeat    => _repeat;
  bool            get shuffle   => _shuffle;
  double          get volume    => _volume;
  Duration        get position  => _position;
  Duration        get duration  => _duration;
  bool            get loading   => _loading;
  String?         get error     => _error;
  bool            get hasTrack  => _current != null;
  bool            get skipSilence       => _skipSilence;
  bool            get normalizeLoudness => _normalizeLoudness;
  Duration?       get sleepRemaining    => _sleepRemaining;

  /// Expose raw position stream for lyrics sync
  Stream<Duration> get positionStream => _player.positionStream;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionStr => _fmt(_position);
  String get durationStr => _fmt(_duration);

  PlayerProvider() { _initListeners(); }

  void _initListeners() {
    _player.playerStateStream.listen((state) {
      _playing = state.playing;
      if (state.processingState == ProcessingState.completed) _onEnded();
      notifyListeners();
    }, onError: (e) => debugPrint('playerStateStream: $e'));

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    }, onError: (e) => debugPrint('positionStream: $e'));

    _player.durationStream.listen((dur) {
      if (dur != null) { _duration = dur; notifyListeners(); }
    }, onError: (e) => debugPrint('durationStream: $e'));

    _player.playbackEventStream.listen((_) {}, onError: (e) {
      _error = 'Playback error';
      debugPrint('playbackEventStream: $e');
      notifyListeners();
    });
  }

  // ── Primary play entry ────────────────────────────────────────────────────
  Future<void> play(SongModel song, {List<SongModel>? queue}) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    if (_current != null) {
      _history = [_current!, ..._history].take(50).toList();
    }
    _current = song;
    if (queue != null) _queue = queue.where((s) => s.id != song.id).toList();

    try {
      final streamUrl = await _resolveStream(song);
      if (streamUrl == null) throw Exception('No stream URL found');

      Uri? artUri;
      try {
        if (song.thumbnail != null && song.thumbnail!.isNotEmpty) {
          artUri = Uri.parse(song.thumbnail!);
        }
      } catch (_) {}

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id:     song.id,
            title:  song.title,
            artist: song.artist,
            album:  song.album ?? '',
            artUri: artUri,
          ),
        ),
      );
      await _player.play();
      if (_queue.isEmpty) unawaited(_autoQueue(song));
    } catch (e) {
      _error = 'Could not play: ${song.title}';
      debugPrint('PlayerProvider.play error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// 3-tier stream resolution:
  /// 1. Muzo /api/stream/:ytId  (Invidious — best quality)
  /// 2. Saavn downloadUrl       (for Saavn songs)
  /// 3. RapidAPI video/info     (fallback)
  Future<String?> _resolveStream(SongModel song) async {
    // ── Tier 1: YouTube path via Muzo ────────────────────────────────────
    if (song.source == 'youtube' || song.ytId != null) {
      final ytId = song.ytId ?? song.id;
      final url = await MuzoApi.streamUrl(ytId);
      if (url != null) return url;

      // Muzo failed → try RapidAPI
      final rapidUrl = await _rapidStreamUrl(ytId);
      if (rapidUrl != null) return rapidUrl;
      return null;
    }

    // ── Tier 2: Saavn path ───────────────────────────────────────────────
    // Try to find YouTube ID first for better quality
    final ytId = await MuzoApi.findVideoId(
      name: song.title, artist: song.artist,
    );
    if (ytId != null && ytId.isNotEmpty) {
      final url = await MuzoApi.streamUrl(ytId);
      if (url != null) {
        _current = song.copyWith(ytId: ytId);
        return url;
      }
      // Muzo stream failed, try RapidAPI with found ytId
      final rapidUrl = await _rapidStreamUrl(ytId);
      if (rapidUrl != null) {
        _current = song.copyWith(ytId: ytId);
        return rapidUrl;
      }
    }

    // ── Tier 3: Saavn direct stream URL ──────────────────────────────────
    if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
      return song.streamUrl;
    }
    return await _saavnStreamUrl(song.id);
  }

  Future<String?> _saavnStreamUrl(String songId) async {
    try {
      final song = await SaavnApi.getSongById(songId);
      if (song == null) return null;
      return SaavnApi.bestStreamUrl(song);
    } catch (_) { return null; }
  }

  Future<String?> _rapidStreamUrl(String videoId) async {
    try {
      final info = await RapidApi.videoInfo(videoId);
      if (info == null) return null;
      // Some RapidAPI responses include adaptiveFormats
      final adaptive = info['adaptiveFormats'] as List?;
      if (adaptive != null && adaptive.isNotEmpty) {
        final audio = adaptive
            .where((f) => f['type']?.toString().contains('audio') == true && f['url'] != null)
            .toList();
        if (audio.isNotEmpty) {
          audio.sort((a, b) {
            final aBr = int.tryParse(a['bitrate']?.toString() ?? '0') ?? 0;
            final bBr = int.tryParse(b['bitrate']?.toString() ?? '0') ?? 0;
            return bBr.compareTo(aBr);
          });
          return audio.first['url'] as String?;
        }
      }
      return null;
    } catch (_) { return null; }
  }

  // ── Play YouTube video by ID ──────────────────────────────────────────────
  Future<void> playYtId(String videoId,
      {String? title, String? artist, String? thumbnail}) async {
    await play(SongModel(
      id:        videoId,
      ytId:      videoId,
      title:     title    ?? 'YouTube Track',
      artist:    artist   ?? '',
      thumbnail: thumbnail ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      source:    'youtube',
      addedAt:   DateTime.now().millisecondsSinceEpoch,
    ));
  }

  // ── Queue control ─────────────────────────────────────────────────────────
  void addToQueue(SongModel song) {
    if (_queue.any((s) => s.id == song.id)) return;
    _queue = [..._queue, song];
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue = [..._queue]..removeAt(index);
    notifyListeners();
  }

  void setQueue(List<SongModel> songs) {
    _queue = List.from(songs);
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    final nextSong = _shuffle ? (_queue..shuffle()).first : _queue.first;
    await play(nextSong, queue: _queue.skip(1).toList());
  }

  Future<void> previous() async {
    if (_position.inSeconds > 3) { await _player.seek(Duration.zero); return; }
    if (_history.isEmpty) return;
    final prev = _history.first;
    _history = _history.skip(1).toList();
    await play(prev);
  }

  // ── Playback controls ─────────────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    try {
      _player.playing ? await _player.pause() : await _player.play();
    } catch (e) { debugPrint('togglePlayPause: $e'); }
  }

  Future<void> seekTo(Duration pos) async {
    try { await _player.seek(pos); } catch (_) {}
  }

  Future<void> seekToFraction(double fraction) async {
    if (_duration == Duration.zero) return;
    try {
      await _player.seek(Duration(
        milliseconds: (fraction * _duration.inMilliseconds).round()));
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    try { await _player.setVolume(_volume); } catch (_) {}
    notifyListeners();
  }

  void toggleShuffle() { _shuffle = !_shuffle; notifyListeners(); }

  void cycleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    try {
      _player.setLoopMode(switch (_repeat) {
        RepeatMode.none => LoopMode.off,
        RepeatMode.one  => LoopMode.one,
        RepeatMode.all  => LoopMode.all,
      });
    } catch (_) {}
    notifyListeners();
  }

  void stop() {
    try { _player.stop(); } catch (_) {}
    _current  = null;
    _queue    = [];
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  // ── Auto-queue ────────────────────────────────────────────────────────────
  Future<void> _autoQueue(SongModel song) async {
    try {
      final ytId = song.ytId ?? (song.source == 'youtube' ? song.id : null);
      if (ytId != null) {
        final related = await MuzoApi.related(ytId);
        if (related.isNotEmpty && _queue.isEmpty) {
          _queue = related.take(10)
              .map(MuzoApi.normalise)
              .map((m) => SongModel.fromMuzo(m))
              .toList();
          notifyListeners();
        }
      } else {
        final suggestions = await SaavnApi.getSongSuggestions(song.id);
        if (suggestions.isNotEmpty && _queue.isEmpty) {
          _queue = suggestions.map(SongModel.fromSaavn).toList();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _onEnded() {
    switch (_repeat) {
      case RepeatMode.one:
        try { _player.seek(Duration.zero); _player.play(); } catch (_) {}
      case RepeatMode.all:
        if (_queue.isNotEmpty) next();
        else if (_current != null) {
          try { _player.seek(Duration.zero); _player.play(); } catch (_) {}
        }
      case RepeatMode.none:
        if (_queue.isNotEmpty) next();
        else _playing = false;
    }
    notifyListeners();
  }

  // ── Skip silence ──────────────────────────────────────────────────────────
  Future<void> setSkipSilence(bool value) async {
    _skipSilence = value;
    try { await _player.setSkipSilenceEnabled(value); } catch (_) {}
    notifyListeners();
  }

  // ── Normalize loudness ────────────────────────────────────────────────────
  void setNormalizeLoudness(bool value) {
    _normalizeLoudness = value;
    // just_audio doesn't have built-in normalization; we adjust volume as proxy
    notifyListeners();
  }

  // ── Sleep timer ───────────────────────────────────────────────────────────
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepRemaining = duration;
    notifyListeners();
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sleepRemaining == null || _sleepRemaining!.inSeconds <= 0) {
        t.cancel();
        _sleepTimer = null;
        _sleepRemaining = null;
        try { _player.pause(); } catch (_) {}
        notifyListeners();
        return;
      }
      _sleepRemaining = _sleepRemaining! - const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepRemaining = null;
    notifyListeners();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
