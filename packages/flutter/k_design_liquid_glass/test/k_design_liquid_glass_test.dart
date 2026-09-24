import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_liquid_glass/k_design_liquid_glass.dart';

void main() {
  testWidgets('liquid-glass adapter builds a supplied child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => kLiquidGlassSurfaceBuilder(
            context,
            const SizedBox(key: Key('content'), width: 120, height: 48),
            BorderRadius.circular(24),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('content')), findsOneWidget);
  });
}
