import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// JioSaavn API — base: https://jiosavan-ytify.vercel.app/api/
class SaavnApi {
  static const _base = 'https://jiosavan-ytify.vercel.app/api/';

  static final _dio = Dio(BaseOptions(
    baseUrl:        _base,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
  ));

  // ── Search ──────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> searchSongs(
      String query, {int page = 1, int limit = 20}) async {
    try {
      final r = await _dio.get('search/songs', queryParameters: {
        'query': query, 'page': page, 'limit': limit,
      });
      final data = r.data is Map ? r.data['data'] : null;
      return _list(data?['results']);
    } catch (e) {
      debugPrint('SaavnApi.searchSongs error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchAlbums(
      String query, {int page = 1, int limit = 20}) async {
    try {
      final r = await _dio.get('search/albums', queryParameters: {
        'query': query, 'page': page, 'limit': limit,
      });
      final data = r.data is Map ? r.data['data'] : null;
      return _list(data?['results']);
    } catch (e) {
      debugPrint('SaavnApi.searchAlbums error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchArtists(
      String query, {int page = 1, int limit = 20}) async {
    try {
      final r = await _dio.get('search/artists', queryParameters: {
        'query': query, 'page': page, 'limit': limit,
      });
      final data = r.data is Map ? r.data['data'] : null;
      return _list(data?['results']);
    } catch (e) {
      debugPrint('SaavnApi.searchArtists error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchPlaylists(
      String query, {int page = 1, int limit = 20}) async {
    try {
      final r = await _dio.get('search/playlists', queryParameters: {
        'query': query, 'page': page, 'limit': limit,
      });
      final data = r.data is Map ? r.data['data'] : null;
      return _list(data?['results']);
    } catch (e) {
      debugPrint('SaavnApi.searchPlaylists error: $e');
      return [];
    }
  }

  // ── Songs ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getSongById(String id) async {
    try {
      final r = await _dio.get('songs/$id');
      final data = r.data is Map ? r.data['data'] : null;
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data[0] as Map);
      }
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e) {
      debugPrint('SaavnApi.getSongById error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSongsByIds(
      List<String> ids) async {
    try {
      final r = await _dio.get('songs', queryParameters: {'ids': ids.join(',')});
      return _list(r.data is Map ? r.data['data'] : null);
    } catch (e) {
      debugPrint('SaavnApi.getSongsByIds error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSongSuggestions(
      String id, {int limit = 10}) async {
    try {
      final r = await _dio.get('songs/$id/suggestions',
          queryParameters: {'limit': limit});
      return _list(r.data is Map ? r.data['data'] : null);
    } catch (e) {
      debugPrint('SaavnApi.getSongSuggestions error: $e');
      return [];
    }
  }

  // ── Albums ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getAlbumById(String id) async {
    try {
      final r = await _dio.get('albums', queryParameters: {'id': id});
      return _map(r.data is Map ? r.data['data'] : null);
    } catch (e) {
      debugPrint('SaavnApi.getAlbumById error: $e');
      return null;
    }
  }

  // ── Artists ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getArtistById(String id,
      {int page = 1, int songCount = 10, int albumCount = 10}) async {
    try {
      final r = await _dio.get('artists/$id', queryParameters: {
        'page': page, 'songCount': songCount, 'albumCount': albumCount,
      });
      return _map(r.data is Map ? r.data['data'] : null);
    } catch (e) {
      debugPrint('SaavnApi.getArtistById error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getArtistSongs(String id,
      {int page = 1}) async {
    try {
      final r = await _dio.get('artists/$id/songs', queryParameters: {
        'page': page, 'sortBy': 'popularity', 'sortOrder': 'desc',
      });
      final data = r.data is Map ? r.data['data'] : null;
      return _list(data?['results'] ?? data);
    } catch (e) {
      debugPrint('SaavnApi.getArtistSongs error: $e');
      return [];
    }
  }

  // ── Playlists ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getPlaylistById(String id) async {
    try {
      final r = await _dio.get('playlists', queryParameters: {'id': id});
      return _map(r.data is Map ? r.data['data'] : null);
    } catch (e) {
      debugPrint('SaavnApi.getPlaylistById error: $e');
      return null;
    }
  }

  // ── Best stream URL from a song object ───────────────────────────────────
  static String? bestStreamUrl(Map<String, dynamic> song) {
    final urls = song['downloadUrl'];
    if (urls is! List || urls.isEmpty) return null;
    const order = {'320kbps': 0, '160kbps': 1, '96kbps': 2, '48kbps': 3, '12kbps': 4};
    final sorted = List.from(urls)
      ..sort((a, b) =>
          (order[a['quality']] ?? 5).compareTo(order[b['quality']] ?? 5));
    return sorted.first['url'] as String?;
  }

  /// Best thumbnail URL from image array
  static String? bestImage(dynamic images, {int size = 2}) {
    if (images is! List || images.isEmpty) return null;
    final idx = size.clamp(0, images.length - 1);
    return images[idx]['url'] as String? ?? images.last['url'] as String?;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _list(dynamic d) {
    if (d is List) {
      return d
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  static Map<String, dynamic>? _map(dynamic d) {
    if (d is Map) return Map<String, dynamic>.from(d);
    return null;
  }
}
