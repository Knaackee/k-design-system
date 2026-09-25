import 'package:flutter/foundation.dart';

@immutable
class KChartPoint {
  const KChartPoint({required this.id, required this.x, required this.y});
  final String id;
  final double x;
  final double? y;
}

@immutable
class KChartSeries {
  KChartSeries({
    required this.id,
    required this.label,
    required List<KChartPoint> points,
    this.colorIndex = 0,
  }) : points = List.unmodifiable(points);
  final String id;
  final String label;
  final List<KChartPoint> points;
  final int colorIndex;
}

@immutable
class KChartSelection {
  const KChartSelection({required this.seriesId, required this.pointId});
  final String seriesId;
  final String pointId;
  @override
  bool operator ==(Object other) =>
      other is KChartSelection &&
      other.seriesId == seriesId &&
      other.pointId == pointId;
  @override
  int get hashCode => Object.hash(seriesId, pointId);
}

@immutable
class KChartAxis {
  KChartAxis({
    required this.min,
    required this.max,
    required List<double> ticks,
    required this.format,
  }) : assert(min < max),
       ticks = List.unmodifiable(ticks);
  final double min;
  final double max;
  final List<double> ticks;
  final String Function(double) format;
  double fraction(double value) => (value - min) / (max - min);
}
