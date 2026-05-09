import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/library_provider.dart';
import 'providers/search_provider.dart';
import 'providers/lyrics_provider.dart';
import 'providers/download_provider.dart';
import 'providers/settings_provider.dart';
import 'router/app_router.dart';

void main() {
  // Must be the very first call — no async, no zone wrapping before this
  WidgetsFlutterBinding.ensureInitialized();

  // Show Flutter framework errors visibly instead of blank screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Run the async init then launch the app
  _initAndRun();
}

Future<void> _initAndRun() async {
  try {
    // ── 1. Hive local database ──────────────────────────────────────────
    await Hive.initFlutter();
    await Hive.openBox('arise_liked');
    await Hive.openBox('arise_playlists');
    await Hive.openBox('arise_recent');
    await Hive.openBox('arise_settings');
    await Hive.openBox('arise_cache');
    await Hive.openBox('arise_downloads');
  } catch (e, st) {
    debugPrint('Hive init failed: $e\n$st');
    // Still launch — providers will handle missing boxes gracefully
  }

  // ── 2. Background audio service ───────────────────────────────────────
  // Non-fatal: if this fails the app still works, just no lock-screen controls
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId:   'com.arise.music.channel.audio',
      androidNotificationChannelName: 'Arise Music',
      androidNotificationOngoing:     true,
      androidStopForegroundOnPause:   false,
      androidNotificationIcon:        'mipmap/ic_launcher',
    );
  } catch (e) {
    debugPrint('JustAudioBackground init failed (non-fatal): $e');
  }

  // ── 3. System UI chrome ───────────────────────────────────────────────
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:                   Colors.transparent,
      statusBarIconBrightness:          Brightness.light,
      systemNavigationBarColor:         Colors.transparent,
      systemNavigationBarIconBrightness:Brightness.light,
    ));
  } catch (e) {
    debugPrint('SystemChrome setup failed (non-fatal): $e');
  }

  // ── 4. Launch app ─────────────────────────────────────────────────────
  runApp(const AriseApp());
}

class AriseApp extends StatelessWidget {
  const AriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => LyricsProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title:                      'Arise Music',
            debugShowCheckedModeBanner: false,
            theme:                      AppTheme.light,
            darkTheme:                  AppTheme.dark,
            themeMode:                  themeProvider.isDark
                                            ? ThemeMode.dark
                                            : ThemeMode.light,
            routerConfig:               AppRouter.router,
          );
        },
      ),
    );
  }
}
