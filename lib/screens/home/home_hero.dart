import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class _FeaturedItem {
  final String title, subtitle, desc, badge, query, image;
  final Color accent;
  const _FeaturedItem({
    required this.title, required this.subtitle, required this.desc,
    required this.badge, required this.query, required this.image, required this.accent,
  });
}

const _dark = [
  _FeaturedItem(title:'Dark Energy', subtitle:'Playlist · Mood',
    desc:'Industrial beats and midnight frequencies for the relentless.',
    badge:'HOT', query:'dark energy beats', accent:Color(0xFFFF003C),
    image:'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&q=80'),
  _FeaturedItem(title:'Night Drive', subtitle:'Playlist · Synthwave',
    desc:'Lo-fi and synthwave for roads lit by nothing but instinct.',
    badge:'NEW', query:'night drive lofi synthwave', accent:Color(0xFF9D4EDD),
    image:'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80'),
  _FeaturedItem(title:'Shadow Hours', subtitle:'Playlist · Jazz',
    desc:'Jazz, soul, and broken blues for the moments between hours.',
    badge:'DEEP', query:'jazz soul midnight', accent:Color(0xFF0088FF),
    image:'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&q=80'),
];

const _light = [
  _FeaturedItem(title:'Divine Morning', subtitle:'Playlist · Devotional',
    desc:'Peaceful melodies and golden harmonies to start your day.',
    badge:'DIVINE', query:'morning meditation bhajan', accent:Color(0xFFD4AF37),
    image:'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800&q=80'),
  _FeaturedItem(title:'Golden Bhajans', subtitle:'Playlist · Sacred',
    desc:'Sacred hymns and devotional songs that lift the soul.',
    badge:'SACRED', query:'bhajan devotional hindi', accent:Color(0xFFC9A227),
    image:'https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=800&q=80'),
  _FeaturedItem(title:'Celestial Classical', subtitle:'Playlist · Classical',
    desc:'Ragas and rhythms from the celestial realm of Indian classical.',
    badge:'PURE', query:'indian classical ragas', accent:Color(0xFFA07C10),
    image:'https://images.unsplash.com/photo-1519677100203-a0e668c92439?w=800&q=80'),
];

class HomeHero extends StatefulWidget {
  const HomeHero({super.key});
  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero> {
  int    _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _active = (_active + 1) % 3);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final featured = isDark ? _dark : _light;
    final item     = featured[_active];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: CachedNetworkImage(
                key:      ValueKey(item.image),
                imageUrl: item.image,
                fit:      BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.black.withOpacity(.65) : Colors.black.withOpacity(.45),
                  BlendMode.darken,
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end:   Alignment.bottomLeft,
                  colors: [
                    item.accent.withOpacity(.2),
                    Colors.black.withOpacity(.85),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal:8, vertical:3),
                    decoration: BoxDecoration(
                      color:        item.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.badge, style: const TextStyle(
                      fontFamily:'Orbitron', color:Colors.white,
                      fontSize:9, fontWeight:FontWeight.w900, letterSpacing:.3)),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(item.title,
                      key: ValueKey(item.title),
                      style: const TextStyle(
                        fontFamily: 'Orbitron', color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -.5,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.desc, maxLines:2,
                    style: const TextStyle(
                      fontFamily:'Rajdhani', color:Colors.white70, fontSize:12)),
                  const Spacer(),

                  // Buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.go('/search/${Uri.encodeComponent(item.query)}'),
                        icon:  const Icon(Icons.play_arrow_rounded, size:18),
                        label: const Text('Play Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
                          textStyle: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.go('/search/${Uri.encodeComponent(item.query)}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
                        ),
                        child: const Text('Explore →', style: TextStyle(fontFamily:'Rajdhani', fontSize:13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  // Dot indicators
                  Row(
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  i == _active ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color:        i == _active ? item.accent : Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
