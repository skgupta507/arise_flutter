import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId, artistName;
  const ArtistDetailScreen({super.key, required this.artistId, required this.artistName});
  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String,dynamic>? _artist;
  List<SongModel>       _songs  = [];
  List<Map<String,dynamic>> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);

    final artist = await SaavnApi.getArtistById(widget.artistId);
    List<SongModel> songs = [];
    List<Map<String,dynamic>> albums = [];

    if (artist != null) {
      final topSongs = artist['topSongs'] as List? ?? [];
      songs = topSongs.map((s) => SongModel.fromSaavn(Map<String,dynamic>.from(s))).toList();
      final topAlbums = artist['topAlbums'] as List? ?? [];
      albums = topAlbums.map((a) => Map<String,dynamic>.from(a)).toList();
    }

    // Fallback: search by name if no songs from API
    if (songs.isEmpty) {
      final r = await SaavnApi.searchSongs('${widget.artistName} songs', limit: 20);
      songs = r.map(SongModel.fromSaavn).toList();
    }
    if (albums.isEmpty) {
      final r = await SaavnApi.searchAlbums('${widget.artistName} album', limit: 10);
      albums = r;
    }

    if (!mounted) return;
    setState(() {
      _artist  = artist;
      _songs   = songs;
      _albums  = albums;
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

    final images = _artist?['image'] as List?;
    final thumb  = images != null && images.length > 1
        ? images[1]['url']?.toString() : images?.lastOrNull?['url']?.toString();
    final name   = _artist?['name']?.toString() ?? widget.artistName;
    final bio    = _artist?['bio']?.toString() ?? '';

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(child: CircularProgressIndicator(color:accent))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: bg,
                  iconTheme: IconThemeData(color:accent),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumb != null)
                          CachedNetworkImage(
                            imageUrl:    thumb,
                            fit:         BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(.55), BlendMode.darken),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent.withOpacity(.3), bg],
                                begin: Alignment.topCenter,
                                end:   Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        Positioned(left:16, bottom:16, right:16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ARTIST', style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:10)),
                              const SizedBox(height:4),
                              Text(name, style:const TextStyle(fontFamily:'Orbitron',
                                color:Colors.white, fontWeight:FontWeight.w900, fontSize:26)),
                              if (bio.isNotEmpty) ...[
                                const SizedBox(height:6),
                                Text(bio, maxLines:2, overflow:TextOverflow.ellipsis,
                                  style:const TextStyle(fontFamily:'Rajdhani', color:Colors.white70, fontSize:13)),
                              ],
                              const SizedBox(height:12),
                              if (_songs.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => player.play(_songs.first, queue:_songs.skip(1).toList()),
                                  icon:  const Icon(Icons.play_arrow_rounded, size:18),
                                  label: const Text('Play All'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    textStyle: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700),
                                  ),
                                ),
                            ],
                          )),
                      ],
                    ),
                  ),
                  bottom: TabBar(
                    controller:          _tabs,
                    indicatorColor:      accent,
                    labelColor:          accent,
                    unselectedLabelColor:textMut,
                    labelStyle: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700),
                    tabs: [Tab(text:'🎵 Songs (${_songs.length})'), Tab(text:'💿 Albums (${_albums.length})')],
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      // Songs
                      _songs.isEmpty
                          ? Center(child:Text('No songs found', style:TextStyle(fontFamily:'Rajdhani', color:textMut)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _songs.length,
                              itemBuilder: (_, i) => SongTile(
                                song:_songs[i], queue:_songs, showIndex:true, index:i),
                            ),
                      // Albums
                      _albums.isEmpty
                          ? Center(child:Text('No albums found', style:TextStyle(fontFamily:'Rajdhani', color:textMut)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:2, mainAxisSpacing:12, crossAxisSpacing:12, childAspectRatio:.85),
                              itemCount: _albums.length,
                              itemBuilder: (_, i) {
                                final a = _albums[i];
                                final imgs = a['image'] as List?;
                                final t = imgs != null && imgs.length > 1 ? imgs[1]['url']?.toString() : null;
                                return GestureDetector(
                                  onTap: () {}, // navigate to album
                                  child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                                    Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(12),
                                      child:t!=null ? CachedNetworkImage(imageUrl:t, fit:BoxFit.cover, width:double.infinity)
                                        : Container(color:accent.withOpacity(.1), child:Icon(Icons.album_rounded,color:accent,size:40)))),
                                    const SizedBox(height:5),
                                    Text(a['name']?.toString()??'', maxLines:1, overflow:TextOverflow.ellipsis,
                                      style:TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:13)),
                                    Text(a['year']?.toString()??'', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:11)),
                                  ]),
                                );
                              }),
                    ],
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
