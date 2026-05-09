import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/saavn_api.dart';
import '../api/muzo_api.dart';
import '../models/song_model.dart';

class SearchProvider extends ChangeNotifier {
  String                    _query       = '';
  List<String>              _suggestions = [];
  List<SongModel>           _songs       = [];
  List<Map<String, dynamic>> _albums     = [];
  List<Map<String, dynamic>> _artists    = [];
  List<SongModel>           _ytResults   = [];
  bool                      _loading     = false;
  Timer?                    _debounce;

  String                    get query      => _query;
  List<String>              get suggestions=> List.unmodifiable(_suggestions);
  List<SongModel>           get songs      => List.unmodifiable(_songs);
  List<Map<String, dynamic>> get albums    => List.unmodifiable(_albums);
  List<Map<String, dynamic>> get artists   => List.unmodifiable(_artists);
  List<SongModel>           get ytResults  => List.unmodifiable(_ytResults);
  bool                      get loading    => _loading;
  bool get hasResults =>
      _songs.isNotEmpty || _albums.isNotEmpty ||
      _artists.isNotEmpty || _ytResults.isNotEmpty;

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
    _query     = query;
    _loading   = true;
    _songs     = [];
    _albums    = [];
    _artists   = [];
    _ytResults = [];
    _suggestions = [];
    notifyListeners();

    await Future.wait([
      _searchSaavn(query),
      _searchYT(query),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchSuggestions(String q) async {
    try {
      _suggestions = await MuzoApi.suggestions(q);
      notifyListeners();
    } catch (e) {
      debugPrint('SearchProvider._fetchSuggestions: $e');
    }
  }

  Future<void> _searchSaavn(String q) async {
    try {
      final results = await Future.wait([
        SaavnApi.searchSongs(q, limit: 20),
        SaavnApi.searchAlbums(q, limit: 12),
        SaavnApi.searchArtists(q, limit: 12),
      ]);
      _songs   = (results[0])
          .map(SongModel.fromSaavn).toList();
      _albums  = results[1];
      _artists = results[2];
    } catch (e) {
      debugPrint('SearchProvider._searchSaavn: $e');
    }
  }

  Future<void> _searchYT(String q) async {
    try {
      final results = await MuzoApi.search(q, filter: 'songs', limit: 15);
      _ytResults = results.map((m) {
        final id = m['videoId']?.toString() ?? m['id']?.toString() ?? '';
        final thumbs = m['thumbnails'] as List?;
        final thumb  = thumbs != null && thumbs.isNotEmpty
            ? thumbs.last['url']?.toString()
            : 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
        final artists = (m['artists'] as List?)
                ?.map((a) => a['name']?.toString() ?? '').join(', ') ??
            m['artist']?.toString() ?? '';
        return SongModel(
          id:        id,
          ytId:      id,
          title:     m['title']?.toString() ?? '',
          artist:    artists,
          thumbnail: thumb ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
          source:    'youtube',
          addedAt:   DateTime.now().millisecondsSinceEpoch,
        );
      }).where((s) => s.id.isNotEmpty).toList();
    } catch (e) {
      debugPrint('SearchProvider._searchYT: $e');
    }
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
