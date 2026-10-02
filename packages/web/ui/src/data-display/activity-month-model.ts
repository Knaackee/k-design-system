/** Monday-first columns. Null cells pad only the edges of each month. */
export function activityMonth(offset: number, today = "2026-10-02") {
  const start = new Date(
    Date.UTC(
      Number(today.slice(0, 4)),
      Number(today.slice(5, 7)) - 1 + offset,
      1,
    ),
  );
  const key = start.toISOString().slice(0, 7);
  const length = new Date(
    Date.UTC(start.getUTCFullYear(), start.getUTCMonth() + 1, 0),
  ).getUTCDate();
  const leading = (start.getUTCDay() + 6) % 7;
  const weeks = 6;
  const cells = Array.from({ length: weeks * 7 }, (_, index) => {
    const day = index - leading + 1;
    return day < 1 || day > length
      ? null
      : `${key}-${String(day).padStart(2, "0")}`;
  });
  return { key, start, weeks, cells };
}
