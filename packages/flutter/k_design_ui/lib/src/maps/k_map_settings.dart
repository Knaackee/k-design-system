enum KMapSettingType { range, toggle, select }

final class KMapSettingMetadata {
  const KMapSettingMetadata({
    required this.key,
    required this.label,
    required this.description,
    required this.type,
    required this.defaultValue,
    this.min,
    this.max,
    this.step,
    this.options = const [],
  });

  final String key;
  final String label;
  final String description;
  final KMapSettingType type;
  final Object defaultValue;
  final double? min;
  final double? max;
  final double? step;
  final List<String> options;
}

final class KMapSettings {
  const KMapSettings({
    this.lang = 'de',
    this.roadWidthScale = 1,
    this.casingScale = 1,
    this.labelScale = 1,
    this.haloWidth = 1.4,
    this.showLanduse = true,
    this.showBuildings = true,
    this.buildingMinZoom = 14.5,
    this.showRail = true,
    this.showPaths = true,
    this.showPois = true,
    this.poiMinZoom = 15,
    this.poiMaxRank = 18,
    this.poiDotScale = 1,
    this.roadLabelMinZoom = 13,
    this.showQuarterLabels = true,
  }) : assert(
         lang == 'de' ||
             lang == 'en' ||
             lang == 'fr' ||
             lang == 'it' ||
             lang == 'es' ||
             lang == 'pl' ||
             lang == 'nl',
       );

  final String lang;
  final double roadWidthScale;
  final double casingScale;
  final double labelScale;
  final double haloWidth;
  final bool showLanduse;
  final bool showBuildings;
  final double buildingMinZoom;
  final bool showRail;
  final bool showPaths;
  final bool showPois;
  final double poiMinZoom;
  final double poiMaxRank;
  final double poiDotScale;
  final double roadLabelMinZoom;
  final bool showQuarterLabels;

  KMapSettings copyWith({
    String? lang,
    double? roadWidthScale,
    double? casingScale,
    double? labelScale,
    double? haloWidth,
    bool? showLanduse,
    bool? showBuildings,
    double? buildingMinZoom,
    bool? showRail,
    bool? showPaths,
    bool? showPois,
    double? poiMinZoom,
    double? poiMaxRank,
    double? poiDotScale,
    double? roadLabelMinZoom,
    bool? showQuarterLabels,
  }) => KMapSettings(
    lang: lang ?? this.lang,
    roadWidthScale: roadWidthScale ?? this.roadWidthScale,
    casingScale: casingScale ?? this.casingScale,
    labelScale: labelScale ?? this.labelScale,
    haloWidth: haloWidth ?? this.haloWidth,
    showLanduse: showLanduse ?? this.showLanduse,
    showBuildings: showBuildings ?? this.showBuildings,
    buildingMinZoom: buildingMinZoom ?? this.buildingMinZoom,
    showRail: showRail ?? this.showRail,
    showPaths: showPaths ?? this.showPaths,
    showPois: showPois ?? this.showPois,
    poiMinZoom: poiMinZoom ?? this.poiMinZoom,
    poiMaxRank: poiMaxRank ?? this.poiMaxRank,
    poiDotScale: poiDotScale ?? this.poiDotScale,
    roadLabelMinZoom: roadLabelMinZoom ?? this.roadLabelMinZoom,
    showQuarterLabels: showQuarterLabels ?? this.showQuarterLabels,
  );

  Map<String, Object> toMap() => {
    'lang': lang,
    'roadWidthScale': roadWidthScale,
    'casingScale': casingScale,
    'labelScale': labelScale,
    'haloWidth': haloWidth,
    'showLanduse': showLanduse,
    'showBuildings': showBuildings,
    'buildingMinZoom': buildingMinZoom,
    'showRail': showRail,
    'showPaths': showPaths,
    'showPois': showPois,
    'poiMinZoom': poiMinZoom,
    'poiMaxRank': poiMaxRank,
    'poiDotScale': poiDotScale,
    'roadLabelMinZoom': roadLabelMinZoom,
    'showQuarterLabels': showQuarterLabels,
  };
}

const kMapSettingsMetadata = <KMapSettingMetadata>[
  KMapSettingMetadata(
    key: 'lang',
    label: 'Label language',
    description: 'Preferred label language with source-name fallback.',
    type: KMapSettingType.select,
    defaultValue: 'de',
    options: ['de', 'en', 'fr', 'it', 'es', 'pl', 'nl'],
  ),
  KMapSettingMetadata(
    key: 'roadWidthScale',
    label: 'Road width',
    description: 'Scale applied to every road fill width.',
    type: KMapSettingType.range,
    defaultValue: 1.0,
    min: 0.6,
    max: 1.6,
    step: 0.05,
  ),
  KMapSettingMetadata(
    key: 'casingScale',
    label: 'Road casing',
    description: 'Scale applied to road casing width.',
    type: KMapSettingType.range,
    defaultValue: 1.0,
    min: 0,
    max: 2,
    step: 0.1,
  ),
  KMapSettingMetadata(
    key: 'labelScale',
    label: 'Label size',
    description: 'Scale applied to map label sizes.',
    type: KMapSettingType.range,
    defaultValue: 1.0,
    min: 0.8,
    max: 1.4,
    step: 0.05,
  ),
  KMapSettingMetadata(
    key: 'haloWidth',
    label: 'Text halo',
    description: 'Text halo width in pixels.',
    type: KMapSettingType.range,
    defaultValue: 1.4,
    min: 0,
    max: 3,
    step: 0.1,
  ),
  KMapSettingMetadata(
    key: 'showLanduse',
    label: 'Land use',
    description: 'Show residential, commercial and civic land-use fills.',
    type: KMapSettingType.toggle,
    defaultValue: true,
  ),
  KMapSettingMetadata(
    key: 'showBuildings',
    label: 'Buildings',
    description: 'Show building footprints.',
    type: KMapSettingType.toggle,
    defaultValue: true,
  ),
  KMapSettingMetadata(
    key: 'buildingMinZoom',
    label: 'Buildings from zoom',
    description: 'Minimum zoom for building footprints.',
    type: KMapSettingType.range,
    defaultValue: 14.5,
    min: 12,
    max: 17,
    step: 0.5,
  ),
  KMapSettingMetadata(
    key: 'showRail',
    label: 'Rail lines',
    description: 'Show rail and transit lines.',
    type: KMapSettingType.toggle,
    defaultValue: true,
  ),
  KMapSettingMetadata(
    key: 'showPaths',
    label: 'Foot and cycle paths',
    description: 'Show path-class transportation lines.',
    type: KMapSettingType.toggle,
    defaultValue: true,
  ),
  KMapSettingMetadata(
    key: 'showPois',
    label: 'POIs',
    description: 'Show points of interest and their labels.',
    type: KMapSettingType.toggle,
    defaultValue: true,
  ),
  KMapSettingMetadata(
    key: 'poiMinZoom',
    label: 'POIs from zoom',
    description: 'Minimum zoom for points of interest.',
    type: KMapSettingType.range,
    defaultValue: 15.0,
    min: 13,
    max: 18,
    step: 0.5,
  ),
  KMapSettingMetadata(
    key: 'poiMaxRank',
    label: 'POI density',
    description: 'Maximum OpenMapTiles POI rank; lower values show fewer POIs.',
    type: KMapSettingType.range,
    defaultValue: 18.0,
    min: 1,
    max: 40,
    step: 1,
  ),
  KMapSettingMetadata(
    key: 'poiDotScale',
    label: 'POI dot size',
    description: 'Scale applied to POI dots.',
    type: KMapSettingType.range,
    defaultValue: 1.0,
    min: 0.5,
    max: 2,
    step: 0.1,
  ),
  KMapSettingMetadata(
    key: 'roadLabelMinZoom',
    label: 'Road names from zoom',
    description:
        'Minimum zoom for major road labels; minor labels start two levels later.',
    type: KMapSettingType.range,
    defaultValue: 13.0,
    min: 11,
    max: 17,
    step: 0.5,
  ),
  KMapSettingMetadata(
    key: 'showQuarterLabels',
    label: 'Quarter labels',
    description: 'Show suburb, quarter and neighbourhood labels.',
    type: KMapSettingType.toggle,
    defaultValue: true,
  ),
];
