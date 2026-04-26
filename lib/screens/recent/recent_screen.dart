import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lib    = context.watch<LibraryProvider>();
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    final bg     = isDark ? AriseColors.demonBg     : AriseColors.angelBg;
    final textMut= isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Recently Played', style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
        actions: [
          if (lib.recentlyPlayed.isNotEmpty)
            TextButton.icon(
              icon: Icon(Icons.delete_outline_rounded, color:Colors.redAccent, size:18),
              label: const Text('Clear', style:TextStyle(color:Colors.redAccent, fontFamily:'Rajdhani')),
              onPressed: lib.clearHistory,
            ),
        ],
      ),
      body: lib.recentlyPlayed.isEmpty
          ? Center(child:Text('Nothing played yet — start listening!',
              style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:15)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lib.recentlyPlayed.length,
              itemBuilder: (_, i) => SongTile(song:lib.recentlyPlayed[i], queue:lib.recentlyPlayed, showIndex:true, index:i),
            ),
    );
  }
}
