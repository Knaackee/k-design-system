import 'k_map_settings.dart';

const kMapSourceId = 'openmaptiles';
const isLine = <Object>[
  'match',
  ['geometry-type'],
  ['LineString', 'MultiLineString'],
  true,
  false,
];
const isPoly = <Object>[
  'match',
  ['geometry-type'],
  ['Polygon', 'MultiPolygon'],
  true,
  false,
];
const isPoint = <Object>[
  'match',
  ['geometry-type'],
  ['Point', 'MultiPoint'],
  true,
  false,
];

List<Object> nameField(String lang) => [
  'coalesce',
  ['get', 'name:$lang'],
  ['get', 'name_$lang'],
  ['get', 'name'],
];

typedef Stops = List<(num, Object)>;

List<Object> zexp(Stops stops, [double base = 1.55]) => [
  'interpolate',
  ['exponential', base],
  ['zoom'],
  for (final (zoom, value) in stops) ...[zoom, value],
];

List<Object> zlin(Stops stops) => [
  'interpolate',
  ['linear'],
  ['zoom'],
  for (final (zoom, value) in stops) ...[zoom, value],
];

Stops scaleStops(Stops stops, double factor) => [
  for (final (zoom, value) in stops)
    (zoom, rounded((value as num) * factor, 3)),
];

Map<String, Object> visibility(bool on) => {
  'visibility': on ? 'visible' : 'none',
};

double rounded(num value, int fractionDigits) =>
    double.parse(value.toStringAsFixed(fractionDigits));

List<Object> byClass(List<String> classes) => [
  'match',
  ['get', 'class'],
  classes,
  true,
  false,
];

extension KMapSettingsExpressions on KMapSettings {
  List<Object> get localizedNameField => nameField(lang);
}
