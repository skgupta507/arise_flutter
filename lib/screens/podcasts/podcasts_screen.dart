import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/muzo_api.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});
  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  static const _categories = [
    ('🕉️ Mythology',      'indian mythology spiritual podcast'),
    ('🔍 True Crime',      'true crime india podcast hindi'),
    ('😂 Comedy',          'indian comedy podcast stand up hindi'),
    ('🏏 Cricket',         'cricket sports podcast india hindi'),
    ('💡 Startup',         'startup business podcast india hindi'),
    ('🏛️ History',         'indian history podcast hindi'),
    ('🎬 Bollywood',       'bollywood podcast behind scenes celebrity'),
    ('🧘 Health',          'health ayurveda wellness podcast india'),
    ('👻 Horror',          'horror paranormal stories podcast hindi'),
    ('💰 Finance',         'personal finance india investing podcast'),
    ('🧠 Philosophy',      'philosophy life lessons podcast hindi'),
    ('🧒 Kids',            'kids stories podcast hindi children'),
  ];

  int _selectedCat = 0;
  List<Map<String,dynamic>> _podcasts  = [];
  List<Map<String,dynamic>> _featured  = [];
  bool _loadingFeat = true;
  bool _loadingCat  = false;
  final Map<int, List<Map<String,dynamic>>> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadCategory(0);
  }

  Future<void> _loadFeatured() async {
    final r = await MuzoApi.searchPodcasts('popular indian podcast');
    if (!mounted) return;
    setState(() { _featured = r.take(8).toList(); _loadingFeat = false; });
  }

  Future<void> _loadCategory(int i) async {
    if (_cache.containsKey(i)) {
      setState(() { _podcasts = _cache[i]!; _selectedCat = i; });
      return;
    }
    setState(() { _loadingCat = true; _selectedCat = i; });
    final r = await MuzoApi.searchPodcasts(_categories[i].$2);
    if (!mounted) return;
    _cache[i] = r;
    setState(() { _podcasts = r; _loadingCat = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final player  = Provider.of<PlayerProvider>(context, listen: false);
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Podcasts', style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
      ),
      body: CustomScrollView(
        slivers: [
          // Featured row
          if (!_loadingFeat && _featured.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text('Featured', style:TextStyle(fontFamily:'Rajdhani',
                      color:textPri, fontWeight:FontWeight.w700, fontSize:17)),
                  ),
                  SizedBox(
                    height: 175,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal:16),
                      itemCount: _featured.length,
                      separatorBuilder:(_, __) => const SizedBox(width:12),
                      itemBuilder:(_, i) => _PodcastCard(
                        item:    _featured[i],
                        accent:  accent,
                        textPri: textPri,
                        textSub: textSub,
                        onPlay:  (id, title, artist, thumb) => player.playYtId(
                          id, title:title, artist:artist, thumbnail:thumb),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal:16),
                itemCount: _categories.length,
                separatorBuilder:(_, __) => const SizedBox(width:8),
                itemBuilder:(_, i) {
                  final selected = _selectedCat == i;
                  return GestureDetector(
                    onTap: () => _loadCategory(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds:200),
                      padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
                      decoration: BoxDecoration(
                        color:        selected ? accent : (isDark ? AriseColors.demonCard : AriseColors.angelCard),
                        borderRadius: BorderRadius.circular(20),
                        border:       Border.all(color: selected ? Colors.transparent : (isDark ? AriseColors.demonBorder : AriseColors.angelBorder)),
                      ),
                      child: Text(_categories[i].$1, style:TextStyle(
                        fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:13,
                        color: selected ? Colors.white : textSub)),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height:16)),

          // Category results
          _loadingCat
              ? const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(32), child: CircularProgressIndicator())))
              : _podcasts.isEmpty
                  ? SliverToBoxAdapter(child: Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No podcasts found', style:TextStyle(fontFamily:'Rajdhani', color:textMut)))))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal:16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:2, mainAxisSpacing:14, crossAxisSpacing:14, childAspectRatio:.82),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _PodcastCard(
                            item:    _podcasts[i],
                            accent:  accent,
                            textPri: textPri,
                            textSub: textSub,
                            onPlay:  (id, title, artist, thumb) => player.playYtId(
                              id, title:title, artist:artist, thumbnail:thumb),
                          ),
                          childCount: _podcasts.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height:120)),
        ],
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final Map<String,dynamic> item;
  final Color accent, textPri, textSub;
  final void Function(String id, String title, String artist, String thumb) onPlay;

  const _PodcastCard({
    required this.item, required this.accent,
    required this.textPri, required this.textSub, required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final id     = item['videoId']?.toString() ?? item['id']?.toString() ?? '';
    final title  = item['title']?.toString() ?? item['name']?.toString() ?? '';
    final artist = (item['artists'] as List?)?.map((a) => a['name']?.toString() ?? a.toString()).join(', ')
        ?? item['channelTitle']?.toString() ?? '';
    final thumb  = MuzoApi.thumbnail(item) ?? '';

    return GestureDetector(
      onTap: () { if (id.isNotEmpty) onPlay(id, title, artist, thumb); },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: thumb.isNotEmpty
                      ? CachedNetworkImage(imageUrl:thumb, fit:BoxFit.cover,
                          errorWidget:(_,__,___)=>Container(color:accent.withValues(alpha: .1),
                            child:Icon(Icons.mic_rounded, color:accent, size:40)))
                      : Container(color:accent.withValues(alpha: .1),
                          child:Icon(Icons.mic_rounded, color:accent, size:40)),
                ),
                Positioned(top:6, right:6,
                  child:Container(
                    padding: const EdgeInsets.symmetric(horizontal:5, vertical:2),
                    decoration:BoxDecoration(color:accent, borderRadius:BorderRadius.circular(6)),
                    child:Text('PODCAST', style:TextStyle(fontFamily:'Orbitron',
                      color:Colors.white, fontSize:7, letterSpacing:.1)))),
                Positioned.fill(
                  child:Material(color:Colors.transparent,
                    child:InkWell(borderRadius:BorderRadius.circular(14), onTap:(){
                      if(id.isNotEmpty) onPlay(id, title, artist, thumb);}))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(title, maxLines:2, overflow:TextOverflow.ellipsis,
            style:TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:12)),
          Text(artist, maxLines:1, overflow:TextOverflow.ellipsis,
            style:TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:11)),
        ],
      ),
    );
  }
}

