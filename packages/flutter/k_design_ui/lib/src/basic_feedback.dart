import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'localization/k_localization.dart';
import 'overlays/k_overlays.dart';
import 'primitives/k_button.dart';
import 'primitives/k_icon.dart';

enum KStatusTone { neutral, info, success, warning, error }

class KAlert extends StatelessWidget {
  const KAlert({
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.tone = KStatusTone.neutral,
    this.liveRegion,
    super.key,
  });

  final Widget title;
  final Widget? description;
  final KIconName? icon;
  final Widget? action;
  final KStatusTone tone;
  final bool? liveRegion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final (background, foreground, border) = switch (tone) {
      KStatusTone.neutral => (
        t.colorSurfaceRaised,
        t.colorTextPrimary,
        t.colorBorderDefault,
      ),
      KStatusTone.info => (
        t.colorStatusInfoBackground,
        t.colorStatusInfoForeground,
        t.colorStatusInfoBorder,
      ),
      KStatusTone.success => (
        t.colorStatusSuccessBackground,
        t.colorStatusSuccessForeground,
        t.colorStatusSuccessBorder,
      ),
      KStatusTone.warning => (
        t.colorStatusWarningBackground,
        t.colorStatusWarningForeground,
        t.colorStatusWarningBorder,
      ),
      KStatusTone.error => (
        t.colorStatusErrorBackground,
        t.colorStatusErrorForeground,
        t.colorStatusErrorBorder,
      ),
    };
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: _textStyle(t, t.fontLabelSize, t.fontLabelWeight, foreground),
          child: title,
        ),
        if (description != null) ...[
          SizedBox(height: t.spaceMicro),
          DefaultTextStyle(
            style: _textStyle(
              t,
              t.fontBodySmallSize,
              t.fontBodyWeight,
              foreground.withValues(alpha: t.componentToastMessageOpacity),
            ),
            child: description!,
          ),
        ],
      ],
    );
    return Semantics(
      liveRegion: liveRegion ?? tone == KStatusTone.error,
      child: Container(
        padding: EdgeInsets.all(t.spaceCardPadding),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border, width: t.borderWidthDefault),
          borderRadius: BorderRadius.circular(t.radiusCard),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;
            final leadingContent = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  KIcon(icon!, color: foreground),
                  SizedBox(width: t.spaceControlGap),
                ],
                Expanded(child: content),
              ],
            );
            if (action == null) return leadingContent;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leadingContent,
                  SizedBox(height: t.spaceControlGap),
                  action!,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: leadingContent),
                SizedBox(width: t.spaceControlGap),
                action!,
              ],
            );
          },
        ),
      ),
    );
  }
}

class KAlertDialog extends StatelessWidget {
  const KAlertDialog({
    required this.title,
    required this.description,
    required this.onCancel,
    required this.onAction,
    this.cancelLabel,
    this.actionLabel,
    this.media,
    this.destructive = false,
    this.actionDisabled = false,
    super.key,
  });

  final Widget title;
  final Widget description;
  final Widget? media;
  final String? cancelLabel;
  final String? actionLabel;
  final VoidCallback onCancel;
  final VoidCallback onAction;
  final bool destructive;
  final bool actionDisabled;

  static Future<bool?> show({
    required BuildContext context,
    required Widget title,
    required Widget description,
    String? cancelLabel,
    String? actionLabel,
    Widget? media,
    bool destructive = false,
    bool actionDisabled = false,
  }) {
    final localization = KLocalization.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => localization.wrap(
        KAlertDialog(
          title: title,
          description: description,
          media: media,
          cancelLabel: cancelLabel,
          actionLabel: actionLabel,
          destructive: destructive,
          actionDisabled: actionDisabled,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onAction: () => Navigator.of(dialogContext).pop(true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final messages = KLocalization.of(context);
    final resolvedCancelLabel = cancelLabel ?? messages.text('cancel');
    final resolvedActionLabel = actionLabel ?? messages.text('apply');
    return KDialog(
      title: title,
      description: description,
      maxWidth: t.componentAlertDialogMaxWidth,
      actions: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: t.spaceContentActionGap,
          runSpacing: t.spaceControlGap,
          alignment: WrapAlignment.end,
          children: [
            KButton(
              label: resolvedCancelLabel,
              variant: KButtonVariant.secondary,
              onPressed: onCancel,
            ),
            destructive
                ? _DestructiveButton(
                    label: resolvedActionLabel,
                    onPressed: actionDisabled ? null : onAction,
                  )
                : KButton(
                    label: resolvedActionLabel,
                    onPressed: actionDisabled ? null : onAction,
                  ),
          ],
        ),
      ),
      child: media == null
          ? const SizedBox.shrink()
          : Container(
              width: t.componentAlertDialogMediaSize,
              height: t.componentAlertDialogMediaSize,
              decoration: BoxDecoration(
                color: t.colorSurfaceSubtle,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: media,
            ),
    );
  }
}

class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(0, t.sizeControl),
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceControlInsetInline + t.borderWidthDefault,
        ),
        backgroundColor: t.colorStatusErrorBackground,
        foregroundColor: t.colorStatusErrorForeground,
        side: BorderSide(color: t.colorStatusErrorBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusControl),
        ),
        textStyle: _textStyle(
          t,
          t.fontControlSize,
          t.fontControlWeight,
          t.colorStatusErrorForeground,
        ),
      ),
      child: Text(label),
    );
  }
}

TextStyle _textStyle(
  KDesignTokens t,
  double size,
  FontWeight weight,
  Color color,
) => TextStyle(
  color: color,
  fontFamily: t.fontFamily,
  fontSize: size,
  fontWeight: weight,
  height: t.fontRelaxedHeight,
  leadingDistribution: TextLeadingDistribution.even,
  fontVariations: [
    FontVariation.weight(weight.value.toDouble()),
    FontVariation.opticalSize(size.clamp(14, 32)),
  ],
);
