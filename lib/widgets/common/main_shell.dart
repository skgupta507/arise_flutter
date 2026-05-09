import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../player/mini_player.dart';
import '../player/full_player.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int  _selectedIndex  = 0;
  bool _fullPlayerOpen = false;

  static const _routes = ['/', '/search', '/library', '/charts', '/settings'];

  static const _navItems = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'HOME',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'SEARCH',
    ),
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music),
      label: 'LIBRARY',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'CHARTS',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'SETTINGS',
    ),
  ];

  void _onNavTap(int idx) {
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
      context.go(_routes[idx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final player   = context.watch<PlayerProvider>();
    final hasTrack = player.hasTrack;

    // Nav bar height + system bottom padding
    const navBarHeight = 68.0;
    const miniPlayerH  = 76.0; // progress bar (3) + padding (8*2) + content (44+8) ≈ 76

    return Scaffold(
      backgroundColor: isDark ? AriseColors.demonBg : AriseColors.angelBg,
      extendBody: true, // content goes behind nav bar — we handle padding ourselves
      body: Stack(
        children: [
          // ── Main content with bottom padding so it's not hidden ──────────
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: hasTrack
                    ? navBarHeight + miniPlayerH + 8
                    : navBarHeight,
              ),
              child: widget.child,
            ),
          ),

          // ── Mini-player — sits just above the nav bar ────────────────────
          if (hasTrack)
            Positioned(
              left:   8,
              right:  8,
              bottom: navBarHeight + 6,
              child: GestureDetector(
                onTap: () => setState(() => _fullPlayerOpen = true),
                onVerticalDragEnd: (d) {
                  if (d.primaryVelocity != null && d.primaryVelocity! < -300) {
                    setState(() => _fullPlayerOpen = true);
                  }
                },
                child: const MiniPlayer(),
              ),
            ),

          // ── Full-screen player overlay ────────────────────────────────────
          if (_fullPlayerOpen)
            Positioned.fill(
              child: FullPlayer(
                onClose: () => setState(() => _fullPlayerOpen = false),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex:         _selectedIndex,
        onDestinationSelected: _onNavTap,
        destinations:          _navItems,
        height:                navBarHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
