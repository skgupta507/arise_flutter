import 'package:flutter/material.dart';

// ── Arise colour palette ──────────────────────────────────────────────────────
class AriseColors {
  // Dark (Demon) theme
  static const demonBg         = Color(0xFF07070D);
  static const demonCard       = Color(0xFF12121F);
  static const demonCardHover  = Color(0xFF1C1C30);
  static const demonElevated   = Color(0xFF0E0E1A);
  static const demonAccent     = Color(0xFFFF003C);
  static const demonAccent2    = Color(0xFF9D4EDD);
  static const demonBorder     = Color(0x1FFF003C);
  static const demonText       = Color(0xFFE8E8F8);
  static const demonSubtext    = Color(0xFFAAAACC);
  static const demonMuted      = Color(0xFF666688);
  static const demonFaint      = Color(0xFF44445A);
  static const demonNav        = Color(0xFF05050A);
  static const demonPlayer     = Color(0xFF04040A);

  // Light (Angel) theme
  static const angelBg         = Color(0xFFFDFBF4);
  static const angelCard       = Color(0xFFFFFAE4);
  static const angelCardHover  = Color(0xFFFFF7D2);
  static const angelElevated   = Color(0xFFFFFEF6);
  static const angelAccent     = Color(0xFFC9A227);
  static const angelAccent2    = Color(0xFFA07C10);
  static const angelBorder     = Color(0x59D4AF37);
  static const angelText       = Color(0xFF1A1208);
  static const angelSubtext    = Color(0xFF3D3010);
  static const angelMuted      = Color(0xFF7A6830);
  static const angelFaint      = Color(0xFFB09840);
  static const angelNav        = Color(0xFFFFFCE8);
  static const angelPlayer     = Color(0xFFFFFBE4);
}

class AppTheme {
  static ThemeData get dark => _buildTheme(isDark: true);
  static ThemeData get light => _buildTheme(isDark: false);

  static ThemeData _buildTheme({required bool isDark}) {
    final accent    = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg        = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final card      = isDark ? AriseColors.demonCard    : AriseColors.angelCard;
    final textPrimary   = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSecondary = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;

    return ThemeData(
      useMaterial3:         true,
      brightness:           isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness:     isDark ? Brightness.dark : Brightness.light,
        primary:        accent,
        onPrimary:      Colors.white,
        secondary:      isDark ? AriseColors.demonAccent2 : AriseColors.angelAccent2,
        onSecondary:    Colors.white,
        surface:        card,
        onSurface:      textPrimary,
        error:          const Color(0xFFCF6679),
        onError:        Colors.white,
        surface:        bg,
        onSurface:   textPrimary,
      ),
      fontFamily: 'Rajdhani',
      textTheme: TextTheme(
        displayLarge:  TextStyle(fontFamily:'Orbitron', color:textPrimary, fontWeight:FontWeight.w900, letterSpacing:-1),
        displayMedium: TextStyle(fontFamily:'Orbitron', color:textPrimary, fontWeight:FontWeight.w900),
        displaySmall:  TextStyle(fontFamily:'Orbitron', color:textPrimary, fontWeight:FontWeight.w700),
        headlineLarge: TextStyle(fontFamily:'Orbitron', color:textPrimary, fontWeight:FontWeight.w700),
        headlineMedium:TextStyle(fontFamily:'Orbitron', color:textPrimary, fontWeight:FontWeight.w700),
        headlineSmall: TextStyle(fontFamily:'Rajdhani', color:textPrimary, fontWeight:FontWeight.w700, letterSpacing:.5),
        titleLarge:    TextStyle(fontFamily:'Rajdhani', color:textPrimary, fontWeight:FontWeight.w700),
        titleMedium:   TextStyle(fontFamily:'Rajdhani', color:textPrimary, fontWeight:FontWeight.w600),
        titleSmall:    TextStyle(fontFamily:'Rajdhani', color:textSecondary,fontWeight:FontWeight.w600),
        bodyLarge:     TextStyle(fontFamily:'Rajdhani', color:textPrimary),
        bodyMedium:    TextStyle(fontFamily:'Rajdhani', color:textSecondary),
        bodySmall:     TextStyle(fontFamily:'Rajdhani', color:isDark ? AriseColors.demonMuted : AriseColors.angelMuted),
        labelLarge:    TextStyle(fontFamily:'Rajdhani', color:accent, fontWeight:FontWeight.w700, letterSpacing:.1),
        labelMedium:   TextStyle(fontFamily:'Orbitron', color:isDark ? AriseColors.demonMuted : AriseColors.angelMuted, fontSize:10),
        labelSmall:    TextStyle(fontFamily:'Orbitron', color:isDark ? AriseColors.demonFaint  : AriseColors.angelFaint,  fontSize:9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  isDark ? AriseColors.demonNav : AriseColors.angelNav,
        foregroundColor:  textPrimary,
        elevation:        0,
        centerTitle:      false,
        titleTextStyle:   TextStyle(fontFamily:'Orbitron', color:textPrimary, fontWeight:FontWeight.w700, fontSize:16),
        iconTheme:        IconThemeData(color: textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:      isDark ? AriseColors.demonNav : AriseColors.angelNav,
        indicatorColor:       accent.withValues(alpha: .15),
        iconTheme:            WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return IconThemeData(color: accent, size:24);
          return IconThemeData(color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted, size:24);
        }),
        labelTextStyle:       WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return TextStyle(fontFamily:'Orbitron', color:accent, fontSize:9, fontWeight:FontWeight.w700, letterSpacing:.1);
          return TextStyle(fontFamily:'Orbitron', color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted, fontSize:9, letterSpacing:.1);
        }),
        elevation:            0,
        surfaceTintColor:     Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color:            card,
        elevation:        0,
        shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin:           EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:           true,
        fillColor:        card,
        border:           OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none),
        enabledBorder:    OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide(color: isDark ? AriseColors.demonBorder : AriseColors.angelBorder)),
        focusedBorder:    OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide(color:accent, width:1.5)),
        hintStyle:        TextStyle(color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted, fontFamily:'Rajdhani'),
        contentPadding:   const EdgeInsets.symmetric(horizontal:16, vertical:12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  accent,
          foregroundColor:  Colors.white,
          elevation:        0,
          shape:            RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
          textStyle:        const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:15, letterSpacing:.5),
          padding:          const EdgeInsets.symmetric(horizontal:20, vertical:12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor:   accent,
        inactiveTrackColor: (isDark ? AriseColors.demonFaint : AriseColors.angelFaint).withValues(alpha: .3),
        thumbColor:         accent,
        thumbShape:         const RoundSliderThumbShape(enabledThumbRadius:6),
        trackHeight:        3,
        overlayColor:       accent.withValues(alpha: .2),
      ),
      dividerTheme: DividerThemeData(
        color:     isDark ? AriseColors.demonBorder : AriseColors.angelBorder,
        thickness: 0.5,
        space:     0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
