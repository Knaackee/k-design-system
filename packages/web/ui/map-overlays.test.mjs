import test from "node:test";
import assert from "node:assert/strict";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KMap } from "./dist/patterns/map.js";
import { overlayCoordinates, routeParts } from "./dist/maps/map-overlays.js";
import { edgePanVelocity, resolvePinDrag } from "./dist/maps/map-pin-drag.js";

const pin = { id: "a", label: "Start", position: [13, 52] };
const route = {
  id: "a",
  coordinates: [
    [13, 52],
    [14, 53],
  ],
};

test("embedded maps opt into a shared outer surface without changing standalone defaults", () => {
  const render = (embedded) =>
    renderToStaticMarkup(
      React.createElement(KMap, {
        mapStyle: { version: 8, sources: {}, layers: [] },
        center: [13, 52],
        embedded,
      }),
    );
  assert.doesNotMatch(render(), /data-embedded/);
  assert.doesNotMatch(render(false), /data-embedded/);
  assert.match(render(true), /<section class="k-map" data-embedded="true"/);
  assert.match(render(true), /k-map__controls/);
});

test("edge pan stays still inside the safe area and accelerates toward bounds", () => {
  assert.deepEqual(
    edgePanVelocity({ x: 160, y: 120 }, { width: 320, height: 240 }, 48, 180),
    { x: 0, y: 0 },
  );
  const edge = edgePanVelocity(
    { x: 12, y: 230 },
    { width: 320, height: 240 },
    48,
    180,
  );
  assert.ok(edge.x < 0);
  assert.ok(edge.y > 0);
  assert.ok(Math.abs(edge.x) <= 180 && Math.abs(edge.y) <= 180);
  assert.equal(resolvePinDrag().edgePan, null);
  assert.deepEqual(resolvePinDrag({ edgePan: {} }).edgePan, {
    padding: 56,
    maxSpeed: 180,
    zoomOutPerSecond: 0.18,
    minZoom: 8,
  });
});

test("fit geometry includes all pins and route points; empty overlays are valid", () => {
  assert.deepEqual(overlayCoordinates([pin], [route]), [
    [13, 52],
    [13, 52],
    [14, 53],
  ]);
  assert.deepEqual(overlayCoordinates([], []), []);
});
test("invalid identities, inaccessible pins and invalid geometry are rejected", () => {
  assert.throws(() => overlayCoordinates([pin, pin], []), /unique/);
  assert.throws(() => overlayCoordinates([], [route, route]), /unique/);
  assert.throws(() => overlayCoordinates([{ ...pin, label: "" }], []), /label/);
  assert.throws(
    () => overlayCoordinates([{ ...pin, position: [NaN, 52] }], []),
    /WGS84/,
  );
  assert.throws(
    () =>
      overlayCoordinates(
        [],
        [
          {
            ...route,
            coordinates: [
              [181, 0],
              [0, 0],
            ],
          },
        ],
      ),
    /WGS84/,
  );
  assert.throws(
    () => overlayCoordinates([], [{ ...route, coordinates: [] }]),
    /two/,
  );
  assert.throws(() => overlayCoordinates([{ ...pin, size: -1 }], []), /size/);
  assert.throws(
    () => overlayCoordinates([], [{ ...route, width: Infinity }]),
    /width/,
  );
});

test("traffic segments retain endpoints and inherited width", () => {
  const value = {
    id: "r",
    coordinates: [
      [13, 52],
      [14, 52],
      [15, 52],
      [16, 52],
    ],
    color: "#123456",
    width: 6,
    segments: [{ id: "jam", startIndex: 1, endIndex: 2, traffic: "congested" }],
  };
  const parts = routeParts(value);
  assert.equal(parts.length, 2);
  assert.deepEqual(parts[0].coordinates, value.coordinates);
  assert.deepEqual(parts[1].coordinates, [
    [14, 52],
    [15, 52],
  ]);
  assert.equal(parts[1].color, undefined);
  assert.equal(parts[1].traffic, "congested");
  assert.equal(parts[1].width, 6);
  assert.equal(parts[1].routeId, "r");
});
test("segment ranges reject overlaps and out-of-range or duplicate entries", () => {
  const value = {
    id: "r",
    coordinates: [
      [0, 0],
      [1, 1],
      [2, 2],
      [3, 3],
    ],
  };
  assert.throws(
    () =>
      routeParts({
        ...value,
        segments: [{ id: "x", startIndex: 0, endIndex: 4 }],
      }),
    /indices/,
  );
  assert.throws(
    () =>
      routeParts({
        ...value,
        segments: [
          { id: "x", startIndex: 0, endIndex: 2 },
          { id: "y", startIndex: 1, endIndex: 3 },
        ],
      }),
    /indices/,
  );
  assert.throws(
    () =>
      routeParts({
        ...value,
        segments: [
          { id: "x", startIndex: 0, endIndex: 1 },
          { id: "x", startIndex: 1, endIndex: 2 },
        ],
      }),
    /unique/,
  );
  assert.equal(
    routeParts({
      ...value,
      segments: [
        { id: "x", startIndex: 0, endIndex: 1 },
        { id: "y", startIndex: 1, endIndex: 3 },
      ],
    }).length,
    3,
  );
});

test("pin drag defaults and consumer overrides remain bounded", () => {
  assert.deepEqual(resolvePinDrag(), {
    activation: "drag",
    longPressMs: 400,
    scale: 1.15,
    durationMs: 160,
    edgePan: null,
  });
  assert.equal(
    resolvePinDrag({ activation: "longPress", durationMs: 0, scale: 1 })
      .durationMs,
    0,
  );
  assert.throws(() => resolvePinDrag({ scale: 0 }), /scale/);
  assert.throws(() => resolvePinDrag({ longPressMs: -1 }), /durations/);
  assert.throws(() => resolvePinDrag({ durationMs: NaN }), /durations/);
  assert.throws(() => resolvePinDrag({ activation: "unknown" }), /activation/);
});
