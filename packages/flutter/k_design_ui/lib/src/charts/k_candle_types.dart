import 'package:flutter/foundation.dart';

@immutable
class KChartCandle {
  const KChartCandle({
    required this.id,
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });
  final String id;
  final double x, open, high, low, close;
  final double? volume;
  bool get isValid =>
      [x, open, high, low, close].every((v) => v.isFinite) &&
      low <= open &&
      low <= close &&
      high >= open &&
      high >= close;
}

@immutable
class KChartVisibleRange {
  const KChartVisibleRange({required this.min, required this.max})
    : assert(min < max);
  final double min, max;
}

@immutable
class KChartOhlcLabels {
  const KChartOhlcLabels({
    this.open = 'Open',
    this.high = 'High',
    this.low = 'Low',
    this.close = 'Close',
    this.volume = 'Volume',
  });
  final String open, high, low, close, volume;
}
