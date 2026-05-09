import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/song_model.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class QrShareSheet extends StatelessWidget {
  final SongModel song;
  const QrShareSheet({super.key, required this.song});

  static void show(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QrShareSheet(song: song),
    );
  }

  String get _shareUrl {
    if (song.source == 'youtube' || song.ytId != null) {
      final id = song.ytId ?? song.id;
      return 'https://youtube.com/watch?v=$id';
    }
    return 'https://www.jiosaavn.com/song/${song.id}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonCard    : AriseColors.angelCard;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;
    final url     = _shareUrl;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: textMut.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text('Share Song', style: TextStyle(
            fontFamily: 'Orbitron', color: textPri,
            fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(song.title, style: TextStyle(
            fontFamily: 'Rajdhani', color: textMut, fontSize: 13),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // URL text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(url,
              style: TextStyle(fontFamily: 'Rajdhani', color: accent, fontSize: 11),
              textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Share.share(
                  '🎵 ${song.title} by ${song.artist}\n$url',
                  subject: song.title,
                );
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
