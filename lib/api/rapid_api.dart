import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// RapidAPI yt-api.p.rapidapi.com wrapper with automatic key rotation.
/// Used as fallback stream resolver when Muzo stream endpoint fails.
class RapidApi {
  static const _base = 'https://yt-api.p.rapidapi.com';
  static const _host = 'yt-api.p.rapidapi.com';

  // Two keys provided — rotated on 429
  static const _keys = [
    '5332ac74f9msh544e1e9c6d6019dp141254jsn65d4fd6eca29',
    '771b89b911msh11007d4239b8317p11e18fjsncd79c24b8179',
  ];

  static int _keyIndex = 0;

  static String get _currentKey => _keys[_keyIndex % _keys.length];

  static void _rotateKey() {
    _keyIndex = (_keyIndex + 1) % _keys.length;
  }

  static Options _opts() => Options(headers: {
        'X-RapidAPI-Key':  _currentKey,
        'X-RapidAPI-Host': _host,
      });

  static final _dio = Dio(BaseOptions(
    baseUrl:        _base,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
  ));

  // ── Search ────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> search(String query,
      {String type = 'video'}) async {
    for (int attempt = 0; attempt < _keys.length; attempt++) {
      try {
        final r = await _dio.get('/search',
            queryParameters: {'query': query, 'type': type},
            options: _opts());
        final raw = r.data['data'] ?? r.data['items'] ?? r.data['results'] ?? [];
        return _list(raw);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          _rotateKey();
          continue;
        }
        debugPrint('RapidApi.search error: $e');
        return [];
      } catch (e) {
        debugPrint('RapidApi.search error: $e');
        return [];
      }
    }
    debugPrint('RapidApi: all keys rate-limited');
    return [];
  }

  // ── Video info (includes stream URLs on some endpoints) ───────────────────
  static Future<Map<String, dynamic>?> videoInfo(String videoId) async {
    for (int attempt = 0; attempt < _keys.length; attempt++) {
      try {
        final r = await _dio.get('/video/info',
            queryParameters: {'id': videoId}, options: _opts());
        return r.data is Map ? Map<String, dynamic>.from(r.data) : null;
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          _rotateKey();
          continue;
        }
        debugPrint('RapidApi.videoInfo error: $e');
        return null;
      } catch (e) {
        debugPrint('RapidApi.videoInfo error: $e');
        return null;
      }
    }
    return null;
  }

  // ── Trending music ────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> trending(
      {String geo = 'IN', String type = 'music'}) async {
    for (int attempt = 0; attempt < _keys.length; attempt++) {
      try {
        final r = await _dio.get('/trending',
            queryParameters: {'geo': geo, 'type': type}, options: _opts());
        final raw = r.data['data'] ?? r.data['items'] ?? [];
        return _list(raw);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          _rotateKey();
          continue;
        }
        debugPrint('RapidApi.trending error: $e');
        return [];
      } catch (e) {
        debugPrint('RapidApi.trending error: $e');
        return [];
      }
    }
    return [];
  }

  // ── Related videos ────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> related(String videoId) async {
    for (int attempt = 0; attempt < _keys.length; attempt++) {
      try {
        final r = await _dio.get('/related',
            queryParameters: {'id': videoId}, options: _opts());
        final raw = r.data['data'] ?? r.data['items'] ?? [];
        return _list(raw);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          _rotateKey();
          continue;
        }
        debugPrint('RapidApi.related error: $e');
        return [];
      } catch (e) {
        debugPrint('RapidApi.related error: $e');
        return [];
      }
    }
    return [];
  }

  // ── Normalise a RapidAPI item to SongModel-compatible map ─────────────────
  static Map<String, dynamic> normalise(Map<String, dynamic> raw) {
    final id = raw['videoId']?.toString() ?? raw['id']?.toString() ?? '';
    final thumbArr = raw['thumbnail']?['thumbnails'] as List? ??
        (raw['thumbnails'] is List ? raw['thumbnails'] as List : null) ??
        [];
    final thumb = thumbArr.isNotEmpty
        ? thumbArr.last['url']?.toString()
        : 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
    return {
      'id':        id,
      'ytId':      id,
      'title':     raw['title']?.toString() ?? '',
      'artist':    raw['channelTitle']?.toString() ?? raw['author']?.toString() ?? '',
      'thumbnail': thumb ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      'duration':  raw['lengthSeconds']?.toString() ?? '',
      'source':    'youtube',
    };
  }

  static List<Map<String, dynamic>> _list(dynamic d) {
    if (d is List) {
      return d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}
