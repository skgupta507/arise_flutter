import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../api/update_api.dart';
import '../../providers/download_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../charts/charts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version     = '';
  bool   _checkingUpd = false;
  String? _updStatus;

  bool   _autoplay  = true;
  bool   _showVideo = true;
  String _quality   = 'high';
  String _language  = 'hindi';
  double _crossfade = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _checkUpdate() async {
    setState(() { _checkingUpd = true; _updStatus = null; });
    final info = await UpdateApi.check();
    if (!mounted) return;
    setState(() {
      _checkingUpd = false;
      if (info == null) {
        _updStatus = 'You are on the latest version ✓';
      } else {
        _updStatus = null;
      }
    });
    if (info != null) _showUpdateDialog(info);
  }

  void _showUpdateDialog(UpdateInfo info) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AriseColors.demonCard : AriseColors.angelCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🔥 Update Available',
          style: TextStyle(fontFamily: 'Orbitron', color: accent, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Version', info.version),
            _InfoRow('Size',    info.size),
            _InfoRow('Date',    info.date),
            const SizedBox(height: 10),
            Text("What's new:", style: TextStyle(fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              color: isDark ? AriseColors.demonText : AriseColors.angelText)),
            const SizedBox(height: 4),
            Text(info.changelog, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 13,
              color: isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: TextStyle(
              color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () { Navigator.pop(context); _startDownload(info); },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload(UpdateInfo info) async {
    setState(() => _updStatus = 'Downloading ${info.version}…');
    final path = await UpdateApi.downloadApk(info, onProgress: (p) {
      if (mounted) setState(() => _updStatus = 'Downloading… ${(p * 100).toInt()}%');
    });
    if (!mounted) return;
    if (path == null) {
      setState(() => _updStatus = 'Download failed — try again');
      return;
    }
    setState(() => _updStatus = 'Download complete! Tap to install');
    try {
      final uri = Uri.parse('file://$path');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        setState(() => _updStatus = 'Download complete! Open $path to install');
      }
    } catch (_) {
      setState(() => _updStatus = 'Download complete! Open the file manually to install');
    }
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final lib     = context.watch<LibraryProvider>();
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Settings', style: TextStyle(
          fontFamily: 'Orbitron', color: accent, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Stats ──────────────────────────────────────────────────────────
          _SectionLabel('Your Library', isDark),
          GridView.count(
            shrinkWrap: true, crossAxisCount: 2,
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(label: 'Liked Songs', value: '${lib.likedCount}',
                icon: Icons.favorite_rounded, color: accent, isDark: isDark),
              _StatCard(label: 'Playlists', value: '${lib.plCount}',
                icon: Icons.queue_music_rounded,
                color: const Color(0xFF4285F4), isDark: isDark),
              _StatCard(label: 'Recently Played',
                value: '${lib.recentlyPlayed.length}',
                icon: Icons.history_rounded,
                color: const Color(0xFF9D4EDD), isDark: isDark),
              _StatCard(label: 'Queue',
                value: '${Provider.of<PlayerProvider>(context, listen: false).queue.length}',
                icon: Icons.list_rounded,
                color: const Color(0xFF1DB954), isDark: isDark),
            ],
          ),
          const SizedBox(height: 24),

          // ── Appearance ─────────────────────────────────────────────────────
          _SectionLabel('Appearance', isDark),
          _SettingsCard(isDark: isDark, children: [
            _SwitchRow(
              icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              label: isDark
                  ? 'Switch to Light ✨ Angel Theme'
                  : 'Switch to Dark 🔥 Demon Theme',
              desc: isDark
                  ? 'Golden particles · Divine vibes'
                  : 'Crimson glow · Dark atmosphere',
              value: !isDark,
              accent: accent, isDark: isDark,
              onChanged: (_) =>
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Playback ───────────────────────────────────────────────────────
          _SectionLabel('Playback', isDark),
          _SettingsCard(isDark: isDark, children: [
            _SwitchRow(
              icon: Icons.play_arrow_rounded, label: 'Autoplay',
              desc: 'Play related songs when queue ends',
              value: _autoplay, accent: accent, isDark: isDark,
              onChanged: (v) => setState(() => _autoplay = v),
            ),
            _Divider(isDark),
            _SwitchRow(
              icon: Icons.videocam_rounded, label: 'Show Video Mode',
              desc: 'Open video when playing YouTube content',
              value: _showVideo, accent: accent, isDark: isDark,
              onChanged: (v) => setState(() => _showVideo = v),
            ),
            _Divider(isDark),
            Consumer<PlayerProvider>(
              builder: (ctx, player, _) => _SwitchRow(
                icon: Icons.volume_off_rounded, label: 'Skip Silence',
                desc: 'Automatically skip silent parts',
                value: player.skipSilence, accent: accent, isDark: isDark,
                onChanged: (v) {
                  player.setSkipSilence(v);
                  context.read<SettingsProvider>().setSkipSilence(v);
                },
              ),
            ),
            _Divider(isDark),
            Consumer<PlayerProvider>(
              builder: (ctx, player, _) => _SwitchRow(
                icon: Icons.equalizer_rounded, label: 'Audio Normalization',
                desc: 'Normalize volume across tracks',
                value: player.normalizeLoudness, accent: accent, isDark: isDark,
                onChanged: (v) {
                  player.setNormalizeLoudness(v);
                  context.read<SettingsProvider>().setNormalizeAudio(v);
                },
              ),
            ),
            _Divider(isDark),
            _DropdownRow<String>(
              icon: Icons.high_quality_rounded, label: 'Audio Quality',
              desc: _quality == 'high'
                  ? 'High (320kbps)'
                  : _quality == 'medium'
                      ? 'Medium (160kbps)'
                      : 'Low (96kbps)',
              value: _quality, isDark: isDark, accent: accent,
              items: const [
                DropdownMenuItem(value: 'high',   child: Text('High (320kbps)')),
                DropdownMenuItem(value: 'medium', child: Text('Medium (160kbps)')),
                DropdownMenuItem(value: 'low',    child: Text('Low (96kbps)')),
              ],
              onChanged: (v) { if (v != null) setState(() => _quality = v); },
            ),
            _Divider(isDark),
            _SliderRow(
              icon: Icons.swap_horiz_rounded,
              label: 'Crossfade: ${_crossfade.toInt()}s',
              desc: 'Smooth transition between tracks',
              value: _crossfade, min: 0, max: 12, divisions: 12,
              accent: accent, isDark: isDark,
              onChanged: (v) => setState(() => _crossfade = v),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Sleep Timer ────────────────────────────────────────────────────
          _SectionLabel('Sleep Timer', isDark),
          _SettingsCard(isDark: isDark, children: [
            Consumer<PlayerProvider>(
              builder: (ctx, player, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (player.sleepRemaining != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Icon(Icons.timer_rounded, color: accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Active: ${_fmtDuration(player.sleepRemaining!)} remaining',
                            style: TextStyle(fontFamily: 'Rajdhani',
                              color: accent, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: player.cancelSleepTimer,
                            child: const Text('Cancel', style: TextStyle(
                              fontFamily: 'Rajdhani', color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set timer:', style: TextStyle(
                          fontFamily: 'Rajdhani',
                          color: isDark
                              ? AriseColors.demonText
                              : AriseColors.angelText,
                          fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [15, 30, 45, 60, 90].map((min) {
                            return GestureDetector(
                              onTap: () =>
                                  player.setSleepTimer(Duration(minutes: min)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Text('$min min', style: TextStyle(
                                  fontFamily: 'Rajdhani', color: accent,
                                  fontWeight: FontWeight.w700)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Downloads ──────────────────────────────────────────────────────
          _SectionLabel('Downloads', isDark),
          _SettingsCard(isDark: isDark, children: [
            Consumer<DownloadProvider>(
              builder: (ctx, dl, _) => FutureBuilder<String>(
                future: dl.getCacheSizeFormatted(),
                builder: (ctx, snap) => ListTile(
                  leading: Icon(Icons.download_done_rounded, color: accent),
                  title: Text('Downloaded Songs',
                    style: TextStyle(fontFamily: 'Rajdhani',
                      color: isDark
                          ? AriseColors.demonText
                          : AriseColors.angelText,
                      fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${dl.downloadedCount} songs · ${snap.data ?? '…'}',
                    style: TextStyle(fontFamily: 'Rajdhani',
                      color: isDark
                          ? AriseColors.demonMuted
                          : AriseColors.angelMuted,
                      fontSize: 12)),
                ),
              ),
            ),
            _Divider(isDark),
            _ActionRow(
              icon: Icons.delete_sweep_rounded,
              label: 'Clear Download Cache',
              desc: 'Remove all downloaded songs',
              accent: accent, isDark: isDark, danger: true,
              onTap: () => _confirm(
                'Clear Downloads?',
                'All downloaded songs will be deleted from device.',
                () => context.read<DownloadProvider>().clearAll(),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Discover ───────────────────────────────────────────────────────
          _SectionLabel('Discover', isDark),
          _SettingsCard(isDark: isDark, children: [
            ListTile(
              leading: Icon(Icons.bar_chart_rounded, color: accent),
              title: Text('Music Charts', style: TextStyle(
                fontFamily: 'Rajdhani',
                color: isDark ? AriseColors.demonText : AriseColors.angelText,
                fontWeight: FontWeight.w700)),
              subtitle: Text('Top songs by country', style: TextStyle(
                fontFamily: 'Rajdhani',
                color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
                fontSize: 12)),
              trailing: Icon(Icons.chevron_right_rounded,
                color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted),
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChartsScreen())),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Language ───────────────────────────────────────────────────────
          _SectionLabel('Language & Region', isDark),
          _SettingsCard(isDark: isDark, children: [
            _DropdownRow<String>(
              icon: Icons.language_rounded, label: 'Music Language',
              desc: 'Preferred content language',
              value: _language, isDark: isDark, accent: accent,
              items: const [
                DropdownMenuItem(value: 'hindi',   child: Text('Hindi')),
                DropdownMenuItem(value: 'punjabi', child: Text('Punjabi')),
                DropdownMenuItem(value: 'english', child: Text('English')),
                DropdownMenuItem(value: 'all',     child: Text('All Languages')),
              ],
              onChanged: (v) { if (v != null) setState(() => _language = v); },
            ),
          ]),
          const SizedBox(height: 16),

          // ── Updates ────────────────────────────────────────────────────────
          _SectionLabel('App Updates', isDark),
          _SettingsCard(isDark: isDark, children: [
            ListTile(
              leading: Icon(Icons.system_update_rounded, color: accent),
              title: Text('Current Version: $_version',
                style: TextStyle(fontFamily: 'Rajdhani',
                  color: isDark ? AriseColors.demonText : AriseColors.angelText,
                  fontWeight: FontWeight.w700)),
              subtitle: _updStatus != null
                  ? Text(_updStatus!, style: TextStyle(
                      fontFamily: 'Rajdhani', color: accent, fontSize: 12))
                  : Text('Tap to check for updates',
                      style: TextStyle(fontFamily: 'Rajdhani',
                        color: isDark
                            ? AriseColors.demonMuted
                            : AriseColors.angelMuted,
                        fontSize: 12)),
              trailing: _checkingUpd
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: accent, strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _checkUpdate,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6)),
                      child: const Text('Check',
                          style: TextStyle(fontFamily: 'Rajdhani', fontSize: 12)),
                    ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Data ───────────────────────────────────────────────────────────
          _SectionLabel('Data & Privacy', isDark),
          _SettingsCard(isDark: isDark, children: [
            _ActionRow(
              icon: Icons.history_rounded, label: 'Clear Listening History',
              desc: 'Remove all recently played tracks',
              accent: accent, isDark: isDark, danger: true,
              onTap: () => _confirm(
                'Clear History?',
                'This removes all recently played tracks.',
                () => lib.clearHistory()),
            ),
            _Divider(isDark),
            _ActionRow(
              icon: Icons.favorite_border_rounded, label: 'Clear Liked Songs',
              desc: 'Remove all liked songs',
              accent: accent, isDark: isDark, danger: true,
              onTap: () => _confirm(
                'Clear Liked Songs?', 'All liked songs will be removed.', () {}),
            ),
          ]),
          const SizedBox(height: 16),

          // ── About ──────────────────────────────────────────────────────────
          _SectionLabel('About', isDark),
          _SettingsCard(isDark: isDark, children: [
            ListTile(
              leading: Text(isDark ? '🔥' : '✨',
                  style: const TextStyle(fontSize: 22)),
              title: Text('Arise Music v$_version',
                style: TextStyle(fontFamily: 'Orbitron',
                  color: isDark ? AriseColors.demonText : AriseColors.angelText,
                  fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text(
                isDark
                    ? 'Rise from the Shadows · JioSaavn + YouTube'
                    : 'Hear the Divine · JioSaavn + YouTube',
                style: TextStyle(fontFamily: 'Rajdhani',
                  color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
                  fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirm(String title, String msg, VoidCallback onOk) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); onOk(); },
            child: const Text('Confirm',
                style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// ── Reusable setting sub-widgets ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel(this.label, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: TextStyle(
      fontFamily: 'Orbitron', fontSize: 10, letterSpacing: .2,
      fontWeight: FontWeight.w700,
      color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted)),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AriseColors.demonCard : AriseColors.angelCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: isDark ? AriseColors.demonBorder : AriseColors.angelBorder),
    ),
    child: Column(children: children),
  );
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final bool value, isDark;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label, required this.desc,
    required this.value, required this.isDark, required this.accent,
    required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: accent),
    title: Text(label, style: TextStyle(fontFamily: 'Rajdhani',
      color: isDark ? AriseColors.demonText : AriseColors.angelText,
      fontWeight: FontWeight.w700)),
    subtitle: Text(desc, style: TextStyle(fontFamily: 'Rajdhani',
      color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
      fontSize: 12)),
    trailing: Switch(
      value: value, onChanged: onChanged,
      activeTrackColor: accent,
      thumbColor: const WidgetStatePropertyAll(Colors.white)),
  );
}

class _DropdownRow<T> extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final T value;
  final bool isDark;
  final Color accent;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownRow({required this.icon, required this.label, required this.desc,
    required this.value, required this.isDark, required this.accent,
    required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: accent),
    title: Text(label, style: TextStyle(fontFamily: 'Rajdhani',
      color: isDark ? AriseColors.demonText : AriseColors.angelText,
      fontWeight: FontWeight.w700)),
    subtitle: Text(desc, style: TextStyle(fontFamily: 'Rajdhani',
      color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
      fontSize: 12)),
    trailing: DropdownButton<T>(
      value: value, items: items, onChanged: onChanged,
      underline: const SizedBox(),
      style: TextStyle(fontFamily: 'Rajdhani',
        color: isDark ? AriseColors.demonText : AriseColors.angelText,
        fontSize: 13),
      dropdownColor: isDark ? AriseColors.demonCard : AriseColors.angelCard,
      iconEnabledColor: accent,
    ),
  );
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final double value, min, max;
  final int divisions;
  final bool isDark;
  final Color accent;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.icon, required this.label, required this.desc,
    required this.value, required this.min, required this.max,
    required this.divisions, required this.isDark, required this.accent,
    required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontFamily: 'Rajdhani',
            color: isDark ? AriseColors.demonText : AriseColors.angelText,
            fontWeight: FontWeight.w700)),
        ]),
        Text(desc, style: TextStyle(fontFamily: 'Rajdhani',
          color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
          fontSize: 12)),
        Slider(
          value: value, min: min, max: max,
          divisions: divisions, onChanged: onChanged),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final bool isDark, danger;
  final Color accent;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.desc,
    required this.isDark, required this.danger, required this.accent,
    required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: danger ? Colors.redAccent : accent),
    title: Text(label, style: TextStyle(fontFamily: 'Rajdhani',
      color: danger
          ? Colors.redAccent
          : (isDark ? AriseColors.demonText : AriseColors.angelText),
      fontWeight: FontWeight.w700)),
    subtitle: Text(desc, style: TextStyle(fontFamily: 'Rajdhani',
      color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
      fontSize: 12)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(
        fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13)),
      Text(value, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 13)),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.icon,
    required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AriseColors.demonCard : AriseColors.angelCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: isDark ? AriseColors.demonBorder : AriseColors.angelBorder),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Orbitron', color: color,
        fontSize: 18, fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(fontFamily: 'Orbitron',
        color: isDark ? AriseColors.demonMuted : AriseColors.angelMuted,
        fontSize: 9, letterSpacing: .1)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);

  @override
  Widget build(BuildContext context) => Divider(
    color: isDark ? AriseColors.demonBorder : AriseColors.angelBorder,
    height: 0, thickness: 0.5, indent: 16, endIndent: 16,
  );
}
