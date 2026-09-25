import test from "node:test";
import assert from "node:assert/strict";
import {
  validCandles,
  candleSpan,
  nearestCandle,
} from "../packages/web/ui/src/charts/candle-model.ts";
const candle = (id, x, patch = {}) => ({
  id,
  x,
  open: 10,
  high: 14,
  low: 8,
  close: 12,
  ...patch,
});
test("OHLC validation rejects impossible and nonfinite prices but preserves Doji and caller data", () => {
  const data = [
    candle("later", 2),
    candle("doji", 1, { close: 10 }),
    candle("bad", 0, { high: 9 }),
    candle("nan", 3, { open: NaN }),
    candle("low", 4, { low: 11 }),
  ];
  const before = structuredClone(data);
  assert.deepEqual(
    validCandles(data).map((c) => c.id),
    ["doji", "later"],
  );
  assert.deepEqual(data, before);
});
test("visible range is inclusive and nearest-x ties select the earlier candle", () => {
  const data = validCandles([candle("c", 3), candle("a", 1), candle("b", 2)], {
    min: 1,
    max: 2,
  });
  assert.deepEqual(
    data.map((c) => c.id),
    ["a", "b"],
  );
  assert.equal(nearestCandle(data, 1.5).id, "a");
  assert.equal(nearestCandle(data, 100).id, "b");
  assert.equal(nearestCandle([], 0), undefined);
});
test("candle width uses minimum distinct spacing and a single-candle fallback", () => {
  assert.equal(
    candleSpan([candle("a", 0), candle("b", 2), candle("c", 5)], 10),
    1.44,
  );
  assert.equal(
    candleSpan([candle("a", 2), candle("b", 2)], 10),
    7.199999999999999,
  );
});
