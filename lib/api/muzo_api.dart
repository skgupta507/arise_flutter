import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Muzo backend API — base: https://muzo-backendx.vercel.app
/// Powers YouTube Music features: search, trending, related, stream, etc.
class MuzoApi {
  static const _base = 'https://muzo-backendx.vercel.app';

  static final _dio = Dio(BaseOptions(
    baseUrl:        _base,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // ── Search ────────────────────────────────────────────────────────────────
  /// filter: songs | videos | albums | artists | playlists
  static Future<List<Map<String, dynamic>>> search(
      String query, {String filter = '', int limit = 20}) async {
    try {
      final params = <String, dynamic>{'q': query, 'limit': limit};
      if (filter.isNotEmpty) params['filter'] = filter;
      final r = await _dio.get('/api/search', queryParameters: params);
      return _list(r.data['results'] ?? r.data['data'] ?? r.data);
    } catch (e) {
      debugPrint('MuzoApi.search error: $e');
      return [];
    }
  }

  static Future<List<String>> suggestions(String query) async {
    try {
      final r = await _dio.get('/api/search/suggestions',
          queryParameters: {'q': query, 'music': '1'});
      final s = r.data['suggestions'];
      if (s is List) return s.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('MuzoApi.suggestions error: $e');
      return [];
    }
  }

  // ── Trending ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> trending() async {
    try {
      final r = await _dio.get('/api/trending');
      // Response: { success, data: { songs, videos, playlists } }
      final data = r.data['data'] ?? r.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } catch (e) {
      debugPrint('MuzoApi.trending error: $e');
      return {};
    }
  }

  // ── Related ───────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> related(String videoId) async {
    try {
      final r = await _dio.get('/api/related/$videoId');
      return _list(r.data['data'] ?? r.data['results'] ?? r.data);
    } catch (e) {
      debugPrint('MuzoApi.related error: $e');
      return [];
    }
  }

  // ── Similar ───────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> similar(
      {required String title, required String artist, int limit = 10}) async {
    try {
      final r = await _dio.get('/api/similar', queryParameters: {
        'title': title, 'artist': artist, 'limit': limit,
      });
      return _list(r.data['results'] ?? r.data['data'] ?? r.data);
    } catch (e) {
      debugPrint('MuzoApi.similar error: $e');
      return [];
    }
  }

  // ── Stream URL ────────────────────────────────────────────────────────────
  /// Returns best audio URL from Invidious stream data.
  /// Priority: streamingUrls (Saavn) → adaptiveFormats (audio) → formatStreams
  static Future<String?> streamUrl(String videoId) async {
    try {
      final r = await _dio.get('/api/stream/$videoId');
      final data = r.data;
      if (data == null) return null;

      // Saavn streaming URLs (highest priority)
      final streamingUrls = data['streamingUrls'] as List?;
      if (streamingUrls != null && streamingUrls.isNotEmpty) {
        final best = streamingUrls.firstWhere(
          (u) => u['quality'] == '320kbps',
          orElse: () => streamingUrls.firstWhere(
            (u) => u['quality'] == '160kbps',
            orElse: () => streamingUrls.first,
          ),
        );
        if (best['url'] != null) return best['url'] as String;
      }

      // Adaptive formats (audio-only)
      final adaptive = data['adaptiveFormats'] as List?;
      if (adaptive != null && adaptive.isNotEmpty) {
        final audio = adaptive
            .where((f) =>
                f['type']?.toString().contains('audio') == true && f['url'] != null)
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

      // Format streams (muxed)
      final formats = data['formatStreams'] as List?;
      if (formats != null && formats.isNotEmpty) {
        final sorted = formats.where((f) => f['url'] != null).toList()
          ..sort((a, b) {
            final aq = int.tryParse(
                    a['quality']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
                0;
            final bq = int.tryParse(
                    b['quality']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
                0;
            return bq.compareTo(aq);
          });
        if (sorted.isNotEmpty) return sorted.first['url'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('MuzoApi.streamUrl error: $e');
      return null;
    }
  }

  // ── Find YouTube Music ID ─────────────────────────────────────────────────
  static Future<String?> findVideoId(
      {required String name, required String artist}) async {
    try {
      final r = await _dio.get('/api/music/find',
          queryParameters: {'name': name, 'artist': artist});
      final data = r.data['data'] ?? r.data;
      return (data is Map)
          ? (data['videoId'] ?? data['id'])?.toString()
          : null;
    } catch (e) {
      debugPrint('MuzoApi.findVideoId error: $e');
      return null;
    }
  }

  // ── Podcast search ────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> searchPodcasts(String query) async {
    try {
      final results = await search(query, filter: 'podcasts', limit: 12);
      if (results.isNotEmpty) return results;
      return await search(query, filter: 'videos', limit: 12);
    } catch (e) {
      debugPrint('MuzoApi.searchPodcasts error: $e');
      return [];
    }
  }

  // ── Charts ────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> charts({String country = 'IN'}) async {
    try {
      final r = await _dio.get('/api/charts', queryParameters: {'country': country});
      return _list(r.data['results'] ?? r.data['data'] ?? r.data);
    } catch (e) {
      debugPrint('MuzoApi.charts error: $e');
      return [];
    }
  }

  // ── Moods ─────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> moods() async {
    try {
      final r = await _dio.get('/api/moods');
      return _list(r.data['data'] ?? r.data);
    } catch (e) {
      debugPrint('MuzoApi.moods error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> moodPlaylists(
      String categoryId) async {
    try {
      final r = await _dio.get('/api/moods/$categoryId');
      return _list(r.data['data'] ?? r.data);
    } catch (e) {
      debugPrint('MuzoApi.moodPlaylists error: $e');
      return [];
    }
  }

  // ── Album & Playlist ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> album(String browseId) async {
    try {
      final r = await _dio.get('/api/album/$browseId');
      final d = r.data['album'] ?? r.data;
      return d is Map ? Map<String, dynamic>.from(d) : null;
    } catch (e) {
      debugPrint('MuzoApi.album error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> playlist(String playlistId) async {
    try {
      final r = await _dio.get('/api/playlist/$playlistId');
      final d = r.data['playlist'] ?? r.data;
      return d is Map ? Map<String, dynamic>.from(d) : null;
    } catch (e) {
      debugPrint('MuzoApi.playlist error: $e');
      return null;
    }
  }

  // ── Artist ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> artist(String browseId) async {
    try {
      final r = await _dio.get('/api/artists/$browseId');
      return r.data is Map ? Map<String, dynamic>.from(r.data) : null;
    } catch (e) {
      debugPrint('MuzoApi.artist error: $e');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _list(dynamic d) {
    if (d is List) {
      return d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Extract best thumbnail URL from a Muzo item
  static String? thumbnail(Map<String, dynamic> item, {int size = 1}) {
    final t = item['thumbnails'];
    if (t is List && t.isNotEmpty) {
      final idx = size.clamp(0, t.length - 1);
      return t[idx]['url']?.toString() ?? t.last['url']?.toString();
    }
    final id = item['videoId'] ?? item['id'];
    if (id != null) return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
    return null;
  }

  /// Normalise a Muzo item into a common track map
  static Map<String, dynamic> normalise(Map<String, dynamic> item) {
    final artists = (item['artists'] as List?)
            ?.map((a) => a['name']?.toString() ?? a.toString())
            .join(', ') ??
        item['artist']?.toString() ??
        item['author']?.toString() ??
        item['channelTitle']?.toString() ??
        '';
    final id = item['videoId']?.toString() ?? item['id']?.toString() ?? '';
    return {
      'id':        id,
      'ytId':      id,
      'title':     item['title']?.toString() ?? item['name']?.toString() ?? '',
      'artist':    artists,
      'thumbnail': thumbnail(item) ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      'duration':  item['duration']?.toString() ?? '',
      'source':    'youtube',
    };
  }
}
