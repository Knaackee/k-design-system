import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'consumer owns actions and disabled/loading actions cannot fire',
    (tester) async {
      var primary = 0;
      var secondary = 0;
      Widget setup({bool disabled = false, bool loading = false}) =>
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: KPaymentSetup(
                  state: KPaymentSetupState.ready,
                  providerName: 'Provider',
                  connectionLabel: 'Connected',
                  statusLabel: 'Ready',
                  title: 'Account ready',
                  description: 'Consumer-provided description',
                  primaryAction: KPaymentSetupAction(
                    label: 'Open payments',
                    onAction: () => primary++,
                    disabled: disabled,
                    loading: loading,
                  ),
                  secondaryAction: KPaymentSetupAction(
                    label: 'Refresh',
                    onAction: () => secondary++,
                    disabled: disabled,
                  ),
                ),
              ),
            ),
          );
      await tester.pumpWidget(setup());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open payments'));
      await tester.tap(find.text('Refresh'));
      expect(primary, 1);
      expect(secondary, 1);
      await tester.pumpWidget(setup(disabled: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open payments'));
      await tester.tap(find.text('Refresh'));
      expect(primary, 1);
      expect(secondary, 1);
      await tester.pumpWidget(setup(loading: true));
      await tester.pump();
      await tester.tap(find.text('Open payments'));
      expect(primary, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
