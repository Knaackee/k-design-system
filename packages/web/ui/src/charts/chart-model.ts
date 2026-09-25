export interface KChartPoint {
  id: string;
  x: number;
  y: number | null;
}
export interface KChartSeries {
  id: string;
  label: string;
  points: readonly KChartPoint[];
  colorIndex?: number;
}
export interface KChartSelection {
  seriesId: string;
  pointId: string;
}
export interface KChartAxis {
  min: number;
  max: number;
  ticks: readonly number[];
  format: (value: number) => string;
}

export function chartPoint(
  series: readonly KChartSeries[],
  selection?: KChartSelection | null,
) {
  return series
    .find((s) => s.id === selection?.seriesId)
    ?.points.find((p) => p.id === selection?.pointId && p.y !== null);
}
export function chartCandidates(
  series: readonly KChartSeries[],
  xAxis: KChartAxis,
  yAxis: KChartAxis,
) {
  return series
    .flatMap((s) =>
      s.points
        .filter(
          (p) =>
            p.y !== null &&
            Number.isFinite(p.y) &&
            Number.isFinite(p.x) &&
            p.x >= xAxis.min &&
            p.x <= xAxis.max &&
            p.y >= yAxis.min &&
            p.y <= yAxis.max,
        )
        .map((p) => ({ seriesId: s.id, pointId: p.id, x: p.x, y: p.y! })),
    )
    .sort((a, b) => a.x - b.x);
}
export function chartRatio(value: number, axis: KChartAxis) {
  return (value - axis.min) / (axis.max - axis.min);
}
export function validChartAxis(axis: KChartAxis) {
  return (
    Number.isFinite(axis.min) &&
    Number.isFinite(axis.max) &&
    axis.max > axis.min
  );
}
