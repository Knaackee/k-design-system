import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_map_layers.dart';
import 'k_map_settings.dart';
import 'k_map_tokens.dart';

final class KMapSources {
  const KMapSources({
    this.tiles = 'https://tiles.openfreemap.org/planet',
    this.glyphs = 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
    this.attribution =
        '<a href="https://openfreemap.org" target="_blank">OpenFreeMap</a> '
        '<a href="https://www.openmaptiles.org/" target="_blank">&copy; OpenMapTiles</a> '
        'Data from <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>',
  });

  final String tiles;
  final String glyphs;
  final String attribution;

  KMapSources copyWith({String? tiles, String? glyphs, String? attribution}) =>
      KMapSources(
        tiles: tiles ?? this.tiles,
        glyphs: glyphs ?? this.glyphs,
        attribution: attribution ?? this.attribution,
      );
}

Map<String, dynamic> createKMapStyle({
  required KDesignTokens tokens,
  KMapSettings settings = const KMapSettings(),
  KMapSources sources = const KMapSources(),
  Map<String, Object?> tokenOverrides = const {},
}) {
  final mapTokens = KMapTokens.fromTokens(tokens).withOverrides(tokenOverrides);
  return {
    'version': 8,
    'name': 'KDS Map Style',
    'metadata': {
      'kds:generator': '@k-design-system/ui/maps',
      'kds:settings': settings.toMap(),
      'kds:slots': {'route': 'kds-slot-route'},
    },
    'sources': {
      'openmaptiles': {
        'type': 'vector',
        'url': sources.tiles,
        'attribution': sources.attribution,
      },
    },
    'glyphs': sources.glyphs,
    'layers': buildKMapLayers(mapTokens, settings),
  };
}
