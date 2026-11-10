import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import {
  KRobotHead,
  kRobotHeadShapes,
  kRobotHeadStates,
} from "../dist/data-display/robot-head.js";
import {
  FACES,
  makeGrid,
} from "../dist/data-display/robot-head-engine/tv/faces.js";
import { RobotSim } from "../dist/data-display/robot-head-engine/tv/sim.js";
import {
  createKRobotHeadAudioReader,
  robotAudioUnit,
} from "../dist/data-display/robot-head-audio.js";

test("all shapes and states render server-side without canvas or browser globals", () => {
  for (const shape of kRobotHeadShapes)
    for (const state of kRobotHeadStates) {
      const html = renderToStaticMarkup(
        createElement(KRobotHead, {
          shape,
          state,
          "aria-label": "Roboter aktivieren",
        }),
      );
      assert.match(html, /role="button"/);
      assert.match(html, /tabindex="0"/);
      assert.match(html, /aria-label="Roboter aktivieren"/);
      assert.match(html, /<canvas[^>]+aria-hidden="true"/);
    }
  const image = renderToStaticMarkup(
    createElement(KRobotHead, { interactive: false }),
  );
  assert.match(image, /role="img"/);
  assert.doesNotMatch(image, /tabindex/);
});

const face = (state, audioLevel, time = 1) => {
  const grid = makeGrid(22, 14);
  FACES[state](grid, {
    lookX: 0,
    lookY: 0,
    blink: 0,
    time,
    side: 1,
    seed: 0.42,
    audioLevel,
  });
  return grid.v;
};
test("real silence closes the mouth; loud audio opens it independently of synthetic time", () => {
  assert.deepEqual(face("speaking", 0, 0), face("speaking", 0, 5));
  const quiet = face("speaking", 0);
  const loud = face("speaking", 1);
  assert.ok(loud.reduce((a, b) => a + b, 0) > quiet.reduce((a, b) => a + b, 0));
  assert.notDeepEqual(
    face("speaking", undefined, 0.3),
    face("speaking", undefined, 2.6),
  );
  assert.notDeepEqual(face("listening", 0), face("listening", 1));
});

test("consumer analyser reader handles RMS, gain, clamping and FFT-size changes", () => {
  let amplitude = 0.2;
  const analyser = {
    fftSize: 1024,
    frequencyBinCount: 512,
    getFloatTimeDomainData(array) {
      assert.equal(array.length, this.fftSize);
      array.fill(amplitude);
    },
    getByteFrequencyData(array) {
      assert.equal(array.length, this.frequencyBinCount);
      array.fill(255);
    },
  };
  const read = createKRobotHeadAudioReader(analyser);
  assert.ok(Math.abs(read().level - 0.6) < 1e-6);
  assert.equal(read().bands.length, 12);
  amplitude = 0;
  assert.equal(read().level, 0);
  assert.ok(read().bands.every((x) => x === 0));
  amplitude = 2;
  analyser.fftSize = 2048;
  analyser.frequencyBinCount = 1024;
  assert.equal(read().level, 1);
  for (const value of [NaN, Infinity, -Infinity, -1])
    assert.equal(robotAudioUnit(value), 0);
});

test("same seed and frame schedule reproduce motion; a reaction returns to consumer state", () => {
  const a = new RobotSim(0.42, "listening"),
    b = new RobotSim(0.42, "listening");
  for (let i = 0; i < 240; i++) {
    a.update(1 / 120);
    b.update(1 / 120);
  }
  assert.deepEqual(a.pose, b.pose);
  assert.deepEqual(a.face, b.face);
  a.poke();
  a.update(1 / 120);
  assert.equal(a.shown, "happy");
  assert.equal(a.state, "listening");
  for (let i = 0; i < 240; i++) a.update(1 / 120);
  assert.equal(a.shown, "listening");
});
