export interface KChartCandle {
  id: string;
  x: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
}
export interface KChartVisibleRange {
  min: number;
  max: number;
}
/** Invalid prices are omitted; caller-owned records are never modified. */
export function validCandles(
  data: readonly KChartCandle[],
  range?: KChartVisibleRange,
) {
  return data
    .filter(
      (c) =>
        [c.x, c.open, c.high, c.low, c.close].every(Number.isFinite) &&
        c.low <= Math.min(c.open, c.close) &&
        c.high >= Math.max(c.open, c.close) &&
        (!range || (c.x >= range.min && c.x <= range.max)),
    )
    .sort((a, b) => a.x - b.x);
}
export function candleSpan(data: readonly KChartCandle[], fallback: number) {
  const xs = [...new Set(data.map((c) => c.x))].sort((a, b) => a - b);
  const deltas = xs
    .slice(1)
    .map((x, i) => x - xs[i])
    .filter((d) => d > 0);
  return 0.72 * (deltas.length ? Math.min(...deltas) : fallback);
}
export function nearestCandle(data: readonly KChartCandle[], x: number) {
  return data.reduce<KChartCandle | undefined>(
    (best, c) => (!best || Math.abs(c.x - x) < Math.abs(best.x - x) ? c : best),
    undefined,
  );
}
