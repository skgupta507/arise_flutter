import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  Map<String,dynamic>? _album;
  List<SongModel>      _tracks = [];
  bool                 _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final album = await SaavnApi.getAlbumById(widget.albumId);
    if (!mounted) return;
    setState(() {
      _album   = album;
      final songs = album?['songs'] as List? ?? [];
      _tracks  = songs.map((s) => SongModel.fromSaavn(Map<String,dynamic>.from(s))).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final player  = context.read<PlayerProvider>();
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    final images = _album?['image'] as List?;
    final thumb  = images != null && images.length > 1
        ? images[1]['url']?.toString()
        : images?.lastOrNull?['url']?.toString();
    final name   = _album?['name']?.toString() ?? '';
    final artist = _album?['artists']?['primary']?[0]?['name']?.toString() ?? '';
    final year   = _album?['year']?.toString() ?? '';

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: bg,
                  iconTheme: IconThemeData(color: accent),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumb != null)
                          CachedNetworkImage(
                            imageUrl:    thumb,
                            fit:         BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(.5), BlendMode.darken),
                          ),
                        Positioned(
                          left: 16, bottom: 16, right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ALBUM', style: TextStyle(
                                fontFamily:'Orbitron', color:accent, fontSize:10, letterSpacing:.3)),
                              const SizedBox(height: 4),
                              Text(name, style: const TextStyle(
                                fontFamily:'Orbitron', color:Colors.white,
                                fontWeight:FontWeight.w900, fontSize:22)),
                              const SizedBox(height: 4),
                              Text('$artist · $year', style: const TextStyle(
                                fontFamily:'Rajdhani', color:Colors.white70, fontSize:14)),
                              const SizedBox(height: 12),
                              if (_tracks.isNotEmpty)
                                Row(children: [
                                  ElevatedButton.icon(
                                    onPressed: () => player.play(_tracks.first, queue:_tracks.skip(1).toList()),
                                    icon:  const Icon(Icons.play_arrow_rounded, size:18),
                                    label: const Text('Play Album'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accent,
                                      textStyle: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      player.setQueue(_tracks);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Album added to queue')));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color:Colors.white38),
                                    ),
                                    child: const Text('Add to Queue', style:TextStyle(fontFamily:'Rajdhani')),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _tracks.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(child: Text('No tracks found',
                            style: TextStyle(fontFamily:'Rajdhani', color:textMut))))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => SongTile(
                              song:      _tracks[i],
                              queue:     _tracks,
                              showIndex: true,
                              index:     i,
                            ),
                            childCount: _tracks.length,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

extension _ListExt<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

extension _CtxRead on BuildContext {
  T read<T>() => Provider.of<T>(this, listen: false);
}
