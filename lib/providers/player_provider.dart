import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart';

import '../models/song_model.dart';
import '../api/saavn_api.dart';
import '../api/muzo_api.dart';
import '../api/saavn_api.dart' show SaavnApi;

enum PlayerSource { saavn, youtube }
enum RepeatMode   { none, one, all }

class PlayerProvider extends ChangeNotifier {
  // ── Audio player ──────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();

  // ── State ─────────────────────────────────────────────────────────────────
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

  // ── Getters ───────────────────────────────────────────────────────────────
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

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionStr => _fmt(_position);
  String get durationStr => _fmt(_duration);

  PlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    _player.playerStateStream.listen((state) {
      _playing = state.playing;
      if (state.processingState == ProcessingState.completed) _onEnded();
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) { _duration = dur; notifyListeners(); }
    });

    _player.playbackEventStream.listen((_) {}, onError: (e) {
      _error = 'Playback error: $e';
      notifyListeners();
    });
  }

  // ── Primary play entry ───────────────────────────────────────────────────
  /// Plays a song. Routes Saavn songs through YouTube Music first (better quality),
  /// falls back to Saavn stream URL if YouTube lookup fails.
  Future<void> play(SongModel song, {List<SongModel>? queue}) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    // Push current to history
    if (_current != null) {
      _history = [_current!, ..._history].take(50).toList();
    }
    _current = song;
    if (queue != null) _queue = queue.where((s) => s.id != song.id).toList();

    try {
      String? streamUrl;

      if (song.source == 'youtube' || song.ytId != null) {
        // ── YouTube path ─────────────────────────────────────────────────
        final ytId = song.ytId ?? song.id;
        streamUrl = await _resolveYtStream(ytId);
      } else {
        // ── Saavn path — try YouTube Music first ─────────────────────────
        final ytId = await MuzoApi.findVideoId(
          name: song.title, artist: song.artist,
        );
        if (ytId != null && ytId.isNotEmpty) {
          streamUrl = await _resolveYtStream(ytId);
          _current  = song.copyWith(ytId: ytId);
        }
        // Fallback to Saavn stream URL
        streamUrl ??= song.streamUrl ?? await _resolveSaavnStream(song.id);
      }

      if (streamUrl == null) throw Exception('No stream URL found');

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id:       song.id,
            title:    song.title,
            artist:   song.artist,
            album:    song.album ?? '',
            artUri:   song.thumbnail != null ? Uri.parse(song.thumbnail!) : null,
          ),
        ),
      );
      await _player.play();

      // Auto-queue related if queue is empty
      if (_queue.isEmpty) unawaited(_autoQueue(song));

    } catch (e) {
      _error = 'Could not play: ${song.title}';
    }

    _loading = false;
    notifyListeners();
  }

  // ── Play a YouTube video by ID ────────────────────────────────────────────
  Future<void> playYtId(String videoId,
      {String? title, String? artist, String? thumbnail}) async {
    final song = SongModel(
      id:        videoId,
      ytId:      videoId,
      title:     title    ?? 'YouTube Track',
      artist:    artist   ?? '',
      thumbnail: thumbnail ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      source:    'youtube',
      addedAt:   DateTime.now().millisecondsSinceEpoch,
    );
    await play(song);
  }

  // ── Queue control ─────────────────────────────────────────────────────────
  void addToQueue(SongModel song) {
    if (_queue.any((s) => s.id == song.id)) return;
    _queue = [..._queue, song];
    notifyListeners();
  }

  void removeFromQueue(int index) {
    _queue = [..._queue]..removeAt(index);
    notifyListeners();
  }

  void setQueue(List<SongModel> songs) {
    _queue = List.from(songs);
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    final next = _shuffle
        ? (_queue..shuffle()).first
        : _queue.first;
    await play(next, queue: _queue.skip(1).toList());
  }

  Future<void> previous() async {
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_history.isEmpty) return;
    final prev = _history.first;
    _history = _history.skip(1).toList();
    await play(prev);
  }

  // ── Playback controls ─────────────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (_player.playing) { await _player.pause(); }
    else                 { await _player.play();  }
  }

  Future<void> seekTo(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> seekToFraction(double fraction) async {
    if (_duration == Duration.zero) return;
    await _player.seek(Duration(
      milliseconds: (fraction * _duration.inMilliseconds).round(),
    ));
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void cycleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    _player.setLoopMode(switch (_repeat) {
      RepeatMode.none => LoopMode.off,
      RepeatMode.one  => LoopMode.one,
      RepeatMode.all  => LoopMode.all,
    });
    notifyListeners();
  }

  void stop() {
    _player.stop();
    _current  = null;
    _queue    = [];
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  void _onEnded() {
    switch (_repeat) {
      case RepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
      case RepeatMode.all:
        if (_queue.isNotEmpty) next();
        else if (_current != null) { _player.seek(Duration.zero); _player.play(); }
      case RepeatMode.none:
        if (_queue.isNotEmpty) next();
        else _playing = false;
    }
    notifyListeners();
  }

  Future<String?> _resolveYtStream(String videoId) async {
    // Try Muzo stream endpoint first
    final muzoUrl = await MuzoApi.streamUrl(videoId);
    if (muzoUrl != null) return muzoUrl;
    // Fallback: construct a direct YouTube embed audio URL
    // (some devices can play YouTube audio via manifest)
    return null;
  }

  Future<String?> _resolveSaavnStream(String songId) async {
    final song = await SaavnApi.getSongById(songId);
    if (song == null) return null;
    return SaavnApi.bestStreamUrl(song);
  }

  Future<void> _autoQueue(SongModel song) async {
    try {
      final ytId = song.ytId ?? (song.source == 'youtube' ? song.id : null);
      if (ytId != null) {
        final related = await MuzoApi.related(ytId);
        if (related.isNotEmpty && _queue.isEmpty) {
          _queue = related.take(10).map(MuzoApi.normalise)
              .map((m) => SongModel.fromMuzo(m)).toList();
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

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
