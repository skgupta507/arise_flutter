import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class _Mood {
  final String id, title, desc, icon, query;
  final List<Color> gradient;
  const _Mood({required this.id, required this.title, required this.desc,
    required this.icon, required this.query, required this.gradient});
}

const _darkMoods = [
  _Mood(id:'dark-energy',  title:'Dark Energy',    desc:'Industrial · Techno · Rage',        icon:'⚡', query:'dark energy beats',          gradient:[Color(0xFF1a0000), Color(0xFF8B0000)]),
  _Mood(id:'night-drive',  title:'Night Drive',    desc:'Synthwave · Retrowave · Lo-Fi',     icon:'🌙', query:'night drive lofi synthwave',  gradient:[Color(0xFF0d001f), Color(0xFF4B0082)]),
  _Mood(id:'shadow-hours', title:'Shadow Hours',   desc:'Jazz · Soul · Neo-Soul',            icon:'🌊', query:'jazz soul midnight',          gradient:[Color(0xFF001122), Color(0xFF003366)]),
  _Mood(id:'abyss',        title:'Into the Abyss', desc:'Ambient · Post-Rock · Cinematic',   icon:'🔮', query:'ambient cinematic dark',       gradient:[Color(0xFF050508), Color(0xFF1a1a2e)]),
  _Mood(id:'bloodlust',    title:'Bloodlust',      desc:'Metal · Hardcore · Death Rock',     icon:'🩸', query:'metal hardcore rock',         gradient:[Color(0xFF3B0000), Color(0xFF660000)]),
  _Mood(id:'void',         title:'The Void',       desc:'Drone · Dark Ambient · Experimental',icon:'∅', query:'dark ambient experimental',   gradient:[Color(0xFF030305), Color(0xFF111120)]),
];

const _lightMoods = [
  _Mood(id:'morning-bliss',  title:'Morning Bliss',    desc:'Devotional · Peaceful · Spiritual', icon:'🌅', query:'morning bhajan devotional',       gradient:[Color(0xFFfff7d6), Color(0xFFfde68a)]),
  _Mood(id:'golden-ragas',   title:'Golden Ragas',     desc:'Indian Classical · Healing',         icon:'🪕', query:'indian classical ragas healing',  gradient:[Color(0xFFfffbeb), Color(0xFFfcd34d)]),
  _Mood(id:'divine-love',    title:'Divine Love',      desc:'Romantic · Sufi · Soulful',          icon:'💛', query:'sufi romantic soulful songs',     gradient:[Color(0xFFfff0f7), Color(0xFFfbcfe8)]),
  _Mood(id:'heavens-pop',    title:"Heaven's Pop",     desc:'Upbeat · Joyful · Bollywood',        icon:'✨', query:'happy upbeat bollywood hits',     gradient:[Color(0xFFf0fff4), Color(0xFFbbf7d0)]),
  _Mood(id:'celestial-lofi', title:'Celestial Lo-Fi',  desc:'Study · Calm · Meditative',          icon:'☁️', query:'lofi chill study music india',    gradient:[Color(0xFFeff6ff), Color(0xFFbfdbfe)]),
  _Mood(id:'vedic-chants',   title:'Vedic Chants',     desc:'Mantras · Chants · Sacred Hymns',    icon:'🕉️', query:'vedic mantra chant meditation',  gradient:[Color(0xFFfffbf0), Color(0xFFfef3c7)]),
];

class MoodSection extends StatelessWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final moods  = isDark ? _darkMoods : _lightMoods;
    final textPri= isDark ? AriseColors.demonText   : AriseColors.angelText;
    final textMut= isDark ? AriseColors.demonMuted  : AriseColors.angelMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isDark ? '🔥 Mood Playlists' : '✨ Angelic Playlists',
          style: TextStyle(fontFamily:'Rajdhani', color:textPri,
              fontWeight:FontWeight.w700, fontSize:17)),
        const SizedBox(height: 2),
        Text(isDark ? 'Curated for your state of mind' : 'Curated for your divine journey',
          style: TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:12)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap:   true,
          physics:      const NeverScrollableScrollPhysics(),
          itemCount:    moods.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemBuilder: (_, i) {
            final m = moods[i];
            return GestureDetector(
              onTap: () => context.go('/search/${Uri.encodeComponent(m.query)}'),
              child: Container(
                decoration: BoxDecoration(
                  gradient:     LinearGradient(colors: m.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(
                    color: isDark ? Colors.white.withValues(alpha: .04) : Colors.black.withValues(alpha: .05)),
                ),
                padding: const EdgeInsets.symmetric(horizontal:12, vertical:10),
                child: Stack(
                  children: [
                    Positioned(top:0, right:0,
                      child: Text(m.icon, style: const TextStyle(fontSize:22))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        Text(m.title, style: TextStyle(
                          fontFamily:'Rajdhani', color: isDark ? Colors.white : const Color(0xFF2a1a00),
                          fontWeight:FontWeight.w700, fontSize:13)),
                        Text(m.desc, maxLines:1, overflow:TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily:'Rajdhani', fontSize:10,
                            color: isDark ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
