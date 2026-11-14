import 'package:flutter/material.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';

/// Exact-case section heading for settings sub-pages.
///
/// The HTML uses uppercase eyebrows for groups; settings pages keep the
/// existing labels verbatim so muscle memory and tests stay intact.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(
    this.title, {
    super.key,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: GsFont.display,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: tokens.bone,
                  ),
                ),
                if (description != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: TextStyle(
                      fontFamily: GsFont.body,
                      fontSize: 11.5,
                      height: 1.45,
                      color: tokens.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Compact -/+ target control used by daily repetition and macro targets.
class SettingsTargetAdjuster extends StatelessWidget {
  const SettingsTargetAdjuster({
    super.key,
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    this.unit,
  });

  final String label;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GsFont.body,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: tokens.bone,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              border: Border.all(color: tokens.line, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove, size: 16),
                ),
                Text(
                  unit == null ? '$value' : '$value $unit',
                  style: TextStyle(
                    fontFamily: GsFont.mono,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.bone,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
