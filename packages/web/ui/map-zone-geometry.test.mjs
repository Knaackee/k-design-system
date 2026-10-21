import assert from "node:assert/strict";
import test from "node:test";
import {
  createCircleCoordinates,
  distanceKm,
  mapZoneCenter,
  moveMapZone,
  validateMapZone,
  zoneHasSelfIntersection,
  zonesOverlap,
} from "./dist/maps/map-zone-geometry.js";
import {
  planMapZoneCommit,
  subtractZoneGeometry,
} from "./dist/maps/map-zone-boolean.js";

const rectangle = (west, south, east, north) => [
  [west, south],
  [east, south],
  [east, north],
  [west, north],
];

test("validates an 8580-point ring without changing its geometry", () => {
  const points = Array.from({ length: 8580 }, (_, index) => {
    const angle = (index / 8580) * Math.PI * 2;
    return [Math.cos(angle), Math.sin(angle)];
  });
  assert.equal(points.length, 8580);
  assert.equal(zoneHasSelfIntersection(points), false);
  assert.equal(points.length, 8580);
});

test("creates and moves a circle without losing its exact radius contract", () => {
  const center = [13.397, 52.5205];
  const circle = {
    id: "radius-1",
    name: "Radius",
    kind: "circle",
    circle: { center, radiusKm: 2.5 },
    coordinates: createCircleCoordinates(center, 2.5),
  };
  assert.equal(circle.coordinates.length, 48);
  assert.ok(
    circle.coordinates.every(
      (point) => Math.abs(distanceKm(center, point) - 2.5) < 1e-8,
    ),
  );
  const moved = moveMapZone(circle, mapZoneCenter(circle), [13.41, 52.53]);
  assert.deepEqual(moved.circle.center, [13.41, 52.53]);
  assert.ok(
    moved.coordinates.every(
      (point) => Math.abs(distanceKm(moved.circle.center, point) - 2.5) < 1e-8,
    ),
  );
});

test("rejects unsafe circle helper inputs", () => {
  assert.throws(() => createCircleCoordinates([181, 0], 2), RangeError);
  assert.throws(() => createCircleCoordinates([0, 0], 0), RangeError);
  assert.throws(() => createCircleCoordinates([0, 0], 2, 361), RangeError);
});

test("allows a shared boundary but rejects positive-area overlap", () => {
  const west = rectangle(13.382, 52.515, 13.397, 52.526);
  const east = rectangle(13.397, 52.515, 13.412, 52.526);
  assert.equal(zonesOverlap(west, east), false);
  assert.equal(
    zonesOverlap(west, rectangle(13.39, 52.515, 13.405, 52.526)),
    true,
  );
});

test("rejects containment and coincident polygons", () => {
  const outer = rectangle(13.38, 52.51, 13.42, 52.54);
  const inner = rectangle(13.39, 52.52, 13.4, 52.53);
  assert.equal(zonesOverlap(outer, inner), true);
  assert.equal(zonesOverlap(outer, [...outer].reverse()), true);
});

test("detects containment when a T-junction hides whole-edge midpoint overlap", () => {
  const extended = [
    [0, 0],
    [1, 0],
    [1, -1],
    [2, 0],
    [2, 2],
    [0, 2],
  ];
  assert.equal(zonesOverlap(extended, rectangle(0, 0, 2, 2)), true);
});

test("detects crossings and invalid rings", () => {
  assert.equal(
    zonesOverlap(rectangle(13.38, 52.51, 13.4, 52.53), [
      [13.39, 52.5],
      [13.41, 52.52],
      [13.39, 52.54],
      [13.37, 52.52],
    ]),
    true,
  );
  assert.equal(
    zoneHasSelfIntersection([
      [13.38, 52.51],
      [13.4, 52.53],
      [13.38, 52.53],
      [13.4, 52.51],
    ]),
    true,
  );
  assert.equal(
    zoneHasSelfIntersection([
      [0, 0],
      [1, 0],
      [2, 0],
    ]),
    true,
  );
});

test("ignores transient consecutive duplicates but keeps bowties invalid", () => {
  const duplicate = [
    [0, 0],
    [2, 0],
    [2, 0],
    [2, 2],
    [0, 2],
    [0, 0],
  ];
  assert.equal(
    validateMapZone({
      id: "duplicate",
      name: "Duplicate",
      coordinates: duplicate,
    }),
    null,
  );
  assert.equal(
    validateMapZone({
      id: "bowtie",
      name: "Bowtie",
      coordinates: [
        [0, 0],
        [2, 2],
        [0, 2],
        [2, 0],
      ],
    }).code,
    "self-intersection",
  );
  assert.equal(
    validateMapZone({
      id: "collapsed",
      name: "Collapsed",
      coordinates: [
        [0, 0],
        [0, 0],
        [0, 0],
      ],
    }).code,
    "self-intersection",
  );
});

test("retains proper orientation at sub-meter coordinate scales", () => {
  const first = [
    [9.9999995, 49.9999995],
    [10.0000005, 49.9999995],
    [10.0000005, 50.0000005],
    [9.9999995, 50.0000005],
  ];
  const second = [
    [9.999998629401949, 49.999999046718514],
    [9.999999553281482, 49.99999942940195],
    [9.99999917059805, 50.00000035328148],
    [9.999998246718517, 49.99999997059804],
  ];
  assert.equal(zonesOverlap(first, second), true);
});

test("returns stable validation codes and rejects antimeridian rings", () => {
  assert.equal(
    validateMapZone({
      id: "a",
      name: "A",
      coordinates: [
        [0, 0],
        [1, 0],
      ],
    }).code,
    "minimum-vertices",
  );
  assert.equal(
    validateMapZone({
      id: "a",
      name: "A",
      coordinates: [
        [179, 10],
        [-179, 10],
        [-179, 11],
        [179, 11],
      ],
    }).code,
    "invalid-coordinate",
  );
  assert.equal(
    validateMapZone({
      id: "candidate",
      name: "Candidate",
      coordinates: rectangle(1, 1, 3, 3),
    }),
    null,
  );
});

test("public validation can still reject overlap when neighbors are supplied", () => {
  const existing = {
    id: "existing",
    name: "Existing",
    coordinates: rectangle(0, 0, 2, 2),
  };
  assert.equal(
    validateMapZone(
      {
        id: "candidate",
        name: "Candidate",
        coordinates: rectangle(1, 1, 3, 3),
      },
      [existing],
    ).code,
    "zone-overlap",
  );
});

test("rejects holes outside their outer ring and overlapping polygon parts", () => {
  assert.equal(
    validateMapZone({
      id: "bad-hole",
      name: "Bad hole",
      coordinates: rectangle(0, 0, 4, 4),
      polygons: [
        {
          outer: rectangle(0, 0, 4, 4),
          holes: [rectangle(3, 3, 5, 5)],
        },
      ],
    }).code,
    "self-intersection",
  );
  assert.equal(
    validateMapZone({
      id: "bad-parts",
      name: "Bad parts",
      coordinates: rectangle(0, 0, 4, 4),
      polygons: [
        { outer: rectangle(0, 0, 4, 4) },
        { outer: rectangle(2, 2, 6, 6) },
      ],
    }).code,
    "self-intersection",
  );
});

test("candidate wins by subtracting partial overlap while properties survive", () => {
  const existing = {
    id: "existing",
    name: "Existing",
    color: "#123456",
    settings: { travelCostOptionId: "mileage" },
    coordinates: rectangle(0, 0, 4, 4),
  };
  const candidate = {
    id: "candidate",
    name: "Candidate",
    coordinates: rectangle(2, 0, 6, 4),
  };
  const plan = planMapZoneCommit([existing], candidate);
  assert.deepEqual(plan.impacts, [
    { zoneId: "existing", zoneName: "Existing", outcome: "reduced" },
  ]);
  assert.equal(plan.zones[0].color, "#123456");
  assert.deepEqual(plan.zones[0].settings, existing.settings);
  assert.deepEqual(plan.zones[0].coordinates, rectangle(0, 0, 2, 4));
  assert.equal(plan.zones[1].id, "candidate");
});

test("full containment removes the losing zone and keeps an undo snapshot", () => {
  const existing = {
    id: "contained",
    name: "Contained",
    coordinates: rectangle(1, 1, 2, 2),
  };
  const winner = {
    id: "winner",
    name: "Winner",
    coordinates: rectangle(0, 0, 3, 3),
  };
  const plan = planMapZoneCommit([existing], winner);
  assert.deepEqual(
    plan.zones.map((zone) => zone.id),
    ["winner"],
  );
  assert.equal(plan.impacts[0].outcome, "removed");
  assert.deepEqual(plan.previousZones, [existing]);
  assert.notEqual(plan.previousZones[0], existing);
});

test("subtraction supports multipart splits and holes", () => {
  const subject = {
    id: "subject",
    name: "Subject",
    coordinates: rectangle(0, 0, 6, 2),
  };
  const splitter = {
    id: "splitter",
    name: "Splitter",
    coordinates: rectangle(2, -1, 4, 3),
  };
  assert.equal(subtractZoneGeometry(subject, splitter).length, 2);

  const hole = subtractZoneGeometry(
    { ...subject, coordinates: rectangle(0, 0, 10, 10) },
    { ...splitter, coordinates: rectangle(3, 3, 7, 7) },
  );
  assert.equal(hole.length, 1);
  assert.equal(hole[0].holes.length, 1);
  assert.deepEqual(
    new Set(hole[0].holes[0].map(String)),
    new Set(rectangle(3, 3, 7, 7).map(String)),
  );
});

test("shared edges and disjoint reversed rings preserve unaffected identity", () => {
  const circle = {
    id: "circle",
    name: "Circle",
    kind: "circle",
    circle: { center: [0, 0], radiusKm: 1 },
    coordinates: createCircleCoordinates([0, 0], 1),
  };
  const disjoint = {
    id: "far",
    name: "Far",
    coordinates: rectangle(10, 10, 11, 11).reverse(),
  };
  const plan = planMapZoneCommit([circle], disjoint);
  assert.equal(plan.impacts.length, 0);
  assert.equal(plan.zones[0], circle);
  assert.equal(plan.zones[0].kind, "circle");

  const touching = {
    id: "touching",
    name: "Touching",
    coordinates: rectangle(11, 10, 12, 11),
  };
  const touchingPlan = planMapZoneCommit([disjoint], touching);
  assert.equal(touchingPlan.impacts.length, 0);
  assert.equal(touchingPlan.zones[0], disjoint);
});
