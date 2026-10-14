import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'reduced motion keeps the activity label readable and stops frames',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(
            body: KTextShimmer(
              text: 'Agenten',
              active: true,
              label: 'Agenten: Wartet auf dich',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agenten'), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
  testWidgets('inactive shimmer schedules no animation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: KTextShimmer(text: 'Agenten')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
