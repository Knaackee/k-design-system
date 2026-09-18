import test from "node:test";
import assert from "node:assert/strict";
import { tableWidths } from "../packages/web/ui/src/data/table-layout.ts";
test("table shares surplus by weight without changing fixed columns", () => {
  const tracks = [
    { minWidth: 240, flex: 2 },
    { minWidth: 160 },
    { width: 120 },
  ];
  assert.deepEqual(tableWidths(tracks, 820), [440, 260, 120]);
  assert.deepEqual(tableWidths(tracks, 320), [240, 160, 120]);
  assert.deepEqual(tableWidths(tracks, 0), [240, 160, 120]);
  assert.deepEqual(
    tableWidths([{ width: 80 }, { width: 120 }], 900),
    [80, 120],
  );
  assert.deepEqual(tableWidths([{}], 300), [300]);
});
test("table preserves fractional track widths and exact total", () => {
  const widths = tableWidths(
    [{ minWidth: 100 }, { minWidth: 100 }, { minWidth: 100 }],
    400,
  );
  assert.ok(Math.abs(widths.reduce((a, b) => a + b, 0) - 400) < 1e-9);
});
test("table rejects unusable layout inputs", () => {
  for (const tracks of [
    [],
    [{ width: 0 }],
    [{ width: NaN }],
    [{ minWidth: -1 }],
    [{ flex: 0 }],
    [{ flex: Infinity }],
    [{ width: Infinity }],
    [{ minWidth: Number.MAX_VALUE }, { minWidth: Number.MAX_VALUE }],
  ])
    assert.throws(() => tableWidths(tracks, 300), RangeError);
  for (const available of [-1, NaN, Infinity])
    assert.throws(() => tableWidths([{}], available), RangeError);
});
