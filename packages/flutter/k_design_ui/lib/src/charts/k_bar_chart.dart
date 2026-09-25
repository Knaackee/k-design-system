import 'k_cartesian_chart.dart';

class KBarChart extends KCartesianChart {
  const KBarChart({
    required super.series,
    required super.xAxis,
    required super.yAxis,
    required super.label,
    super.description,
    super.selectedPoint,
    super.onSelectionChange,
    super.visibleSeriesIds,
    super.onVisibleSeriesChange,
    super.showDataTable,
    super.dataTableLabel,
    super.dataTableXAxisLabel,
    super.loading,
    super.error,
    super.emptyContent,
    super.loadingContent,
    super.errorContent,
    super.height,
    super.key,
    super.stacked,
    super.orientation,
  }) : super(area: false);
}
