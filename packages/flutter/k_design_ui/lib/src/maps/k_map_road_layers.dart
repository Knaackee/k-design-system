import 'k_map_expressions.dart';
import 'k_map_settings.dart';
import 'k_map_tokens.dart';

const _roads = [
  (
    id: 'service',
    classes: ['service', 'track'],
    minzoom: 15.0,
    width: [(15, 0.8), (16, 2.0), (18, 7.0), (20, 16.0)],
    fill: 'roadMinor',
    casing: 'roadMinorCasing',
  ),
  (
    id: 'minor',
    classes: ['minor'],
    minzoom: 13.0,
    width: [(13, 0.6), (14, 2.2), (16, 6.0), (18, 13.0), (20, 30.0)],
    fill: 'roadMinor',
    casing: 'roadMinorCasing',
  ),
  (
    id: 'secondary',
    classes: ['secondary', 'tertiary'],
    minzoom: 10.0,
    width: [(10, 0.4), (12, 1.3), (14, 4.0), (16, 9.0), (18, 18.0), (20, 40.0)],
    fill: 'road',
    casing: 'roadCasing',
  ),
  (
    id: 'primary',
    classes: ['primary'],
    minzoom: 8.0,
    width: [(8, 0.4), (11, 1.2), (14, 5.0), (16, 11.0), (18, 22.0), (20, 46.0)],
    fill: 'road',
    casing: 'roadCasing',
  ),
  (
    id: 'trunk',
    classes: ['trunk'],
    minzoom: 6.0,
    width: [(6, 0.5), (10, 1.6), (14, 5.5), (16, 12.0), (18, 24.0), (20, 50.0)],
    fill: 'trunk',
    casing: 'trunkCasing',
  ),
  (
    id: 'motorway',
    classes: ['motorway'],
    minzoom: 5.0,
    width: [(5, 0.6), (10, 2.0), (14, 6.0), (16, 13.0), (18, 26.0), (20, 54.0)],
    fill: 'motorway',
    casing: 'motorwayCasing',
  ),
];

double _casingExtra(num zoom) => zoom < 11
    ? 0.8
    : zoom < 14
    ? 1.6
    : 2.4;

Stops _withCasing(Stops stops, double scale) => [
  for (final (zoom, width) in stops)
    (zoom, rounded((width as num) + _casingExtra(zoom) * scale, 3)),
];

List<Object> _roadFilter(List<String> classes, String brunnel) {
  final Object brunnelFilter = brunnel == 'normal'
      ? [
          '!',
          [
            'match',
            ['get', 'brunnel'],
            ['bridge', 'tunnel'],
            true,
            false,
          ],
        ]
      : [
          '==',
          ['get', 'brunnel'],
          brunnel,
        ];
  return [
    'all',
    isLine,
    [
      'match',
      ['get', 'class'],
      classes,
      true,
      false,
    ],
    brunnelFilter,
  ];
}

List<Map<String, Object>> roadLayers(
  KMapTokens tokens,
  String brunnel,
  KMapSettings settings,
) {
  final casings = <Map<String, Object>>[];
  final fills = <Map<String, Object>>[];
  final tunnel = brunnel == 'tunnel';

  for (final road in _roads) {
    final width = scaleStops(road.width, settings.roadWidthScale);
    final filter = _roadFilter(road.classes, brunnel);
    final casingFade = road.id == 'motorway' || road.id == 'trunk'
        ? 1
        : zlin([
            (road.minzoom > 11 ? road.minzoom : 11, 0),
            ((road.minzoom > 11 ? road.minzoom : 11) + 1.5, 1),
          ]);
    casings.add({
      'id': 'road-$brunnel-${road.id}-casing',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'transportation',
      'minzoom': road.minzoom,
      'filter': filter,
      'layout': {
        'line-cap': tunnel ? 'butt' : 'round',
        'line-join': 'round',
        ...visibility(settings.casingScale > 0),
      },
      'paint': {
        'line-color': tokens[road.casing],
        'line-width': zexp(_withCasing(width, settings.casingScale)),
        'line-opacity': tunnel ? tokens.tunnelOpacity : casingFade,
        if (tunnel) 'line-dasharray': [1.5, 1],
      },
    });
    fills.add({
      'id': 'road-$brunnel-${road.id}',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'transportation',
      'minzoom': road.minzoom,
      'filter': filter,
      'layout': {'line-cap': 'round', 'line-join': 'round'},
      'paint': {
        'line-color': tokens[road.fill],
        'line-width': zexp(width),
        if (tunnel) 'line-opacity': tokens.tunnelOpacity,
      },
    });
  }
  return [...casings, ...fills];
}
