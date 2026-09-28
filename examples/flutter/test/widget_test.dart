import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'package:k_design_flutter_example/app.dart';

void main() {
  testWidgets('renders package components with consumer-owned tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const ConsumerExampleApp());

    expect(find.text('Consumer-owned configuration'), findsOneWidget);
    expect(find.text('Important updates only'), findsOneWidget);

    final context = tester.element(find.text('Save settings'));
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    expect(tokens.colorActionPrimaryBackground, const Color(0xFF6D28D9));
  });

  testWidgets('forwards consumer events and keeps state in the app', (
    tester,
  ) async {
    await tester.pumpWidget(const ConsumerExampleApp());

    await tester.enterText(find.byType(EditableText), 'Orbit');
    await tester.tap(find.text('All updates'));
    await tester.tap(find.text('Save settings'));
    await tester.pump();

    expect(find.text('Saved 1 time: Orbit'), findsOneWidget);
  });
}
