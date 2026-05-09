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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SongModel>            _trendingSongs    = [];
  List<SongModel>            _trendingVideos   = [];
  List<Map<String, dynamic>> _trendingPlaylists= [];
  List<SongModel>            _bollywood        = [];
  List<SongModel>            _latest           = [];
  List<SongModel>            _lofi             = [];
  List<Map<String, dynamic>> _albums           = [];
  List<Map<String, dynamic>> _artists          = [];

  bool    _loading   = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _loadError = null; });

    try {
      final results = await Future.wait([
        MuzoApi.trending(),
        SaavnApi.searchSongs('bollywood hits 2025',       limit: 20),
        SaavnApi.searchSongs('new hindi songs 2025',      limit: 20),
        SaavnApi.searchSongs('lofi hindi chill',          limit: 16),
        SaavnApi.searchAlbums('new hindi album 2025',     limit: 14),
        SaavnApi.searchArtists('trending indian artists', limit: 14),
      ]);

      if (!mounted) return;

      final trending   = results[0] as Map<String, dynamic>;
      final tSongs     = (trending['songs']    as List? ?? []).whereType<Map<String, dynamic>>().toList();
      final tVideos    = (trending['videos']   as List? ?? []).whereType<Map<String, dynamic>>().toList();
      final tPlaylists = (trending['playlists']as List? ?? []).whereType<Map<String, dynamic>>().toList();

      SongModel _muzoToSong(Map<String, dynamic> m) {
        final id = m['id']?.toString() ?? '';
        return SongModel(
          id:        id, ytId: id,
          title:     m['title']?.toString()     ?? '',
          artist:    m['artist']?.toString()    ?? '',
          thumbnail: m['thumbnail']?.toString() ?? 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
          source:    'youtube',
          addedAt:   DateTime.now().millisecondsSinceEpoch,
        );
      }

      setState(() {
        _trendingSongs     = tSongs.take(20).map(_muzoToSong).toList();
        _trendingVideos    = tVideos.take(20).map(_muzoToSong).toList();
        _trendingPlaylists = tPlaylists.take(10).toList();
        _bollywood = (results[1] as List<Map<String, dynamic>>).map(SongModel.fromSaavn).toList();
        _latest    = (results[2] as List<Map<String, dynamic>>).map(SongModel.fromSaavn).toList();
        _lofi      = (results[3] as List<Map<String, dynamic>>).map(SongModel.fromSaavn).toList();
        _albums    =  results[4] as List<Map<String, dynamic>>;
        _artists   =  results[5] as List<Map<String, dynamic>>;
        _loading   = false;
      });
    } catch (e) {
      debugPrint('HomeScreen._load error: $e');
      if (mounted) setState(() { _loading = false; _loadError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final player  = Provider.of<PlayerProvider>(context, listen: false);
    final bg      = isDark ? AriseColors.demonBg     : AriseColors.angelBg;
    final accent  = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final textMut = isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color:     accent,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── App bar ────────────────────────────────────────────────────
            SliverAppBar(
              floating:        true,
              snap:            true,
              backgroundColor: bg,
              elevation:       0,
              titleSpacing:    16,
              title: Row(
                children: [
                  // Logo + title
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: .6)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arise Music', style: TextStyle(
                        fontFamily: 'Orbitron', color: accent,
                        fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: .3)),
                      Text(
                        isDark ? '✦ Rise from the Shadows ✦' : '✦ Hear the Divine ✦',
                        style: TextStyle(fontFamily: 'Orbitron', color: textMut, fontSize: 8),
                      ),
                    ],
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
                    color: accent),
                  onPressed: () =>
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverToBoxAdapter(
              child: _loading
                  ? _buildSkeletons()
                  : _loadError != null && _trendingSongs.isEmpty
                      ? _buildError(accent, textMut)
                      : _buildContent(context, player, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick-access chips (VIVI-style) ────────────────────────────────────────
  Widget _buildQuickChips(BuildContext ctx, bool isDark) {
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final card    = isDark ? AriseColors.demonCard    : AriseColors.angelCard;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;

    final chips = [
      ('❤️ Liked',     '/liked',    Icons.favorite_rounded),
      ('🕐 Recent',    '/recent',   Icons.history_rounded),
      ('📋 Playlists', '/playlists',Icons.queue_music_rounded),
      ('🎤 Artists',   '/artists',  Icons.mic_rounded),
      ('💿 Albums',    '/albums',   Icons.album_rounded),
      ('🎙 Podcasts',  '/podcasts', Icons.podcasts_rounded),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, route, icon) = chips[i];
          return GestureDetector(
            onTap: () => ctx.go(route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:        card,
                borderRadius: BorderRadius.circular(22),
                border:       Border.all(color: accent.withValues(alpha: .25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: accent, size: 14),
                  const SizedBox(width: 6),
                  Text(label.split(' ').last, style: TextStyle(
                    fontFamily: 'Rajdhani', color: textPri,
                    fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, PlayerProvider player, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero banner ────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
          child:   HomeHero(),
        ),
        const SizedBox(height: 16),

        // ── Quick-access chips (VIVI-style) ────────────────────────────────
        _buildQuickChips(ctx, isDark),
        const SizedBox(height: 24),

        // ── Trending Songs (Muzo — YouTube Music) ─────────────────────────
        if (_trendingSongs.isNotEmpty) ...[
          HScrollSection(
            title:       isDark ? '🔥 Trending Now' : '✨ Trending Now',
            subtitle:    'YouTube Music · Global',
            seeAllRoute: '/trending',
            height:      210,
            children:    _trendingSongs.map((s) => SongCard(song: s, queue: _trendingSongs)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Top Artists ────────────────────────────────────────────────────
        if (_artists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:       isDark ? '🎤 Top Artists' : '🎤 Top Artists',
              subtitle:    'JioSaavn · India',
              seeAllRoute: '/artists',
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:         const EdgeInsets.symmetric(horizontal: 16),
              itemCount:       _artists.length,
              separatorBuilder:(_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final a      = _artists[i];
                final name   = a['name']?.toString() ?? '';
                final images = a['image'] as List?;
                final thumb  = images != null && images.length > 1
                    ? images[1]['url']?.toString()
                    : images?.lastOrNull?['url']?.toString();
                return _ArtistBubble(
                  name:  name,
                  thumb: thumb ?? '',
                  onTap: () => ctx.go('/artists/${a['id']}?name=${Uri.encodeComponent(name)}'),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Bollywood Hits ─────────────────────────────────────────────────
        if (_bollywood.isNotEmpty) ...[
          HScrollSection(
            title:       '🎬 Bollywood Hits',
            subtitle:    'JioSaavn · Hindi',
            seeAllRoute: '/search/bollywood hits',
            height:      210,
            children:    _bollywood.map((s) => SongCard(song: s, queue: _bollywood)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── New Releases (list style like VIVI) ────────────────────────────
        if (_latest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:       isDark ? '💿 New Releases' : '💿 New Releases',
              subtitle:    'JioSaavn · Latest',
              seeAllRoute: '/albums',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _latest.take(6).map((s) => SongTile(
                song:      s,
                queue:     _latest,
                showIndex: true,
                index:     _latest.indexOf(s),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Trending Videos ────────────────────────────────────────────────
        if (_trendingVideos.isNotEmpty) ...[
          HScrollSection(
            title:    '🎬 Trending Videos',
            subtitle: 'YouTube · Global',
            height:   210,
            children: _trendingVideos.map((s) => SongCard(song: s, queue: _trendingVideos)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Lo-Fi & Chill ──────────────────────────────────────────────────
        if (_lofi.isNotEmpty) ...[
          HScrollSection(
            title:    isDark ? '🌙 Lo-Fi & Chill' : '☁️ Lo-Fi & Chill',
            subtitle: 'JioSaavn · Relax',
            height:   210,
            children: _lofi.map((s) => SongCard(song: s, queue: _lofi)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Trending Playlists ─────────────────────────────────────────────
        if (_trendingPlaylists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:    '📋 Trending Playlists',
              subtitle: 'YouTube Music · Curated',
            ),
          ),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:         const EdgeInsets.symmetric(horizontal: 16),
              itemCount:       _trendingPlaylists.length,
              separatorBuilder:(_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p      = _trendingPlaylists[i];
                final id     = p['id']?.toString()        ?? '';
                final title  = p['title']?.toString()     ?? '';
                final thumb  = p['thumbnail']?.toString() ?? '';
                final artist = p['artist']?.toString()    ?? '';
                return _PlaylistCard(
                  title:  title, artist: artist, thumb: thumb,
                  onTap:  () => player.playYtId(id, title: title, artist: artist, thumbnail: thumb),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Albums ─────────────────────────────────────────────────────────
        if (_albums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title:       '💿 Albums',
              subtitle:    'JioSaavn · Collections',
              seeAllRoute: '/albums',
            ),
          ),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:         const EdgeInsets.symmetric(horizontal: 16),
              itemCount:       _albums.length,
              separatorBuilder:(_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final a      = _albums[i];
                final images = a['image'] as List?;
                final thumb  = images != null && images.length > 1
                    ? images[1]['url']?.toString() : null;
                return _AlbumCard(
                  name:   a['name']?.toString()        ?? '',
                  artist: a['description']?.toString() ?? '',
                  thumb:  thumb,
                  onTap:  () => ctx.go('/albums/${a['id']}'),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildError(Color accent, Color textMut) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(Icons.wifi_off_rounded, color: textMut, size: 48),
        const SizedBox(height: 12),
        Text('Could not load content',
            style: TextStyle(fontFamily: 'Rajdhani', color: textMut, fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ],
    ),
  );

  Widget _buildSkeletons() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: double.infinity, height: 220, radius: 20),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => ShimmerBox(width: 90, height: 44, radius: 22),
          ),
        ),
        const SizedBox(height: 24),
        ShimmerBox(width: 160, height: 18, radius: 8),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => ShimmerBox(width: 130, height: 160),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(4, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child:   ShimmerBox(width: double.infinity, height: 64, radius: 14),
        )),
      ],
    ),
  );
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ArtistBubble extends StatelessWidget {
  final String name, thumb;
  final VoidCallback onTap;
  const _ArtistBubble({required this.name, required this.thumb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .4), width: 2),
                gradient: LinearGradient(colors: [
                  accent.withValues(alpha: .3), accent.withValues(alpha: .1)]),
              ),
              child: ClipOval(
                child: thumb.isNotEmpty
                    ? CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _initial(name, accent))
                    : _initial(name, accent),
              ),
            ),
            const SizedBox(height: 5),
            Text(name,
              textAlign: TextAlign.center, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Rajdhani', color: textSub,
                fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _initial(String name, Color accent) => Center(
    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(fontFamily: 'Orbitron', color: accent,
        fontSize: 20, fontWeight: FontWeight.w900)),
  );
}

class _AlbumCard extends StatelessWidget {
  final String name, artist;
  final String? thumb;
  final VoidCallback onTap;
  const _AlbumCard({required this.name, required this.artist, this.thumb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: thumb ?? '', width: 120, height: 120, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 120, height: 120, color: accent.withValues(alpha: .1),
                  child: Icon(Icons.album_rounded, color: accent, size: 40)),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Rajdhani', color: textPri,
                fontWeight: FontWeight.w700, fontSize: 12)),
            Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Rajdhani', color: textSub, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String title, artist, thumb;
  final VoidCallback onTap;
  const _PlaylistCard({required this.title, required this.artist,
    required this.thumb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: thumb, width: 130, height: 130, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 130, height: 130, color: accent.withValues(alpha: .1),
                      child: Icon(Icons.queue_music_rounded, color: accent, size: 40)),
                  ),
                ),
                Positioned(top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(6)),
                    child: const Text('PLAYLIST', style: TextStyle(
                      fontFamily: 'Orbitron', color: Colors.white,
                      fontSize: 7, letterSpacing: .1)),
                  )),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Rajdhani', color: textPri,
                fontWeight: FontWeight.w700, fontSize: 12)),
            Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Rajdhani', color: textSub, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
