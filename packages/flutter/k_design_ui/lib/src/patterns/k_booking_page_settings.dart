import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

class KColorSwatch {
  const KColorSwatch({
    required this.value,
    required this.label,
    required this.color,
    this.gradient,
  });
  final String value, label;
  final Color color;
  final Gradient? gradient;
}

/// Named, accessible swatches; colour data belongs to the consuming application.
class KColorSwatches extends StatelessWidget {
  const KColorSwatches({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });
  final List<KColorSwatch> options;
  final String value, label;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      child: Wrap(
        spacing: t.spaceControlGap,
        runSpacing: t.spaceControlGap,
        children: [
          for (final option in options)
            Semantics(
              label: option.label,
              checked: option.value == value,
              inMutuallyExclusiveGroup: true,
              enabled: onChanged != null,
              child: Tooltip(
                message: option.label,
                child: InkResponse(
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(option.value),
                  child: SizedBox.square(
                    dimension: t.sizeHitTarget,
                    child: Center(
                      child: Container(
                        width: t.componentAvatarPickerSwatchSize,
                        height: t.componentAvatarPickerSwatchSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: option.color,
                          gradient: option.gradient,
                          border: option.value == value
                              ? Border.all(
                                  color: t.colorTextPrimary,
                                  width: t.borderWidthStrong,
                                )
                              : null,
                        ),
                        child: option.value == value
                            ? KIcon(
                                KIconName.check,
                                size: t.sizeIconDefault,
                                color: option.color.computeLuminance() > .4
                                    ? t.colorTextPrimary
                                    : t.colorActionPrimaryForeground,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class KBookingPageAction {
  const KBookingPageAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });
  final String label;
  final KIconName icon;
  final VoidCallback? onPressed;
  final bool primary;
}

/// Four phone actions with complete labels; tablet preview has its own action.
class KBookingPageActions extends StatelessWidget {
  const KBookingPageActions({
    required this.actions,
    required this.previewAction,
    required this.compact,
    super.key,
  });
  final List<KBookingPageAction> actions;
  final KBookingPageAction previewAction;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final visible = [...actions, if (compact) previewAction];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = compact
            ? (MediaQuery.textScalerOf(context).scale(1) >= 1.3 ? 2 : 4)
            : 3;
        final width =
            (c.maxWidth - (columns - 1) * t.spaceControlGap) / columns;
        return Wrap(
          spacing: t.spaceControlGap,
          runSpacing: t.spaceControlGap,
          children: [
            for (final action in visible)
              SizedBox(
                width: width,
                child: KButton(
                  label: action.label,
                  onPressed: action.onPressed,
                  fullWidth: true,
                  paddingInline: t.spaceTight,
                  variant: action.primary
                      ? KButtonVariant.primary
                      : KButtonVariant.secondary,
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
                    child: compact
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              KIcon(
                                action.icon,
                                color: action.primary
                                    ? t.colorActionPrimaryForeground
                                    : null,
                              ),
                              SizedBox(height: t.spaceTight),
                              KText(
                                action.label,
                                variant: KTextVariant.caption,
                                style: TextStyle(
                                  color: action.primary
                                      ? t.colorActionPrimaryForeground
                                      : t.colorActionSecondaryForeground,
                                ),
                                align: TextAlign.center,
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: t.spaceControlGap,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            children: [
                              KIcon(
                                action.icon,
                                color: action.primary
                                    ? t.colorActionPrimaryForeground
                                    : null,
                              ),
                              Text(action.label),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
