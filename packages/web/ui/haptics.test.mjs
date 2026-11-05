import test from "node:test";
import assert from "node:assert/strict";
import {
  KHapticController,
  kHapticPatterns,
} from "./dist/feedback/haptics-controller.js";

function fixture(options = {}) {
  const calls = [];
  let time = 0;
  const haptics = new KHapticController({
    vibrate: (pattern) => {
      calls.push(pattern);
      return true;
    },
    now: () => time,
    ...options,
  });
  return { calls, haptics, advance: (ms) => (time += ms) };
}

test("off by default, then one cue per interval", () => {
  const { haptics, calls, advance } = fixture();
  haptics.perform("selection");
  assert.equal(calls.length, 0);
  haptics.setEnabled(true);
  haptics.perform("selection");
  haptics.perform("selection");
  assert.deepEqual(calls, [8]);
  advance(60);
  haptics.perform("success");
  assert.deepEqual(calls.at(-1), [10, 60, 14]);
});

test("hidden page, missing API and failures stay silent", () => {
  const { haptics, calls } = fixture({ enabled: true });
  haptics.setActive(false);
  haptics.perform("error");
  assert.equal(calls.length, 0);
  const unsupported = new KHapticController({ enabled: true });
  assert.equal(unsupported.isSupported, false);
  assert.doesNotThrow(() => unsupported.perform("error"));
  const failing = new KHapticController({
    enabled: true,
    vibrate: () => {
      throw new Error("blocked");
    },
  });
  assert.doesNotThrow(() => failing.perform("light"));
});

test("cues match Flutter's set", () => {
  assert.deepEqual(Object.keys(kHapticPatterns), [
    "selection",
    "light",
    "medium",
    "heavy",
    "success",
    "warning",
    "error",
  ]);
});
