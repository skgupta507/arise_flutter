import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final player  = context.watch<PlayerProvider>();
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonCard    : AriseColors.angelCard;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    final options = [15, 30, 45, 60];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: textMut.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.bedtime_rounded, color: accent, size: 22),
              const SizedBox(width: 10),
              Text('Sleep Timer', style: TextStyle(
                fontFamily: 'Orbitron', color: textPri,
                fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          // Active timer countdown
          if (player.sleepRemaining != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatRemaining(player.sleepRemaining!),
                    style: TextStyle(
                      fontFamily: 'Orbitron', color: accent,
                      fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text('remaining', style: TextStyle(
                    fontFamily: 'Rajdhani', color: textMut, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                player.cancelSleepTimer();
                Navigator.pop(context);
              },
              icon: Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
              label: Text('Cancel Timer', style: TextStyle(
                fontFamily: 'Rajdhani', color: Colors.redAccent,
                fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
          ],

          // Timer options
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((min) {
              final isActive = player.sleepRemaining != null &&
                  player.sleepRemaining!.inMinutes == min;
              return GestureDetector(
                onTap: () {
                  player.setSleepTimer(Duration(minutes: min));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? accent : accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? accent : accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$min min',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      color: isActive ? Colors.white : accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // End of song option
          ListTile(
            leading: Icon(Icons.music_off_rounded, color: accent),
            title: Text('End of current song', style: TextStyle(
              fontFamily: 'Rajdhani', color: textPri, fontWeight: FontWeight.w600)),
            onTap: () {
              // Set a very short timer that fires when song ends
              final remaining = player.duration - player.position;
              if (remaining > Duration.zero) {
                player.setSleepTimer(remaining);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
