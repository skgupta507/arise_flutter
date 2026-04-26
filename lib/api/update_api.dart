import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String tag;
  final String version;
  final String apkUrl;
  final String size;
  final String changelog;
  final String date;
  const UpdateInfo({
    required this.tag, required this.version, required this.apkUrl,
    required this.size, required this.changelog, required this.date,
  });
}

class UpdateApi {
  static const _owner   = 'skgupta507';
  static const _repo    = 'arise';
  static const _apkName = 'arise.apk';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds:12),
    receiveTimeout: const Duration(seconds:12),
    headers: {'Accept': 'application/vnd.github+json'},
  ));

  /// Check GitHub releases for a newer version.
  /// Returns null if up to date or on error.
  static Future<UpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      final r = await _dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
      );
      final json = r.data as Map<String,dynamic>;
      final tag  = json['tag_name']?.toString() ?? '';
      if (!_isNewer(tag, current)) return null;

      // Find APK asset
      final assets = (json['assets'] as List?) ?? [];
      String apkUrl = '';
      int apkBytes = 0;
      for (final a in assets) {
        if (a['name'] == _apkName) {
          apkUrl   = a['browser_download_url'] ?? '';
          apkBytes = a['size'] as int? ?? 0;
          break;
        }
      }
      if (apkUrl.isEmpty) return null;

      final sizeMB = (apkBytes / 1048576).toStringAsFixed(1);
      final date   = (json['published_at']?.toString() ?? '').replaceAll(RegExp(r'T.*'), '');
      final body   = json['body']?.toString() ?? 'See GitHub for details';

      return UpdateInfo(
        tag:       tag,
        version:   tag.replaceFirst(RegExp(r'^[vb]'), ''),
        apkUrl:    apkUrl,
        size:      '$sizeMB MB',
        changelog: body.length > 800 ? '${body.substring(0,800)}…' : body,
        date:      date,
      );
    } catch (_) { return null; }
  }

  /// Download APK and return the local file path.
  /// [onProgress] receives 0.0 – 1.0
  static Future<String?> downloadApk(
    UpdateInfo info, {
    void Function(double)? onProgress,
  }) async {
    try {
      final dir  = await getExternalStorageDirectory()
          ?? await getApplicationDocumentsDirectory();
      final dest = '${dir.path}/arise_update.apk';

      await _dio.download(
        info.apkUrl,
        dest,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );
      return dest;
    } catch (_) { return null; }
  }

  // ── version compare ────────────────────────────────────────────────────────
  static bool _isNewer(String latest, String current) {
    List<int> parse(String v) => v
        .replaceFirst(RegExp(r'^[vb]'), '')
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
    final l = parse(latest);
    final c = parse(current);
    final len = l.length > c.length ? l.length : c.length;
    for (int i = 0; i < len; i++) {
      final li = i < l.length ? l[i] : 0;
      final ci = i < c.length ? c[i] : 0;
      if (li > ci) return true;
      if (li < ci) return false;
    }
    return false;
  }
}
