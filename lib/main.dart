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
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Background audio service ─────────────────────────────────────────────
  await JustAudioBackground.init(
    androidNotificationChannelId:   'com.arise.music.channel.audio',
    androidNotificationChannelName: 'Arise Music',
    androidNotificationOngoing:     true,
    androidStopForegroundOnPause:   false,
    androidNotificationIcon:        'mipmap/ic_launcher',
  );

  // ── Local database ──────────────────────────────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox('arise_liked');
  await Hive.openBox('arise_playlists');
  await Hive.openBox('arise_recent');
  await Hive.openBox('arise_settings');
  await Hive.openBox('arise_cache');

  // ── Portrait + landscape, immersive ────────────────────────────────────
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  Colors.transparent,
  ));

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title:            'Arise Music',
            debugShowCheckedModeBanner: false,
            theme:            AppTheme.dark,
            darkTheme:        AppTheme.dark,
            themeMode:        themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig:     AppRouter.router,
          );
        },
      ),
    );
  }
}
