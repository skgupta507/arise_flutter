import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/saavn_api.dart';
import '../api/muzo_api.dart';
import '../models/song_model.dart';

class SearchProvider extends ChangeNotifier {
  String              _query       = '';
  List<String>        _suggestions = [];
  List<SongModel>     _songs       = [];
  List<Map<String,dynamic>> _albums    = [];
  List<Map<String,dynamic>> _artists   = [];
  List<Map<String,dynamic>> _ytResults = [];
  bool                _loading     = false;
  String              _tab         = 'all';  // all | songs | albums | artists | yt
  Timer?              _debounce;

  String              get query       => _query;
  List<String>        get suggestions => List.unmodifiable(_suggestions);
  List<SongModel>     get songs       => List.unmodifiable(_songs);
  List<Map<String,dynamic>> get albums   => List.unmodifiable(_albums);
  List<Map<String,dynamic>> get artists  => List.unmodifiable(_artists);
  List<Map<String,dynamic>> get ytResults=> List.unmodifiable(_ytResults);
  bool                get loading     => _loading;
  String              get tab         => _tab;
  bool                get hasResults  =>
      _songs.isNotEmpty || _albums.isNotEmpty || _artists.isNotEmpty || _ytResults.isNotEmpty;

  void setTab(String t) { _tab = t; notifyListeners(); }

  void onQueryChanged(String q) {
    _query = q;
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(q);
    });
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _query   = query;
    _loading = true;
    _songs   = [];
    _albums  = [];
    _artists = [];
    _ytResults = [];
    notifyListeners();

    await Future.wait([
      _searchSongs(query),
      _searchAlbums(query),
      _searchArtists(query),
      _searchYT(query),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchSuggestions(String q) async {
    _suggestions = await MuzoApi.suggestions(q);
    notifyListeners();
  }

  Future<void> _searchSongs(String q) async {
    final saavn = await SaavnApi.searchSongs(q, limit: 20);
    _songs = saavn.map(SongModel.fromSaavn).toList();
  }

  Future<void> _searchAlbums(String q) async {
    _albums = await SaavnApi.searchAlbums(q, limit: 12);
  }

  Future<void> _searchArtists(String q) async {
    _artists = await SaavnApi.searchArtists(q);
  }

  Future<void> _searchYT(String q) async {
    final yt = await MuzoApi.search(q, filter: 'songs', limit: 15);
    _ytResults = yt;
  }

  void clear() {
    _query       = '';
    _suggestions = [];
    _songs       = [];
    _albums      = [];
    _artists     = [];
    _ytResults   = [];
    _loading     = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
