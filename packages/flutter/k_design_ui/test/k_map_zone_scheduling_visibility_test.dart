import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';
import 'k_map_zone_editor_test.dart' as fixture;

void main() {
  testWidgets(
    'areas-only properties hide scheduling but retain other controls',
    (tester) async {
      final request = ValueNotifier<({String zoneId, int requestId})?>(null);
      addTearDown(request.dispose);
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: request,
              builder: (context, value, child) => KMapZoneEditor(
                mapStyle: 'invalid',
                center: const KMapCenter(longitude: 13.397, latitude: 52.52),
                zones: const [fixture.zone],
                editRequest: value,
                propertyOptions: KMapZonePropertyOptions(
                  weekdayOptions: fixture.options.weekdayOptions,
                  currency: 'EUR',
                  timeZone: 'Europe/Berlin',
                  showScheduling: false,
                ),
                onChange: (_) {},
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      request.value = (zoneId: fixture.zone.id, requestId: 1);
      await tester.pumpAndSettle();
      expect(find.text('Einsatzzeiten'), findsNothing);
      expect(find.byType(KInput), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
