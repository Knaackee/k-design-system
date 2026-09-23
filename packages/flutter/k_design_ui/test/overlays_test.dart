import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final sheet in [false, true]) {
    testWidgets('${sheet ? 'sheet' : 'dialog'} opens and closes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  if (sheet) {
                    KBottomSheet.show<void>(
                      context: context,
                      title: const Text('Title'),
                      child: const Text('Content'),
                    );
                  } else {
                    KDialog.show<void>(
                      context: context,
                      title: const Text('Title'),
                      child: const Text('Content'),
                    );
                  }
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsOneWidget);
      if (sheet) {
        await tester.tapAt(const Offset(10, 10));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsNothing);
    });
  }
}
