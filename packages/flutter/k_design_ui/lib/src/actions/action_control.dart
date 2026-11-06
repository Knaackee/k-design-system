import '../feedback/k_sound.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_focus_ring.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_button.dart';

class KActionControlVisualScope extends InheritedWidget {
  const KActionControlVisualScope({required super.child, super.key});

  static bool enabledOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KActionControlVisualScope>() !=
      null;

  @override
  bool updateShouldNotify(KActionControlVisualScope oldWidget) => false;
}

/// Shared internal trigger styling for labelled and icon-only actions.
class KActionControl extends StatelessWidget {
  const KActionControl({
    required this.label,
    required this.onPressed,
    required this.focusNode,
    this.icon,
    this.iconContent,
    this.iconOnly = false,
    this.selected = false,
    this.variant = KButtonVariant.ghost,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final FocusNode focusNode;
  final KIconName? icon;
  final Widget? iconContent;
  final bool iconOnly;
  final bool selected;
  final KButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final scaled = MediaQuery.textScalerOf(context).scale(t.fontControlSize);
    final effectiveVariant = selected ? KButtonVariant.primary : variant;
    final foreground = !iconOnly
        ? t.colorActionSecondaryForeground
        : switch (effectiveVariant) {
            KButtonVariant.primary => t.colorActionPrimaryForeground,
            KButtonVariant.secondary => t.colorActionSecondaryForeground,
            KButtonVariant.ghost => t.colorActionGhostForeground,
          };
    final target = math.max(t.sizeControl, t.sizeHitTarget);
    final scopedVisual =
        iconOnly && KActionControlVisualScope.enabledOf(context);
    Color background(Set<WidgetState> states) {
      final pressed = states.contains(WidgetState.pressed);
      final hovered = states.contains(WidgetState.hovered);
      return switch (effectiveVariant) {
        KButtonVariant.primary =>
          pressed
              ? t.colorActionPrimaryPressed
              : hovered
              ? t.colorActionPrimaryHover
              : t.colorActionPrimaryBackground,
        KButtonVariant.secondary =>
          pressed
              ? t.colorActionSecondaryPressed
              : hovered
              ? t.colorActionSecondaryHover
              : t.colorActionSecondaryBackground,
        KButtonVariant.ghost =>
          pressed
              ? t.colorActionGhostPressed
              : hovered
              ? t.colorActionGhostHover
              : t.colorActionGhostBackground,
      };
    }

    BorderSide border(Set<WidgetState> states) => BorderSide(
      color: kFocusVisible(states)
          ? t.colorBorderFocus
          : switch (effectiveVariant) {
              KButtonVariant.primary => Colors.transparent,
              KButtonVariant.secondary => t.colorActionSecondaryBorder,
              KButtonVariant.ghost => t.colorActionGhostBorder,
            },
    );
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
                enableFeedback: KSoundProvider.maybeOf(context) == null,
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
                  (states) => scopedVisual
                      ? Colors.transparent
                      : iconOnly
                      ? background(states)
                      : states.contains(WidgetState.pressed)
                      ? t.colorActionSecondaryPressed
                      : states.contains(WidgetState.hovered)
                      ? t.colorActionSecondaryHover
                      : t.colorActionSecondaryBackground,
                ),
                foregroundColor: WidgetStatePropertyAll(foreground),
                side: WidgetStateProperty.resolveWith(
                  (states) => scopedVisual
                      ? BorderSide.none
                      : iconOnly
                      ? border(states)
                      : BorderSide(
                          color: kFocusVisible(states)
                              ? t.colorBorderFocus
                              : selected
                              ? Colors.transparent
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
                backgroundBuilder: scopedVisual
                    ? (context, states, child) => Center(
                        child: SizedBox.square(
                          dimension: t.sizeControl,
                          child: DecoratedBox(
                            key: const ValueKey('k-action-control-visual'),
                            decoration: BoxDecoration(
                              color: background(states),
                              border: Border.fromBorderSide(border(states)),
                              borderRadius: BorderRadius.circular(
                                t.radiusControl,
                              ),
                            ),
                            child: Center(child: child),
                          ),
                        ),
                      )
                    : null,
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
                  ? iconContent ?? KIcon(icon!, color: foreground)
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
