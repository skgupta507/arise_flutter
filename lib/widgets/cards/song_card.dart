import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final int?      index;
  final bool      showIndex;
  final VoidCallback?   onTap;
  final List<SongModel>? queue;

  const SongTile({
    super.key,
    required this.song,
    this.index,
    this.showIndex = false,
    this.onTap,
    this.queue,
  });

  @override
  Widget build(BuildContext context) {
    final player  = context.watch<PlayerProvider>();
    final lib     = context.watch<LibraryProvider>();
    final isDark  = context.watch<ThemeProvider>().isDark;

    final accent   = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textPri  = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub  = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut  = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;
    final border   = isDark ? AriseColors.demonBorder  : AriseColors.angelBorder;

    final isPlaying = player.current?.id == song.id && player.playing;
    final isCurrent = player.current?.id == song.id;
    final isLiked   = lib.isLiked(song.id);

    return GestureDetector(
      onTap: onTap ?? () => player.play(song, queue: queue),
      child: Container(
        margin:  const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        isCurrent ? accent.withValues(alpha: .08) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
            color: isCurrent ? accent.withValues(alpha: .3) : border,
          ),
        ),
        child: Row(
          children: [
            // Index or playing indicator
            if (showIndex && index != null)
              SizedBox(
                width: 28,
                child: isPlaying
                    ? _WaveIcon(color: accent)
                    : Text('${index! + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color:  isCurrent ? accent : textMut,
                          fontSize: 10,
                        )),
              ),

            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl:    song.thumbnail ?? '',
                width: 46, height: 46,
                fit:   BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 46, height: 46,
                  color: accent.withValues(alpha: .1),
                  child: Icon(Icons.music_note, color: accent, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily:  'Rajdhani',
                      color:       isCurrent ? accent : textPri,
                      fontWeight:  FontWeight.w700,
                      fontSize:    14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      color:      textSub,
                      fontSize:   12,
                    ),
                  ),
                ],
              ),
            ),

            // Like + overflow menu
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => lib.toggleLike(song),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: accent,
                      size:  18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showMenu(context, player, lib),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.more_vert_rounded, color: textMut, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext ctx, PlayerProvider player, LibraryProvider lib) {
    final isDark = Provider.of<ThemeProvider>(ctx,     listen: false).isDark;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AriseColors.demonCard : AriseColors.angelCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded),
            title:   const Text('Play Now'),
            onTap:   () { Navigator.pop(ctx); player.play(song); },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title:   const Text('Add to Queue'),
            onTap:   () { player.addToQueue(song); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title:   const Text('Add to Playlist'),
            onTap:   () {
              Navigator.pop(ctx);
              _addToPlaylistSheet(ctx, lib);
            },
          ),
          ListTile(
            leading: Icon(lib.isLiked(song.id)
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded),
            title: Text(lib.isLiked(song.id) ? 'Unlike' : 'Like'),
            onTap: () { lib.toggleLike(song); Navigator.pop(ctx); },
          ),
        ],
      ),
    );
  }

  void _addToPlaylistSheet(BuildContext ctx, LibraryProvider lib) {
    final isDark = Provider.of<ThemeProvider>(ctx,     listen: false).isDark;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AriseColors.demonCard : AriseColors.angelCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Add to Playlist', style: Theme.of(ctx).textTheme.titleMedium),
          ),
          if (lib.playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No playlists — create one in Library'),
            )
          else
            ...lib.playlists.map((pl) => ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title:   Text(pl.name),
              subtitle:Text('${pl.count} tracks'),
              onTap:   () {
                lib.addSongToPlaylist(pl.id, song);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Added to ${pl.name}')));
              },
            )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Horizontal scroll card ────────────────────────────────────────────────────
class SongCard extends StatelessWidget {
  final SongModel      song;
  final List<SongModel>? queue;
  final double         width;

  const SongCard({super.key, required this.song, this.queue, this.width = 130});

  @override
  Widget build(BuildContext context) {
    final player  = Provider.of<PlayerProvider>(context, listen: false);
    final isDark  = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final accent   = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textPri  = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub  = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final border   = isDark ? AriseColors.demonBorder  : AriseColors.angelBorder;
    final isPlaying= player.current?.id == song.id;

    return GestureDetector(
      onTap: () => player.play(song, queue: queue),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnail ?? '',
                    width: width, height: width,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: width, height: width,
                      decoration: BoxDecoration(
                        color:        accent.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                        border:       Border.all(color: border),
                      ),
                      child: Icon(Icons.music_note, color: accent, size: 40),
                    ),
                  ),
                ),
                if (isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color:        accent.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: _WaveIcon(color: Colors.white, size: 32)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily:  'Rajdhani',
                color:       isPlaying ? accent : textPri,
                fontWeight:  FontWeight.w700,
                fontSize:    12,
              ),
            ),
            Text(
              song.artist,
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
              style: TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated wave icon for "now playing" ─────────────────────────────────────
class _WaveIcon extends StatefulWidget {
  final Color color;
  final double size;
  const _WaveIcon({required this.color, this.size = 18});

  @override
  State<_WaveIcon> createState() => _WaveIconState();
}

class _WaveIconState extends State<_WaveIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final h = (widget.size * .3) + (widget.size * .7) *
              ((0.5 + 0.5 * _ctrl.value + i * 0.2) % 1.0);
          return Container(
            width:  widget.size * .18,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color:        widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

