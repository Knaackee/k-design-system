import 'k_map_expressions.dart';
import 'k_map_label_layers.dart';
import 'k_map_road_layers.dart';
import 'k_map_settings.dart';
import 'k_map_tokens.dart';

List<Map<String, Object>> buildKMapLayers(
  KMapTokens tokens,
  KMapSettings settings,
) {
  Map<String, Object> fillLayer(
    String id,
    String sourceLayer,
    Object filter,
    String color, {
    bool visible = true,
    Map<String, Object> paint = const {},
    Map<String, Object> layer = const {},
  }) => {
    'id': id,
    'type': 'fill',
    'source': kMapSourceId,
    'source-layer': sourceLayer,
    'filter': ['all', isPoly, filter],
    'layout': visibility(visible),
    'paint': {'fill-color': color, 'fill-antialias': true, ...paint},
    ...layer,
  };

  final landuse = settings.showLanduse;
  return [
    {
      'id': 'background',
      'type': 'background',
      'paint': {'background-color': tokens.background},
    },
    fillLayer(
      'landuse-residential',
      'landuse',
      byClass(['residential', 'suburb', 'neighbourhood', 'quarter']),
      tokens.landuseResidential,
      visible: landuse,
    ),
    fillLayer(
      'landuse-commercial',
      'landuse',
      byClass(['commercial', 'retail']),
      tokens.landuseCommercial,
      visible: landuse,
      layer: {'minzoom': 12},
    ),
    fillLayer(
      'landuse-industrial',
      'landuse',
      byClass(['industrial', 'railway', 'garages']),
      tokens.landuseIndustrial,
      visible: landuse,
      layer: {'minzoom': 12},
    ),
    fillLayer(
      'landuse-hospital',
      'landuse',
      byClass(['hospital']),
      tokens.landuseHospital,
      visible: landuse,
      layer: {'minzoom': 12},
    ),
    fillLayer(
      'landuse-school',
      'landuse',
      byClass(['school', 'university', 'college', 'kindergarten']),
      tokens.landuseSchool,
      visible: landuse,
      layer: {'minzoom': 12},
    ),
    fillLayer(
      'landuse-cemetery',
      'landuse',
      byClass(['cemetery']),
      tokens.cemetery,
      visible: landuse,
      layer: {'minzoom': 11},
    ),
    fillLayer('landcover-sand', 'landcover', byClass(['sand']), tokens.sand),
    fillLayer(
      'landcover-grass',
      'landcover',
      byClass(['grass', 'farmland', 'wetland']),
      tokens.grass,
      paint: {
        'fill-opacity': zlin([(8, 0.4), (12, 0.9)]),
      },
    ),
    fillLayer(
      'landcover-wood',
      'landcover',
      byClass(['wood']),
      tokens.wood,
      paint: {
        'fill-opacity': zlin([(6, 0.5), (12, 1)]),
      },
    ),
    fillLayer(
      'park',
      'park',
      true,
      tokens.park,
      paint: {
        'fill-opacity': zlin([(6, 0.6), (11, 1)]),
      },
    ),
    fillLayer(
      'landuse-pitch',
      'landuse',
      byClass(['pitch', 'stadium', 'playground']),
      tokens.grass,
      layer: {'minzoom': 13},
    ),
    fillLayer(
      'aeroway-area',
      'aeroway',
      byClass(['runway', 'taxiway', 'aerodrome', 'apron']),
      tokens.aeroway,
      layer: {'minzoom': 11},
    ),
    fillLayer('water', 'water', [
      '!=',
      ['get', 'brunnel'],
      'tunnel',
    ], tokens.water),
    {
      'id': 'waterway',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'waterway',
      'filter': [
        'all',
        isLine,
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
      ],
      'layout': {'line-cap': 'round', 'line-join': 'round'},
      'paint': {
        'line-color': tokens.water,
        'line-width': zexp([
          (
            8,
            [
              'match',
              ['get', 'class'],
              ['river', 'canal'],
              0.6,
              0,
            ],
          ),
          (
            12,
            [
              'match',
              ['get', 'class'],
              ['river', 'canal'],
              1.6,
              0.4,
            ],
          ),
          (
            15,
            [
              'match',
              ['get', 'class'],
              ['river', 'canal'],
              4,
              1.4,
            ],
          ),
          (
            18,
            [
              'match',
              ['get', 'class'],
              ['river', 'canal'],
              10,
              4,
            ],
          ),
        ]),
      },
    },
    {
      'id': 'building',
      'type': 'fill',
      'source': kMapSourceId,
      'source-layer': 'building',
      'minzoom': settings.buildingMinZoom,
      'layout': visibility(settings.showBuildings),
      'paint': {
        'fill-color': tokens.building,
        'fill-outline-color': tokens.buildingOutline,
        'fill-opacity': zlin([
          (settings.buildingMinZoom, 0),
          (settings.buildingMinZoom + 1.5, 1),
        ]),
      },
    },
    {
      'id': 'aeroway-runway',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'aeroway',
      'minzoom': 11,
      'filter': [
        'all',
        isLine,
        byClass(['runway', 'taxiway']),
      ],
      'paint': {
        'line-color': tokens.aeroway,
        'line-width': zexp([(11, 2), (14, 12), (17, 40)]),
      },
    },
    ...roadLayers(tokens, 'tunnel', settings),
    {
      'id': 'road-path',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'transportation',
      'minzoom': 15,
      'filter': [
        'all',
        isLine,
        byClass(['path']),
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
      ],
      'layout': {
        'line-cap': 'round',
        'line-join': 'round',
        ...visibility(settings.showPaths),
      },
      'paint': {
        'line-color': tokens.path,
        'line-width': zexp([(15, 0.6), (18, 1.6)]),
        'line-dasharray': [2, 2],
      },
    },
    ...roadLayers(tokens, 'normal', settings),
    {
      'id': 'rail',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'transportation',
      'minzoom': 11,
      'filter': [
        'all',
        isLine,
        byClass(['rail', 'transit']),
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
        [
          '!',
          ['has', 'service'],
        ],
      ],
      'layout': visibility(settings.showRail),
      'paint': {
        'line-color': tokens.rail,
        'line-width': zexp([(11, 0.6), (15, 1.4), (18, 2.4)]),
      },
    },
    ...roadLayers(tokens, 'bridge', settings),
    {
      'id': 'boundary-state',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'boundary',
      'minzoom': 5,
      'filter': [
        'all',
        [
          '==',
          ['get', 'admin_level'],
          4,
        ],
        [
          '!=',
          ['get', 'maritime'],
          1,
        ],
      ],
      'layout': {'line-join': 'round'},
      'paint': {
        'line-color': tokens.boundary,
        'line-width': zlin([(5, 0.6), (10, 1.2)]),
        'line-dasharray': [3, 2],
      },
    },
    {
      'id': 'boundary-country',
      'type': 'line',
      'source': kMapSourceId,
      'source-layer': 'boundary',
      'filter': [
        'all',
        [
          '==',
          ['get', 'admin_level'],
          2,
        ],
        [
          '!=',
          ['get', 'maritime'],
          1,
        ],
      ],
      'layout': {'line-join': 'round'},
      'paint': {
        'line-color': tokens.boundary,
        'line-width': zlin([(3, 0.8), (10, 2)]),
      },
    },
    {
      'id': 'kds-slot-route',
      'type': 'background',
      'layout': {'visibility': 'none'},
      'paint': {'background-color': 'rgba(0,0,0,0)'},
    },
    ...buildLabelLayers(tokens, settings),
  ];
}
