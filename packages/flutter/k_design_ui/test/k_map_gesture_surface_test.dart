import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/src/maps/k_map_gesture_surface.dart';
import 'package:k_design_ui/src/maps/k_map_pin.dart';

void main() {
  for (final handle in ['vertex', 'midpoint', 'center']) {
    for (final active in [false, true]) {
      testWidgets(
        '$handle + map pinches after ${active ? 'active' : 'pending'} drag',
        (tester) async {
          final fixture = _Fixture();
          await fixture.mount(tester);
          final first = await tester.startGesture(
            fixture.point(handle),
            pointer: 1,
          );
          if (active) {
            await first.moveBy(const Offset(25, 0));
            await tester.pump();
          }
          final second = await tester.startGesture(
            const Offset(650, 300),
            pointer: 2,
          );
          await first.moveBy(const Offset(-40, 0));
          await second.moveBy(const Offset(40, 0));
          await tester.pump();
          expect(fixture.controller.view.zoom, greaterThan(4));
          expect(fixture.cancels, active ? 1 : 0);
          final editsAtPinch = fixture.previews;
          await second.up();
          await first.moveBy(const Offset(30, 0));
          await first.up();
          await tester.pumpAndSettle();
          expect(fixture.moves, 0);
          expect(fixture.taps, 0);
          expect(fixture.ends, 0);
          expect(fixture.previews, editsAtPinch);
          expect(fixture.nativeAccepted, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'two different handles cancel both taps and zoom around focal point',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      final first = await tester.startGesture(
        fixture.point('vertex'),
        pointer: 1,
      );
      final second = await tester.startGesture(
        fixture.point('midpoint'),
        pointer: 2,
      );
      final anchor = fixture.controller.toMapCenter(const Offset(250, 300));
      await first.moveBy(const Offset(-50, 0));
      await second.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(fixture.controller.view.zoom, closeTo(5, .0001));
      expect(fixture.controller.toScreenOffset(anchor).dx, closeTo(250, .0001));
      expect(fixture.controller.toScreenOffset(anchor).dy, closeTo(300, .0001));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(fixture.moves, 0);
      expect(fixture.taps, 0);
      expect(fixture.nativeAccepted, 0);
    },
  );
  testWidgets('map pan then second finger on a handle becomes pinch', (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    final first = await tester.startGesture(const Offset(650, 300), pointer: 1);
    await first.moveBy(const Offset(-30, 0));
    await tester.pump();
    final second = await tester.startGesture(
      fixture.point('center'),
      pointer: 2,
    );
    await first.moveBy(const Offset(40, 0));
    await second.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(fixture.controller.view.zoom, greaterThan(4));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(fixture.moves, 0);
    expect(fixture.taps, 0);
    expect(fixture.nativeAccepted, 0);
  });
  testWidgets('one finger still directly drags and commits a handle', (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    final first = await tester.startGesture(fixture.point('vertex'));
    await first.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(fixture.starts, 1);
    expect(fixture.previews, 1);
    expect(fixture.controller.cameraMoves, 0);
    await first.up();
    await tester.pumpAndSettle();
    expect(fixture.moves, 1);
    expect(fixture.ends, 1);
  });
  testWidgets(
    'pending pinch releases suppress insertion taps; next independent tap works',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      final first = await tester.startGesture(
        fixture.point('midpoint'),
        pointer: 1,
      );
      final second = await tester.startGesture(
        const Offset(650, 300),
        pointer: 2,
      );
      await second.up();
      await first.up();
      await tester.pumpAndSettle();
      expect(fixture.taps, 0);
      await tester.tapAt(fixture.point('midpoint'));
      await tester.pumpAndSettle();
      expect(fixture.taps, 1);
    },
  );
  testWidgets(
    'queued fast pan retains entire grab anchor and ignores subslop movement',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      fixture.controller.delay = Completer<void>();
      final first = await tester.startGesture(const Offset(650, 300));
      final anchor = fixture.controller.toMapCenter(const Offset(650, 300));
      await first.moveBy(const Offset(2, 0));
      expect(fixture.controller.cameraMoves, 0);
      await first.moveBy(const Offset(-30, 0));
      await first.moveBy(const Offset(-30, 0));
      await first.moveBy(const Offset(-30, 0));
      fixture.controller.delay!.complete();
      await tester.pump();
      await tester.pump();
      expect(fixture.controller.toScreenOffset(anchor).dx, closeTo(562, .0001));
      expect(fixture.nativeAccepted, 0);
      await first.up();
    },
  );
  testWidgets('pointer cancellation clears scope for a following drag', (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    final first = await tester.startGesture(
      fixture.point('center'),
      pointer: 1,
    );
    final second = await tester.startGesture(
      const Offset(650, 300),
      pointer: 2,
    );
    await first.cancel();
    await second.cancel();
    await tester.pumpAndSettle();
    final next = await tester.startGesture(fixture.point('vertex'), pointer: 3);
    await next.moveBy(const Offset(30, 0));
    await next.up();
    await tester.pumpAndSettle();
    expect(fixture.moves, 1);
    expect(fixture.taps, 0);
  });
}

class _Fixture {
  final controller = _Controller()
    ..viewport = const Rect.fromLTWH(0, 0, 800, 600);
  var starts = 0,
      previews = 0,
      ends = 0,
      cancels = 0,
      moves = 0,
      taps = 0,
      nativeAccepted = 0;
  Offset point(String id) => Offset(switch (id) {
    'vertex' => 200,
    'midpoint' => 300,
    _ => 400,
  }, 300);
  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: KMapGestureSurface(
          controller: controller,
          child: Stack(
            children: [
              Positioned.fill(
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _NativeMapRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _NativeMapRecognizer
                        >(
                          () => _NativeMapRecognizer(() => nativeAccepted++),
                          (_) {},
                        ),
                  },
                  child: const ColoredBox(color: Colors.grey),
                ),
              ),
              for (final id in ['vertex', 'midpoint', 'center'])
                Positioned(
                  left: point(id).dx - 22,
                  top: 278,
                  width: 44,
                  height: 44,
                  child: KMapInteractivePin(
                    controller: controller,
                    pin: KMapPin(
                      id: id,
                      position: controller.toMapCenter(point(id)),
                      label: id,
                      anchor: KMapPinAnchor.center,
                      draggable: true,
                      size: 44,
                    ),
                    selected: true,
                    options: const KMapPinDragOptions(
                      animationDuration: Duration.zero,
                    ),
                    onTap: () => taps++,
                    onDragStart: (_) => starts++,
                    onDrag: (_) => previews++,
                    onDragEnd: (_) => ends++,
                    onDragCancel: (_) => cancels++,
                    onMove: (_) {
                      moves++;
                      return true;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Like the native platform view with its default empty gesture recognizer set:
// it wins only when no Flutter recognizer claims the pointer's gesture arena.
class _NativeMapRecognizer extends OneSequenceGestureRecognizer {
  _NativeMapRecognizer(this.onAccept);
  final VoidCallback onAccept;
  @override
  void addAllowedPointer(PointerDownEvent event) =>
      startTrackingPointer(event.pointer);
  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) => onAccept();
  @override
  void didStopTrackingLastPointer(int pointer) {}
  @override
  String get debugDescription => 'native test map';
}

class _Controller extends KMapController {
  KMapCenter center = const KMapCenter(longitude: 0, latitude: 0);
  double zoom = 4;
  int cameraMoves = 0;
  Completer<void>? delay;
  double get scale => math.pow(2, zoom).toDouble();
  @override
  KMapView get view => KMapView(center: center, zoom: zoom);
  @override
  Offset toScreenOffset(KMapCenter position) => Offset(
    400 + (position.longitude - center.longitude) * scale,
    300 + (position.latitude - center.latitude) * scale,
  );
  @override
  KMapCenter toMapCenter(Offset offset) => KMapCenter(
    longitude: center.longitude + (offset.dx - 400) / scale,
    latitude: center.latitude + (offset.dy - 300) / scale,
  );
  @override
  Future<void> moveCamera({KMapCenter? center, double? zoom}) async {
    cameraMoves++;
    await delay?.future;
    this.center = center ?? this.center;
    this.zoom = zoom ?? this.zoom;
  }

  @override
  KMapView updateView() => view;
}
