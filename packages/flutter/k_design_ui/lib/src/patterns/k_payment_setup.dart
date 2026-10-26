import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_display.dart';
import '../primitives/k_button.dart';
import '../primitives/k_card.dart';
import '../primitives/k_disclosure.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';

enum KPaymentSetupState {
  connected,
  actionRequired,
  pending,
  needsCorrection,
  ready,
}

enum KPaymentSetupStepState { complete, current, waiting, attention }

@immutable
class KPaymentSetupStep {
  const KPaymentSetupStep({
    required this.id,
    required this.label,
    required this.description,
    required this.state,
  });
  final String id;
  final String label;
  final String description;
  final KPaymentSetupStepState state;
}

@immutable
class KPaymentSetupAction {
  const KPaymentSetupAction({
    required this.label,
    required this.onAction,
    this.icon,
    this.loading = false,
    this.disabled = false,
  });
  final String label;
  final VoidCallback onAction;
  final KIconName? icon;
  final bool loading;
  final bool disabled;
}

@immutable
class KPaymentSetupHelp {
  const KPaymentSetupHelp({required this.title, required this.child});
  final String title;
  final Widget child;
}

/// Presentation only: the consumer owns provider data, verification and actions.
class KPaymentSetup extends StatelessWidget {
  const KPaymentSetup({
    required this.state,
    required this.providerName,
    required this.connectionLabel,
    required this.statusLabel,
    required this.title,
    required this.description,
    this.providerIcon,
    this.environmentLabel,
    this.note,
    this.steps = const [],
    this.stepsLabel = 'Setup progress',
    this.primaryAction,
    this.secondaryAction,
    this.help,
    super.key,
  });

  final KPaymentSetupState state;
  final String providerName;
  final Widget? providerIcon;
  final String connectionLabel;
  final String? environmentLabel;
  final String statusLabel;
  final String title;
  final String description;
  final String? note;
  final List<KPaymentSetupStep> steps;
  final String stepsLabel;
  final KPaymentSetupAction? primaryAction;
  final KPaymentSetupAction? secondaryAction;
  final KPaymentSetupHelp? help;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final (accent, background, foreground) = switch (state) {
      KPaymentSetupState.actionRequired ||
      KPaymentSetupState.needsCorrection => (
        t.colorStatusWarningAccent,
        t.colorStatusWarningBackground,
        t.colorStatusWarningForeground,
      ),
      KPaymentSetupState.ready => (
        t.colorStatusSuccessAccent,
        t.colorStatusSuccessBackground,
        t.colorStatusSuccessForeground,
      ),
      _ => (
        t.colorStatusInfoAccent,
        t.colorStatusInfoBackground,
        t.colorStatusInfoForeground,
      ),
    };
    final statusIcon = switch (state) {
      KPaymentSetupState.connected => KIconName.link,
      KPaymentSetupState.actionRequired => KIconName.clipboardList,
      KPaymentSetupState.pending => KIconName.clock3,
      KPaymentSetupState.needsCorrection => KIconName.shieldAlert,
      KPaymentSetupState.ready => KIconName.shieldCheck,
    };
    KText muted(String text, KTextVariant variant) => KText(
      text,
      variant: variant,
      style: TextStyle(color: t.colorTextMuted),
    );
    Widget iconBox(
      Widget child,
      double size,
      Color color,
      double radius, {
      Color? border,
    }) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border == null
            ? null
            : Border.all(color: border, width: t.borderWidthDefault),
      ),
      child: child,
    );

    return SizedBox(
      width: double.infinity,
      child: KCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth <= 420;
            final identity = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: t.spaceControlGap,
                children: [
                  ExcludeSemantics(
                    child: iconBox(
                      providerIcon ??
                          const KIcon(KIconName.creditCard, size: 22),
                      t.sizeControl,
                      t.colorSurfaceSubtle,
                      t.radiusControl,
                      border: t.colorBorderDefault,
                    ),
                  ),
                  Flexible(
                    child: KStack(
                      gap: KLayoutGap.control,
                      align: KLayoutAlign.start,
                      children: [
                        KText(providerName, variant: KTextVariant.heading5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: t.spaceControlGap,
                          children: [
                            KIcon(
                              KIconName.check,
                              size: 14,
                              color: t.colorStatusSuccessAccent,
                            ),
                            Flexible(
                              child: muted(
                                connectionLabel,
                                KTextVariant.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            final copy = KStack(
              gap: KLayoutGap.control,
              align: KLayoutAlign.stretch,
              children: [
                KText(
                  statusLabel,
                  variant: KTextVariant.label,
                  style: TextStyle(color: foreground),
                ),
                KText(title, variant: KTextVariant.heading3),
                muted(description, KTextVariant.body),
              ],
            );
            final status = Padding(
              padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
              child: Semantics(
                liveRegion: true,
                container: true,
                child: compact
                    ? KStack(
                        gap: KLayoutGap.action,
                        align: KLayoutAlign.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: iconBox(
                              KIcon(statusIcon, size: 28, color: foreground),
                              t.sizeControl + t.spaceControlGap,
                              background,
                              t.radiusCard,
                            ),
                          ),
                          copy,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: t.spaceContentActionGap,
                        children: [
                          iconBox(
                            KIcon(statusIcon, size: 28, color: foreground),
                            t.sizeControl + t.spaceControlGap,
                            background,
                            t.radiusCard,
                          ),
                          Expanded(child: copy),
                        ],
                      ),
              ),
            );
            Widget action(
              KPaymentSetupAction value, {
              bool secondary = false,
            }) => KButton(
              label: value.label,
              onPressed: value.disabled ? null : value.onAction,
              loading: value.loading,
              variant: secondary
                  ? KButtonVariant.ghost
                  : KButtonVariant.primary,
              fullWidth: false,
              leading: secondary && value.icon != null
                  ? KIcon(value.icon!, size: 16)
                  : null,
              trailing: !secondary && value.icon != null
                  ? KIcon(value.icon!, size: 16)
                  : null,
            );
            final actions = [
              if (primaryAction case final value?) action(value),
              if (secondaryAction case final value?)
                action(value, secondary: true),
            ];
            return KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: t.spaceContentActionGap,
                  runSpacing: t.spaceContentActionGap,
                  children: [
                    identity,
                    if (environmentLabel case final label?)
                      KBadge(
                        variant: KBadgeVariant.outline,
                        child: Text(label),
                      ),
                  ],
                ),
                _StatusEntry(
                  state: state,
                  offset: t.spaceControlGap,
                  child: status,
                ),
                if (steps.isNotEmpty)
                  Semantics(
                    label: stepsLabel,
                    container: true,
                    explicitChildNodes: true,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: t.spaceContentActionGap,
                      ),
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: t.colorBorderDefault,
                            width: t.borderWidthDefault,
                          ),
                        ),
                      ),
                      child: compact
                          ? KStack(
                              gap: KLayoutGap.action,
                              align: KLayoutAlign.stretch,
                              children: [
                                for (var i = 0; i < steps.length; i++)
                                  _PaymentStep(
                                    step: steps[i],
                                    index: i,
                                    compact: true,
                                    last: i == steps.length - 1,
                                    accent: accent,
                                    background: background,
                                    foreground: foreground,
                                  ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: t.spaceContentActionGap,
                              children: [
                                for (var i = 0; i < steps.length; i++)
                                  Expanded(
                                    child: _PaymentStep(
                                      step: steps[i],
                                      index: i,
                                      compact: false,
                                      last: i == steps.length - 1,
                                      accent: accent,
                                      background: background,
                                      foreground: foreground,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                if (actions.isNotEmpty || note != null)
                  KStack(
                    gap: KLayoutGap.control,
                    align: KLayoutAlign.stretch,
                    children: [
                      if (actions.isNotEmpty)
                        compact
                            ? KStack(
                                gap: KLayoutGap.action,
                                align: KLayoutAlign.start,
                                children: actions,
                              )
                            : KInline(
                                gap: KLayoutGap.action,
                                wrap: true,
                                children: actions,
                              ),
                      if (note case final text?)
                        muted(text, KTextVariant.caption),
                    ],
                  ),
                if (help case final value?)
                  KDisclosure(
                    title: value.title,
                    leadingIcon: const KIcon(KIconName.flaskConical, size: 16),
                    child: value.child,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.step,
    required this.index,
    required this.compact,
    required this.last,
    required this.accent,
    required this.background,
    required this.foreground,
  });
  final KPaymentSetupStep step;
  final int index;
  final bool compact;
  final bool last;
  final Color accent, background, foreground;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final complete = step.state == KPaymentSetupStepState.complete;
    final active =
        step.state == KPaymentSetupStepState.current ||
        step.state == KPaymentSetupStepState.attention;
    final copy = KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.start,
      children: [
        KText(step.label, variant: KTextVariant.label),
        KText(
          step.description,
          variant: KTextVariant.caption,
          style: TextStyle(color: t.colorTextMuted),
        ),
      ],
    );
    final marker = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : t.motionStandard,
      width: t.sizeControl,
      height: t.sizeControl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusFull),
        color: complete
            ? t.colorStatusSuccessBackground
            : active
            ? background
            : t.colorSurfaceCanvas,
        border: Border.all(
          width: t.borderWidthDefault,
          color: complete
              ? t.colorStatusSuccessBorder
              : active
              ? accent
              : t.colorBorderDefault,
        ),
      ),
      child: complete
          ? KIcon(
              KIconName.check,
              size: 16,
              color: t.colorStatusSuccessForeground,
            )
          : step.state == KPaymentSetupStepState.attention
          ? KIcon(KIconName.circleAlert, size: 16, color: foreground)
          : KText(
              '${index + 1}',
              variant: KTextVariant.label,
              style: TextStyle(color: active ? foreground : t.colorTextMuted),
            ),
    );
    return Semantics(
      key: ValueKey(step.id),
      container: true,
      label: '${step.label}, ${step.description}',
      selected: active,
      child: ExcludeSemantics(
        child: compact
            ? Row(
                spacing: t.spaceControlGap,
                children: [
                  marker,
                  Expanded(child: copy),
                ],
              )
            : Stack(
                children: [
                  if (!last)
                    PositionedDirectional(
                      start: t.sizeControl + t.spaceControlGap,
                      end: 0,
                      top: t.sizeControl / 2,
                      child: Container(
                        height: t.borderWidthDefault,
                        color: t.colorBorderDefault,
                      ),
                    ),
                  KStack(gap: KLayoutGap.control, children: [marker, copy]),
                ],
              ),
      ),
    );
  }
}

class _StatusEntry extends StatelessWidget {
  const _StatusEntry({
    required this.state,
    required this.offset,
    required this.child,
  });
  final KPaymentSetupState state;
  final double offset;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return TweenAnimationBuilder<double>(
      key: ValueKey(state),
      tween: Tween(begin: 0, end: 1),
      duration: t.motionEmphasis,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
