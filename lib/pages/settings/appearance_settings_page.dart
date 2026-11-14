import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';

/// Theme selection, split out of the old monolithic settings page.
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Text(
                'Theme & Skins (Greyskull Motif)',
                style: TextStyle(
                  fontFamily: GsFont.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: tokens.bone,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your gym aesthetic: rugged dark charcoal, pitch black OLED, or daylight chalk.',
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 11.5,
                  height: 1.45,
                  color: tokens.muted,
                ),
              ),
              const SizedBox(height: 12),
              ...GreyskullSkin.values.map(
                (skin) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _SkinCard(skin: skin),
                ),
              ),
              const SizedBox(height: 8),
              GsCard(
                color: tokens.surface2,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    GsIcon('info', size: 16, color: tokens.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Themes apply instantly and are saved on this device. '
                        'No data is changed when you switch skins.',
                        style: TextStyle(
                          fontFamily: GsFont.body,
                          fontSize: 11,
                          height: 1.45,
                          color: tokens.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({required this.skin});

  final GreyskullSkin skin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final selected = trainingState.activeSkin == skin;
    return GsCard(
      onTap: () => trainingState.setActiveSkin(skin),
      borderColor: selected ? tokens.accent : tokens.line,
      color: selected ? tokens.accent.withValues(alpha: 0.05) : null,
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Color(skin.bgHex),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: tokens.line, width: 1),
            ),
            child: Center(
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Color(skin.accentHex),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        skin.displayName,
                        style: TextStyle(
                          fontFamily: GsFont.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.bone,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    GsTag(
                      skin.badge,
                      tone: selected ? GsTagTone.accent : GsTagTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  skin.subtitle,
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.bone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  skin.description,
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11,
                    height: 1.4,
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (selected)
            GsIcon('check', size: 18, color: tokens.accent)
          else
            GsIcon('chevron', size: 16, color: tokens.muted),
        ],
      ),
    );
  }
}
