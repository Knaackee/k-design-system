import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:maplibre/maplibre.dart' as maplibre;

import '../primitives/k_icon.dart';
import 'k_map_controller.dart';
import 'k_map_pin.dart';

enum KMapPinShape { pin, circle, square }

enum KMapPinAnchor { center, bottom }

enum KMapTraffic { free, slow, congested }

enum KMapPinMoveSource { drag, keyboard }

enum KMapPinDragActivation { drag, longPress }

@immutable
class KMapPinEdgePanOptions {
  const KMapPinEdgePanOptions({
    this.padding = 56,
    this.maxSpeed = 180,
    this.zoomOutPerSecond = .18,
    this.minZoom = 8,
  }) : assert(padding > 0),
       assert(maxSpeed >= 0),
       assert(zoomOutPerSecond >= 0),
       assert(minZoom >= 0 && minZoom <= 22);
  final double padding, maxSpeed, zoomOutPerSecond, minZoom;
}

@immutable
class KMapPinDragOptions {
  const KMapPinDragOptions({
    this.activation = KMapPinDragActivation.drag,
    this.longPressDuration = const Duration(milliseconds: 400),
    this.animationDuration,
    this.scale = 1.15,
    this.keyboardStep = 12,
    this.edgePan,
  }) : assert(scale > 0),
       assert(keyboardStep > 0);

  final KMapPinDragActivation activation;
  final Duration longPressDuration;

  /// Defaults to the theme's standard motion duration.
  final Duration? animationDuration;
  final double scale;
  final double keyboardStep;
  final KMapPinEdgePanOptions? edgePan;

  KMapPinDragOptions merge(KMapPinDragOptions? override) => override ?? this;
}

@immutable
class KMapPin {
  const KMapPin({
    required this.id,
    required this.position,
    required this.label,
    this.icon,
    this.image,
    this.child,
    this.color,
    this.size = 40,
    this.shape = KMapPinShape.pin,
    this.anchor = KMapPinAnchor.bottom,
    this.draggable = false,
    this.drag,
  }) : assert(id != ''),
       assert(label != ''),
       assert(size > 0);

  final String id;
  final KMapCenter position;
  final String label;
  final KIconName? icon;
  final ImageProvider<Object>? image;
  final Widget? child;
  final Color? color;
  final double size;
  final KMapPinShape shape;
  final KMapPinAnchor anchor;
  final bool draggable;
  final KMapPinDragOptions? drag;
}

@immutable
class KMapRouteSegment {
  const KMapRouteSegment({
    required this.id,
    required this.startIndex,
    required this.endIndex,
    this.color,
    this.width,
    this.dashed,
    this.traffic,
  });

  final String id;
  final int startIndex;
  final int endIndex;
  final Color? color;
  final double? width;
  final bool? dashed;
  final KMapTraffic? traffic;
}

@immutable
class KMapRoute {
  const KMapRoute({
    required this.id,
    required this.coordinates,
    this.color,
    this.width = 5,
    this.dashed = false,
    this.segments = const [],
  });

  final String id;
  final List<KMapCenter> coordinates;
  final Color? color;

  /// Logical-pixel width. The current Flutter MapLibre renderer rounds this
  /// to the nearest physical layer width because its declarative API uses int.
  final double width;
  final bool dashed;
  final List<KMapRouteSegment> segments;
}

@immutable
class KMapPinMove {
  const KMapPinMove({
    required this.id,
    required this.position,
    required this.source,
  });

  final String id;
  final KMapCenter position;
  final KMapPinMoveSource source;
}

typedef KMapPinMoveCallback = FutureOr<bool?> Function(KMapPinMove event);
typedef KMapPinCallback = void Function(String id);
typedef KMapPinDragCallback = void Function(KMapPinMove event);
typedef KMapPinBuilder =
    Widget Function(BuildContext context, KMapPin pin, KMapPinState state);

@immutable
class KMapPinState {
  const KMapPinState({
    required this.selected,
    required this.draggable,
    required this.dragging,
  });

  final bool selected;
  final bool draggable;
  final bool dragging;
}

@visibleForTesting
List<KMapRoutePart> kMapRouteParts(KMapRoute route) {
  if (route.coordinates.length < 2) {
    throw ArgumentError.value(
      route.coordinates,
      'coordinates',
      'A route needs at least two positions',
    );
  }
  if (!route.width.isFinite || route.width <= 0) {
    throw ArgumentError.value(
      route.width,
      'width',
      'Must be positive and finite',
    );
  }
  for (final position in route.coordinates) {
    _validateCoordinate(position);
  }
  final ids = <String>{};
  var previousEnd = 0;
  for (final segment in route.segments) {
    if (segment.id.isEmpty || !ids.add(segment.id)) {
      throw ArgumentError('Segment IDs must be nonempty and unique per route');
    }
    if (segment.startIndex < previousEnd ||
        segment.endIndex <= segment.startIndex ||
        segment.endIndex >= route.coordinates.length) {
      throw RangeError(
        'Segments need ordered, non-overlapping valid point indices',
      );
    }
    if (segment.width case final width? when !width.isFinite || width <= 0) {
      throw ArgumentError.value(width, 'width', 'Must be positive and finite');
    }
    previousEnd = segment.endIndex;
  }
  return [
    KMapRoutePart(
      routeId: route.id,
      coordinates: route.coordinates,
      color: route.color,
      width: route.width,
      dashed: route.dashed,
    ),
    for (final segment in route.segments)
      KMapRoutePart(
        routeId: route.id,
        coordinates: route.coordinates.sublist(
          segment.startIndex,
          segment.endIndex + 1,
        ),
        color: segment.color ?? (segment.traffic == null ? route.color : null),
        width: segment.width ?? route.width,
        dashed: segment.dashed ?? route.dashed,
        traffic: segment.traffic,
      ),
  ];
}

@immutable
class KMapRoutePart {
  const KMapRoutePart({
    required this.routeId,
    required this.coordinates,
    required this.width,
    required this.dashed,
    this.color,
    this.traffic,
  });
  final String routeId;
  final List<KMapCenter> coordinates;
  final Color? color;
  final double width;
  final bool dashed;
  final KMapTraffic? traffic;
}

class KMapOverlays extends StatefulWidget {
  const KMapOverlays({
    required this.controller,
    this.pins = const [],
    this.routes = const [],
    this.selectedPinId,
    this.selectionControlled = false,
    this.defaultSelectedPinId,
    this.selectedRouteId,
    this.onPinTap,
    this.onSelectionChanged,
    this.onPinMove,
    this.pinDrag = const KMapPinDragOptions(),
    this.onPinDragStart,
    this.onPinDrag,
    this.onPinDragEnd,
    this.onPinDragCancel,
    this.pinBuilder,
    super.key,
  });

  final KMapController controller;
  final List<KMapPin> pins;
  final List<KMapRoute> routes;
  final String? selectedPinId;
  final bool selectionControlled;
  final String? defaultSelectedPinId;
  final String? selectedRouteId;
  final KMapPinCallback? onPinTap;
  final KMapPinCallback? onSelectionChanged;
  final KMapPinMoveCallback? onPinMove;
  final KMapPinDragOptions pinDrag;
  final KMapPinDragCallback? onPinDragStart;
  final KMapPinDragCallback? onPinDrag;
  final KMapPinDragCallback? onPinDragEnd;
  final KMapPinDragCallback? onPinDragCancel;
  final KMapPinBuilder? pinBuilder;

  @override
  State<KMapOverlays> createState() => _KMapOverlaysState();
}

class _KMapOverlaysState extends State<KMapOverlays> {
  String? _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.defaultSelectedPinId;
  }

  @override
  Widget build(BuildContext context) {
    _validateOverlayIds(widget.pins, widget.routes);
    final selected = widget.selectionControlled
        ? widget.selectedPinId
        : widget.selectedPinId ?? _selection;
    if (widget.pins.isEmpty) return const SizedBox.shrink();
    return KMapPinLayer(
      controller: widget.controller,
      pins: widget.pins,
      selectedPinId: selected,
      dragOptions: widget.pinDrag,
      onPinMove: widget.onPinMove,
      onDragStart: widget.onPinDragStart,
      onDrag: widget.onPinDrag,
      onDragEnd: widget.onPinDragEnd,
      onDragCancel: widget.onPinDragCancel,
      pinBuilder: widget.pinBuilder,
      onTap: (id) {
        if (selected != id) {
          setState(() => _selection = id);
          widget.onSelectionChanged?.call(id);
        }
        widget.onPinTap?.call(id);
      },
    );
  }
}

@internal
List<maplibre.Layer> buildKMapRouteLayers(
  List<KMapRoute> routes,
  KDesignTokens tokens, {
  String? selectedRouteId,
}) => [
  for (final part in routes.expand(kMapRouteParts))
    maplibre.PolylineLayer(
      polylines: [
        maplibre.Feature(
          geometry: maplibre.LineString.from([
            for (final point in part.coordinates)
              maplibre.Geographic(lon: point.longitude, lat: point.latitude),
          ]),
        ),
      ],
      color: _routeColor(part, tokens).withValues(
        alpha: selectedRouteId != null && selectedRouteId != part.routeId
            ? .45
            : 1,
      ),
      width: (part.width + (selectedRouteId == part.routeId ? 3 : 0)).round(),
      dashArray: part.dashed ? const [1, 2] : null,
    ),
];

Color _routeColor(KMapRoutePart part, KDesignTokens tokens) =>
    part.color ??
    switch (part.traffic) {
      KMapTraffic.free => tokens.colorStatusSuccessAccent,
      KMapTraffic.slow => tokens.colorStatusWarningAccent,
      KMapTraffic.congested => tokens.colorStatusErrorAccent,
      null => tokens.colorBrandPrimaryAccent,
    };

void _validateOverlayIds(List<KMapPin> pins, List<KMapRoute> routes) {
  for (final entries in <Iterable<String>>[
    pins.map((pin) => pin.id),
    routes.map((route) => route.id),
  ]) {
    final ids = <String>{};
    for (final id in entries) {
      if (id.isEmpty || !ids.add(id)) {
        throw ArgumentError(
          'KMap overlay IDs must be nonempty and unique per type',
        );
      }
    }
  }
  for (final pin in pins) {
    if (pin.label.trim().isEmpty) {
      throw ArgumentError('KMap pins need an accessible label');
    }
    if (!pin.size.isFinite || pin.size <= 0) {
      throw ArgumentError.value(
        pin.size,
        'size',
        'Must be positive and finite',
      );
    }
    _validateCoordinate(pin.position);
  }
}

void _validateCoordinate(KMapCenter position) {
  if (!position.longitude.isFinite ||
      !position.latitude.isFinite ||
      position.longitude.abs() > 180 ||
      position.latitude.abs() > 90) {
    throw ArgumentError.value(
      position,
      'position',
      'Must be a valid WGS84 position',
    );
  }
}
