import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Presentation only. Position and chat state belong to the consumer.
class KChatBubble extends StatelessWidget {
  const KChatBubble({
    required this.label,
    required this.child,
    required this.onPressed,
    this.size = 64,
    this.visible = true,
    this.clipBehavior = Clip.antiAlias,
    this.style,
    this.onLongPress,
    super.key,
  });

  final String label;
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double size;

  /// Use Clip.none for illustrations that extend beyond the circular surface.
  final Clip clipBehavior;

  /// Content stays mounted and animated while waiting for consumer readiness.
  final bool visible;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final dimension = math.max(size, tokens.sizeHitTarget);
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        onTap: onPressed,
        onLongPress: onLongPress,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: tokens.elevationOverlay,
            ),
            child: SizedBox.square(
              dimension: dimension,
              child: FilledButton(
                onPressed: onPressed,
                onLongPress: onLongPress,
                clipBehavior: clipBehavior,
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  surfaceTintColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  shape: const WidgetStatePropertyAll(CircleBorder()),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.all(tokens.spaceControlGap),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed)
                        ? tokens.colorActionSecondaryPressed
                        : states.contains(WidgetState.hovered)
                        ? tokens.colorActionSecondaryHover
                        : tokens.colorActionSecondaryBackground,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    tokens.colorActionSecondaryForeground,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: tokens.colorActionSecondaryBorder),
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                ).merge(style),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
