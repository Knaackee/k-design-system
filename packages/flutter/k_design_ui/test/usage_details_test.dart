import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('renders usage windows, reset badge and expiry details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(
          body: SizedBox(
            width: 294,
            child: KUsageDetails(
              title: 'Account-Kontingent',
              statusLabel: 'Aktuell gemeldet',
              windows: [
                KUsageWindow(
                  id: 'five-hour',
                  label: 'Verfügbares Kontingent · 7 Tage',
                  valueLabel: '41 % frei',
                  progress: 41,
                  extraResetCount: 2,
                  renewalLabel: 'Nächste Aufladung in 1 Std.',
                  renewalExact: 'Nächster Reset laut Anbieter: 07.10.26, 15:20',
                ),
              ],
              extraResetsLabel: 'Zusatz-Resets',
              extraResets: [
                KUsageValue(
                  id: 'expiry',
                  label: 'Ablaufdatum: 22.10.26, 22:51',
                  valueLabel: '2 Resets',
                  detail: 'Läuft in 15 Tagen ab',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('41 % frei'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Ablaufdatum: 22.10.26, 22:51'), findsOneWidget);
    expect(find.byType(KProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
