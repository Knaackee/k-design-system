import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class PlanPickerFixture extends StatefulWidget {
  const PlanPickerFixture({this.annual = false, super.key});
  final bool annual;
  @override
  State<PlanPickerFixture> createState() => _PlanPickerFixtureState();
}

class _PlanPickerFixtureState extends State<PlanPickerFixture> {
  late String interval = widget.annual ? 'yearly' : 'monthly';
  String event = '';
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceCardPadding),
            child: KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.stretch,
              children: [
                const KStack(
                  align: KLayoutAlign.center,
                  children: [
                    KText(
                      'Mach mehr aus deinem Alltag.',
                      variant: KTextVariant.heading2,
                    ),
                    KText('Ein Plan, der zu dir passt.'),
                  ],
                ),
                KPlanPicker(
                  plans: const [
                    KPlan(
                      id: 'essential',
                      name: 'Essential',
                      description: 'Alles für deinen Start.',
                      features: [
                        'Deine eigene Buchungsseite',
                        'Online-Termine',
                        'Kundenverwaltung',
                      ],
                      prices: {
                        'monthly': KPlanPrice(
                          amount: '19 €',
                          period: '/ Monat',
                          billingNote: 'Monatliche Abrechnung',
                        ),
                        'yearly': KPlanPrice(
                          amount: '190 €',
                          period: '/ Jahr',
                          billingNote: 'Jährliche Abrechnung',
                        ),
                      },
                    ),
                  ],
                  value: 'essential',
                  onValueChange: (_) {},
                  intervals: [
                    const KPlanInterval(id: 'monthly', label: 'Monatlich'),
                    if (widget.annual)
                      const KPlanInterval(id: 'yearly', label: 'Jährlich'),
                  ],
                  interval: interval,
                  onIntervalChange: (value) => setState(() {
                    interval = value;
                    event = 'onIntervalChange: $value';
                  }),
                  label: 'Plan wählen',
                  intervalLabel: 'Zahlungsweise',
                  unavailableLabel: 'Nicht verfügbar',
                  actionLabel: 'Weiter mit deinem Plan',
                  onContinue: (value) => setState(
                    () => event =
                        'onContinue: ${value.planId}, ${value.intervalId}',
                  ),
                  note: const KText(
                    'Beispielpreise für die Designprüfung. Es wird kein Kauf ausgelöst.',
                    variant: KTextVariant.bodySmall,
                    align: TextAlign.center,
                  ),
                ),
                KText(event, variant: KTextVariant.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
