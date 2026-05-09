import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/albums/albums_screen.dart';
import '../screens/albums/album_detail_screen.dart';
import '../screens/artists/artists_screen.dart';
import '../screens/artists/artist_detail_screen.dart';
import '../screens/playlists/playlists_screen.dart';
import '../screens/podcasts/podcasts_screen.dart';
import '../screens/trending/trending_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/liked/liked_screen.dart';
import '../screens/recent/recent_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/charts/charts_screen.dart';
import '../widgets/common/main_shell.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _shellKey= GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',          builder: (c,s) => const HomeScreen()),
          GoRoute(path: '/search',    builder: (c,s) => const SearchScreen()),
          GoRoute(path: '/search/:q', builder: (c,s) => SearchScreen(initialQuery: s.pathParameters['q'])),
          GoRoute(path: '/albums',    builder: (c,s) => const AlbumsScreen()),
          GoRoute(path: '/albums/:id',builder: (c,s) => AlbumDetailScreen(albumId: s.pathParameters['id']!)),
          GoRoute(path: '/artists',   builder: (c,s) => const ArtistsScreen()),
          GoRoute(path: '/artists/:id', builder: (c,s) => ArtistDetailScreen(
            artistId: s.pathParameters['id']!,
            artistName: s.uri.queryParameters['name'] ?? '',
          )),
          GoRoute(path: '/playlists', builder: (c,s) => const PlaylistsScreen()),
          GoRoute(path: '/podcasts',  builder: (c,s) => const PodcastsScreen()),
          GoRoute(path: '/trending',  builder: (c,s) => const TrendingScreen()),
          GoRoute(path: '/library',   builder: (c,s) => const LibraryScreen()),
          GoRoute(path: '/liked',     builder: (c,s) => const LikedScreen()),
          GoRoute(path: '/recent',    builder: (c,s) => const RecentScreen()),
          GoRoute(path: '/settings',  builder: (c,s) => const SettingsScreen()),
          GoRoute(path: '/about',     builder: (c,s) => const AboutScreen()),
          GoRoute(path: '/charts',    builder: (c,s) => const ChartsScreen()),
        ],
      ),
    ],
  );
}
