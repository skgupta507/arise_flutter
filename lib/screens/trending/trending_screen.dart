import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../models/song_model.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<SongModel> _items = [];
  bool _loading = true;

  static const _cats = [
    ('🔥 All',      'trending hits india 2025'),
    ('🎬 Bollywood','trending bollywood songs 2025'),
    ('🎤 Punjabi',  'trending punjabi songs 2025'),
    ('🌙 Lo-Fi',    'lofi hindi chill music'),
    ('🎶 New',      'new hindi songs 2025'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _cats.length, vsync: this)
      ..addListener(() { if (!_tabs.indexIsChanging) _load(_tabs.index); });
    _load(0);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load(int i) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await SaavnApi.searchSongs(_cats[i].$2, limit: 30);
    if (!mounted) return;
    setState(() { _items = results.map(SongModel.fromSaavn).toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final bg     = isDark ? AriseColors.demonBg     : AriseColors.angelBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Trending India', style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
        bottom: TabBar(
          controller:          _tabs,
          indicatorColor:      accent,
          labelColor:          accent,
          unselectedLabelColor:isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
          labelStyle:          const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:12),
          isScrollable:        true,
          tabs:                _cats.map((c) => Tab(text:c.$1)).toList(),
        ),
      ),
      body: _loading
          ? Center(child:CircularProgressIndicator(color:accent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) => SongTile(song:_items[i], queue:_items, showIndex:true, index:i),
            ),
    );
  }
}

