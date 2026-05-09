import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/song_model.dart';
import '../models/playlist_model.dart';

class LibraryProvider extends ChangeNotifier {
  List<SongModel>     _liked   = [];
  List<PlaylistModel> _userPls = [];
  List<SongModel>     _history = [];

  List<SongModel>     get liked          => List.unmodifiable(_liked);
  List<PlaylistModel> get playlists      => List.unmodifiable(_userPls);
  List<SongModel>     get recentlyPlayed => List.unmodifiable(_history);
  int                 get likedCount     => _liked.length;
  int                 get plCount        => _userPls.length;

  LibraryProvider() {
    _load();
  }

  // ── Safe box accessors ────────────────────────────────────────────────────
  Box? get _likedBox  { try { return Hive.box('arise_liked');     } catch (_) { return null; } }
  Box? get _plsBox    { try { return Hive.box('arise_playlists'); } catch (_) { return null; } }
  Box? get _recentBox { try { return Hive.box('arise_recent');    } catch (_) { return null; } }

  void _load() {
    try {
      final likedStr = _likedBox?.get('songs',   defaultValue: '[]') as String? ?? '[]';
      final plsStr   = _plsBox?.get('all',       defaultValue: '[]') as String? ?? '[]';
      final histStr  = _recentBox?.get('history',defaultValue: '[]') as String? ?? '[]';
      _liked   = _parseSongs(likedStr);
      _userPls = _parsePlaylists(plsStr);
      _history = _parseSongs(histStr);
    } catch (e) {
      debugPrint('LibraryProvider._load error: $e');
      _liked   = [];
      _userPls = [];
      _history = [];
    }
    notifyListeners();
  }

  List<SongModel> _parseSongs(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .map((j) => SongModel.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) { return []; }
  }

  List<PlaylistModel> _parsePlaylists(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .map((j) => PlaylistModel.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) { return []; }
  }

  // ── Like / unlike ─────────────────────────────────────────────────────────
  bool isLiked(String id) => _liked.any((s) => s.id == id);

  void toggleLike(SongModel song) {
    if (isLiked(song.id)) {
      _liked = _liked.where((s) => s.id != song.id).toList();
    } else {
      _liked = [song, ..._liked];
    }
    _saveLiked();
    notifyListeners();
  }

  void _saveLiked() {
    try {
      _likedBox?.put('songs', jsonEncode(_liked.map((s) => s.toJson()).toList()));
    } catch (e) { debugPrint('_saveLiked error: $e'); }
  }

  // ── Recently played ───────────────────────────────────────────────────────
  void addToRecent(SongModel song) {
    _history = [song, ..._history.where((s) => s.id != song.id)].take(50).toList();
    try {
      _recentBox?.put('history', jsonEncode(_history.map((s) => s.toJson()).toList()));
    } catch (e) { debugPrint('addToRecent error: $e'); }
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    try { _recentBox?.delete('history'); } catch (_) {}
    notifyListeners();
  }

  // ── Playlists ─────────────────────────────────────────────────────────────
  PlaylistModel createPlaylist(String name) {
    final pl = PlaylistModel(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      name:      name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _userPls = [pl, ..._userPls];
    _savePlaylists();
    notifyListeners();
    return pl;
  }

  void renamePlaylist(String id, String name) {
    _userPls = _userPls.map((p) => p.id == id ? p.copyWith(name: name) : p).toList();
    _savePlaylists();
    notifyListeners();
  }

  void deletePlaylist(String id) {
    _userPls = _userPls.where((p) => p.id != id).toList();
    _savePlaylists();
    notifyListeners();
  }

  void addSongToPlaylist(String playlistId, SongModel song) {
    _userPls = _userPls.map((p) {
      if (p.id != playlistId) return p;
      if (p.songs.any((s) => s.id == song.id)) return p;
      return p.copyWith(songs: [...p.songs, song]);
    }).toList();
    _savePlaylists();
    notifyListeners();
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    _userPls = _userPls.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(songs: p.songs.where((s) => s.id != songId).toList());
    }).toList();
    _savePlaylists();
    notifyListeners();
  }

  void reorderPlaylist(String playlistId, int oldIdx, int newIdx) {
    _userPls = _userPls.map((p) {
      if (p.id != playlistId) return p;
      final songs = List<SongModel>.from(p.songs);
      final song  = songs.removeAt(oldIdx);
      songs.insert(newIdx, song);
      return p.copyWith(songs: songs);
    }).toList();
    _savePlaylists();
    notifyListeners();
  }

  PlaylistModel? getPlaylist(String id) =>
      _userPls.where((p) => p.id == id).firstOrNull;

  void _savePlaylists() {
    try {
      _plsBox?.put('all', jsonEncode(_userPls.map((p) => p.toJson()).toList()));
    } catch (e) { debugPrint('_savePlaylists error: $e'); }
  }
}
