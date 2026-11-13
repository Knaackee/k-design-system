/** Normalized chart coordinates, independent of CSS size or device density. */
export function metricTrendPath(values: readonly (number | null)[]): string {
  const finite = values.filter(
    (value): value is number => value !== null && Number.isFinite(value),
  );
  if (finite.length < 2) return "";
  const min = Math.min(...finite),
    max = Math.max(...finite);
  let connected = false;
  return values
    .map((value, index) => {
      if (value === null || !Number.isFinite(value)) {
        connected = false;
        return "";
      }
      const x = (index / Math.max(values.length - 1, 1)) * 100;
      const y = max === min ? 12 : 24 - ((value - min) / (max - min)) * 24;
      const command = `${connected ? "L" : "M"}${x.toFixed(2)},${y.toFixed(2)}`;
      connected = true;
      return command;
    })
    .join(" ")
    .trim();
}
