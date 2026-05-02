import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../api/muzo_api.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';
import '../../widgets/common/section_header.dart';
import 'home_hero.dart';
import 'mood_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SongModel> _trending  = [];
  List<SongModel> _bollywood = [];
  List<SongModel> _latest    = [];
  List<SongModel> _lofi      = [];
  List<Map<String,dynamic>> _albums  = [];
  List<Map<String,dynamic>> _artists = [];
  List<Map<String,dynamic>> _podcasts= [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // Fire all fetches concurrently
    final results = await Future.wait([
      SaavnApi.searchSongs('trending hits india', limit: 20),
      SaavnApi.searchSongs('bollywood hits 2025', limit: 20),
      SaavnApi.searchSongs('new hindi songs 2025', limit: 20),
      SaavnApi.searchSongs('lofi hindi chill',     limit: 16),
      SaavnApi.searchAlbums('new hindi album 2025',limit: 14),
      SaavnApi.searchArtists('trending indian artists'),
      MuzoApi.searchPodcasts('popular indian podcast'),
    ]);

    if (!mounted) return;
    setState(() {
      _trending  = (results[0] as List).cast<Map<String,dynamic>>().map(SongModel.fromSaavn).toList();
      _bollywood = (results[1] as List).cast<Map<String,dynamic>>().map(SongModel.fromSaavn).toList();
      _latest    = (results[2] as List).cast<Map<String,dynamic>>().map(SongModel.fromSaavn).toList();
      _lofi      = (results[3] as List).cast<Map<String,dynamic>>().map(SongModel.fromSaavn).toList();
      _albums    = List<Map<String,dynamic>>.from(results[4] as List);
      _artists   = List<Map<String,dynamic>>.from(results[5] as List);
      _podcasts  = List<Map<String,dynamic>>.from(results[6] as List);
      _loading   = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final player  = Provider.of<PlayerProvider>(context, listen: false);
    final bg      = isDark ? AriseColors.demonBg     : AriseColors.angelBg;
    final textMut = isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;
    final accent  = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color:       accent,
        onRefresh:   _load,
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────────
            SliverAppBar(
              floating:         true,
              snap:             true,
              backgroundColor:  bg,
              elevation:        0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arise Music', style: TextStyle(
                    fontFamily:'Orbitron', color:accent,
                    fontWeight:FontWeight.w900, fontSize:18, letterSpacing:.5)),
                  Text(
                    isDark ? '✦ Rise from the Shadows ✦' : '✦ Hear the Divine ✦',
                    style: TextStyle(fontFamily:'Orbitron', color:textMut, fontSize:9, letterSpacing:.2),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search_rounded, color: accent),
                  onPressed: () => context.go('/search'),
                ),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: accent,
                  ),
                  onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: _loading ? _buildSkeletons(isDark) : _buildContent(context, player, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, PlayerProvider player, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero ─────────────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
          child:   HomeHero(),
        ),
        const SizedBox(height: 24),

        // ── Mood playlists ────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:   MoodSection(),
        ),
        const SizedBox(height: 24),

        // ── Trending ─────────────────────────────────────────────────────────
        if (_trending.isNotEmpty) ...[
          HScrollSection(
            title:    isDark ? '🔥 Trending India' : '✨ Trending India',
            subtitle: isDark ? 'What the realm is consuming' : 'What the world is rejoicing',
            seeAllRoute: '/trending',
            height: 185,
            children: _trending.map((s) => SongCard(song: s, queue: _trending)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Top Artists ───────────────────────────────────────────────────────
        if (_artists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:    isDark ? '🎤 Top Artists' : '🎤 Divine Artists',
              subtitle: isDark ? 'Voices conjured from the depths' : 'Blessed voices of the divine',
              seeAllRoute: '/artists',
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:         const EdgeInsets.symmetric(horizontal: 16),
              itemCount:       _artists.take(14).length,
              separatorBuilder:(_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final a = _artists[i];
                final name  = a['name']?.toString() ?? '';
                final images= a['image'] as List?;
                final thumb = images != null && images.length > 1
                    ? images[1]['url']?.toString()
                    : images?.lastOrNull?['url']?.toString();
                return _ArtistBubble(
                  name:   name,
                  thumb:  thumb ?? '',
                  onTap:  () => ctx.go('/artists/${a['id']}?name=${Uri.encodeComponent(name)}'),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Bollywood ─────────────────────────────────────────────────────────
        if (_bollywood.isNotEmpty) ...[
          HScrollSection(
            title:    '🎬 Bollywood Hits',
            subtitle: isDark ? 'Mortal realm anthems' : 'Joyful anthems of celebration',
            seeAllRoute: '/search/bollywood hits',
            height: 185,
            children: _bollywood.map((s) => SongCard(song: s, queue: _bollywood)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── New releases ──────────────────────────────────────────────────────
        if (_latest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:    isDark ? '💿 New Releases' : '💿 Fresh Arrivals',
              subtitle: isDark ? 'Grimoires of sound sealed in blood' : 'Sacred albums of celestial harmony',
              seeAllRoute: '/albums',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _latest.take(6).map((s) => SongTile(
                song:  s,
                queue: _latest,
                showIndex: true,
                index: _latest.indexOf(s),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Lo-Fi ─────────────────────────────────────────────────────────────
        if (_lofi.isNotEmpty) ...[
          HScrollSection(
            title:    isDark ? '🌙 Lo-Fi & Chill' : '☁️ Celestial Lo-Fi',
            subtitle: isDark ? 'Drifting in the void' : 'Study · Calm · Meditative',
            height: 185,
            children: _lofi.map((s) => SongCard(song: s, queue: _lofi)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Albums ────────────────────────────────────────────────────────────
        if (_albums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:    '💿 Albums',
              subtitle: isDark ? 'Grimoires of sound' : 'Sacred collections',
              seeAllRoute: '/albums',
            ),
          ),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:         const EdgeInsets.symmetric(horizontal: 16),
              itemCount:       _albums.take(14).length,
              separatorBuilder:(_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final a = _albums[i];
                final images = a['image'] as List?;
                final thumb  = images != null && images.length > 1
                    ? images[1]['url']?.toString()
                    : null;
                return _AlbumCard(
                  name:  a['name']?.toString() ?? '',
                  artist:a['description']?.toString() ?? '',
                  thumb: thumb,
                  onTap: () => ctx.go('/albums/${a['id']}'),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Podcasts ─────────────────────────────────────────────────────────
        if (_podcasts.isNotEmpty) ...[
          HScrollSection(
            title:    '🎙 Podcasts',
            subtitle: isDark ? 'Stories from the underground' : 'Stories of wisdom and light',
            seeAllRoute: '/podcasts',
            height: 185,
            children: _podcasts.take(8).map((p) {
              final id    = p['videoId']?.toString() ?? p['id']?.toString() ?? '';
              final title = p['title']?.toString() ?? '';
              final thumb = MuzoApi.thumbnail(p) ?? '';
              final artist= (p['artists'] as List?)?.map((a) => a['name']?.toString() ?? '').join(', ') ?? '';
              return _PodcastCard(
                id:     id,
                title:  title,
                host:   artist,
                thumb:  thumb,
                onTap:  () {
                  if (id.isNotEmpty) {
                    Provider.of<PlayerProvider>(ctx,     listen: false).playYtId(id,
                      title: title, artist: artist, thumbnail: thumb);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildSkeletons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 220, radius: 20),
          const SizedBox(height: 24),
          ShimmerBox(width: 180, height: 20, radius: 8),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => ShimmerBox(width: 130, height: 130),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerBox(width: double.infinity, height: 64, radius: 14),
          )),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────
class _ArtistBubble extends StatelessWidget {
  final String   name;
  final String?  thumb;
  final VoidCallback onTap;
  const _ArtistBubble({required this.name, this.thumb, required this.onTap});


  static _ArtistBubble create({required String name, String? thumb, required VoidCallback onTap}) =>
      _ArtistBubble(name: name, thumb: thumb, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final textSub= isDark ? AriseColors.demonSubtext: AriseColors.angelSubtext;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .35), width: 2),
                gradient: LinearGradient(colors: [accent.withValues(alpha: .3), accent.withValues(alpha: .1)]),
              ),
              child: ClipOval(
                child: thumb != null && thumb!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumb ?? '', fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:22, fontWeight:FontWeight.w900)),
                        ),
                      )
                    : Center(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:22, fontWeight:FontWeight.w900)),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, textAlign:TextAlign.center, maxLines:2, overflow:TextOverflow.ellipsis,
              style: TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:11, fontWeight:FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String name, artist;
  final String? thumb;
  final VoidCallback onTap;
  const _AlbumCard({required this.name, required this.artist, this.thumb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final accent  = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final textPri = isDark ? AriseColors.demonText   : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext: AriseColors.angelSubtext;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: thumb ?? '',
                width: 120, height: 120, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width:120, height:120,
                  color: accent.withValues(alpha: .1),
                  child: Icon(Icons.album_rounded, color:accent, size:40),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, maxLines:1, overflow:TextOverflow.ellipsis,
              style: TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:12)),
            Text(artist, maxLines:1, overflow:TextOverflow.ellipsis,
              style: TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:11)),
          ],
        ),
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final String id, title, host, thumb;
  final VoidCallback onTap;
  const _PodcastCard({required this.id, required this.title, required this.host,
    required this.thumb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final accent  = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final textPri = isDark ? AriseColors.demonText   : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext: AriseColors.angelSubtext;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: thumb, width:130, height:130, fit:BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width:130, height:130,
                      color: accent.withValues(alpha: .1),
                      child: Icon(Icons.mic_rounded, color:accent, size:40),
                    ),
                  ),
                ),
                Positioned(top:6, right:6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:5, vertical:2),
                    decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(6)),
                    child: Text('PODCAST', style: TextStyle(
                      fontFamily:'Orbitron', color:Colors.white, fontSize:7, letterSpacing:.1)),
                  )),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, maxLines:2, overflow:TextOverflow.ellipsis,
              style: TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:12)),
            Text(host, maxLines:1, overflow:TextOverflow.ellipsis,
              style: TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:11)),
          ],
        ),
      ),
    );
  }
}


