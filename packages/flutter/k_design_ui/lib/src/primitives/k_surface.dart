import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KSurfaceTone { canvas, raised, subtle }

enum KSurfaceBorder { none, standard, strong }

enum KSurfaceRadius {
  none,
  small,
  medium,
  large,
  extraLarge,
  card,
  overlay,
  full,
}

enum KSurfaceElevation { none, low, medium, overlay }

class KSurface extends StatelessWidget {
  const KSurface({
    required this.child,
    this.tone = KSurfaceTone.raised,
    this.border = KSurfaceBorder.standard,
    this.radius = KSurfaceRadius.medium,
    this.elevation = KSurfaceElevation.none,
    super.key,
  });

  final Widget child;
  final KSurfaceTone tone;
  final KSurfaceBorder border;
  final KSurfaceRadius radius;
  final KSurfaceElevation elevation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final background = switch (tone) {
      KSurfaceTone.canvas => tokens.colorSurfaceCanvas,
      KSurfaceTone.raised => tokens.colorSurfaceRaised,
      KSurfaceTone.subtle => tokens.colorSurfaceSubtle,
    };
    final borderColor = switch (border) {
      KSurfaceBorder.none => null,
      KSurfaceBorder.standard => tokens.colorBorderDefault,
      KSurfaceBorder.strong => tokens.colorBorderStrong,
    };
    final radiusValue = switch (radius) {
      KSurfaceRadius.none => tokens.radiusNone,
      KSurfaceRadius.small => tokens.radiusSmall,
      KSurfaceRadius.medium => tokens.radiusMedium,
      KSurfaceRadius.large => tokens.radiusLarge,
      KSurfaceRadius.extraLarge => tokens.radiusExtraLarge,
      KSurfaceRadius.card => tokens.radiusCard,
      KSurfaceRadius.overlay => tokens.radiusOverlay,
      KSurfaceRadius.full => tokens.radiusFull,
    };
    final shadows = switch (elevation) {
      KSurfaceElevation.none => tokens.elevationNone,
      KSurfaceElevation.low => tokens.elevationLow,
      KSurfaceElevation.medium => tokens.elevationMedium,
      KSurfaceElevation.overlay => tokens.elevationOverlay,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: tokens.borderWidthDefault),
        borderRadius: BorderRadius.circular(radiusValue),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
