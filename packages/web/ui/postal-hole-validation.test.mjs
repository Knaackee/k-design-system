import assert from "node:assert/strict";
import test from "node:test";
import { validateMapZone } from "./dist/maps/map-zone-geometry.js";

const outer = [
  [0, 0],
  [4, 0],
  [4, 4],
  [0, 4],
];
const zone = (hole, boundary = outer) => ({
  id: "postal",
  name: "Postal",
  kind: "postal",
  coordinates: boundary,
  polygons: [{ outer: boundary, holes: [hole] }],
});

test("a postal hole may touch its outer ring at one point", () => {
  assert.equal(
    validateMapZone(
      zone([
        [0, 2],
        [1, 1],
        [1, 3],
      ]),
    ),
    null,
  );
});

test("postal holes still reject crossings and shared boundary edges", () => {
  assert.equal(
    validateMapZone(
      zone([
        [-1, 2],
        [1, 1],
        [1, 3],
      ]),
    )?.code,
    "self-intersection",
  );
  assert.equal(
    validateMapZone(
      zone([
        [0, 1],
        [1, 1],
        [1, 3],
        [0, 3],
      ]),
    )?.code,
    "self-intersection",
  );
});

test("a hole edge cannot leave a concave outer ring through boundary vertices", () => {
  const concave = [
    [0, 0],
    [4, 0],
    [4, 4],
    [2, 2],
    [0, 4],
  ];
  const outsideInterval = [
    [1, 3],
    [3, 3],
    [2, 1],
  ];
  assert.equal(
    validateMapZone(zone(outsideInterval, concave))?.code,
    "self-intersection",
  );
});
