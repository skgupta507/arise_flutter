import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lib    = context.watch<LibraryProvider>();
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final bg     = isDark ? AriseColors.demonBg     : AriseColors.angelBg;
    final textMut= isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Liked Songs', style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
        actions: [
          if (lib.liked.isNotEmpty)
            IconButton(
              icon: Icon(Icons.play_arrow_rounded, color:accent),
              tooltip: 'Play All',
              onPressed: () => player.play(lib.liked.first, queue:lib.liked.skip(1).toList()),
            ),
        ],
      ),
      body: lib.liked.isEmpty
          ? Center(child:Column(mainAxisSize:MainAxisSize.min, children:[
              Icon(Icons.favorite_border_rounded, color:textMut, size:64),
              const SizedBox(height:16),
              Text('No liked songs yet', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:16)),
              Text('Tap ♥ on any song to add it here', style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lib.liked.length,
              itemBuilder: (_, i) => SongTile(song:lib.liked[i], queue:lib.liked, showIndex:true, index:i),
            ),
    );
  }
}
