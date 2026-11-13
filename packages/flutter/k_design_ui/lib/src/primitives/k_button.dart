import '../feedback/k_sound.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_icon.dart';
import 'k_overflow_text.dart';

enum KButtonVariant { primary, secondary, ghost }

enum KButtonTone { standard, destructive }

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
    this.tone = KButtonTone.standard,
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
  final KButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final style = KAdaptive.maybeOf(context)?.style ?? KStyle.linear;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final (
      background,
      hover,
      pressed,
      foreground,
      border,
    ) = tone == KButtonTone.destructive
        ? (
            tokens.colorStatusErrorAccent,
            Color.lerp(
              tokens.colorStatusErrorAccent,
              tokens.colorTextPrimary,
              .12,
            )!,
            Color.lerp(
              tokens.colorStatusErrorAccent,
              tokens.colorTextPrimary,
              .24,
            )!,
            tokens.colorActionPrimaryForeground,
            tokens.colorStatusErrorAccent,
          )
        : switch (variant) {
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

    final button = SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: loading || onPressed == null
            ? tokens.componentButtonDisabledOpacity
            : 1,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: ButtonStyle(
            // Press and hover colour changes use the feedback role, as on
            // Web (`--k-motion-feedback-*`).
            animationDuration: tokens.motion(KMotionRole.feedback).settle,
            enableFeedback: KSoundProvider.maybeOf(context) == null,
            // Density is already resolved by the tokens; do not compact twice.
            visualDensity: VisualDensity.standard,
            // A full-width button is a call to action: centred label and the
            // prominent touch height (iOS 50 pt) (Decision 0015).
            minimumSize: WidgetStatePropertyAll(
              Size(0, fullWidth ? tokens.sizeProminent : tokens.sizeControl),
            ),
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
            // Material 3 Expressive: the pressed button morphs to a
            // squarer shape; Material animates the change (Decision 0015).
            shape: WidgetStateProperty.resolveWith(
              (states) => RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  style == KStyle.material &&
                          states.contains(WidgetState.pressed)
                      ? tokens.radiusControl
                      : tokens.componentButtonRadius,
                ),
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
    // Apple: the pressed button scales down slightly (Decision 0015).
    return style == KStyle.apple && onPressed != null && !loading
        ? KPressScale(child: button)
        : button;
  }
}

/// Scales its child to 96 % while pressed, with the feedback motion role
/// (iOS press response). Used by buttons and tappable surfaces in the Apple
/// style.
class KPressScale extends StatefulWidget {
  const KPressScale({required this.child, super.key});
  final Widget child;

  @override
  State<KPressScale> createState() => _KPressScaleState();
}

class _KPressScaleState extends State<KPressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(
      context,
    ).extension<KDesignTokens>()!.motion(KMotionRole.feedback);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        // Reduced motion: distance 0, no scaling.
        scale: _pressed ? 1 - .04 * motion.distance : 1,
        duration: motion.settle,
        curve: motion.curve,
        child: widget.child,
      ),
    );
  }
}
