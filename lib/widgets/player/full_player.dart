import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/app_theme.dart';

class FullPlayer extends StatefulWidget {
  final VoidCallback onClose;
  const FullPlayer({super.key, required this.onClose});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player  = context.watch<PlayerProvider>();
    final isDark  = context.watch<ThemeProvider>().isDark;
    final lib     = context.watch<LibraryProvider>();
    final song    = player.current;
    if (song == null) return const SizedBox.shrink();

    final accent   = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final accent2  = isDark ? AriseColors.demonAccent2 : AriseColors.angelAccent2;
    final bg       = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri  = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub  = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut  = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;
    final isLiked  = lib.isLiked(song.id);

    return Material(
      color: Colors.transparent,
      child: Container(
        color: bg,
        child: SafeArea(
          child: Column(
            children: [
              // ── Handle / close ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color:textSub, size:28),
                      onPressed: widget.onClose,
                    ),
                    const Spacer(),
                    Text('NOW PLAYING', style: TextStyle(
                      fontFamily:'Orbitron', color:textMut, fontSize:10, letterSpacing:.2)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded, color:textSub),
                      onPressed: () => _showSongMenu(context, player, lib, song),
                    ),
                  ],
                ),
              ),

              // ── Tabs: Player / Queue ────────────────────────────────────────
              TabBar(
                controller:    _tabs,
                indicatorColor:accent,
                labelColor:    accent,
                unselectedLabelColor: textMut,
                labelStyle:    const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:13),
                dividerColor:  Colors.transparent,
                tabs: const [Tab(text:'PLAYER'), Tab(text:'QUEUE')],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // ── Player tab ────────────────────────────────────────────
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal:24),
                        child: Column(
                          children: [
                            const SizedBox(height:24),

                            // Album art
                            Hero(
                              tag: 'player_thumb',
                              child: Container(
                                width:  280, height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(
                                    color: accent.withValues(alpha: .3),
                                    blurRadius: 40, spreadRadius: 5,
                                  )],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl:    song.thumbnail ?? '',
                                    fit:         BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: accent.withValues(alpha: .1),
                                      child: Icon(Icons.music_note, color:accent, size:80),
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
                                    style: TextStyle(fontFamily:'Orbitron', color:textPri, fontWeight:FontWeight.w700, fontSize:20),
                                    blankSpace: 60, velocity: 30,
                                    pauseAfterRound: const Duration(seconds:2),
                                  )
                                : Text(song.title, style: TextStyle(
                                    fontFamily:'Orbitron', color:textPri,
                                    fontWeight:FontWeight.w700, fontSize:20)),
                            ),
                            const SizedBox(height: 6),
                            Text(song.artist, style: TextStyle(
                              fontFamily:'Rajdhani', color:textSub, fontSize:15)),
                            const SizedBox(height: 28),

                            // Seek bar
                            _SeekBar(player: player, accent: accent, textMut: textMut),
                            const SizedBox(height: 28),

                            // Main controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Shuffle
                                IconButton(
                                  icon: Icon(Icons.shuffle_rounded,
                                    color: player.shuffle ? accent : textMut, size:24),
                                  onPressed: player.toggleShuffle,
                                ),
                                // Prev
                                IconButton(
                                  icon: Icon(Icons.skip_previous_rounded, color:textSub, size:36),
                                  onPressed: player.previous,
                                ),
                                // Play/Pause
                                GestureDetector(
                                  onTap: player.togglePlayPause,
                                  child: Container(
                                    width:64, height:64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [accent2, accent],
                                        begin: Alignment.topLeft,
                                        end:   Alignment.bottomRight,
                                      ),
                                      boxShadow: [BoxShadow(
                                        color:      accent.withValues(alpha: .5),
                                        blurRadius: 24, spreadRadius: 2,
                                      )],
                                    ),
                                    child: Icon(
                                      player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white, size: 34,
                                    ),
                                  ),
                                ),
                                // Next
                                IconButton(
                                  icon: Icon(Icons.skip_next_rounded, color:textSub, size:36),
                                  onPressed: player.next,
                                ),
                                // Repeat
                                IconButton(
                                  icon: Icon(
                                    player.repeat == RepeatMode.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    color: player.repeat != RepeatMode.none ? accent : textMut,
                                    size: 24,
                                  ),
                                  onPressed: player.cycleRepeat,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Like + add to playlist
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: accent, size:28),
                                  onPressed: () => lib.toggleLike(song),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(Icons.playlist_add_rounded, color:textSub, size:28),
                                  onPressed: () => _showAddToPlaylist(context, lib, song),
                                ),
                                const SizedBox(width: 16),
                                // Source badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal:8, vertical:3),
                                  decoration: BoxDecoration(
                                    color:        accent.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(8),
                                    border:       Border.all(color: accent.withValues(alpha: .3)),
                                  ),
                                  child: Text(
                                    song.source == 'youtube' ? 'YouTube' : 'Saavn',
                                    style: TextStyle(
                                      fontFamily:'Orbitron', color:accent,
                                      fontSize:9, letterSpacing:.1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // ── Queue tab ─────────────────────────────────────────────
                    _QueueTab(player: player, isDark: isDark, accent: accent,
                      textPri: textPri, textSub: textSub, textMut: textMut),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSongMenu(BuildContext ctx, PlayerProvider p, LibraryProvider l, song) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Provider.of<ThemeProvider>(context, listen: false).isDark
          ? AriseColors.demonCard : AriseColors.angelCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () { Navigator.pop(ctx); _showAddToPlaylist(ctx, l, song); },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Add to Queue'),
            onTap: () { p.addToQueue(song); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylist(BuildContext ctx, LibraryProvider lib, song) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Provider.of<ThemeProvider>(ctx,     listen: false).isDark
          ? AriseColors.demonCard : AriseColors.angelCard,
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

class _SeekBar extends StatelessWidget {
  final PlayerProvider player;
  final Color accent, textMut;
  const _SeekBar({required this.player, required this.accent, required this.textMut});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight:     3,
            thumbShape:      const RoundSliderThumbShape(enabledThumbRadius:6),
            overlayShape:    const RoundSliderOverlayShape(overlayRadius:14),
            activeTrackColor:   accent,
            inactiveTrackColor: accent.withValues(alpha: .2),
            thumbColor:         accent,
            overlayColor:       accent.withValues(alpha: .2),
          ),
          child: Slider(
            value:    player.progress,
            onChanged: player.seekToFraction,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal:4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(player.positionStr, style: TextStyle(
                fontFamily:'Orbitron', color:accent, fontSize:10)),
              Text(player.durationStr, style: TextStyle(
                fontFamily:'Orbitron', color:textMut, fontSize:10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueTab extends StatelessWidget {
  final PlayerProvider player;
  final bool isDark;
  final Color accent, textPri, textSub, textMut;
  const _QueueTab({required this.player, required this.isDark,
    required this.accent, required this.textPri, required this.textSub, required this.textMut});

  @override
  Widget build(BuildContext context) {
    final queue = player.queue;
    if (queue.isEmpty) return Center(
      child: Text('Queue is empty', style: TextStyle(color: textMut, fontFamily:'Rajdhani')),
    );
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
          key:     ValueKey(s.id + i.toString()),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl:    s.thumbnail ?? '',
              width:  42, height: 42, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width:42, height:42, color: accent.withValues(alpha: .1),
                child: Icon(Icons.music_note, color:accent, size:18)),
            ),
          ),
          title: Text(s.title, style: TextStyle(
            fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w600, fontSize:14)),
          subtitle: Text(s.artist, style: TextStyle(
            fontFamily:'Rajdhani', color:textSub, fontSize:12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color:textMut, size:18),
                onPressed: () => player.removeFromQueue(i),
              ),
              ReorderableDragStartListener(
                index: i,
                child: Icon(Icons.drag_handle_rounded, color:textMut),
              ),
            ],
          ),
          onTap: () => player.play(s),
        );
      },
    );
  }
}

