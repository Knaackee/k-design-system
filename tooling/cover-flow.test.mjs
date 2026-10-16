import test from "node:test";
import assert from "node:assert/strict";
import {
  clampCoverFlowIndex,
  coverFlowTransform,
} from "../packages/web/ui/src/data-display/cover-flow-layout.ts";

test("selection clamps empty, invalid and out-of-range positions", () => {
  assert.equal(clampCoverFlowIndex(4, 0), 0);
  assert.equal(clampCoverFlowIndex(NaN, 12), 0);
  assert.equal(clampCoverFlowIndex(-2, 12), 0);
  assert.equal(clampCoverFlowIndex(20, 12), 11);
  assert.equal(clampCoverFlowIndex(1.7, 12), 2);
});
test("front cover is straight; neighbors rotate symmetrically into depth", () => {
  assert.equal(
    coverFlowTransform(0, 55, 120, 28),
    "translate(-50%, -50%) translateX(0%) translateZ(0px) rotateY(0deg)",
  );
  assert.match(
    coverFlowTransform(1, 55, 120, 28),
    /translateX\(68%\) translateZ\(-120px\) rotateY\(-55deg\)/,
  );
  assert.match(
    coverFlowTransform(-1, 55, 120, 28),
    /translateX\(-68%\) translateZ\(-120px\) rotateY\(55deg\)/,
  );
  assert.match(coverFlowTransform(2, 55, 120, 28), /translateX\(96%\)/);
});
test("dragging interpolates through the front pose", () => {
  assert.match(
    coverFlowTransform(0.5, 60, 100, 28),
    /translateX\(34%\) translateZ\(-50px\) rotateY\(-30deg\)/,
  );
});

test("frontal neighbors have configurable size and separation", () => {
  assert.match(
    coverFlowTransform(1, 0, 180, 28, 100, 0.72),
    /translateX\(100%\) translateZ\(-180px\) rotateY\(0deg\) scale\(0.72\)/,
  );
  assert.match(
    coverFlowTransform(0, 0, 180, 28, 100, 0.72),
    /translateX\(0%\) translateZ\(0px\) rotateY\(0deg\)$/,
  );
});
