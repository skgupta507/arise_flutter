import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/muzo_api.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _country = 'IN';
  List<Map<String, dynamic>> _charts = [];
  bool _loading = false;
  String? _error;

  static const _countries = [
    {'code': 'IN', 'name': 'India'},
    {'code': 'US', 'name': 'USA'},
    {'code': 'GB', 'name': 'UK'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'JP', 'name': 'Japan'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCharts();
  }

  Future<void> _loadCharts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await MuzoApi.charts(country: _country);
      if (mounted) setState(() { _charts = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load charts'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final player  = context.watch<PlayerProvider>();
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final card    = isDark ? AriseColors.demonCard    : AriseColors.angelCard;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Charts', style: TextStyle(
          fontFamily: 'Orbitron', color: accent, fontSize: 16)),
        actions: [
          // Country selector
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _country,
              underline: const SizedBox(),
              dropdownColor: card,
              iconEnabledColor: accent,
              style: TextStyle(
                fontFamily: 'Rajdhani', color: textPri, fontSize: 14),
              items: _countries.map((c) => DropdownMenuItem<String>(
                value: c['code'],
                child: Text(c['name']!),
              )).toList(),
              onChanged: (v) {
                if (v != null && v != _country) {
                  setState(() => _country = v);
                  _loadCharts();
                }
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: textMut, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(
                        fontFamily: 'Rajdhani', color: textMut, fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCharts,
                        style: ElevatedButton.styleFrom(backgroundColor: accent),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _charts.isEmpty
                  ? Center(
                      child: Text('No charts available',
                        style: TextStyle(fontFamily: 'Rajdhani', color: textMut)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCharts,
                      color: accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 120),
                        itemCount: _charts.length,
                        itemBuilder: (context, i) {
                          final item = _charts[i];
                          final song = SongModel.fromMuzo(MuzoApi.normalise(item));
                          final thumb = MuzoApi.thumbnail(item) ?? song.thumbnail ?? '';
                          final title = item['title']?.toString() ?? song.title;
                          final artist = (item['artists'] as List?)
                              ?.map((a) => a['name']?.toString() ?? '')
                              .join(', ') ?? song.artist;
                          final isCurrent = player.current?.id == song.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Rank number
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      color: i < 3 ? accent : textMut,
                                      fontSize: i < 3 ? 14 : 12,
                                      fontWeight: i < 3
                                          ? FontWeight.w900
                                          : FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: thumb,
                                    width: 48, height: 48,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 48, height: 48,
                                      color: accent.withValues(alpha: 0.1),
                                      child: Icon(Icons.music_note,
                                        color: accent, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                color: isCurrent ? accent : textPri,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              artist,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                color: textSub,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrent && player.playing
                                ? Icon(Icons.equalizer_rounded,
                                    color: accent, size: 20)
                                : Icon(Icons.play_arrow_rounded,
                                    color: textMut, size: 20),
                            onTap: () => player.play(song),
                          );
                        },
                      ),
                    ),
    );
  }
}
