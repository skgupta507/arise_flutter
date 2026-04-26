import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/song_model.dart';
import '../models/playlist_model.dart';

class LibraryProvider extends ChangeNotifier {
  late Box _likedBox;
  late Box _playlists;
  late Box _recent;

  List<SongModel>    _liked     = [];
  List<PlaylistModel>_userPls   = [];
  List<SongModel>    _history   = [];

  List<SongModel>    get liked      => List.unmodifiable(_liked);
  List<PlaylistModel>get playlists  => List.unmodifiable(_userPls);
  List<SongModel>    get recentlyPlayed => List.unmodifiable(_history);
  int                get likedCount => _liked.length;
  int                get plCount    => _userPls.length;

  LibraryProvider() { _init(); }

  Future<void> _init() async {
    _likedBox  = Hive.box('arise_liked');
    _playlists = Hive.box('arise_playlists');
    _recent    = Hive.box('arise_recent');
    _load();
  }

  void _load() {
    // Liked songs
    _liked = (_likedBox.get('songs', defaultValue: '[]') as String)
        .let((s) => (jsonDecode(s) as List)
            .map((j) => SongModel.fromSaavn(Map<String,dynamic>.from(j))).toList());

    // Playlists
    _userPls = (_playlists.get('all', defaultValue: '[]') as String)
        .let((s) => (jsonDecode(s) as List)
            .map((j) => PlaylistModel.fromJson(Map<String,dynamic>.from(j))).toList());

    // Recently played
    _history = (_recent.get('history', defaultValue: '[]') as String)
        .let((s) => (jsonDecode(s) as List)
            .map((j) => SongModel.fromSaavn(Map<String,dynamic>.from(j))).toList());

    notifyListeners();
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
    _likedBox.put('songs', jsonEncode(_liked.map((s) => s.toJson()).toList()));
  }

  // ── Recently played ───────────────────────────────────────────────────────
  void addToRecent(SongModel song) {
    _history = [song, ..._history.where((s) => s.id != song.id)].take(50).toList();
    _recent.put('history', jsonEncode(_history.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    _recent.delete('history');
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
    _playlists.put('all', jsonEncode(_userPls.map((p) => p.toJson()).toList()));
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

extension _ListExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
