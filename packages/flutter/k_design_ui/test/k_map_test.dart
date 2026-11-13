import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final embedded in [false, true]) {
    testWidgets(
      'map embedded=$embedded leaves only the outer radius to its parent',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
            home: SizedBox(
              width: 400,
              height: 200,
              child: KMap(
                mapStyle: 'not-json',
                center: const KMapCenter(longitude: 13.388, latitude: 52.517),
                embedded: embedded,
              ),
            ),
          ),
        );
        final viewport = find.byKey(const ValueKey('k-map-pointer-signals'));
        final clip = tester.widget<ClipRRect>(
          find.descendant(of: viewport, matching: find.byType(ClipRRect)).first,
        );
        expect(
          clip.borderRadius,
          embedded
              ? BorderRadius.zero
              : BorderRadius.circular(KDesignTokens.orbitLight.radiusCard),
        );
        expect(find.text('Erneut versuchen'), findsOneWidget);
      },
    );
  }
  testWidgets('shows a retryable error for invalid style JSON', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
        home: const SizedBox(
          width: 640,
          height: 480,
          child: KMap(
            mapStyle: 'not-json',
            center: KMapCenter(longitude: 9.9937, latitude: 53.5511),
          ),
        ),
      ),
    );

    expect(find.text('Karte konnte nicht geladen werden.'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);

    final zoomIn = find.byType(KIconButton).first;
    final zoomButton = tester.widget<FilledButton>(
      find.descendant(of: zoomIn, matching: find.byType(FilledButton)),
    );
    expect(
      zoomButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      KDesignTokens.orbitLight.colorActionSecondaryBackground,
    );
    expect(
      zoomButton.style?.side?.resolve(<WidgetState>{})?.color,
      KDesignTokens.orbitLight.colorActionSecondaryBorder,
    );
    expect(
      tester
          .widget<Listener>(find.byKey(const ValueKey('k-map-pointer-signals')))
          .onPointerSignal,
      isNotNull,
    );

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();

    expect(find.text('Karte konnte nicht geladen werden.'), findsOneWidget);
  });

  testWidgets('does not claim pointer signals when interaction is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
        home: const SizedBox(
          width: 640,
          height: 480,
          child: KMap(
            mapStyle: 'not-json',
            center: KMapCenter(longitude: 9.9937, latitude: 53.5511),
            interactive: false,
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<Listener>(find.byKey(const ValueKey('k-map-pointer-signals')))
          .onPointerSignal,
      isNull,
    );
  });
}
