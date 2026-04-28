import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = i.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final accent2 = isDark ? AriseColors.demonAccent2 : AriseColors.angelAccent2;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('About', style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AriseColors.demonAccent.withValues(alpha: .15), AriseColors.demonBg]
                    : [AriseColors.angelAccent.withValues(alpha: .12), AriseColors.angelBg],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Text(isDark ? '🔥' : '✨', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (r) => LinearGradient(colors:[accent, accent2]).createShader(r),
                  child: Text('Arise Music', style:const TextStyle(
                    fontFamily:'Orbitron', fontSize:28, fontWeight:FontWeight.w900, color:Colors.white)),
                ),
                const SizedBox(height: 6),
                Text('v$_version', style:TextStyle(fontFamily:'Orbitron', color:textMut, fontSize:12)),
                const SizedBox(height: 10),
                Text(
                  isDark
                      ? '"Where darkness meets divinity, and sound becomes soul."'
                      : '"Every note is a prayer. Every beat, a pulse of the divine."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:14, fontStyle:FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Two Souls
          Text('⚔️ Two Souls, One App', style:TextStyle(fontFamily:'Orbitron', color:textPri, fontWeight:FontWeight.w700, fontSize:15)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SoulCard(
              emoji: '🔥', title: 'Demon Theme', isDark: isDark,
              desc: 'Crimson glow · Fire & smoke particles · Industrial beats for the relentless.',
              gradient: [const Color(0xFF1a0000), const Color(0xFF8B0000)],
            )),
            const SizedBox(width: 12),
            Expanded(child: _SoulCard(
              emoji: '✨', title: 'Angel Theme', isDark: isDark,
              desc: 'Golden dust · Ivory palette · Divine bhajans for the luminous soul.',
              gradient: [const Color(0xFFfff7d6), const Color(0xFFfde68a)],
              textDark: true,
            )),
          ]),
          const SizedBox(height: 20),

          // Features
          Text('🎵 Features', style:TextStyle(fontFamily:'Orbitron', color:textPri, fontWeight:FontWeight.w700, fontSize:15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              'JioSaavn (100M+ Songs)', 'YouTube Music', 'Muzo API',
              'Background Playback', 'Lock Screen Controls', 'Auto-Queue',
              'Playlists', 'Liked Songs', 'Recently Played',
              'Podcasts', 'Trending India', 'Dark & Light Theme',
              'In-App Updates', 'Offline detection', 'Artist detail pages',
            ].map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
              decoration: BoxDecoration(
                color:        accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color:accent.withValues(alpha: .2)),
              ),
              child: Text(f, style:TextStyle(fontFamily:'Rajdhani', color:accent, fontSize:12, fontWeight:FontWeight.w600)),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Tech stack
          Text('⚙️ Built With', style:TextStyle(fontFamily:'Orbitron', color:textPri, fontWeight:FontWeight.w700, fontSize:15)),
          const SizedBox(height: 12),
          ...['Flutter 3.16+', 'Dart 3.2+', 'just_audio + audio_service',
              'JioSaavn API', 'Muzo Backend', 'Hive (local DB)',
              'Dio HTTP', 'GoRouter', 'Provider'].map((t) => ListTile(
            dense:    true,
            leading:  Icon(Icons.check_circle_rounded, color:accent, size:18),
            title:    Text(t, style:TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:14)),
          )),
          const SizedBox(height: 20),

          // Links
          Text('🔗 Links', style:TextStyle(fontFamily:'Orbitron', color:textPri, fontWeight:FontWeight.w700, fontSize:15)),
          const SizedBox(height: 12),
          ...[
            ('GitHub',    'https://github.com/skgupta507',          Icons.code_rounded),
            ('Twitter',   'https://x.com/sk_gupta143',              Icons.alternate_email_rounded),
            ('Instagram', 'https://instagram.com/sk.gupta507',      Icons.camera_alt_rounded),
            ('YouTube',   'https://www.youtube.com/@sk.gupta50',    Icons.play_circle_rounded),
          ].map((l) => ListTile(
            leading:  Icon(l.$3, color:accent),
            title:    Text(l.$1, style:TextStyle(fontFamily:'Rajdhani', color:textPri, fontWeight:FontWeight.w700)),
            subtitle: Text(l.$2, style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:12)),
            trailing: Icon(Icons.open_in_new_rounded, color:textMut, size:18),
            onTap:    () => launchUrl(Uri.parse(l.$2)),
          )),

          const SizedBox(height: 20),
          Center(child:Text(
            isDark ? '🔥 Crafted in darkness by Sunil' : '✨ Crafted in light by Sunil',
            style:TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:13))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SoulCard extends StatelessWidget {
  final String emoji, title, desc;
  final bool isDark, textDark;
  final List<Color> gradient;
  const _SoulCard({required this.emoji, required this.title, required this.desc,
    required this.isDark, required this.gradient, this.textDark = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient:     LinearGradient(colors:gradient, begin:Alignment.topLeft, end:Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(emoji, style:const TextStyle(fontSize:28)),
      const SizedBox(height:6),
      Text(title, style:TextStyle(fontFamily:'Orbitron', fontSize:12, fontWeight:FontWeight.w700,
        color: textDark ? const Color(0xFF2a1a00) : Colors.white)),
      const SizedBox(height:4),
      Text(desc, style:TextStyle(fontFamily:'Rajdhani', fontSize:11,
        color: textDark ? Colors.black54 : Colors.white70)),
    ]),
  );
}
