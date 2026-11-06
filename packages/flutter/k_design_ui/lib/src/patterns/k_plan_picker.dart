import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';

/// Prices are already formatted by the host, including currency.
class KPlanPrice {
  const KPlanPrice({
    required this.amount,
    this.period,
    this.billingNote,
    this.equivalent,
  });
  final String amount;
  final String? period, billingNote, equivalent;
}

class KPlan {
  const KPlan({
    required this.id,
    required this.name,
    required this.features,
    required this.prices,
    this.description,
    this.disabled = false,
  });
  final String id, name;
  final List<String> features;
  final Map<String, KPlanPrice> prices;
  final String? description;
  final bool disabled;
}

class KPlanInterval {
  const KPlanInterval({required this.id, required this.label});
  final String id, label;
}

class KPlanSelection {
  const KPlanSelection({required this.planId, required this.intervalId});
  final String planId, intervalId;
}

/// Controlled presentation: the host owns purchase, pricing and persistence.
/// Single-plan composition matches the Web PlanPicker; multiple plans stack.
class KPlanPicker extends StatelessWidget {
  const KPlanPicker({
    required this.plans,
    required this.value,
    required this.onValueChange,
    required this.intervals,
    required this.interval,
    required this.onIntervalChange,
    required this.label,
    required this.intervalLabel,
    required this.unavailableLabel,
    this.actionLabel,
    this.onContinue,
    this.actionDisabled = false,
    this.disabled = false,
    this.loading = false,
    this.note,
    super.key,
  });
  final List<KPlan> plans;
  final String? value;
  final ValueChanged<String> onValueChange, onIntervalChange;
  final List<KPlanInterval> intervals;
  final String interval, label, intervalLabel, unavailableLabel;
  final String? actionLabel;
  final ValueChanged<KPlanSelection>? onContinue;
  final bool actionDisabled, disabled, loading;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final selected = plans.where((p) => p.id == value).firstOrNull;
    final available =
        selected != null &&
        !selected.disabled &&
        selected.prices.containsKey(interval) &&
        intervals.any((i) => i.id == interval);
    return KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        if (intervals.length > 1)
          Align(
            child: _PlanIntervalSwitch(
              intervals: intervals,
              value: interval,
              label: intervalLabel,
              onChanged: disabled || loading ? null : onIntervalChange,
            ),
          ),
        Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.stretch,
              children: [
                for (final plan in plans)
                  KPlanCard(
                    plan: plan,
                    price: plan.prices[interval],
                    unavailableLabel: unavailableLabel,
                    selected: value == plan.id,
                    onSelect:
                        plans.length > 1 &&
                            !disabled &&
                            !loading &&
                            !plan.disabled &&
                            plan.prices.containsKey(interval)
                        ? () => onValueChange(plan.id)
                        : null,
                  ),
              ],
            ),
          ),
        ),
        if (actionLabel != null || note != null)
          KStack(
            align: KLayoutAlign.center,
            children: [
              if (actionLabel != null)
                KButton(
                  label: actionLabel!,
                  loading: loading,
                  trailing: const KIcon(KIconName.arrowRight),
                  onPressed:
                      disabled ||
                          loading ||
                          actionDisabled ||
                          !available ||
                          onContinue == null
                      ? null
                      : () => onContinue!(
                          KPlanSelection(
                            planId: selected.id,
                            intervalId: interval,
                          ),
                        ),
                ),
              ?note,
            ],
          ),
      ],
    );
  }
}

class KPlanCard extends StatelessWidget {
  const KPlanCard({
    required this.plan,
    required this.price,
    required this.unavailableLabel,
    this.selected = false,
    this.onSelect,
    super.key,
  });
  final KPlan plan;
  final KPlanPrice? price;
  final String unavailableLabel;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final muted = TextStyle(color: tokens.colorTextMuted);
    final content = Container(
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                tokens.colorActionPrimaryBackground.withValues(alpha: .05),
                tokens.colorSurfaceRaised,
              )
            : tokens.colorSurfaceRaised,
        border: Border.all(
          color: selected
              ? tokens.colorActionPrimaryBackground
              : tokens.colorBorderDefault,
          width: tokens.borderWidthDefault,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        boxShadow: selected ? tokens.elevationLow : tokens.elevationNone,
      ),
      foregroundDecoration: selected
          ? BoxDecoration(
              border: Border.all(
                color: tokens.colorActionPrimaryBackground,
                width: tokens.borderWidthDefault * 2,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusCard),
            )
          : null,
      padding: EdgeInsets.all(tokens.spaceCardPadding),
      child: KStack(
        gap: KLayoutGap.section,
        align: KLayoutAlign.stretch,
        children: [
          KStack(
            gap: KLayoutGap.action,
            align: KLayoutAlign.stretch,
            children: [
              KText(plan.name, variant: KTextVariant.heading4),
              KStack(
                align: KLayoutAlign.stretch,
                children: [
                  KInline(
                    wrap: true,
                    align: KLayoutAlign.center,
                    children: [
                      KText(
                        price?.amount ?? unavailableLabel,
                        variant: KTextVariant.heading1,
                      ),
                      if (price?.period != null)
                        KText(
                          price!.period!,
                          variant: KTextVariant.bodySmall,
                          style: muted,
                        ),
                    ],
                  ),
                  if (price?.billingNote != null)
                    KText(
                      price!.billingNote!,
                      variant: KTextVariant.bodySmall,
                      style: muted,
                    ),
                  if (price?.equivalent != null)
                    KText(
                      price!.equivalent!,
                      variant: KTextVariant.bodySmall,
                      style: muted,
                    ),
                  if (plan.description != null)
                    KText(
                      plan.description!,
                      variant: KTextVariant.bodySmall,
                      style: muted,
                    ),
                ],
              ),
            ],
          ),
          KStack(
            align: KLayoutAlign.stretch,
            children: [
              for (final feature in plan.features)
                KInline(
                  children: [
                    const KIcon(KIconName.check, size: 20),
                    Expanded(
                      child: KText(feature, variant: KTextVariant.bodySmall),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    return Opacity(
      opacity: plan.disabled || price == null ? .55 : 1,
      child: onSelect == null
          ? content
          : Semantics(
              label: plan.name,
              selected: selected,
              button: true,
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(tokens.radiusCard),
                child: content,
              ),
            ),
    );
  }
}

class _PlanIntervalSwitch extends StatelessWidget {
  const _PlanIntervalSwitch({
    required this.intervals,
    required this.value,
    required this.label,
    required this.onChanged,
  });
  final List<KPlanInterval> intervals;
  final String value, label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            borderRadius: BorderRadius.circular(tokens.radiusFull),
            border: Border.all(color: tokens.colorBorderDefault),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceMicro),
            child: Row(
              children: [
                for (final option in intervals)
                  Expanded(
                    child: Semantics(
                      checked: value == option.id,
                      inMutuallyExclusiveGroup: true,
                      child: TextButton(
                        onPressed: onChanged == null
                            ? null
                            : () => onChanged!(option.id),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, tokens.sizeControl),
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceControlInsetInline,
                            vertical: tokens.spaceSmallInset,
                          ),
                          backgroundColor: value == option.id
                              ? tokens.colorSurfaceCanvas
                              : Colors.transparent,
                          shape: const StadiumBorder(),
                          foregroundColor: tokens.colorTextPrimary,
                        ),
                        child: KText(
                          option.label,
                          variant: KTextVariant.bodySmall,
                          align: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: value == option.id
                                ? tokens.colorTextPrimary
                                : tokens.colorTextMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
