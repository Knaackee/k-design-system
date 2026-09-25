import type { KChartSeries } from "./chart-model.js";
export interface KChartSegment {
  id: string;
  label: string;
  value: number;
  colorIndex?: number;
}
/** Shared deterministic numeric geometry; null points remain gaps in area paths. */
export function chartBands(series: readonly KChartSeries[], stacked: boolean) {
  const positive = new Map<number, number>(),
    negative = new Map<number, number>();
  return series.map((s) => ({
    series: s,
    points: [...s.points]
      .filter((p) => Number.isFinite(p.x))
      .sort((a, b) => a.x - b.x)
      .map((p) => {
        if (p.y === null || !Number.isFinite(p.y))
          return { ...p, from: null, to: null };
        const sums = p.y < 0 ? negative : positive;
        const from = stacked ? (sums.get(p.x) ?? 0) : 0,
          to = from + p.y;
        if (stacked) sums.set(p.x, to);
        return { ...p, from, to };
      }),
  }));
}
export function chartCategorySpan(
  series: readonly KChartSeries[],
  range: number,
) {
  const xs = [
    ...new Set(
      series.flatMap((s) =>
        s.points.filter((p) => Number.isFinite(p.x)).map((p) => p.x),
      ),
    ),
  ].sort((a, b) => a - b);
  return xs.length > 1
    ? Math.min(...xs.slice(1).map((x, i) => x - xs[i])) * 0.72
    : range * 0.72;
}
export function validSegments(segments: readonly KChartSegment[]) {
  return segments.filter((s) => Number.isFinite(s.value) && s.value > 0);
}
