import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

/// Section header with title, subtitle, and optional "See all" link
class SectionHeader extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final String? seeAllRoute;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllRoute,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontFamily: 'Rajdhani', color: textPri,
                  fontWeight: FontWeight.w700, fontSize: 17,
                  letterSpacing: .3,
                )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(
                    fontFamily: 'Rajdhani', color: textMut, fontSize: 12,
                  )),
                ],
              ],
            ),
          ),
          if (onSeeAll != null || seeAllRoute != null)
            GestureDetector(
              onTap: onSeeAll ?? () {
                if (seeAllRoute != null) context.go(seeAllRoute!);
              },
              child: Text('See all →', style: TextStyle(
                fontFamily: 'Rajdhani', color: accent,
                fontWeight: FontWeight.w700, fontSize: 13,
              )),
            ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable row of cards with a section header
class HScrollSection extends StatelessWidget {
  final String   title;
  final String?  subtitle;
  final String?  seeAllRoute;
  final List<Widget> children;
  final double   itemSpacing;
  final double   height;
  final EdgeInsets padding;

  const HScrollSection({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllRoute,
    required this.children,
    this.itemSpacing = 12,
    this.height      = 200,
    this.padding     = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: SectionHeader(
            title:      title,
            subtitle:   subtitle,
            seeAllRoute:seeAllRoute,
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:         EdgeInsets.symmetric(horizontal: padding.left),
            itemCount:       children.length,
            separatorBuilder:(_, __) => SizedBox(width: itemSpacing),
            itemBuilder:     (_, i)  => children[i],
          ),
        ),
      ],
    );
  }
}

/// Skeleton shimmer loader
class ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 12});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: false);
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final base   = isDark ? const Color(0xFF1C1C30) : const Color(0xFFEDE8C8);
    final hi     = isDark ? const Color(0xFF2A2A45) : const Color(0xFFFFF8DC);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
            colors: [base, hi, base],
            stops: [
              (_anim.value - .5).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + .5).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

