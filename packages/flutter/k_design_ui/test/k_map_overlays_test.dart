import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/src/maps/k_map_pin.dart';

void main() {
  const points = [
    KMapCenter(longitude: 13.38, latitude: 52.52),
    KMapCenter(longitude: 13.39, latitude: 52.53),
    KMapCenter(longitude: 13.40, latitude: 52.54),
    KMapCenter(longitude: 13.41, latitude: 52.55),
  ];

  test('web pin projection stays local when the map container is offset', () {
    const localPoint = Offset(320, 240);
    const firstOrigin = Offset(0, 0);
    const nestedOrigin = Offset(258, 64);

    Offset localProjection(Offset origin) =>
        origin +
        localPoint +
        kMapPinLayerTranslation(pageOrigin: origin, isWeb: true);

    expect(localProjection(firstOrigin), localPoint);
    expect(localProjection(nestedOrigin), localPoint);
    expect(
      kMapPinLayerTranslation(pageOrigin: nestedOrigin, isWeb: false),
      Offset.zero,
    );
  });

  test('route parts preserve base geometry and traffic segments', () {
    final parts = kMapRouteParts(
      const KMapRoute(
        id: 'route',
        coordinates: points,
        color: Colors.blue,
        width: 7,
        segments: [
          KMapRouteSegment(
            id: 'free',
            startIndex: 0,
            endIndex: 1,
            traffic: KMapTraffic.free,
          ),
          KMapRouteSegment(
            id: 'slow',
            startIndex: 1,
            endIndex: 3,
            traffic: KMapTraffic.slow,
          ),
        ],
      ),
    );

    expect(parts, hasLength(3));
    expect(parts.first.coordinates, points);
    expect(parts[1].coordinates, points.sublist(0, 2));
    expect(parts[1].traffic, KMapTraffic.free);
    expect(parts[1].color, isNull);
    expect(parts[2].coordinates, points.sublist(1, 4));
  });

  test('route segments reject duplicate IDs, overlap, and invalid widths', () {
    expect(
      () => kMapRouteParts(
        const KMapRoute(
          id: 'route',
          coordinates: points,
          segments: [
            KMapRouteSegment(id: 'same', startIndex: 0, endIndex: 2),
            KMapRouteSegment(id: 'same', startIndex: 2, endIndex: 3),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => kMapRouteParts(
        const KMapRoute(
          id: 'route',
          coordinates: points,
          segments: [
            KMapRouteSegment(id: 'one', startIndex: 0, endIndex: 2),
            KMapRouteSegment(id: 'two', startIndex: 1, endIndex: 3),
          ],
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => kMapRouteParts(
        const KMapRoute(id: 'route', coordinates: points, width: double.nan),
      ),
      throwsArgumentError,
    );
  });

  test('coordinate model rejects non-finite WGS84 values', () {
    expect(
      () => KMapCenter(longitude: double.nan, latitude: 52),
      throwsAssertionError,
    );
    expect(
      () => KMapCenter(longitude: 13, latitude: double.infinity),
      throwsAssertionError,
    );
  });

  testWidgets('controlled selection can be cleared by the host', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
        home: KMapOverlays(
          controller: KMapController(),
          selectionControlled: true,
          selectedPinId: null,
          pins: const [
            KMapPin(
              id: 'pin',
              label: 'Pin',
              position: KMapCenter(longitude: 13, latitude: 52),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('rejected and failed pin moves roll back', () async {
    final coordinator = KMapPinMoveCoordinator();
    var rollbacks = 0;
    const event = KMapPinMove(
      id: 'pin',
      position: KMapCenter(longitude: 13, latitude: 52),
      source: KMapPinMoveSource.drag,
    );

    await coordinator.commit(
      callback: (_) => false,
      event: event,
      rollback: () => rollbacks += 1,
    );
    await coordinator.commit(
      callback: (_) => throw StateError('host failed'),
      event: event,
      rollback: () => rollbacks += 1,
    );

    expect(rollbacks, 2);
  });

  test('stale rejected pin move cannot roll back a newer result', () async {
    final coordinator = KMapPinMoveCoordinator();
    final first = Completer<bool?>();
    var rollbacks = 0;
    const event = KMapPinMove(
      id: 'pin',
      position: KMapCenter(longitude: 13, latitude: 52),
      source: KMapPinMoveSource.drag,
    );

    final stale = coordinator.commit(
      callback: (_) => first.future,
      event: event,
      rollback: () => rollbacks += 1,
    );
    await coordinator.commit(
      callback: (_) => true,
      event: event,
      rollback: () => rollbacks += 1,
    );
    first.complete(false);
    await stale;

    expect(rollbacks, 0);
  });
}
