import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/playlist_model.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});
  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  PlaylistModel? _open;

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final lib     = context.watch<LibraryProvider>();
    final player  = context.read<PlayerProvider>();
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;
    final card    = isDark ? AriseColors.demonCard    : AriseColors.angelCard;
    final border  = isDark ? AriseColors.demonBorder  : AriseColors.angelBorder;

    // ── Playlist detail view ──────────────────────────────────────────────────
    if (_open != null) {
      final pl = lib.getPlaylist(_open!.id) ?? _open!;
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color:accent),
            onPressed: () => setState(() => _open = null),
          ),
          title: Text(pl.name, style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:15)),
          actions: [
            if (pl.songs.isNotEmpty)
              IconButton(
                icon: Icon(Icons.play_arrow_rounded, color:accent),
                onPressed: () => player.play(pl.songs.first, queue:pl.songs.skip(1).toList()),
              ),
            PopupMenuButton<String>(
              color: card,
              onSelected: (v) {
                if (v == 'rename') _renameDialog(context, lib, pl);
                if (v == 'delete') { lib.deletePlaylist(pl.id); setState(() => _open = null); }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value:'rename', child:Text('Rename')),
                const PopupMenuItem(value:'delete', child:Text('Delete', style:TextStyle(color:Colors.red))),
              ],
            ),
          ],
        ),
        body: pl.songs.isEmpty
            ? Center(child:Text('No songs yet\nAdd songs using the ⋮ menu on any track',
                textAlign:TextAlign.center, style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:14)))
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pl.songs.length,
                onReorder: (o, n) => lib.reorderPlaylist(pl.id, o, n > o ? n-1 : n),
                itemBuilder: (_, i) => SongTile(
                  key:       ValueKey(pl.songs[i].id + i.toString()),
                  song:      pl.songs[i],
                  queue:     pl.songs,
                  showIndex: true,
                  index:     i,
                ),
              ),
      );
    }

    // ── Playlists list ────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Playlists', style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color:accent),
            onPressed: () => _createDialog(context, lib),
          ),
        ],
      ),
      body: lib.playlists.isEmpty
          ? Center(child:Column(mainAxisSize:MainAxisSize.min, children:[
              Icon(Icons.queue_music_rounded, color:textMut, size:64),
              const SizedBox(height:16),
              Text('No playlists yet', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:16)),
              const SizedBox(height:8),
              ElevatedButton.icon(
                onPressed: () => _createDialog(context, lib),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Playlist'),
                style: ElevatedButton.styleFrom(backgroundColor:accent),
              ),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lib.playlists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final pl = lib.playlists[i];
                return GestureDetector(
                  onTap: () => setState(() => _open = pl),
                  child: Container(
                    decoration: BoxDecoration(
                      color:        card,
                      borderRadius: BorderRadius.circular(14),
                      border:       Border.all(color:border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal:14, vertical:12),
                    child: Row(children:[
                      Container(width:50, height:50,
                        decoration: BoxDecoration(color:accent.withOpacity(.12), borderRadius:BorderRadius.circular(12)),
                        child: pl.songs.isNotEmpty && pl.songs.first.thumbnail != null
                            ? ClipRRect(borderRadius:BorderRadius.circular(12),
                                child:Image.network(pl.songs.first.thumbnail!, fit:BoxFit.cover))
                            : Icon(Icons.queue_music_rounded, color:accent, size:24)),
                      const SizedBox(width:12),
                      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                        Text(pl.name, style:TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:15)),
                        Text('${pl.count} songs', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:12)),
                      ])),
                      Row(mainAxisSize:MainAxisSize.min, children:[
                        if (pl.songs.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.play_arrow_rounded, color:accent, size:22),
                            onPressed: () => player.play(pl.songs.first, queue:pl.songs.skip(1).toList()),
                          ),
                        PopupMenuButton<String>(
                          color: card,
                          onSelected: (v) {
                            if (v == 'rename') _renameDialog(context, lib, pl);
                            if (v == 'delete') lib.deletePlaylist(pl.id);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value:'rename', child:Text('Rename')),
                            const PopupMenuItem(value:'delete', child:Text('Delete', style:TextStyle(color:Colors.red))),
                          ],
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  void _createDialog(BuildContext ctx, LibraryProvider lib) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) { lib.createPlaylist(ctrl.text.trim()); Navigator.pop(ctx); }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _renameDialog(BuildContext ctx, LibraryProvider lib, PlaylistModel pl) {
    final ctrl = TextEditingController(text: pl.name);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) { lib.renamePlaylist(pl.id, ctrl.text.trim()); Navigator.pop(ctx); }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

extension _CtxRead on BuildContext {
  T read<T>() => Provider.of<T>(this, listen: false);
}
