import 'package:dio/dio.dart';

/// JioSaavn API wrapper — mirrors lib/fetch.js from the web app
class SaavnApi {
  static const _base = 'https://saavn.sumit.co/api/';
  static final _dio = Dio(BaseOptions(
    baseUrl:         _base,
    connectTimeout:  const Duration(seconds: 12),
    receiveTimeout:  const Duration(seconds: 20),
  ));

  // ── Search ──────────────────────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> searchSongs(
      String query, {int page=1, int limit=20}) async {
    try {
      final r = await _dio.get('search/songs', queryParameters:{
        'query': query, 'page': page, 'limit': limit,
      });
      final data = r.data['data'];
      return _list(data?['results']);
    } catch (_) { return []; }
  }

  static Future<List<Map<String,dynamic>>> searchAlbums(
      String query, {int limit=20}) async {
    try {
      final r = await _dio.get('search/albums', queryParameters:{
        'query': query, 'limit': limit,
      });
      return _list(r.data['data']?['results']);
    } catch (_) { return []; }
  }

  static Future<List<Map<String,dynamic>>> searchArtists(String query) async {
    try {
      final r = await _dio.get('search/artists', queryParameters:{'query': query});
      return _list(r.data['data']?['results']);
    } catch (_) { return []; }
  }

  static Future<List<Map<String,dynamic>>> searchPlaylists(String query) async {
    try {
      final r = await _dio.get('search/playlists', queryParameters:{'query': query});
      return _list(r.data['data']?['results']);
    } catch (_) { return []; }
  }

  // ── Songs ───────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> getSongById(String id) async {
    try {
      final r = await _dio.get('songs/$id');
      final list = r.data['data'];
      if (list is List && list.isNotEmpty) return Map<String,dynamic>.from(list[0]);
      return null;
    } catch (_) { return null; }
  }

  static Future<List<Map<String,dynamic>>> getSongsByIds(List<String> ids) async {
    try {
      final r = await _dio.get('songs', queryParameters:{'ids': ids.join(',')});
      return _list(r.data['data']);
    } catch (_) { return []; }
  }

  static Future<List<Map<String,dynamic>>> getSongSuggestions(
      String id, {int limit=10}) async {
    try {
      final r = await _dio.get('songs/$id/suggestions', queryParameters:{'limit':limit});
      return _list(r.data['data']);
    } catch (_) { return []; }
  }

  static Future<List<Map<String,dynamic>>> getTrendingSongs({int limit=20}) async {
    try {
      final r = await _dio.get('search/songs', queryParameters:{
        'query': 'trending hits india 2025', 'limit': limit,
      });
      return _list(r.data['data']?['results']);
    } catch (_) { return []; }
  }

  // ── Albums ──────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> getAlbumById(String id) async {
    try {
      final r = await _dio.get('albums', queryParameters:{'id': id});
      return _map(r.data['data']);
    } catch (_) { return null; }
  }

  static Future<List<Map<String,dynamic>>> getNewReleases({int limit=20}) async {
    try {
      final r = await _dio.get('search/albums', queryParameters:{
        'query': 'new hindi album 2025', 'limit': limit,
      });
      return _list(r.data['data']?['results']);
    } catch (_) { return []; }
  }

  // ── Artists ─────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> getArtistById(String id) async {
    try {
      final r = await _dio.get('artists/$id');
      return _map(r.data['data']);
    } catch (_) { return null; }
  }

  static Future<List<Map<String,dynamic>>> getArtistSongs(
      String id, {int limit=20}) async {
    try {
      final r = await _dio.get('artists/$id/songs', queryParameters:{'limit':limit});
      return _list(r.data['data']?['results']);
    } catch (_) { return []; }
  }

  // ── Playlists ────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> getPlaylistById(String id) async {
    try {
      final r = await _dio.get('playlists', queryParameters:{'id': id});
      return _map(r.data['data']);
    } catch (_) { return null; }
  }

  // ── Extract best stream URL from a song object ───────────────────────────
  static String? bestStreamUrl(Map<String,dynamic> song) {
    final urls = song['downloadUrl'];
    if (urls is! List || urls.isEmpty) return null;
    final sorted = List.from(urls)..sort((a,b) {
      const order = {'320kbps':0,'160kbps':1,'96kbps':2,'48kbps':3,'12kbps':4};
      return (order[a['quality']] ?? 5).compareTo(order[b['quality']] ?? 5);
    });
    return sorted.first['url'] as String?;
  }

  /// Best thumbnail URL from image array
  static String? bestImage(dynamic images, {int size=2}) {
    if (images is! List || images.isEmpty) return null;
    final idx = size.clamp(0, images.length-1);
    return images[idx]['url'] as String?
        ?? images.last['url'] as String?;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static List<Map<String,dynamic>> _list(dynamic d) {
    if (d is List) return d.map((e) => Map<String,dynamic>.from(e as Map)).toList();
    return [];
  }
  static Map<String,dynamic>? _map(dynamic d) {
    if (d is Map) return Map<String,dynamic>.from(d);
    return null;
  }
}
