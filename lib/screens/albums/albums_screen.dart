import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});
  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String,dynamic>> _items = [];
  bool _loading = true;

  static const _genres = [
    ('🆕 New',      'new hindi album 2025'),
    ('🎬 Bollywood','bollywood album 2025'),
    ('🎤 Punjabi',  'punjabi album 2025'),
    ('🎸 Indie',    'indie hindi album'),
    ('📻 Retro',    'classic hindi songs album'),
    ('🌍 English',  'top english album 2025'),
    ('🌙 Lo-Fi',    'lofi hindi album'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _genres.length, vsync: this)
      ..addListener(() { if (!_tabs.indexIsChanging) _load(_tabs.index); });
    _load(0);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load(int i) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await SaavnApi.searchAlbums(_genres[i].$2, limit: 20);
    if (!mounted) return;
    setState(() { _items = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final accent = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg     = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri= isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub= isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final card   = isDark ? AriseColors.demonCard    : AriseColors.angelCard;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Albums', style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
        bottom: TabBar(
          controller:          _tabs,
          indicatorColor:      accent,
          labelColor:          accent,
          unselectedLabelColor:isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
          labelStyle:          const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:12),
          isScrollable:        true,
          tabs:                _genres.map((g) => Tab(text: g.$1)).toList(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final a      = _items[i];
                final images = a['image'] as List?;
                final thumb  = images != null && images.length > 1
                    ? images[1]['url']?.toString()
                    : images?.lastOrNull?['url']?.toString();
                final name   = a['name']?.toString() ?? '';
                final artist = a['description']?.toString() ?? '';
                return GestureDetector(
                  onTap: () => context.go('/albums/${a['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: thumb != null
                              ? CachedNetworkImage(
                                  imageUrl:    thumb,
                                  fit:         BoxFit.cover,
                                  width:       double.infinity,
                                  errorWidget: (_, __, ___) => Container(
                                    color: accent.withOpacity(.1),
                                    child: Icon(Icons.album_rounded, color: accent, size: 50),
                                  ),
                                )
                              : Container(
                                  color: accent.withOpacity(.1),
                                  child: Icon(Icons.album_rounded, color: accent, size: 50),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:13)),
                      Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:12)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

extension _ListExt<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
