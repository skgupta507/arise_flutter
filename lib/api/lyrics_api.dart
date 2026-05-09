import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/lyric_line.dart';

class LyricsApi {
  static const _base = 'https://lrclib.net/api';

  /// Fetch synced lyrics from lrclib.net.
  /// Returns null if not found or on error.
  static Future<List<LyricLine>?> fetchSynced({
    required String artist,
    required String title,
    String? album,
    int? durationSec,
  }) async {
    try {
      final params = <String, String>{
        'artist_name': artist,
        'track_name':  title,
        if (album != null && album.isNotEmpty) 'album_name': album,
        if (durationSec != null) 'duration': durationSec.toString(),
      };
      final uri  = Uri.parse('$_base/get').replace(queryParameters: params);
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data   = jsonDecode(resp.body) as Map<String, dynamic>;
      final synced = data['syncedLyrics'] as String?;
      if (synced == null || synced.isEmpty) return null;
      return _parseLrc(synced);
    } catch (e) {
      debugPrint('LyricsApi.fetchSynced error: $e');
      return null;
    }
  }

  /// Parse LRC format: [mm:ss.xx] line text
  static List<LyricLine> _parseLrc(String lrc) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$');
    for (final raw in lrc.split('\n')) {
      final match = regex.firstMatch(raw.trim());
      if (match == null) continue;
      final min   = int.parse(match.group(1)!);
      final sec   = int.parse(match.group(2)!);
      final msRaw = match.group(3)!;
      final ms    = msRaw.length == 2
          ? int.parse(msRaw) * 10
          : int.parse(msRaw);
      final text  = match.group(4)!.trim();
      lines.add(LyricLine(
        time: Duration(minutes: min, seconds: sec, milliseconds: ms),
        text: text,
      ));
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
