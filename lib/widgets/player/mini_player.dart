import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final song   = player.current;
    if (song == null) return const SizedBox.shrink();

    final bg     = isDark ? AriseColors.demonPlayer : AriseColors.angelPlayer;
    final border = isDark ? AriseColors.demonBorder : AriseColors.angelBorder;
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: border),
        boxShadow: [BoxShadow(
          color:      accent.withValues(alpha: .15),
          blurRadius: 20,
          spreadRadius: 2,
        )],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: LinearProgressIndicator(
              value:            player.progress,
              backgroundColor:  (isDark ? AriseColors.demonFaint : AriseColors.angelFaint).withValues(alpha: .2),
              valueColor:       AlwaysStoppedAnimation<Color>(accent),
              minHeight:        3,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl:    song.thumbnail ?? '',
                    width:  44, height: 44,
                    fit:    BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.music_note, color: accent, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title + artist (scrolling if long)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20,
                        child: song.title.length > 28
                            ? Marquee(
                                text:                  song.title,
                                style:                 TextStyle(fontFamily:'Rajdhani', color: isDark ? AriseColors.demonText : AriseColors.angelText, fontWeight:FontWeight.w700, fontSize:14),
                                scrollAxis:            Axis.horizontal,
                                blankSpace:            40,
                                velocity:              30,
                                pauseAfterRound:       const Duration(seconds:2),
                                startPadding:          0,
                              )
                            : Text(
                                song.title,
                                style: TextStyle(fontFamily:'Rajdhani', color: isDark ? AriseColors.demonText : AriseColors.angelText, fontWeight:FontWeight.w700, fontSize:14),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(fontFamily:'Rajdhani', color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted, fontSize:12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Controls: prev / play-pause / next / close
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Btn(icon: Icons.skip_previous_rounded, size: 22,
                        color: isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext,
                        onTap: () => player.previous()),
                    const SizedBox(width: 2),
                    _PlayPauseBtn(player: player, accent: accent),
                    const SizedBox(width: 2),
                    _Btn(icon: Icons.skip_next_rounded, size: 22,
                        color: isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext,
                        onTap: () => player.next()),
                    const SizedBox(width: 4),
                    _Btn(icon: Icons.close_rounded, size: 20,
                        color: isDark ? AriseColors.demonFaint : AriseColors.angelFaint,
                        onTap: () => player.stop()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseBtn extends StatelessWidget {
  final PlayerProvider player;
  final Color accent;
  const _PlayPauseBtn({required this.player, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: player.togglePlayPause,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: player.playing
                ? [accent.withValues(alpha: .85), accent]
                : [accent.withValues(alpha: .15), accent.withValues(alpha: .25)],
          ),
          boxShadow: player.playing ? [BoxShadow(color: accent.withValues(alpha: .4), blurRadius:10)] : null,
        ),
        child: Icon(
          player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size:  22,
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.size, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(icon, color: color, size: size),
    ),
  );
}
