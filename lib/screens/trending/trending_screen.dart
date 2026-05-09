import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../api/muzo_api.dart';
import '../../models/song_model.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Tab 0 = Muzo global trending, tabs 1-4 = Saavn genre searches
  static const _cats = [
    ('🌍 Global',   ''),
    ('🎬 Bollywood','trending bollywood songs 2025'),
    ('🎤 Punjabi',  'trending punjabi songs 2025'),
    ('🌙 Lo-Fi',    'lofi hindi chill music'),
    ('🎶 New',      'new hindi songs 2025'),
  ];

  List<SongModel> _items   = [];
  bool            _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _cats.length, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) _load(_tabs.index);
      });
    _load(0);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load(int i) async {
    if (!mounted) return;
    setState(() => _loading = true);

    List<SongModel> items = [];

    if (i == 0) {
      // Muzo global trending — songs + videos combined
      final trending = await MuzoApi.trending();
      final songs  = (trending['songs']  as List? ?? []).whereType<Map<String, dynamic>>();
      final videos = (trending['videos'] as List? ?? []).whereType<Map<String, dynamic>>();
      items = [...songs, ...videos].map((m) {
        final id = m['id']?.toString() ?? '';
        return SongModel(
          id:        id,
          ytId:      id,
          title:     m['title']?.toString()     ?? '',
          artist:    m['artist']?.toString()    ?? '',
          thumbnail: m['thumbnail']?.toString() ??
              'https://i.ytimg.com/vi/$id/hqdefault.jpg',
          source:    'youtube',
          addedAt:   DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();
    } else {
      final results = await SaavnApi.searchSongs(_cats[i].$2, limit: 30);
      items = results.map(SongModel.fromSaavn).toList();
    }

    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final bg     = isDark ? AriseColors.demonBg     : AriseColors.angelBg;
    final muted  = isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Trending',
            style: TextStyle(
                fontFamily: 'Orbitron', color: accent, fontSize: 16)),
        bottom: TabBar(
          controller:          _tabs,
          indicatorColor:      accent,
          labelColor:          accent,
          unselectedLabelColor:muted,
          labelStyle: const TextStyle(
              fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 12),
          isScrollable: true,
          tabs: _cats.map((c) => Tab(text: c.$1)).toList(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _items.isEmpty
              ? Center(
                  child: Text('Nothing found',
                      style: TextStyle(
                          fontFamily: 'Rajdhani', color: muted, fontSize: 15)))
              : ListView.builder(
                  padding:     const EdgeInsets.all(16),
                  itemCount:   _items.length,
                  itemBuilder: (_, i) => SongTile(
                    song:      _items[i],
                    queue:     _items,
                    showIndex: true,
                    index:     i,
                  ),
                ),
    );
  }
}
