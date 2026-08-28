import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KButtonVariant { primary, secondary, ghost }

class KButton extends StatelessWidget {
  const KButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = KButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
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

    return Opacity(
      opacity: loading || onPressed == null ? 0.48 : 1,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, tokens.sizeControl)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: tokens.spaceControlInsetInline),
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
              fontWeight: tokens.fontControlWeight,
              fontVariations: [
                FontVariation.weight(tokens.fontControlWeight.value.toDouble()),
                FontVariation.opticalSize(tokens.fontControlSize.clamp(14, 32)),
              ],
              letterSpacing: -0.13,
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
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              ),
              SizedBox(width: tokens.spaceControlGap),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
