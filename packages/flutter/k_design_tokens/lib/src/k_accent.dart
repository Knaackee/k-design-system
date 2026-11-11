import 'package:flutter/painting.dart';

import 'generated/k_design_tokens.g.dart';

/// One brand colour for the whole app.
///
/// Sets the action colours (buttons, switches, selection, badges, charts)
/// and derives the tinted brand colours (icon tiles, FAB) for the current
/// light or dark tokens, so no default accent stays behind. Use it in
/// `kDesignTheme(tokenTransform: (t) => t.withAccent(color))` instead of
/// overriding single colour tokens.
extension KAccentTokens on KDesignTokens {
  KDesignTokens withAccent(Color accent) {
    final dark = colorSurfaceCanvas.computeLuminance() < 0.5;
    final surface = colorSurfaceRaised;
    final onAccent = accent.computeLuminance() > 0.4
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final shade = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final tint = Color.lerp(surface, accent, dark ? 0.24 : 0.12)!;
    final onTint = Color.lerp(accent, colorTextPrimary, dark ? 0.35 : 0.3)!;
    return copyWith(
      colorActionPrimaryBackground: accent,
      colorActionPrimaryForeground: onAccent,
      colorActionPrimaryHover: Color.lerp(accent, shade, 0.1),
      colorActionPrimaryPressed: Color.lerp(accent, shade, 0.2),
      colorBrandPrimaryAccent: onTint,
      colorBrandPrimaryBackground: tint,
      colorBrandPrimaryForeground: onTint,
      colorBrandPrimaryBorder: Color.lerp(surface, accent, 0.35),
      componentBadgePrimaryBackground: accent,
      componentBadgePrimaryForeground: onAccent,
      componentCardBorderColor: accent,
      componentChartSeriesPrimary: accent,
      componentFabBackground: tint,
      componentFabForeground: onTint,
      componentListMediaBackground: tint,
      componentListMediaForeground: onTint,
      componentSelectionSelectedBackground: accent,
      componentSelectionSelectedBorder: accent,
      componentSelectionSelectedForeground: onAccent,
      componentSwitchActiveBorder: accent,
      componentSwitchActiveThumb: onAccent,
      componentSwitchActiveTrack: accent,
    );
  }
}
