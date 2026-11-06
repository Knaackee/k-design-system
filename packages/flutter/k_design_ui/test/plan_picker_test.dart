import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('interval changes while payment action remains disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var interval = 'monthly';
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: KPlanPicker(
                plans: const [
                  KPlan(
                    id: 'one',
                    name: 'Onzeit',
                    features: ['A useful feature'],
                    prices: {
                      'monthly': KPlanPrice(
                        amount: '19',
                        billingNote: 'Monthly billing',
                      ),
                      'yearly': KPlanPrice(
                        amount: '190',
                        billingNote: 'Annual billing',
                      ),
                    },
                  ),
                ],
                value: 'one',
                onValueChange: (_) {},
                intervals: const [
                  KPlanInterval(id: 'monthly', label: 'Monthly'),
                  KPlanInterval(id: 'yearly', label: 'Yearly'),
                ],
                interval: interval,
                onIntervalChange: (value) => setState(() => interval = value),
                label: 'Plan',
                intervalLabel: 'Billing',
                unavailableLabel: 'Unavailable',
                actionLabel: 'Pay',
                actionDisabled: true,
                onContinue: (_) => actions++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(interval, 'yearly');
    expect(find.text('190'), findsOneWidget);
    expect(find.text('Annual billing'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(actions, 0);
    expect(tester.takeException(), isNull);
  });
}
