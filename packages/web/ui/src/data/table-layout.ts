export interface TableTrack {
  width?: number;
  minWidth?: number;
  flex?: number;
}

/** Fixed tracks retain their width; only flexible tracks share surplus space. */
export function tableWidths(
  columns: readonly TableTrack[],
  available: number,
): number[] {
  if (!Number.isFinite(available) || available < 0)
    throw new RangeError(
      "KTable requires a finite nonnegative available width",
    );
  if (!columns.length)
    throw new RangeError("KTable requires at least one column");
  const bases = columns.map(({ width, minWidth = 160, flex = 1 }) => {
    const base = width ?? minWidth;
    if (
      !Number.isFinite(base) ||
      base <= 0 ||
      (width === undefined && (!Number.isFinite(flex) || flex <= 0))
    )
      throw new RangeError(
        "KTable column widths and flex must be positive and finite",
      );
    return base;
  });
  const total = bases.reduce((a, b) => a + b, 0);
  const flex = columns.reduce(
    (sum, column) =>
      sum + (column.width === undefined ? (column.flex ?? 1) : 0),
    0,
  );
  if (!Number.isFinite(total) || !Number.isFinite(flex))
    throw new RangeError("KTable track totals must be finite");
  const extra = Math.max(0, available - total);
  return bases.map(
    (base, index) =>
      base +
      (columns[index].width === undefined
        ? extra * ((columns[index].flex ?? 1) / flex)
        : 0),
  );
}
