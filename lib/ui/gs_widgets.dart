import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';

/// Rounded surface used by every screen in the refresh.
///
/// Mirrors the prototype's `.card`: surface fill, hairline border, 18 px
/// radius. When [onTap] is provided the whole card is tappable with a ripple.
class GsCard extends StatelessWidget {
  const GsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.borderColor,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final radius = BorderRadius.circular(tokens.cardRadius);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: borderColor ?? tokens.line, width: 1),
    );

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }

    return Material(
      color: gradient == null ? (color ?? tokens.surface) : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: clipBehavior,
      child: Ink(
        decoration: gradient == null
            ? null
            : BoxDecoration(gradient: gradient, borderRadius: radius),
        child: content,
      ),
    );
  }
}

/// Uppercase section header with an optional trailing action.
class GsSectionTitle extends StatelessWidget {
  const GsSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: GsFont.body,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: tokens.muted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

enum GsTagTone { neutral, accent, ok, danger }

/// Compact status pill (`.tag` in the prototype).
class GsTag extends StatelessWidget {
  const GsTag(
    this.label, {
    super.key,
    this.tone = GsTagTone.neutral,
    this.icon,
    this.svgIcon,
  });

  final String label;
  final GsTagTone tone;
  final IconData? icon;
  final String? svgIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final Color foreground;
    final Color background;
    final Color border;

    switch (tone) {
      case GsTagTone.accent:
        foreground = tokens.accent;
        background = tokens.accent.withValues(alpha: 0.16);
        border = tokens.accent.withValues(alpha: 0.5);
      case GsTagTone.ok:
        foreground = tokens.ok;
        background = tokens.ok.withValues(alpha: 0.15);
        border = tokens.ok.withValues(alpha: 0.45);
      case GsTagTone.danger:
        foreground = tokens.danger;
        background = tokens.danger.withValues(alpha: 0.12);
        border = tokens.danger.withValues(alpha: 0.4);
      case GsTagTone.neutral:
        foreground = tokens.muted;
        background = tokens.surface2;
        border = tokens.line;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.tagRadius),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (svgIcon != null) ...<Widget>[
            GsIcon(svgIcon!, size: 11, color: foreground),
            const SizedBox(width: 4),
          ] else if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded icon container used inside cards and list rows.
///
/// Use [GsIconTile.svg] for prototype line icons, or the default constructor
/// for Material icons while a screen is still being migrated.
class GsIconTile extends StatelessWidget {
  const GsIconTile(
    IconData iconData, {
    super.key,
    this.size = 40,
    this.color,
  })  : _icon = iconData,
        _svgIcon = null;

  const GsIconTile.svg(
    String svgName, {
    super.key,
    this.size = 40,
    this.color,
  })  : _svgIcon = svgName,
        _icon = null;

  final IconData? _icon;
  final String? _svgIcon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: tokens.line, width: 1),
      ),
      child: Center(
        child: _svgIcon != null
            ? GsIcon(
                _svgIcon,
                size: size * 0.46,
                color: color ?? tokens.accent,
              )
            : Icon(
                _icon,
                size: size * 0.46,
                color: color ?? tokens.accent,
              ),
      ),
    );
  }
}

/// Big numeric stat with a small uppercase caption (`.stat` in the prototype).
class GsStat extends StatelessWidget {
  const GsStat({
    super.key,
    required this.value,
    required this.label,
    this.suffix,
    this.color,
  });

  final String value;
  final String label;
  final String? suffix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: GsFont.display,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: color ?? tokens.bone,
                ),
              ),
            ),
            if (suffix != null) ...<Widget>[
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix!,
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: GsFont.body,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: tokens.muted,
          ),
        ),
      ],
    );
  }
}

/// Circular progress ring used for level/streak summaries.
class GsRing extends StatelessWidget {
  const GsRing({
    super.key,
    required this.progress,
    this.size = 68,
    this.strokeWidth = 6,
    this.color,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: _GsRingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: color ?? tokens.accent,
              trackColor: tokens.surface2,
              strokeWidth: strokeWidth,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _GsRingPainter extends CustomPainter {
  const _GsRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GsRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Tappable row with leading icon, title, optional subtitle and chevron.
class GsListRow extends StatelessWidget {
  const GsListRow({
    super.key,
    this.icon,
    this.svg,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  }) : assert(icon != null || svg != null, 'Provide icon or svg');

  final IconData? icon;
  final String? svg;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Material(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: <Widget>[
              svg != null
                  ? GsIconTile.svg(svg!, size: 34)
                  : GsIconTile(icon!, size: 34),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.bone,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: GsFont.body,
                          fontSize: 11,
                          height: 1.35,
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(Icons.chevron_right, size: 17, color: tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient primary action matching `.btn.primary` in the prototype.
class GsPrimaryButton extends StatelessWidget {
  const GsPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.svgIcon,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final String? svgIcon;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final radius = BorderRadius.circular(tokens.controlRadius);
    final button = Material(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: tokens.accentGradient,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: <Widget>[
                  if (svgIcon != null) ...<Widget>[
                    GsIcon(svgIcon!, size: 17, color: tokens.accentInk),
                    const SizedBox(width: 7),
                  ] else if (icon != null) ...<Widget>[
                    Icon(icon, size: 17, color: tokens.accentInk),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: tokens.accentInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Rounded square action with a custom child (used for the bento menu).
class GsSquareButton extends StatelessWidget {
  const GsSquareButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final button = Material(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: child),
        ),
      ),
    );
    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Rounded square icon action used in the app bar.
class GsIconButton extends StatelessWidget {
  const GsIconButton({
    super.key,
    this.icon,
    this.svg,
    this.onPressed,
    this.tooltip,
  }) : assert(icon != null || svg != null, 'Provide icon or svg');

  final IconData? icon;
  final String? svg;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GsSquareButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: svg != null
          ? GsIcon(svg!, size: 18, color: context.gs.bone)
          : Icon(icon, size: 18, color: context.gs.bone),
    );
  }
}

/// One destination in [GsTabBar].
class GsTabItem {
  const GsTabItem({
    this.icon,
    this.svg,
    required this.label,
  }) : assert(icon != null || svg != null, 'Provide icon or svg');

  final IconData? icon;
  final String? svg;
  final String label;
}

/// Six-destination bottom bar matching the prototype's `.tabbar`.
///
/// The app keeps its existing destinations — only the chrome changed.
class GsTabBar extends StatelessWidget {
  const GsTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GsTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: tokens.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 5),
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              final item = items[index];
              final selected = index == currentIndex;
              final color = selected ? tokens.accent : tokens.muted;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: selected ? 22 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: selected ? tokens.accentGradient : null,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 6),
                        item.svg != null
                            ? GsIcon(item.svg!, size: 19, color: color)
                            : Icon(item.icon, size: 19, color: color),
                        const SizedBox(height: 3),
                        Text(
                          item.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: GsFont.body,
                            fontSize: 8.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: 0.5,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Convenience for screens that want the standard card gap.
const SizedBox gsGap = SizedBox(height: 12);

/// Muted caption used under card titles.
TextStyle gsCaption(BuildContext context) => TextStyle(
      fontFamily: GsFont.body,
      fontSize: 11,
      height: 1.4,
      color: AppTheme.mutedText(context),
    );
