import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final style in [KStyle.apple, KStyle.material]) {
    testWidgets('metric slots align short and wrapped descriptions: $style', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: KAdaptiveTheme(
            overrides: KAdaptiveOverrides(style: style),
            child: const Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: KMetricCard(
                      key: ValueKey('trend-card'),
                      label: 'Umsatz',
                      value: '146 €',
                      description: 'bestätigte Termine',
                      comparison: KMetricComparison(
                        label: '+8',
                        description: 'Vorperiode',
                        sentiment: KMetricSentiment.positive,
                      ),
                      trend: KMetricTrend(values: [0, 2, 4], label: 'Verlauf'),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: KMetricCard(
                      key: ValueKey('plain-card'),
                      label: 'Kontakte',
                      value: '8',
                      description: 'Neu angelegte\nKontakte',
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: KMetricCard(
                      key: ValueKey('progress-card'),
                      label: 'Auslastung',
                      value: '25 %',
                      description: '4 h / 16 h',
                      progress: KMetricProgress(value: 25, label: 'Auslastung'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final height = tester
          .getSize(find.byKey(const ValueKey('trend-card')))
          .height;
      for (final key in ['plain-card', 'progress-card']) {
        expect(
          tester.getSize(find.byKey(ValueKey(key))).height,
          closeTo(height, 1),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.0, 1.3, 2.0, 3.0]) {
    for (final dark in [false, true]) {
      testWidgets('metric cards fit phone at $scale, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(393, 852),
                textScaler: TextScaler.linear(scale),
              ),
              child: KAdaptiveTheme(
                brightness: dark ? Brightness.dark : Brightness.light,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const KMetricCard(
                            label: 'Umsatz',
                            value: '146,76 €',
                            description: 'bestätigte Termine',
                            comparison: KMetricComparison(
                              label: '+12%',
                              description: 'Vorperiode',
                              sentiment: KMetricSentiment.positive,
                            ),
                            trend: KMetricTrend(
                              values: [0, 4, null, 6, 9],
                              label: 'Umsatzverlauf',
                            ),
                          ),
                          const KMetricCard(
                            label: 'Auslastung',
                            value: '25 %',
                            description: '4 von 16 h diese Woche',
                            progress: KMetricProgress(
                              value: 25,
                              label: 'Auslastung',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('146,76 €'), findsOneWidget);
        expect(find.text('25 %'), findsOneWidget);
      });
    }
  }
}
