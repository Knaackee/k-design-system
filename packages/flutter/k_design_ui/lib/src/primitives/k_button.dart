import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KButtonVariant { primary, secondary, ghost }

class KButton extends StatelessWidget {
  const KButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.leading,
    this.paddingInline,
    this.variant = KButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final Widget? leading;

  /// Overrides the density-based horizontal content inset when alignment is
  /// controlled by a parent layout, such as a table column.
  final double? paddingInline;
  final KButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final (background, hover, pressed, foreground, border) = switch (variant) {
      KButtonVariant.primary => (
        tokens.colorActionPrimaryBackground,
        tokens.colorActionPrimaryHover,
        tokens.colorActionPrimaryPressed,
        tokens.colorActionPrimaryForeground,
        Colors.transparent,
      ),
      KButtonVariant.secondary => (
        tokens.colorActionSecondaryBackground,
        tokens.colorActionSecondaryHover,
        tokens.colorActionSecondaryPressed,
        tokens.colorActionSecondaryForeground,
        tokens.colorActionSecondaryBorder,
      ),
      KButtonVariant.ghost => (
        tokens.colorActionGhostBackground,
        tokens.colorActionGhostHover,
        tokens.colorActionGhostPressed,
        tokens.colorActionGhostForeground,
        tokens.colorActionGhostBorder,
      ),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: loading || onPressed == null
            ? tokens.componentButtonDisabledOpacity
            : 1,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: ButtonStyle(
            // Density is already resolved by the tokens; do not compact twice.
            visualDensity: VisualDensity.standard,
            alignment: fullWidth ? AlignmentDirectional.centerStart : null,
            minimumSize: WidgetStatePropertyAll(Size(0, tokens.sizeControl)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                // Material paints its 1px border inside; CSS includes it in layout.
                horizontal: paddingInline ?? tokens.spaceControlInsetInline + 1,
                vertical: tokens.borderWidthDefault,
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return pressed;
              }
              if (states.contains(WidgetState.hovered)) {
                return hover;
              }
              return background;
            }),
            foregroundColor: WidgetStatePropertyAll(foreground),
            side: WidgetStatePropertyAll(BorderSide(color: border)),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(0),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            textStyle: WidgetStatePropertyAll(
              TextStyle(
                fontFamily: tokens.fontFamily,
                fontSize: tokens.fontControlSize,
                // Match the Web control line box while allowing scaled text growth.
                height: tokens.fontTightHeight,
                // CSS centers leading evenly above and below the font metrics.
                leadingDistribution: TextLeadingDistribution.even,
                fontWeight: tokens.fontControlWeight,
                fontVariations: [
                  FontVariation.weight(
                    tokens.fontControlWeight.value.toDouble(),
                  ),
                  FontVariation.opticalSize(
                    MediaQuery.textScalerOf(
                      context,
                    ).scale(tokens.fontControlSize).clamp(14, 32),
                  ),
                ],
                letterSpacing:
                    -.01 *
                    MediaQuery.textScalerOf(
                      context,
                    ).scale(tokens.fontControlSize),
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radiusControl),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                SizedBox.square(
                  dimension: tokens.componentButtonLoadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        tokens.componentButtonLoadingIndicatorStrokeWidth,
                    color: foreground,
                  ),
                ),
                SizedBox(width: tokens.spaceControlGap),
              ],
              if (leading != null) ...[
                leading!,
                SizedBox(width: tokens.spaceControlGap),
              ],
              if (leading != null)
                Flexible(child: Text(label))
              else
                Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
