import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song_model.dart';

class DownloadService {
  static const _boxName = 'arise_cache';
  static final Dio _dio = Dio();

  static Box get _box => Hive.box(_boxName);

  // ── Check if song is cached ───────────────────────────────────────────────
  static String? getCachedPath(String songId) {
    final path = _box.get(songId) as String?;
    if (path == null) return null;
    if (File(path).existsSync()) return path;
    // File was deleted externally — clean up
    _box.delete(songId);
    return null;
  }

  static bool isCached(String songId) => getCachedPath(songId) != null;

  // ── Download a song ───────────────────────────────────────────────────────
  static Future<String?> download(
    SongModel song,
    String streamUrl, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/arise_songs');
      if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);

      // Sanitize filename
      final safeName = song.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      final filePath = '${cacheDir.path}/${song.id}_$safeName.mp3';

      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          headers: {'User-Agent': 'AriseMusic/1.0'},
        ),
      );

      await _box.put(song.id, filePath);
      return filePath;
    } catch (e) {
      debugPrint('DownloadService.download error: $e');
      return null;
    }
  }

  // ── Delete a cached song ──────────────────────────────────────────────────
  static Future<void> deleteCached(String songId) async {
    final path = _box.get(songId) as String?;
    if (path != null) {
      try { File(path).deleteSync(); } catch (_) {}
      await _box.delete(songId);
    }
  }

  // ── Get total cache size in bytes ─────────────────────────────────────────
  static Future<int> getCacheSize() async {
    int total = 0;
    for (final key in _box.keys) {
      final path = _box.get(key) as String?;
      if (path != null) {
        try {
          final f = File(path);
          if (f.existsSync()) total += f.lengthSync();
        } catch (_) {}
      }
    }
    return total;
  }

  // ── Clear all cached songs ────────────────────────────────────────────────
  static Future<void> clearAll() async {
    for (final key in List.from(_box.keys)) {
      await deleteCached(key as String);
    }
  }

  // ── Count cached songs ────────────────────────────────────────────────────
  static int get cachedCount => _box.length;

  // ── Format bytes to human-readable ───────────────────────────────────────
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
