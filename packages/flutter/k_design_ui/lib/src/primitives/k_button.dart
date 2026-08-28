import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class KButton extends StatelessWidget {
  const KButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, tokens.sizeControl)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: tokens.spaceControlInsetInline),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.colorActionPrimaryBackground.withValues(alpha: 0.48);
          }
          if (states.contains(WidgetState.pressed)) {
            return tokens.colorActionPrimaryPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return tokens.colorActionPrimaryHover;
          }
          return tokens.colorActionPrimaryBackground;
        }),
        foregroundColor: WidgetStatePropertyAll(
          tokens.colorActionPrimaryForeground,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: tokens.fontFamily,
            fontSize: tokens.fontSize,
            fontWeight: tokens.fontWeight,
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
                color: tokens.colorActionPrimaryForeground,
              ),
            ),
            SizedBox(width: tokens.spaceControlGap),
          ],
          Text(label),
        ],
      ),
    );
  }
}
