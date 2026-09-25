import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
test("chart family galleries use identical canonical data across platforms", () => {
  const read = (path) =>
    JSON.parse(readFileSync(new URL(path, import.meta.url), "utf8"));
  const canonical = read("../fixtures/chart-families.json");
  assert.deepEqual(
    read("../apps/widgetbook/fixtures/chart-families.json"),
    canonical,
  );
  assert.equal(canonical.series.length, 2);
  for (const series of canonical.series) {
    assert.equal(series.points.length, canonical.categories.length);
    assert.deepEqual(
      series.points.map((point) => point.x),
      [0, 1, 2, 3, 4, 5],
    );
  }
  assert.equal(
    canonical.segments.reduce((sum, segment) => sum + segment.value, 0),
    100,
  );
});
