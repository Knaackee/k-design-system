import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KCallBar } from "../dist/chat/call-bar.js";

const heights = (microphoneLevel, muted = false) => {
  const html = renderToStaticMarkup(
    h(KCallBar, {
      name: "Agent",
      status: "Listening",
      duration: "00:12",
      muted,
      microphoneLevel,
      onMutedChange() {},
    }),
  );
  const waveform = html.match(
    /<span class="k-call-bar__waveform"[^>]*>(.*)<\/span><span class="k-call-bar__duration"/s,
  )?.[1];
  assert.ok(waveform);
  return [...waveform.matchAll(/height:([\d.]+)px/g)].map((match) =>
    Number(match[1]),
  );
};

test("call bar maps quiet raw microphone amplitude to a visible level", () => {
  assert.ok(Math.max(...heights(0.02)) > 10);
});

test("call bar keeps zero, mute, and invalid levels at baseline", () => {
  for (const level of [0, -1, Number.NaN, Number.POSITIVE_INFINITY]) {
    assert.deepEqual(new Set(heights(level)), new Set([3]));
  }
  assert.deepEqual(new Set(heights(0.8, true)), new Set([3]));
});

test("call bar clips full-scale microphone amplitude", () => {
  assert.deepEqual(heights(2), heights(1));
  assert.ok(Math.max(...heights(2)) > 23.9);
});
