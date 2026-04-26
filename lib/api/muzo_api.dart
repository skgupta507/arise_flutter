import 'package:dio/dio.dart';

/// Muzo backend API — mirrors lib/muzo.js from the web app
/// Powers all YouTube Music features: search, trending, related, albums, artists
class MuzoApi {
  static const _base = 'https://Muzo-backend.vercel.app';
  static final _dio = Dio(BaseOptions(
    baseUrl:        _base,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
  ));

  // ── Search ────────────────────────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> search(
      String query, {String filter='', int limit=20}) async {
    try {
      final params = <String,dynamic>{'q': query, 'limit': limit};
      if (filter.isNotEmpty) params['filter'] = filter;
      final r = await _dio.get('/api/search', queryParameters: params);
      return _list(r.data['results'] ?? r.data['data']);
    } catch (_) { return []; }
  }

  static Future<List<String>> suggestions(String query) async {
    try {
      final r = await _dio.get('/api/search/suggestions',
          queryParameters: {'q': query, 'music': '1'});
      final s = r.data['suggestions'];
      if (s is List) return s.map((e) => e.toString()).toList();
      return [];
    } catch (_) { return []; }
  }

  // ── Trending ──────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>> trending() async {
    try {
      final r = await _dio.get('/api/trending');
      return Map<String,dynamic>.from(r.data is Map ? r.data : {});
    } catch (_) { return {}; }
  }

  // ── Related / autoqueue ───────────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> related(String videoId) async {
    try {
      final r = await _dio.get('/api/related/$videoId');
      return _list(r.data['results'] ?? r.data);
    } catch (_) { return []; }
  }

  // ── Similar (by title+artist) ─────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> similar(
      {required String title, required String artist, int limit=10}) async {
    try {
      final r = await _dio.get('/api/similar',
          queryParameters: {'title': title, 'artist': artist, 'limit': limit});
      return _list(r.data['results'] ?? r.data['data'] ?? r.data);
    } catch (_) { return []; }
  }

  // ── Albums ────────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> album(String browseId) async {
    try {
      final r = await _dio.get('/api/album/$browseId');
      return r.data is Map ? Map<String,dynamic>.from(r.data) : null;
    } catch (_) { return null; }
  }

  // ── Artists ───────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> artist(String browseId) async {
    try {
      final r = await _dio.get('/api/artists/$browseId');
      return r.data is Map ? Map<String,dynamic>.from(r.data) : null;
    } catch (_) { return null; }
  }

  // ── Playlists ─────────────────────────────────────────────────────────────
  static Future<Map<String,dynamic>?> playlist(String playlistId) async {
    try {
      final r = await _dio.get('/api/playlist/$playlistId');
      return r.data is Map ? Map<String,dynamic>.from(r.data) : null;
    } catch (_) { return null; }
  }

  // ── Charts ────────────────────────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> charts({String country='IN'}) async {
    try {
      final r = await _dio.get('/api/charts', queryParameters: {'country': country});
      return _list(r.data['results'] ?? r.data);
    } catch (_) { return []; }
  }

  // ── Moods ─────────────────────────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> moods() async {
    try {
      final r = await _dio.get('/api/moods');
      return _list(r.data['data'] ?? r.data);
    } catch (_) { return []; }
  }

  static Future<List<Map<String,dynamic>>> moodPlaylists(String categoryId) async {
    try {
      final r = await _dio.get('/api/moods/$categoryId');
      return _list(r.data['data'] ?? r.data);
    } catch (_) { return []; }
  }

  // ── Stream URL (audio only via Muzo) ──────────────────────────────────────
  static Future<String?> streamUrl(String videoId) async {
    try {
      final r = await _dio.get('/api/stream/$videoId');
      // Adaptive formats — pick best audio
      final formats = r.data['adaptiveFormats'] as List? ?? [];
      final audio = formats.where((f) =>
        f['type']?.toString().contains('audio') == true &&
        (f['type']?.toString().contains('mp4') == true ||
         f['type']?.toString().contains('webm') == true)
      ).toList();
      if (audio.isEmpty) return null;
      // Sort by bitrate descending
      audio.sort((a, b) {
        final aBr = int.tryParse(a['bitrate']?.toString() ?? '0') ?? 0;
        final bBr = int.tryParse(b['bitrate']?.toString() ?? '0') ?? 0;
        return bBr.compareTo(aBr);
      });
      return audio.first['url'] as String?;
    } catch (_) { return null; }
  }

  // ── Find YouTube Music ID for a song ─────────────────────────────────────
  static Future<String?> findVideoId(
      {required String name, required String artist}) async {
    try {
      final r = await _dio.get('/api/music/find',
          queryParameters: {'name': name, 'artist': artist});
      return r.data['videoId'] as String?;
    } catch (_) { return null; }
  }

  // ── Podcast search ────────────────────────────────────────────────────────
  static Future<List<Map<String,dynamic>>> searchPodcasts(String query) async {
    try {
      final results = await search(query, filter: 'podcasts', limit: 12);
      if (results.isNotEmpty) return results;
      return await search(query, filter: 'videos', limit: 12);
    } catch (_) { return []; }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static List<Map<String,dynamic>> _list(dynamic d) {
    if (d is List) return d.map((e) => Map<String,dynamic>.from(e as Map)).toList();
    return [];
  }

  /// Extract the best available thumbnail URL from a Muzo item
  static String? thumbnail(Map<String,dynamic> item, {int size=1}) {
    final t = item['thumbnails'];
    if (t is List && t.isNotEmpty) {
      final idx = size.clamp(0, t.length - 1);
      return t[idx]['url'] as String? ?? t.last['url'] as String?;
    }
    final id = item['videoId'] ?? item['id'];
    if (id != null) return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
    return null;
  }

  /// Normalise a Muzo item into a common track map
  static Map<String,dynamic> normalise(Map<String,dynamic> item) {
    final artists = (item['artists'] as List?)
        ?.map((a) => a['name']?.toString() ?? a.toString())
        .join(', ') ?? '';
    return {
      'id':           item['videoId'] ?? item['id'] ?? '',
      'ytId':         item['videoId'] ?? item['id'] ?? '',
      'title':        item['title']   ?? item['name'] ?? '',
      'artist':       artists.isNotEmpty ? artists : (item['author'] ?? item['channelTitle'] ?? ''),
      'thumbnail':    thumbnail(item),
      'duration':     item['duration'] ?? '',
      'source':       'youtube',
    };
  }
}
