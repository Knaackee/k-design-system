import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

Widget buildMapOverlaysPins(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.pins);
Widget buildMapOverlaysCustomPins(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.customPins);
Widget buildMapOverlaysLogoPins(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.logoPins);
Widget buildMapOverlaysRoutes(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.routes);
Widget buildMapOverlaysPinsAndRoute(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.pinsAndRoute);
Widget buildMapOverlaysTrafficSegments(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.traffic);
Widget buildMapOverlaysDraggablePins(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.draggable);
Widget buildMapOverlaysLongPressPins(BuildContext context) =>
    const _MapOverlaysFixture(kind: _MapOverlayKind.longPress);

enum _MapOverlayKind {
  pins,
  customPins,
  logoPins,
  routes,
  pinsAndRoute,
  traffic,
  draggable,
  longPress,
}

const _center = KMapCenter(longitude: 13.391, latitude: 52.525);
const _basePins = [
  KMapPin(
    id: 'start',
    label: 'Start · Invalidenstraße',
    position: KMapCenter(longitude: 13.387, latitude: 52.53),
    icon: KIconName.house,
  ),
  KMapPin(
    id: 'customer',
    label: 'Kundentermin · Mitte',
    position: KMapCenter(longitude: 13.394, latitude: 52.525),
    icon: KIconName.user,
  ),
  KMapPin(
    id: 'end',
    label: 'Ziel · Friedrichstraße',
    position: KMapCenter(longitude: 13.388, latitude: 52.52),
    icon: KIconName.flag,
  ),
];
const _routes = [
  KMapRoute(
    id: 'drive',
    coordinates: [
      KMapCenter(longitude: 13.387, latitude: 52.53),
      KMapCenter(longitude: 13.391, latitude: 52.531),
      KMapCenter(longitude: 13.395, latitude: 52.527),
      KMapCenter(longitude: 13.394, latitude: 52.525),
    ],
  ),
  KMapRoute(
    id: 'walk',
    dashed: true,
    coordinates: [
      KMapCenter(longitude: 13.394, latitude: 52.525),
      KMapCenter(longitude: 13.39, latitude: 52.523),
      KMapCenter(longitude: 13.388, latitude: 52.52),
    ],
  ),
];

class _MapOverlaysFixture extends StatefulWidget {
  const _MapOverlaysFixture({required this.kind});

  final _MapOverlayKind kind;

  @override
  State<_MapOverlaysFixture> createState() => _MapOverlaysFixtureState();
}

class _MapOverlaysFixtureState extends State<_MapOverlaysFixture> {
  late List<KMapPin> _pins;
  String? _selectedPin = 'customer';
  String? _selectedRoute;
  bool _acceptMove = true;

  @override
  void initState() {
    super.initState();
    _pins = _pinsFor(widget.kind);
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final routes = _routesFor(widget.kind);
    final style = jsonEncode(createKMapStyle(tokens: tokens));
    return ColoredBox(
      color: tokens.colorSurfaceCanvas,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLayoutGutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: tokens.spaceControlGap,
              runSpacing: tokens.spaceControlGap,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(_title(widget.kind), variant: KTextVariant.label),
                    KText(
                      _description(widget.kind),
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: tokens.colorTextMuted),
                    ),
                  ],
                ),
                if (widget.kind == _MapOverlayKind.draggable ||
                    widget.kind == _MapOverlayKind.longPress)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const KText('Verschieben akzeptieren'),
                      Switch(
                        value: _acceptMove,
                        onChanged: (value) =>
                            setState(() => _acceptMove = value),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceLayoutGutter),
            Expanded(
              child: KMap(
                mapStyle: style,
                center: _center,
                zoom: 14,
                pins: widget.kind == _MapOverlayKind.routes ? const [] : _pins,
                routes: routes,
                selectedPinId: _selectedPin,
                selectionControlled: true,
                selectedRouteId: _selectedRoute,
                fitContent: true,
                fitPadding: 80,
                label: _title(widget.kind),
                pinDrag: KMapPinDragOptions(
                  activation: widget.kind == _MapOverlayKind.longPress
                      ? KMapPinDragActivation.longPress
                      : KMapPinDragActivation.drag,
                ),
                pinBuilder: widget.kind == _MapOverlayKind.customPins
                    ? _buildInitialPin
                    : widget.kind == _MapOverlayKind.logoPins
                    ? _buildLogoPin
                    : null,
                onPinTap: (id) => setState(() => _selectedPin = id),
                onSelectionChanged: (id) => setState(() => _selectedPin = id),
                onPinMove: _movePin,
                onPinDragStart: (_) {},
                onPinDrag: (_) {},
                onPinDragEnd: (_) {},
                overlayBuilder: routes.isEmpty
                    ? null
                    : (context, controller) => Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Padding(
                          padding: EdgeInsets.all(tokens.spaceCardPadding),
                          child: KButton(
                            label: _selectedRoute == null
                                ? 'Route hervorheben'
                                : 'Auswahl löschen',
                            variant: KButtonVariant.secondary,
                            onPressed: () => setState(
                              () => _selectedRoute = _selectedRoute == null
                                  ? 'drive'
                                  : null,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _movePin(KMapPinMove event) async {
    if (!_acceptMove) return false;
    setState(() {
      _pins = [
        for (final pin in _pins)
          if (pin.id == event.id)
            _copyPin(pin, position: event.position)
          else
            pin,
      ];
    });
    return true;
  }
}

List<KMapPin> _pinsFor(_MapOverlayKind kind) => [
  for (var index = 0; index < _basePins.length; index++)
    _copyPin(
      _basePins[index],
      size: kind == _MapOverlayKind.customPins
          ? 56
          : kind == _MapOverlayKind.logoPins
          ? 48
          : null,
      shape: kind == _MapOverlayKind.logoPins
          ? KMapPinShape.values[index]
          : null,
      draggable:
          kind == _MapOverlayKind.draggable ||
          kind == _MapOverlayKind.longPress,
    ),
];

List<KMapRoute> _routesFor(_MapOverlayKind kind) {
  if (kind == _MapOverlayKind.routes || kind == _MapOverlayKind.pinsAndRoute) {
    return _routes;
  }
  if (kind != _MapOverlayKind.traffic) return const [];
  return [
    KMapRoute(
      id: 'drive',
      width: 7,
      coordinates: _routes.first.coordinates,
      segments: const [
        KMapRouteSegment(
          id: 'clear',
          startIndex: 0,
          endIndex: 1,
          traffic: KMapTraffic.free,
        ),
        KMapRouteSegment(
          id: 'slow',
          startIndex: 1,
          endIndex: 2,
          traffic: KMapTraffic.slow,
        ),
        KMapRouteSegment(
          id: 'jam',
          startIndex: 2,
          endIndex: 3,
          traffic: KMapTraffic.congested,
        ),
      ],
    ),
    _routes.last,
  ];
}

KMapPin _copyPin(
  KMapPin pin, {
  KMapCenter? position,
  double? size,
  KMapPinShape? shape,
  bool? draggable,
}) => KMapPin(
  id: pin.id,
  position: position ?? pin.position,
  label: pin.label,
  icon: pin.icon,
  image: pin.image,
  child: pin.child,
  color: pin.color,
  size: size ?? pin.size,
  shape: shape ?? pin.shape,
  draggable: draggable ?? pin.draggable,
  drag: pin.drag,
);

Widget _buildInitialPin(BuildContext context, KMapPin pin, KMapPinState state) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  final initials = switch (pin.id) {
    'start' => 'AB',
    'customer' => 'CD',
    _ => 'EF',
  };
  return DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: tokens.colorSurfaceRaised,
      border: Border.all(
        color: tokens.colorBrandPrimaryAccent,
        width: state.selected ? 5 : 2,
      ),
    ),
    child: SizedBox.square(
      dimension: pin.size,
      child: Center(child: KText(initials, variant: KTextVariant.label)),
    ),
  );
}

Widget _buildLogoPin(BuildContext context, KMapPin pin, KMapPinState state) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: tokens.colorSurfaceRaised,
      shape: pin.shape == KMapPinShape.circle
          ? BoxShape.circle
          : BoxShape.rectangle,
      borderRadius: pin.shape == KMapPinShape.circle
          ? null
          : BorderRadius.circular(tokens.radiusControl),
      border: Border.all(
        color: tokens.colorBrandPrimaryAccent,
        width: state.selected ? 4 : 2,
      ),
    ),
    child: SizedBox.square(
      dimension: pin.size,
      child: Center(
        child: KText(
          'K',
          variant: KTextVariant.heading3,
          style: TextStyle(color: tokens.colorBrandPrimaryAccent),
        ),
      ),
    ),
  );
}

String _title(_MapOverlayKind kind) => switch (kind) {
  _MapOverlayKind.pins => 'Pins',
  _MapOverlayKind.customPins => 'Consumer-Inhalte',
  _MapOverlayKind.logoPins => 'Logo-Pins',
  _MapOverlayKind.routes => 'Routen',
  _MapOverlayKind.pinsAndRoute => 'Pins mit Route',
  _MapOverlayKind.traffic => 'Verkehr · Routensegmente',
  _MapOverlayKind.draggable => 'Pins verschieben',
  _MapOverlayKind.longPress => 'Pins · Long Press',
};

String _description(_MapOverlayKind kind) => switch (kind) {
  _MapOverlayKind.customPins => 'Freie Consumer-Widgets mit Auswahlzustand.',
  _MapOverlayKind.logoPins => 'Kreis, Quadrat und Pin mit Markeninhalt.',
  _MapOverlayKind.routes => 'Vom Host gelieferte Routengeometrie.',
  _MapOverlayKind.pinsAndRoute => 'Pins und Routen gemeinsam kontrolliert.',
  _MapOverlayKind.traffic => 'Freier, langsamer und gestauter Abschnitt.',
  _MapOverlayKind.draggable => 'Direkt ziehen oder mit Pfeiltasten bewegen.',
  _MapOverlayKind.longPress => 'Gedrückt halten, dann den Pin bewegen.',
  _ => 'Auswählbare, zugänglich beschriftete Karten-Pins.',
};
