import test from "node:test";
import assert from "node:assert/strict";
import {
  chartBands,
  chartCategorySpan,
  validSegments,
} from "../packages/web/ui/src/charts/chart-family-model.ts";
const series = (id, ys) => ({
  id,
  label: id,
  points: ys.map((y, x) => ({ id: `${id}${x}`, x, y })),
});
test("stacked bands accumulate positive and negative values separately without mutating input", () => {
  const input = [
    series("a", [5, -3]),
    series("b", [-2, 4]),
    series("c", [2, -6]),
  ];
  const before = structuredClone(input),
    result = chartBands(input, true);
  assert.deepEqual(
    result.map((b) => b.points.map((p) => [p.from, p.to])),
    [
      [
        [0, 5],
        [0, -3],
      ],
      [
        [0, -2],
        [0, 4],
      ],
      [
        [5, 7],
        [-3, -9],
      ],
    ],
  );
  assert.deepEqual(input, before);
  assert.deepEqual(
    chartBands(input, false)[2].points.map((p) => [p.from, p.to]),
    [
      [0, 2],
      [0, -6],
    ],
  );
});
test("null and nonfinite values remain explicit area gaps and do not poison later stacks", () => {
  const result = chartBands(
    [series("a", [null, NaN, Infinity]), series("b", [4, 5, 6])],
    true,
  );
  assert.deepEqual(
    result[0].points.map((p) => [p.from, p.to]),
    [
      [null, null],
      [null, null],
      [null, null],
    ],
  );
  assert.deepEqual(
    result[1].points.map((p) => p.to),
    [4, 5, 6],
  );
  assert.equal(
    chartBands(
      [{ id: "a", label: "a", points: [{ id: "bad", x: Infinity, y: 2 }] }],
      false,
    )[0].points.length,
    0,
  );
});
test("group span preserves numeric spacing and has a single-category fallback", () => {
  assert.equal(chartCategorySpan([series("a", [1, 2, 3])], 3), 0.72);
  assert.equal(chartCategorySpan([series("a", [1])], 2), 1.44);
});
test("donut excludes negative, zero and nonfinite segments without mutating values", () => {
  const input = [0, -2, NaN, Infinity, 3, 7].map((value, i) => ({
    id: String(i),
    label: String(i),
    value,
  }));
  assert.deepEqual(
    validSegments(input).map((s) => s.value),
    [3, 7],
  );
  assert.deepEqual(validSegments(input.slice(0, 4)), []);
  assert.equal(input.length, 6);
});
