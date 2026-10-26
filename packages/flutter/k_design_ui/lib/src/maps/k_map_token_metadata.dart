part of 'k_map_tokens.dart';

const kMapTokenMetadata = <KMapTokenMetadata>[
  KMapTokenMetadata(
    key: 'background',
    tokenName: 'map.color.background',
    type: KMapTokenType.color,
    description: 'Map canvas',
    read: _readBackground,
  ),
  KMapTokenMetadata(
    key: 'water',
    tokenName: 'map.color.water',
    type: KMapTokenType.color,
    description: 'Water fill',
    read: _readWater,
  ),
  KMapTokenMetadata(
    key: 'waterLabel',
    tokenName: 'map.color.waterLabel',
    type: KMapTokenType.color,
    description: 'Water labels',
    read: _readWaterLabel,
  ),
  KMapTokenMetadata(
    key: 'park',
    tokenName: 'map.color.park',
    type: KMapTokenType.color,
    description: 'Park fill',
    read: _readPark,
  ),
  KMapTokenMetadata(
    key: 'wood',
    tokenName: 'map.color.wood',
    type: KMapTokenType.color,
    description: 'Woodland fill',
    read: _readWood,
  ),
  KMapTokenMetadata(
    key: 'grass',
    tokenName: 'map.color.grass',
    type: KMapTokenType.color,
    description: 'Grass and farmland fill',
    read: _readGrass,
  ),
  KMapTokenMetadata(
    key: 'cemetery',
    tokenName: 'map.color.cemetery',
    type: KMapTokenType.color,
    description: 'Cemetery fill',
    read: _readCemetery,
  ),
  KMapTokenMetadata(
    key: 'landuseResidential',
    tokenName: 'map.color.landuseResidential',
    type: KMapTokenType.color,
    description: 'Residential land use',
    read: _readLanduseResidential,
  ),
  KMapTokenMetadata(
    key: 'landuseIndustrial',
    tokenName: 'map.color.landuseIndustrial',
    type: KMapTokenType.color,
    description: 'Industrial land use',
    read: _readLanduseIndustrial,
  ),
  KMapTokenMetadata(
    key: 'landuseCommercial',
    tokenName: 'map.color.landuseCommercial',
    type: KMapTokenType.color,
    description: 'Commercial land use',
    read: _readLanduseCommercial,
  ),
  KMapTokenMetadata(
    key: 'landuseHospital',
    tokenName: 'map.color.landuseHospital',
    type: KMapTokenType.color,
    description: 'Hospital land use',
    read: _readLanduseHospital,
  ),
  KMapTokenMetadata(
    key: 'landuseSchool',
    tokenName: 'map.color.landuseSchool',
    type: KMapTokenType.color,
    description: 'School land use',
    read: _readLanduseSchool,
  ),
  KMapTokenMetadata(
    key: 'sand',
    tokenName: 'map.color.sand',
    type: KMapTokenType.color,
    description: 'Sand fill',
    read: _readSand,
  ),
  KMapTokenMetadata(
    key: 'aeroway',
    tokenName: 'map.color.aeroway',
    type: KMapTokenType.color,
    description: 'Airport areas and runways',
    read: _readAeroway,
  ),
  KMapTokenMetadata(
    key: 'building',
    tokenName: 'map.color.building',
    type: KMapTokenType.color,
    description: 'Building fill',
    read: _readBuilding,
  ),
  KMapTokenMetadata(
    key: 'buildingOutline',
    tokenName: 'map.color.buildingOutline',
    type: KMapTokenType.color,
    description: 'Building outline',
    read: _readBuildingOutline,
  ),
  KMapTokenMetadata(
    key: 'road',
    tokenName: 'map.color.road',
    type: KMapTokenType.color,
    description: 'Major road fill',
    read: _readRoad,
  ),
  KMapTokenMetadata(
    key: 'roadCasing',
    tokenName: 'map.color.roadCasing',
    type: KMapTokenType.color,
    description: 'Major road casing',
    read: _readRoadCasing,
  ),
  KMapTokenMetadata(
    key: 'roadMinor',
    tokenName: 'map.color.roadMinor',
    type: KMapTokenType.color,
    description: 'Minor road fill',
    read: _readRoadMinor,
  ),
  KMapTokenMetadata(
    key: 'roadMinorCasing',
    tokenName: 'map.color.roadMinorCasing',
    type: KMapTokenType.color,
    description: 'Minor road casing',
    read: _readRoadMinorCasing,
  ),
  KMapTokenMetadata(
    key: 'path',
    tokenName: 'map.color.path',
    type: KMapTokenType.color,
    description: 'Foot and cycle paths',
    read: _readPath,
  ),
  KMapTokenMetadata(
    key: 'motorway',
    tokenName: 'map.color.motorway',
    type: KMapTokenType.color,
    description: 'Motorway fill',
    read: _readMotorway,
  ),
  KMapTokenMetadata(
    key: 'motorwayCasing',
    tokenName: 'map.color.motorwayCasing',
    type: KMapTokenType.color,
    description: 'Motorway casing',
    read: _readMotorwayCasing,
  ),
  KMapTokenMetadata(
    key: 'trunk',
    tokenName: 'map.color.trunk',
    type: KMapTokenType.color,
    description: 'Trunk road fill',
    read: _readTrunk,
  ),
  KMapTokenMetadata(
    key: 'trunkCasing',
    tokenName: 'map.color.trunkCasing',
    type: KMapTokenType.color,
    description: 'Trunk road casing',
    read: _readTrunkCasing,
  ),
  KMapTokenMetadata(
    key: 'tunnelOpacity',
    tokenName: 'map.opacity.tunnel',
    type: KMapTokenType.number,
    description: 'Tunnel road opacity',
    read: _readTunnelOpacity,
  ),
  KMapTokenMetadata(
    key: 'rail',
    tokenName: 'map.color.rail',
    type: KMapTokenType.color,
    description: 'Rail lines',
    read: _readRail,
  ),
  KMapTokenMetadata(
    key: 'boundary',
    tokenName: 'map.color.boundary',
    type: KMapTokenType.color,
    description: 'Administrative boundaries',
    read: _readBoundary,
  ),
  KMapTokenMetadata(
    key: 'label',
    tokenName: 'map.color.label',
    type: KMapTokenType.color,
    description: 'Default labels',
    read: _readLabel,
  ),
  KMapTokenMetadata(
    key: 'labelStrong',
    tokenName: 'map.color.labelStrong',
    type: KMapTokenType.color,
    description: 'Prominent labels',
    read: _readLabelStrong,
  ),
  KMapTokenMetadata(
    key: 'labelSubtle',
    tokenName: 'map.color.labelSubtle',
    type: KMapTokenType.color,
    description: 'Secondary labels',
    read: _readLabelSubtle,
  ),
  KMapTokenMetadata(
    key: 'labelHalo',
    tokenName: 'map.color.labelHalo',
    type: KMapTokenType.color,
    description: 'Label halo',
    read: _readLabelHalo,
  ),
  KMapTokenMetadata(
    key: 'poiFood',
    tokenName: 'map.color.poiFood',
    type: KMapTokenType.color,
    description: 'Food POIs',
    read: _readPoiFood,
  ),
  KMapTokenMetadata(
    key: 'poiShop',
    tokenName: 'map.color.poiShop',
    type: KMapTokenType.color,
    description: 'Shopping POIs',
    read: _readPoiShop,
  ),
  KMapTokenMetadata(
    key: 'poiHealth',
    tokenName: 'map.color.poiHealth',
    type: KMapTokenType.color,
    description: 'Health POIs',
    read: _readPoiHealth,
  ),
  KMapTokenMetadata(
    key: 'poiEducation',
    tokenName: 'map.color.poiEducation',
    type: KMapTokenType.color,
    description: 'Education POIs',
    read: _readPoiEducation,
  ),
  KMapTokenMetadata(
    key: 'poiLeisure',
    tokenName: 'map.color.poiLeisure',
    type: KMapTokenType.color,
    description: 'Leisure POIs',
    read: _readPoiLeisure,
  ),
  KMapTokenMetadata(
    key: 'poiTransport',
    tokenName: 'map.color.poiTransport',
    type: KMapTokenType.color,
    description: 'Transport POIs',
    read: _readPoiTransport,
  ),
  KMapTokenMetadata(
    key: 'poiOther',
    tokenName: 'map.color.poiOther',
    type: KMapTokenType.color,
    description: 'Other POIs',
    read: _readPoiOther,
  ),
  KMapTokenMetadata(
    key: 'poiStroke',
    tokenName: 'map.color.poiStroke',
    type: KMapTokenType.color,
    description: 'POI dot outline',
    read: _readPoiStroke,
  ),
  KMapTokenMetadata(
    key: 'fontRegular',
    tokenName: 'map.font.regular',
    type: KMapTokenType.fontFamily,
    description: 'Regular map glyph stack',
    read: _readFontRegular,
  ),
  KMapTokenMetadata(
    key: 'fontBold',
    tokenName: 'map.font.bold',
    type: KMapTokenType.fontFamily,
    description: 'Bold map glyph stack',
    read: _readFontBold,
  ),
  KMapTokenMetadata(
    key: 'fontItalic',
    tokenName: 'map.font.italic',
    type: KMapTokenType.fontFamily,
    description: 'Italic map glyph stack',
    read: _readFontItalic,
  ),
];

final _metadataByKey = {
  for (final metadata in kMapTokenMetadata) metadata.key: metadata,
};

Object _readBackground(KMapTokens t) => t.background;
Object _readWater(KMapTokens t) => t.water;
Object _readWaterLabel(KMapTokens t) => t.waterLabel;
Object _readPark(KMapTokens t) => t.park;
Object _readWood(KMapTokens t) => t.wood;
Object _readGrass(KMapTokens t) => t.grass;
Object _readCemetery(KMapTokens t) => t.cemetery;
Object _readLanduseResidential(KMapTokens t) => t.landuseResidential;
Object _readLanduseIndustrial(KMapTokens t) => t.landuseIndustrial;
Object _readLanduseCommercial(KMapTokens t) => t.landuseCommercial;
Object _readLanduseHospital(KMapTokens t) => t.landuseHospital;
Object _readLanduseSchool(KMapTokens t) => t.landuseSchool;
Object _readSand(KMapTokens t) => t.sand;
Object _readAeroway(KMapTokens t) => t.aeroway;
Object _readBuilding(KMapTokens t) => t.building;
Object _readBuildingOutline(KMapTokens t) => t.buildingOutline;
Object _readRoad(KMapTokens t) => t.road;
Object _readRoadCasing(KMapTokens t) => t.roadCasing;
Object _readRoadMinor(KMapTokens t) => t.roadMinor;
Object _readRoadMinorCasing(KMapTokens t) => t.roadMinorCasing;
Object _readPath(KMapTokens t) => t.path;
Object _readMotorway(KMapTokens t) => t.motorway;
Object _readMotorwayCasing(KMapTokens t) => t.motorwayCasing;
Object _readTrunk(KMapTokens t) => t.trunk;
Object _readTrunkCasing(KMapTokens t) => t.trunkCasing;
Object _readTunnelOpacity(KMapTokens t) => t.tunnelOpacity;
Object _readRail(KMapTokens t) => t.rail;
Object _readBoundary(KMapTokens t) => t.boundary;
Object _readLabel(KMapTokens t) => t.label;
Object _readLabelStrong(KMapTokens t) => t.labelStrong;
Object _readLabelSubtle(KMapTokens t) => t.labelSubtle;
Object _readLabelHalo(KMapTokens t) => t.labelHalo;
Object _readPoiFood(KMapTokens t) => t.poiFood;
Object _readPoiShop(KMapTokens t) => t.poiShop;
Object _readPoiHealth(KMapTokens t) => t.poiHealth;
Object _readPoiEducation(KMapTokens t) => t.poiEducation;
Object _readPoiLeisure(KMapTokens t) => t.poiLeisure;
Object _readPoiTransport(KMapTokens t) => t.poiTransport;
Object _readPoiOther(KMapTokens t) => t.poiOther;
Object _readPoiStroke(KMapTokens t) => t.poiStroke;
Object _readFontRegular(KMapTokens t) => t.fontRegular;
Object _readFontBold(KMapTokens t) => t.fontBold;
Object _readFontItalic(KMapTokens t) => t.fontItalic;
