import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';

/// Line icon from `assets/icons`, tinted with the active skin.
///
/// The assets are the exact SVG paths from the approved UI prototype, so the
/// app uses the same 24 px / 1.8 px stroke language as the reference.
class GsIcon extends StatelessWidget {
  const GsIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  /// Asset name without the `.svg` suffix, e.g. `train`, `flame`, `check`.
  final String name;
  final double size;
  final Color? color;

  /// Set only when the icon carries meaning; leave null for decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        color ?? context.gs.bone,
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
