import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('shows a clickable visible label by default', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => KSwitch(
              label: 'Share across devices',
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Share across devices'), findsOneWidget);
    final semantics = tester
        .getSemantics(find.byType(KSwitch))
        .getSemanticsData();
    expect(semantics.label, 'Share across devices');
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(find.text('Share across devices'));
    await tester.pump();
    expect(value, isTrue);
    semanticsHandle.dispose();
  });

  testWidgets('can hide duplicate copy while retaining its semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Material(
          child: KSwitch(
            label: 'Product updates',
            showLabel: false,
            value: true,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.text('Product updates'), findsNothing);
    expect(find.bySemanticsLabel('Product updates'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('wraps a long visible label inside a bounded mobile row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              child: KSwitch(
                label: 'Share assistant updates across all mobile devices',
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(KSwitch)).width, lessThanOrEqualTo(180));
    expect(tester.takeException(), isNull);
  });
}
