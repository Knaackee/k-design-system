import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('call bar fits a narrow view and forwards a real mute change', (
    tester,
  ) async {
    bool? requested;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: KCallBar(
                name: 'A long agent name',
                status: 'Hört zu',
                duration: '02:14',
                muted: false,
                microphoneLevel: .8,
                onMutedChanged: (value) => requested = value,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(KIconButton));
    expect(requested, isTrue);
    expect(find.text('02:14'), findsOneWidget);
  });
}
