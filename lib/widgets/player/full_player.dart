import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:marquee/marquee.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../../models/song_model.dart';
import '../../providers/download_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/lyrics_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'lyrics_view.dart';
import 'qr_share_sheet.dart';
import 'sleep_timer_sheet.dart';

class FullPlayer extends StatefulWidget {
  final VoidCallback onClose;
  const FullPlayer({super.key, required this.onClose});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Color? _dominantColor;
  String? _lastThumbUrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _extractColor(String? thumbUrl, Color fallback) async {
    if (thumbUrl == null || thumbUrl.isEmpty || thumbUrl == _lastThumbUrl) return;
    _lastThumbUrl = thumbUrl;
    try {
      final pg = await PaletteGenerator.fromImageProvider(
        NetworkImage(thumbUrl),
        size: const Size(100, 100),
        maximumColorCount: 8,
      );
      final color = pg.dominantColor?.color ??
          pg.vibrantColor?.color ??
          fallback;
      if (mounted) setState(() => _dominantColor = color);
    } catch (_) {
      if (mounted) setState(() => _dominantColor = fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player  = context.watch<PlayerProvider>();
    final isDark  = context.watch<ThemeProvider>().isDark;
    final lib     = context.watch<LibraryProvider>();
    final lyrics  = context.watch<LyricsProvider>();
    final dl      = context.watch<DownloadProvider>();
    final song    = player.current;
    if (song == null) return const SizedBox.shrink();

    final accent   = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final accent2  = isDark ? AriseColors.demonAccent2 : AriseColors.angelAccent2;
    final bg       = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri  = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub  = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut  = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;
    final isLiked  = lib.isLiked(song.id);

    // Extract dominant color from album art
    _extractColor(song.thumbnail, accent);

    final dynColor = _dominantColor ?? accent;
    final gradientBg = isDark
        ? Color.lerp(AriseColors.demonBg, dynColor, 0.18)!
        : Color.lerp(AriseColors.angelBg, dynColor, 0.12)!;

    // Attach lyrics provider to player position stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      lyrics.attachPlayer(player);
    });

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientBg, bg],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Handle / close ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: textSub, size: 28),
                      onPressed: widget.onClose,
                    ),
                    const Spacer(),
                    Text('NOW PLAYING', style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: textMut,
                        fontSize: 10,
                        letterSpacing: .2)),
                    const Spacer(),
                    // Sleep timer indicator
                    if (player.sleepRemaining != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => SleepTimerSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bedtime_rounded,
                                    color: accent, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  _fmtRemaining(player.sleepRemaining!),
                                  style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      color: accent,
                                      fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded, color: textSub),
                      onPressed: () =>
                          _showSongMenu(context, player, lib, dl, song),
                    ),
                  ],
                ),
              ),

              // ── Tabs: Player / Lyrics / Queue ──────────────────────────────
              TabBar(
                controller: _tabs,
                indicatorColor: dynColor,
                labelColor: dynColor,
                unselectedLabelColor: textMut,
                labelStyle: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'PLAYER'),
                  Tab(text: 'LYRICS'),
                  Tab(text: 'QUEUE'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // ── Player tab ────────────────────────────────────────────
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            // Album art
                            Hero(
                              tag: 'player_thumb',
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dynColor.withValues(alpha: .35),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl: song.thumbnail ?? '',
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: accent.withValues(alpha: .1),
                                      child: Icon(Icons.music_note,
                                          color: accent, size: 80),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Title
                            SizedBox(
                              height: 32,
                              child: song.title.length > 30
                                  ? Marquee(
                                      text: song.title,
                                      style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          color: textPri,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20),
                                      blankSpace: 60,
                                      velocity: 30,
                                      pauseAfterRound:
                                          const Duration(seconds: 2),
                                    )
                                  : Text(song.title,
                                      style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          color: textPri,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                            ),
                            const SizedBox(height: 6),
                            Text(song.artist,
                                style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    color: textSub,
                                    fontSize: 15)),
                            const SizedBox(height: 28),

                            // Seek bar
                            _SeekBar(
                                player: player,
                                accent: dynColor,
                                textMut: textMut),
                            const SizedBox(height: 28),

                            // Main controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.shuffle_rounded,
                                      color: player.shuffle
                                          ? dynColor
                                          : textMut,
                                      size: 24),
                                  onPressed: player.toggleShuffle,
                                ),
                                IconButton(
                                  icon: Icon(Icons.skip_previous_rounded,
                                      color: textSub, size: 36),
                                  onPressed: player.previous,
                                ),
                                GestureDetector(
                                  onTap: player.togglePlayPause,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [accent2, dynColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: dynColor.withValues(alpha: .5),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      player.playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.skip_next_rounded,
                                      color: textSub, size: 36),
                                  onPressed: player.next,
                                ),
                                IconButton(
                                  icon: Icon(
                                    player.repeat == RepeatMode.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    color: player.repeat != RepeatMode.none
                                        ? dynColor
                                        : textMut,
                                    size: 24,
                                  ),
                                  onPressed: player.cycleRepeat,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Action row: like, playlist, sleep, download, QR, source
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Like
                                IconButton(
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: dynColor,
                                    size: 26,
                                  ),
                                  onPressed: () => lib.toggleLike(song),
                                ),
                                // Add to playlist
                                IconButton(
                                  icon: Icon(Icons.playlist_add_rounded,
                                      color: textSub, size: 26),
                                  onPressed: () =>
                                      _showAddToPlaylist(context, lib, song),
                                ),
                                // Sleep timer
                                IconButton(
                                  icon: Icon(
                                    Icons.bedtime_rounded,
                                    color: player.sleepRemaining != null
                                        ? dynColor
                                        : textSub,
                                    size: 24,
                                  ),
                                  onPressed: () =>
                                      SleepTimerSheet.show(context),
                                ),
                                // Download
                                _DownloadButton(
                                    song: song,
                                    dl: dl,
                                    accent: dynColor,
                                    textSub: textSub),
                                // QR Share
                                IconButton(
                                  icon: Icon(Icons.qr_code_rounded,
                                      color: textSub, size: 24),
                                  onPressed: () =>
                                      QrShareSheet.show(context, song),
                                ),
                                // Source badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dynColor.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: dynColor.withValues(alpha: .3)),
                                  ),
                                  child: Text(
                                    song.source == 'youtube'
                                        ? 'YouTube'
                                        : 'Saavn',
                                    style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        color: dynColor,
                                        fontSize: 9,
                                        letterSpacing: .1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // ── Lyrics tab ────────────────────────────────────────────
                    const LyricsView(),

                    // ── Queue tab ─────────────────────────────────────────────
                    _QueueTab(
                        player: player,
                        isDark: isDark,
                        accent: dynColor,
                        textPri: textPri,
                        textSub: textSub,
                        textMut: textMut),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSongMenu(BuildContext ctx, PlayerProvider p, LibraryProvider l,
      DownloadProvider dl, SongModel song) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDark;
    showModalBottomSheet(
      context: ctx,
      backgroundColor:
          isDark ? AriseColors.demonCard : AriseColors.angelCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddToPlaylist(ctx, l, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Add to Queue'),
            onTap: () {
              p.addToQueue(song);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: const Text('Share via QR'),
            onTap: () {
              Navigator.pop(ctx);
              QrShareSheet.show(ctx, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bedtime_rounded),
            title: const Text('Sleep Timer'),
            onTap: () {
              Navigator.pop(ctx);
              SleepTimerSheet.show(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylist(
      BuildContext ctx, LibraryProvider lib, SongModel song) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor:
          Provider.of<ThemeProvider>(ctx, listen: false).isDark
              ? AriseColors.demonCard
              : AriseColors.angelCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final playlists = lib.playlists;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Add to Playlist',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No playlists yet — create one in Library'),
              )
            else
              ...playlists.map((pl) => ListTile(
                    leading: const Icon(Icons.queue_music_rounded),
                    title: Text(pl.name),
                    subtitle: Text('${pl.count} tracks'),
                    onTap: () {
                      lib.addSongToPlaylist(pl.id, song);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Added to ${pl.name}')));
                    },
                  )),
          ],
        );
      },
    );
  }
}

// ── Download button widget ────────────────────────────────────────────────────
class _DownloadButton extends StatelessWidget {
  final SongModel song;
  final DownloadProvider dl;
  final Color accent, textSub;
  const _DownloadButton(
      {required this.song,
      required this.dl,
      required this.accent,
      required this.textSub});

  @override
  Widget build(BuildContext context) {
    final isDownloaded = dl.isDownloaded(song.id);
    final isDownloading = dl.isDownloading(song.id);
    final progress = dl.getProgress(song.id);

    if (isDownloading && progress != null) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: accent,
              strokeWidth: 2,
            ),
            Icon(Icons.download_rounded, color: accent, size: 16),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(
        isDownloaded
            ? Icons.download_done_rounded
            : Icons.download_rounded,
        color: isDownloaded ? accent : textSub,
        size: 24,
      ),
      onPressed: isDownloaded
          ? null
          : () {
              if (song.source == 'saavn') {
                dl.download(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download started…')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Download only available for Saavn songs')),
                );
              }
            },
    );
  }
}

// ── Seek bar ──────────────────────────────────────────────────────────────────
class _SeekBar extends StatelessWidget {
  final PlayerProvider player;
  final Color accent, textMut;
  const _SeekBar(
      {required this.player, required this.accent, required this.textMut});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: .2),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: .2),
          ),
          child: Slider(
            value: player.progress,
            onChanged: player.seekToFraction,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(player.positionStr,
                  style: TextStyle(
                      fontFamily: 'Orbitron', color: accent, fontSize: 10)),
              Text(player.durationStr,
                  style: TextStyle(
                      fontFamily: 'Orbitron', color: textMut, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Queue tab ─────────────────────────────────────────────────────────────────
class _QueueTab extends StatelessWidget {
  final PlayerProvider player;
  final bool isDark;
  final Color accent, textPri, textSub, textMut;
  const _QueueTab(
      {required this.player,
      required this.isDark,
      required this.accent,
      required this.textPri,
      required this.textSub,
      required this.textMut});

  @override
  Widget build(BuildContext context) {
    final queue = player.queue;
    if (queue.isEmpty) {
      return Center(
        child: Text('Queue is empty',
            style: TextStyle(color: textMut, fontFamily: 'Rajdhani')),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: queue.length,
      onReorder: (o, n) {
        final q = List.from(queue);
        final item = q.removeAt(o);
        q.insert(n > o ? n - 1 : n, item);
        player.setQueue(List<dynamic>.from(q).cast());
      },
      itemBuilder: (_, i) {
        final s = queue[i];
        return ListTile(
          key: ValueKey(s.id + i.toString()),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: s.thumbnail ?? '',
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 42,
                height: 42,
                color: accent.withValues(alpha: .1),
                child: Icon(Icons.music_note, color: accent, size: 18),
              ),
            ),
          ),
          title: Text(s.title,
              style: TextStyle(
                  fontFamily: 'Rajdhani',
                  color: textPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          subtitle: Text(s.artist,
              style: TextStyle(
                  fontFamily: 'Rajdhani', color: textSub, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color: textMut, size: 18),
                onPressed: () => player.removeFromQueue(i),
              ),
              ReorderableDragStartListener(
                index: i,
                child: Icon(Icons.drag_handle_rounded, color: textMut),
              ),
            ],
          ),
          onTap: () => player.play(s),
        );
      },
    );
  }
}
