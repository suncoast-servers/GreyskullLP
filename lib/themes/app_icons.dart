import 'package:flutter/widgets.dart';

/// Greyskull iconography shared across navigation and analytics.
class AppIcons {
  const AppIcons._();

  /// Barbell / exercise glyph from the bundled `MaterialSymbols` font.
  ///
  /// Used by the Workout nav entry and by the Stats "Resistance" category so
  /// both surfaces read as the same brand (issue #54: avoid a third-party
  /// fitness-app logo glyph).
  static const IconData barbell =
      IconData(0xf6e6, fontFamily: 'MaterialSymbols');
}
