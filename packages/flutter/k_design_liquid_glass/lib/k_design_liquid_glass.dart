library;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Native liquid-glass surface for Android, iOS, and macOS consumers.
///
/// Pass this builder to [KMobileAppBar.liquidSurfaceBuilder]. The core UI
/// package deliberately does not depend on the renderer so Flutter Web keeps
/// using the portable frosted fallback.
Widget kLiquidGlassSurfaceBuilder(
  BuildContext context,
  Widget child,
  BorderRadius borderRadius,
) {
  final tokens =
      Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
  final radius = borderRadius.topLeft.x;

  return LiquidGlass.withOwnLayer(
    shape: LiquidRoundedSuperellipse(borderRadius: radius),
    settings: LiquidGlassSettings(
      glassColor: tokens.colorSurfaceRaised.withValues(alpha: .42),
      thickness: 13,
      blur: 14,
      chromaticAberration: .004,
      lightIntensity: .38,
      ambientStrength: .08,
      refractiveIndex: 1.14,
      saturation: 1.35,
    ),
    child: child,
  );
}
