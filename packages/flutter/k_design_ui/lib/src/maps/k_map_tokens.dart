import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

part 'k_map_token_metadata.dart';

enum KMapTokenType { color, number, fontFamily }

typedef KMapTokenReader = Object Function(KMapTokens tokens);

final class KMapTokenMetadata {
  const KMapTokenMetadata({
    required this.key,
    required this.tokenName,
    required this.type,
    required this.description,
    required this.read,
  });

  final String key;
  final String tokenName;
  final KMapTokenType type;
  final String description;
  final KMapTokenReader read;

  Object valueFrom(KMapTokens tokens) => read(tokens);
}

final class KMapTokens {
  KMapTokens._(this._values);

  factory KMapTokens.fromTokens(KDesignTokens tokens) => KMapTokens._({
    'background': _cssColor(tokens.mapColorBackground),
    'water': _cssColor(tokens.mapColorWater),
    'waterLabel': _cssColor(tokens.mapColorWaterLabel),
    'park': _cssColor(tokens.mapColorPark),
    'wood': _cssColor(tokens.mapColorWood),
    'grass': _cssColor(tokens.mapColorGrass),
    'cemetery': _cssColor(tokens.mapColorCemetery),
    'landuseResidential': _cssColor(tokens.mapColorLanduseResidential),
    'landuseIndustrial': _cssColor(tokens.mapColorLanduseIndustrial),
    'landuseCommercial': _cssColor(tokens.mapColorLanduseCommercial),
    'landuseHospital': _cssColor(tokens.mapColorLanduseHospital),
    'landuseSchool': _cssColor(tokens.mapColorLanduseSchool),
    'sand': _cssColor(tokens.mapColorSand),
    'aeroway': _cssColor(tokens.mapColorAeroway),
    'building': _cssColor(tokens.mapColorBuilding),
    'buildingOutline': _cssColor(tokens.mapColorBuildingOutline),
    'road': _cssColor(tokens.mapColorRoad),
    'roadCasing': _cssColor(tokens.mapColorRoadCasing),
    'roadMinor': _cssColor(tokens.mapColorRoadMinor),
    'roadMinorCasing': _cssColor(tokens.mapColorRoadMinorCasing),
    'path': _cssColor(tokens.mapColorPath),
    'motorway': _cssColor(tokens.mapColorMotorway),
    'motorwayCasing': _cssColor(tokens.mapColorMotorwayCasing),
    'trunk': _cssColor(tokens.mapColorTrunk),
    'trunkCasing': _cssColor(tokens.mapColorTrunkCasing),
    'tunnelOpacity': tokens.mapOpacityTunnel,
    'rail': _cssColor(tokens.mapColorRail),
    'boundary': _cssColor(tokens.mapColorBoundary),
    'label': _cssColor(tokens.mapColorLabel),
    'labelStrong': _cssColor(tokens.mapColorLabelStrong),
    'labelSubtle': _cssColor(tokens.mapColorLabelSubtle),
    'labelHalo': _cssColor(tokens.mapColorLabelHalo),
    'poiFood': _cssColor(tokens.mapColorPoiFood),
    'poiShop': _cssColor(tokens.mapColorPoiShop),
    'poiHealth': _cssColor(tokens.mapColorPoiHealth),
    'poiEducation': _cssColor(tokens.mapColorPoiEducation),
    'poiLeisure': _cssColor(tokens.mapColorPoiLeisure),
    'poiTransport': _cssColor(tokens.mapColorPoiTransport),
    'poiOther': _cssColor(tokens.mapColorPoiOther),
    'poiStroke': _cssColor(tokens.mapColorPoiStroke),
    'fontRegular': _fontStack(tokens.mapFontRegular),
    'fontBold': _fontStack(tokens.mapFontBold),
    'fontItalic': _fontStack(tokens.mapFontItalic),
  });

  final Map<String, Object> _values;

  Object operator [](String key) =>
      _values[key] ?? (throw ArgumentError.value(key, 'key'));

  KMapTokens withOverrides(Map<String, Object?> overrides) {
    final values = Map<String, Object>.of(_values);
    for (final entry in overrides.entries) {
      final metadata = _metadataByKey[entry.key];
      if (metadata == null) {
        throw ArgumentError.value(entry.key, 'overrides', 'Unknown map token');
      }
      final value = switch ((metadata.type, entry.value)) {
        (KMapTokenType.color, final String value) => value,
        (KMapTokenType.number, final num value) => value.toDouble(),
        (KMapTokenType.number, final String value) => double.tryParse(value),
        (KMapTokenType.fontFamily, final List<String> value) =>
          List<String>.unmodifiable(value),
        (KMapTokenType.fontFamily, final String value) => _fontStack(value),
        _ => null,
      };
      if (value == null) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Invalid ${metadata.type.name} map token value',
        );
      }
      if (value is double &&
          (!value.isFinite ||
              (entry.key == 'tunnelOpacity' && (value < 0 || value > 1)))) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Map number tokens must be finite; tunnelOpacity must be 0 through 1',
        );
      }
      values[entry.key] = value;
    }
    return KMapTokens._(values);
  }

  Map<String, Object> toMap() => Map.unmodifiable(_values);

  String get background => this['background'] as String;
  String get water => this['water'] as String;
  String get waterLabel => this['waterLabel'] as String;
  String get park => this['park'] as String;
  String get wood => this['wood'] as String;
  String get grass => this['grass'] as String;
  String get cemetery => this['cemetery'] as String;
  String get landuseResidential => this['landuseResidential'] as String;
  String get landuseIndustrial => this['landuseIndustrial'] as String;
  String get landuseCommercial => this['landuseCommercial'] as String;
  String get landuseHospital => this['landuseHospital'] as String;
  String get landuseSchool => this['landuseSchool'] as String;
  String get sand => this['sand'] as String;
  String get aeroway => this['aeroway'] as String;
  String get building => this['building'] as String;
  String get buildingOutline => this['buildingOutline'] as String;
  String get road => this['road'] as String;
  String get roadCasing => this['roadCasing'] as String;
  String get roadMinor => this['roadMinor'] as String;
  String get roadMinorCasing => this['roadMinorCasing'] as String;
  String get path => this['path'] as String;
  String get motorway => this['motorway'] as String;
  String get motorwayCasing => this['motorwayCasing'] as String;
  String get trunk => this['trunk'] as String;
  String get trunkCasing => this['trunkCasing'] as String;
  double get tunnelOpacity => this['tunnelOpacity'] as double;
  String get rail => this['rail'] as String;
  String get boundary => this['boundary'] as String;
  String get label => this['label'] as String;
  String get labelStrong => this['labelStrong'] as String;
  String get labelSubtle => this['labelSubtle'] as String;
  String get labelHalo => this['labelHalo'] as String;
  String get poiFood => this['poiFood'] as String;
  String get poiShop => this['poiShop'] as String;
  String get poiHealth => this['poiHealth'] as String;
  String get poiEducation => this['poiEducation'] as String;
  String get poiLeisure => this['poiLeisure'] as String;
  String get poiTransport => this['poiTransport'] as String;
  String get poiOther => this['poiOther'] as String;
  String get poiStroke => this['poiStroke'] as String;
  List<String> get fontRegular => this['fontRegular'] as List<String>;
  List<String> get fontBold => this['fontBold'] as List<String>;
  List<String> get fontItalic => this['fontItalic'] as List<String>;
}

String _cssColor(Color color) {
  final value = color.toARGB32();
  final rgb = (value & 0x00ffffff)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
  if ((value >>> 24) == 0xff) return '#$rgb';
  final alpha = ((value >>> 24) / 255)
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return 'rgba(${(value >>> 16) & 0xff},${(value >>> 8) & 0xff},${value & 0xff},$alpha)';
}

List<String> _fontStack(String value) => List.unmodifiable(
  value
      .split(',')
      .map((font) => font.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''))
      .where((font) => font.isNotEmpty),
);
