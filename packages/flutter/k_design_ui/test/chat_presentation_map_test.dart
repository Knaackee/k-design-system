import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  testWidgets(
    'invalid coordinates do not activate a map or outbound navigation',
    (tester) async {
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
          home: Scaffold(
            body: KPresentationMap(
              title: 'Unknown',
              latitude: 91,
              longitude: 0,
              onOpen: () {},
              mapBuilder: (_, url) {
                loads++;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Karte nicht verfügbar'));
      await tester.pump();
      expect(loads, 0);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    },
  );
  test('bbox remains bounded at pole and dateline', () {
    expect(
      KPresentationMap.embed(90, 180).queryParameters['bbox'],
      '179.98,89.99,180,90',
    );
  });
}
