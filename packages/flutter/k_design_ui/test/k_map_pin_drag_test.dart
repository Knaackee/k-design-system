import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/src/maps/k_map_pin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/src/maps/k_map_pin_drag.dart';

void main() {
  testWidgets(
    'handle wins pan arena and controlled echoes keep a stable finger anchor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _ProjectionController()
        ..viewport = const Rect.fromLTWH(179, 108, 390, 647);
      var position = const KMapCenter(longitude: 19.5, latitude: 32.35);
      var mapPans = 0, starts = 0, ends = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 179,
                  top: 108,
                  width: 390,
                  height: 647,
                  child: GestureDetector(
                    onPanUpdate: (_) => mapPans++,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 84,
                        child: StatefulBuilder(
                          builder: (context, update) => KMapInteractivePin(
                            key: const ValueKey('target'),
                            controller: controller,
                            pin: KMapPin(
                              id: 'pin',
                              position: position,
                              label: 'Handle',
                              anchor: KMapPinAnchor.center,
                              draggable: true,
                              size: 44,
                            ),
                            selected: true,
                            options: const KMapPinDragOptions(),
                            onTap: () {},
                            onDragStart: (_) => starts++,
                            onDragEnd: (_) => ends++,
                            onDrag: (event) =>
                                update(() => position = event.position),
                            onMove: (_) => true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('target'))),
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      expect(position.longitude, closeTo(22, .0001));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(position.longitude, closeTo(24, .0001));
      controller.camera = const Offset(10, 0);
      controller.notifyListeners();
      await tester.pump();
      expect(position.longitude, closeTo(25, .0001));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(mapPans, 0);
      expect(starts, 1);
      expect(ends, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test('fixed grab offset uses map-local coordinates exactly once', () {
    const viewport = Rect.fromLTWH(179, 108, 390, 647);
    final session = KMapPinDragSession(
      pointer: const Offset(350, 300),
      projected: const Offset(180, 190),
      viewport: viewport,
    );
    expect(session.localAnchor(viewport), const Offset(180, 190));
    session.pointer = const Offset(380, 320);
    expect(session.localAnchor(viewport), const Offset(210, 210));
    // Controlled geometry echoes and camera re-projection do not enter the
    // anchor calculation, so a stationary finger cannot accumulate movement.
    for (var echo = 0; echo < 4; echo++) {
      expect(session.localAnchor(viewport), const Offset(210, 210));
    }
    expect(
      session.localAnchor(viewport.shift(const Offset(10, 20))),
      const Offset(200, 190),
    );
  });
  test('edge pan matches the web ramp and clamps outside the viewport', () {
    const options = KMapPinEdgePanOptions();
    const size = Size(390, 647);
    expect(
      kMapEdgePanVelocity(const Offset(195, 320), size, options),
      Offset.zero,
    );
    expect(
      kMapEdgePanVelocity(const Offset(28, 320), size, options),
      const Offset(-90, 0),
    );
    expect(
      kMapEdgePanVelocity(const Offset(390, 647), size, options),
      const Offset(180, 180),
    );
    expect(
      kMapEdgePanVelocity(const Offset(-20, 320), size, options),
      const Offset(-180, 0),
    );
    expect(kMapEdgePanZoom(6, options, .016), 6);
    expect(kMapEdgePanZoom(8, options, .016), 8);
    expect(kMapEdgePanZoom(10, options, 1), 9.82);
  });
}

class _ProjectionController extends KMapController {
  Offset camera = Offset.zero;
  @override
  Offset toScreenOffset(KMapCenter position) =>
      Offset(position.longitude * 10, position.latitude * 10) - camera;
  @override
  KMapCenter toMapCenter(Offset offset) => KMapCenter(
    longitude: (offset.dx + camera.dx) / 10,
    latitude: (offset.dy + camera.dy) / 10,
  );
}
