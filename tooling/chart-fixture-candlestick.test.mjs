import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

test("candlestick galleries share valid rising, falling and doji market data", () => {
  const read = (path) =>
    JSON.parse(readFileSync(new URL(path, import.meta.url), "utf8"));
  const fixture = read("../fixtures/chart-candlestick.json");
  assert.deepEqual(
    read("../apps/widgetbook/fixtures/chart-candlestick.json"),
    fixture,
  );
  assert.equal(fixture.categories.length, fixture.candles.length);
  assert.equal(
    new Set(fixture.candles.map((c) => c.id)).size,
    fixture.candles.length,
  );
  for (const c of fixture.candles) {
    assert.ok(c.low <= Math.min(c.open, c.close));
    assert.ok(c.high >= Math.max(c.open, c.close));
  }
  assert.ok(fixture.candles.some((c) => c.close > c.open));
  assert.ok(fixture.candles.some((c) => c.close < c.open));
  assert.ok(fixture.candles.some((c) => c.close === c.open));
});
