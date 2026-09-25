import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';

/// Shared internal trigger styling for labelled and icon-only actions.
class KActionControl extends StatelessWidget {
  const KActionControl({
    required this.label,
    required this.onPressed,
    required this.focusNode,
    this.icon,
    this.iconOnly = false,
    this.selected = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final FocusNode focusNode;
  final KIconName? icon;
  final bool iconOnly;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final scaled = MediaQuery.textScalerOf(context).scale(t.fontControlSize);
    final foreground = selected
        ? t.colorActionPrimaryForeground
        : iconOnly
        ? t.colorActionGhostForeground
        : t.colorActionSecondaryForeground;
    final target = math.max(t.sizeControl, t.sizeHitTarget);
    return MergeSemantics(
      child: Semantics(
        label: iconOnly ? label : null,
        child: Opacity(
          opacity: onPressed == null ? .48 : 1,
          child: SizedBox(
            width: iconOnly ? target : null,
            child: FilledButton(
              focusNode: focusNode,
              onPressed: onPressed,
              style: ButtonStyle(
                visualDensity: VisualDensity.standard,
                tapTargetSize: Theme.of(context).materialTapTargetSize,
                minimumSize: WidgetStatePropertyAll(Size(0, t.sizeControl)),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: iconOnly
                        ? 0
                        : t.spaceControlInsetInline + t.borderWidthDefault,
                    vertical: t.borderWidthDefault,
                  ),
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? (selected
                            ? t.colorActionPrimaryPressed
                            : iconOnly
                            ? t.colorActionGhostPressed
                            : t.colorActionSecondaryPressed)
                      : states.contains(WidgetState.hovered)
                      ? (selected
                            ? t.colorActionPrimaryHover
                            : iconOnly
                            ? t.colorActionGhostHover
                            : t.colorActionSecondaryHover)
                      : (selected
                            ? t.colorActionPrimaryBackground
                            : iconOnly
                            ? t.colorActionGhostBackground
                            : t.colorActionSecondaryBackground),
                ),
                foregroundColor: WidgetStatePropertyAll(foreground),
                side: WidgetStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.focused)
                        ? t.colorBorderFocus
                        : selected
                        ? Colors.transparent
                        : iconOnly
                        ? t.colorActionGhostBorder
                        : t.colorActionSecondaryBorder,
                  ),
                ),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                elevation: const WidgetStatePropertyAll(0),
                shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                surfaceTintColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(t.radiusControl),
                  ),
                ),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: t.fontFamily,
                    fontSize: t.fontControlSize,
                    fontWeight: t.fontControlWeight,
                    height: t.fontTightHeight,
                    // CSS centers leading evenly above and below the font metrics.
                    leadingDistribution: TextLeadingDistribution.even,
                    letterSpacing: -.01 * scaled,
                    fontVariations: [
                      FontVariation.weight(
                        t.fontControlWeight.value.toDouble(),
                      ),
                      FontVariation.opticalSize(scaled.clamp(14, 32)),
                    ],
                  ),
                ),
              ),
              child: iconOnly
                  ? KIcon(icon!, color: foreground)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(label)),
                        if (icon != null) ...[
                          SizedBox(width: t.spaceControlGap),
                          KIcon(icon!, color: foreground),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
