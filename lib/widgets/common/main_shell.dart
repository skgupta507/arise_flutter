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
  int _selectedIndex = 0;
  bool _fullPlayerOpen = false;

  static const _routes = ['/', '/search', '/library', '/settings'];

  static const _navItems = [
    NavigationDestination(icon: Icon(Icons.home_outlined),    selectedIcon: Icon(Icons.home),           label: 'HOME'),
    NavigationDestination(icon: Icon(Icons.search_outlined),   selectedIcon: Icon(Icons.search),         label: 'SEARCH'),
    NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'LIBRARY'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings),       label: 'SETTINGS'),
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

    return Scaffold(
      backgroundColor: isDark ? AriseColors.demonBg : AriseColors.angelBg,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(child: widget.child),
              // Space for mini-player when active
              if (hasTrack) const SizedBox(height: 72),
            ],
          ),

          // Mini-player docked at bottom above nav bar
          if (hasTrack)
            Positioned(
              left: 0, right: 0,
              bottom: 80, // above nav bar
              child: GestureDetector(
                onTap:    () => setState(() => _fullPlayerOpen = true),
                onVerticalDragEnd: (d) {
                  if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
                    setState(() => _fullPlayerOpen = true);
                  }
                },
                child: const MiniPlayer(),
              ),
            ),

          // Full-screen player overlay
          if (_fullPlayerOpen)
            FullPlayer(onClose: () => setState(() => _fullPlayerOpen = false)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: _navItems,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
