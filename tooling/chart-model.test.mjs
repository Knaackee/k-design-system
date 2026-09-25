import test from "node:test";
import assert from "node:assert/strict";
import {
  chartCandidates,
  chartPoint,
  chartRatio,
  validChartAxis,
} from "../packages/web/ui/src/charts/chart-model.ts";
const axis = { min: 0, max: 10, ticks: [0, 10], format: String };
test("chart interaction excludes gaps/nonfinite/out-of-domain values and preserves distinct series at same x", () => {
  const series = [
    {
      id: "a",
      label: "A",
      points: [
        { id: "valid", x: 5, y: 4 },
        { id: "gap", x: 6, y: null },
        { id: "bad", x: 7, y: NaN },
        { id: "outside", x: 11, y: 2 },
        { id: "high", x: 8, y: 11 },
      ],
    },
    { id: "b", label: "B", points: [{ id: "same-x", x: 5, y: 8 }] },
  ];
  const before = JSON.stringify(series);
  assert.deepEqual(
    chartCandidates(series, axis, axis).map((p) => [p.seriesId, p.pointId]),
    [
      ["a", "valid"],
      ["b", "same-x"],
    ],
  );
  assert.equal(JSON.stringify(series), before);
  assert.equal(
    chartPoint(series, { seriesId: "a", pointId: "gap" }),
    undefined,
  );
  assert.equal(chartPoint(series, { seriesId: "b", pointId: "same-x" }).y, 8);
});
test("chart ratios retain explicit nonzero and negative domains", () => {
  assert.equal(chartRatio(0, { ...axis, min: -10, max: 10 }), 0.5);
  assert.equal(chartRatio(5, axis), 0.5);
  assert.equal(validChartAxis({ ...axis, max: 0 }), false);
  assert.equal(validChartAxis({ ...axis, min: NaN }), false);
  assert.equal(validChartAxis(axis), true);
});

test("Widgetbook bundled fixture matches the canonical Web data exactly", async () => {
  const { readFile } = await import("node:fs/promises");
  const canonical = JSON.parse(
    await readFile(
      new URL("../fixtures/chart-line-reference.json", import.meta.url),
      "utf8",
    ),
  );
  const bundled = JSON.parse(
    await readFile(
      new URL(
        "../apps/widgetbook/fixtures/chart-line-reference.json",
        import.meta.url,
      ),
      "utf8",
    ),
  );
  assert.deepEqual(bundled, canonical);
});
