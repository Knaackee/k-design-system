import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class MetricCardFixture extends StatelessWidget {
  const MetricCardFixture({
    required this.filled,
    required this.dark,
    super.key,
  });
  final bool filled;
  final bool dark;
  @override
  Widget build(BuildContext context) => KAdaptiveTheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    overrides: const KAdaptiveOverrides(style: KStyle.apple),
    tokenTransform: (t) => t.withAccent(const Color(0xFF0C679F)),
    child: Builder(
      builder: (context) {
        final t = Theme.of(context).extension<KDesignTokens>()!;
        final large = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
        final cards = [
          KMetricCard(
            label: 'Umsatz',
            value: filled ? '146,76 €' : '0 €',
            description: filled ? 'bestätigte Termine' : 'noch keine Termine',
            comparison: filled
                ? const KMetricComparison(
                    label: '+12%',
                    description: 'gegenüber der Vorperiode',
                    sentiment: KMetricSentiment.positive,
                  )
                : null,
            trend: filled
                ? const KMetricTrend(
                    values: [12, 16, 13, 18, 22, 19, 26, 24, 28, 25, 29, 33],
                    label: 'Umsatz im ausgewählten Zeitraum',
                  )
                : null,
          ),
          KMetricCard(
            label: 'Buchungen',
            value: filled ? '8' : '0',
            description: filled ? 'heute 3' : 'noch keine Termine',
            comparison: filled
                ? const KMetricComparison(
                    label: '+3',
                    description: 'gegenüber der Vorperiode',
                    sentiment: KMetricSentiment.positive,
                  )
                : null,
            trend: filled
                ? const KMetricTrend(
                    values: [2, 3, 3, 5, 4, 6, 5, 7, 6, 7, 8, 9],
                    label: 'Buchungen im ausgewählten Zeitraum',
                  )
                : null,
          ),
          KMetricCard(
            label: 'Neue Kund:innen',
            value: filled ? '5' : '0',
            description: filled ? 'erstmals gebucht' : '–',
            comparison: filled
                ? const KMetricComparison(
                    label: '+2',
                    description: 'gegenüber der Vorperiode',
                    sentiment: KMetricSentiment.positive,
                  )
                : null,
            trend: filled
                ? const KMetricTrend(
                    values: [1, 1, 2, 2, 3, 2, 3, 4, 4, 4, 5, 5],
                    label: 'Erstbuchungen im ausgewählten Zeitraum',
                  )
                : null,
          ),
          KMetricCard(
            label: 'Auslastung',
            value: filled ? '25 %' : '0 %',
            description: filled
                ? '4 von 16 h diese Woche'
                : '0 von 16 h diese Woche',
            progress: KMetricProgress(
              value: filled ? 25 : 0,
              label: 'Auslastung der verfügbaren Arbeitszeit',
            ),
          ),
        ];
        return Scaffold(
          backgroundColor: t.colorSurfaceCanvas,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(t.spaceLayoutGutter),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: t.spaceCardPadding * 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: t.spaceContentActionGap,
                    children: [
                      for (var i = 0; i < cards.length; i += large ? 1 : 2)
                        if (large)
                          cards[i]
                        else
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: t.spaceContentActionGap,
                              children: [
                                Expanded(child: cards[i]),
                                Expanded(child: cards[i + 1]),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
