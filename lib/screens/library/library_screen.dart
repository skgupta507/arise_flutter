import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';
import '../../widgets/common/section_header.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lib    = context.watch<LibraryProvider>();
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final bg     = isDark ? AriseColors.demonBg     : AriseColors.angelBg;
    final textPri= isDark ? AriseColors.demonText   : AriseColors.angelText;
    final textMut= isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;

    final quickLinks = [
      _QuickLink(icon:Icons.favorite_rounded,       label:'Liked Songs',      sub:'${lib.likedCount} songs',   color:accent,                  route:'/liked'),
      _QuickLink(icon:Icons.history_rounded,        label:'Recently Played',  sub:'${lib.recentlyPlayed.length} tracks', color:const Color(0xFF9D4EDD), route:'/recent'),
      _QuickLink(icon:Icons.queue_music_rounded,    label:'My Playlists',     sub:'${lib.plCount} playlists',  color:const Color(0xFF4285F4), route:'/playlists'),
      _QuickLink(icon:Icons.album_rounded,          label:'Albums',           sub:'Browse albums',             color:const Color(0xFF1DB954), route:'/albums'),
      _QuickLink(icon:Icons.people_rounded,         label:'Artists',          sub:'Browse artists',            color:const Color(0xFFFF9500), route:'/artists'),
      _QuickLink(icon:Icons.mic_rounded,            label:'Podcasts',         sub:'Listen & learn',            color:const Color(0xFFFF6B35), route:'/podcasts'),
      _QuickLink(icon:Icons.trending_up_rounded,   label:'Trending',         sub:'What\'s hot now',           color:const Color(0xFFFF4081), route:'/trending'),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Library', style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick links grid
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: quickLinks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:2, mainAxisSpacing:10, crossAxisSpacing:10, childAspectRatio:2.5),
            itemBuilder: (_, i) {
              final l = quickLinks[i];
              return GestureDetector(
                onTap: () => context.go(l.route),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AriseColors.demonCard : AriseColors.angelCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AriseColors.demonBorder : AriseColors.angelBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal:14, vertical:12),
                  child: Row(children:[
                    Container(width:36, height:36,
                      decoration: BoxDecoration(color:l.color.withValues(alpha: .15), borderRadius:BorderRadius.circular(10)),
                      child: Icon(l.icon, color:l.color, size:18)),
                    const SizedBox(width:10),
                    Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, mainAxisAlignment:MainAxisAlignment.center, children:[
                      Text(l.label, style:TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700, fontSize:13), overflow:TextOverflow.ellipsis),
                      Text(l.sub,   style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:11), overflow:TextOverflow.ellipsis),
                    ])),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent songs
          if (lib.recentlyPlayed.isNotEmpty) ...[
            SectionHeader(
              title: '⏱ Recently Played',
              onSeeAll: () => context.go('/recent'),
            ),
            ...lib.recentlyPlayed.take(8).map((s) => SongTile(
              song:s, queue:lib.recentlyPlayed,
              showIndex:true, index:lib.recentlyPlayed.indexOf(s),
            )),
          ] else
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children:[
                Text(isDark ? '🔮' : '✨', style:const TextStyle(fontSize:48)),
                const SizedBox(height:12),
                Text('Your library is empty', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:15)),
                Text('Start listening to build your collection', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:13)),
              ]),
            )),
        ],
      ),
    );
  }
}

class _QuickLink {
  final IconData icon; final String label, sub, route; final Color color;
  const _QuickLink({required this.icon, required this.label, required this.sub, required this.route, required this.color});
}

// ══════════════════════════════════════════════════════════════════════════════
// These simple screens are defined here to keep file count manageable
// Each imports what it needs
