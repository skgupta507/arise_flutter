import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/lyrics_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scroll = ScrollController();
  int _lastIndex = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCurrent(int index, int total) {
    if (!_scroll.hasClients || index < 0) return;
    // Each line is approximately 56px tall
    const lineHeight = 56.0;
    final offset = (index * lineHeight) - (MediaQuery.of(context).size.height * 0.3);
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final player   = context.watch<PlayerProvider>();
    final lyrics   = context.watch<LyricsProvider>();
    final accent   = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textPri  = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub  = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut  = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    // Load lyrics when song changes
    final song = player.current;
    if (song != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lyrics.loadLyrics(song);
      });
    }

    // Auto-scroll when current line changes
    if (lyrics.currentIndex != _lastIndex) {
      _lastIndex = lyrics.currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrent(lyrics.currentIndex, lyrics.lines.length);
      });
    }

    if (lyrics.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accent, strokeWidth: 2),
            const SizedBox(height: 12),
            Text('Loading lyrics…', style: TextStyle(
              fontFamily: 'Rajdhani', color: textMut, fontSize: 14)),
          ],
        ),
      );
    }

    if (!lyrics.hasLyrics) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_outlined, color: textMut, size: 48),
            const SizedBox(height: 12),
            Text(
              lyrics.error ?? 'No lyrics available',
              style: TextStyle(fontFamily: 'Rajdhani', color: textMut, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: lyrics.lines.length,
      itemBuilder: (context, i) {
        final line    = lyrics.lines[i];
        final isCurrent = i == lyrics.currentIndex;
        final isPast    = i < lyrics.currentIndex;

        return GestureDetector(
          onTap: () => player.seekTo(line.time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? accent.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              line.text.isEmpty ? '♪' : line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: isCurrent ? 20 : 16,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? accent
                    : isPast
                        ? textSub.withValues(alpha: 0.5)
                        : textPri.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}
