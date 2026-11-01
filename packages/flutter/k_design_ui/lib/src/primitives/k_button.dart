import '../feedback/k_sound.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_icon.dart';
import 'k_overflow_text.dart';

enum KButtonVariant { primary, secondary, ghost }

class KButton extends StatelessWidget {
  const KButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.content,
    this.fullWidth = false,
    this.leading,
    this.trailing,
    this.paddingInline,
    this.variant = KButtonVariant.primary,
    super.key,
  });

  final String label;

  /// Rich button content; label remains its accessible name.
  final Widget? content;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final Widget? leading;
  final Widget? trailing;

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
            enableFeedback: KSoundProvider.maybeOf(context) == null,
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
                // Keep glyph descenders inside the line box used by Web and
                // Flutter overflow handling.
                height: tokens.fontRelaxedHeight,
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
          child: content != null
              ? Semantics(
                  label: label,
                  child: ExcludeSemantics(child: content!),
                )
              : Row(
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
                      if (leading is KIcon)
                        KIcon(
                          (leading! as KIcon).name,
                          size: (leading! as KIcon).size,
                          color: (leading! as KIcon).color ?? foreground,
                          label: (leading! as KIcon).label,
                        )
                      else
                        IconTheme.merge(
                          data: IconThemeData(color: foreground),
                          child: leading!,
                        ),
                      SizedBox(width: tokens.spaceControlGap),
                    ],
                    Flexible(
                      child: KOverflowText(text: Text(label), focusable: false),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: tokens.spaceControlGap),
                      if (trailing is KIcon)
                        KIcon(
                          (trailing! as KIcon).name,
                          size: (trailing! as KIcon).size,
                          color: (trailing! as KIcon).color ?? foreground,
                          label: (trailing! as KIcon).label,
                        )
                      else
                        IconTheme.merge(
                          data: IconThemeData(color: foreground),
                          child: trailing!,
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
