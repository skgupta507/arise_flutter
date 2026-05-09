import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/song_model.dart';
import '../services/download_service.dart';
import '../api/saavn_api.dart';

class DownloadProvider extends ChangeNotifier {
  // songId -> progress (0.0 to 1.0), null means not downloading
  final Map<String, double> _progress = {};
  // songId -> error message
  final Map<String, String> _errors = {};

  double? getProgress(String songId) => _progress[songId];
  bool isDownloading(String songId) => _progress.containsKey(songId);
  bool isDownloaded(String songId) => DownloadService.isCached(songId);
  String? getError(String songId) => _errors[songId];

  String? getLocalPath(String songId) => DownloadService.getCachedPath(songId);

  Future<void> download(SongModel song) async {
    if (_progress.containsKey(song.id)) return; // already downloading
    if (DownloadService.isCached(song.id)) return; // already downloaded

    _progress[song.id] = 0.0;
    _errors.remove(song.id);
    notifyListeners();

    try {
      // Resolve stream URL
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        final data = await SaavnApi.getSongById(song.id);
        if (data != null) {
          streamUrl = SaavnApi.bestStreamUrl(data);
        }
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        _errors[song.id] = 'Could not resolve stream URL';
        _progress.remove(song.id);
        notifyListeners();
        return;
      }

      final path = await DownloadService.download(
        song,
        streamUrl,
        onProgress: (p) {
          _progress[song.id] = p;
          notifyListeners();
        },
      );

      if (path == null) {
        _errors[song.id] = 'Download failed';
      }
    } catch (e) {
      _errors[song.id] = 'Download error: $e';
      debugPrint('DownloadProvider.download error: $e');
    }

    _progress.remove(song.id);
    notifyListeners();
  }

  Future<void> deleteDownload(String songId) async {
    await DownloadService.deleteCached(songId);
    _progress.remove(songId);
    _errors.remove(songId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await DownloadService.clearAll();
    _progress.clear();
    _errors.clear();
    notifyListeners();
  }

  Future<String> getCacheSizeFormatted() async {
    final bytes = await DownloadService.getCacheSize();
    return DownloadService.formatBytes(bytes);
  }

  int get downloadedCount {
    // Count entries in the Hive box
    try {
      return DownloadService.cachedCount;
    } catch (_) {
      return 0;
    }
  }
}
