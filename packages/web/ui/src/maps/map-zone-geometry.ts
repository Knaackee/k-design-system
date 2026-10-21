import {
  withZonePolygons,
  zonePolygons,
  zonePositions,
} from "./map-zone-shape.js";

import type {
  KMapPosition,
  KMapZone,
  KMapZoneValidationError,
} from "./map-zone-types.js";

export type {
  KMapPolygon,
  KMapPosition,
  KMapPostalArea,
  KMapZone,
  KMapZoneAvailability,
  KMapZoneSettings,
  KMapZoneWorkingDay,
  KMapZoneTravelCost,
  KMapZoneValidationCode,
  KMapZoneValidationError,
} from "./map-zone-types.js";

const COORDINATE_EPSILON = 1e-12;

const EARTH_RADIUS_KM = 6371.0088;

export function createCircleCoordinates(
  center: KMapPosition,

  radiusKm: number,

  steps = 48,
): KMapPosition[] {
  if (
    !Number.isFinite(center[0]) ||
    !Number.isFinite(center[1]) ||
    Math.abs(center[0]) > 180 ||
    Math.abs(center[1]) > 90
  )
    throw new RangeError("Circle center must be a valid WGS84 position.");

  if (!Number.isFinite(radiusKm) || radiusKm <= 0 || radiusKm > 20_000)
    throw new RangeError("Circle radius must be positive and finite.");

  if (!Number.isInteger(steps) || steps < 12 || steps > 360)
    throw new RangeError("Circle geometry needs between 12 and 360 steps.");

  const latitude = (center[1] * Math.PI) / 180;

  const longitude = (center[0] * Math.PI) / 180;

  const angularDistance = radiusKm / EARTH_RADIUS_KM;

  return Array.from({ length: steps }, (_, index) => {
    const bearing = (index / steps) * Math.PI * 2;

    const destinationLatitude = Math.asin(
      Math.sin(latitude) * Math.cos(angularDistance) +
        Math.cos(latitude) * Math.sin(angularDistance) * Math.cos(bearing),
    );

    const destinationLongitude =
      longitude +
      Math.atan2(
        Math.sin(bearing) * Math.sin(angularDistance) * Math.cos(latitude),

        Math.cos(angularDistance) -
          Math.sin(latitude) * Math.sin(destinationLatitude),
      );

    return [
      (((destinationLongitude * 180) / Math.PI + 540) % 360) - 180,

      (destinationLatitude * 180) / Math.PI,
    ];
  });
}

export function distanceKm(first: KMapPosition, second: KMapPosition) {
  const lat1 = (first[1] * Math.PI) / 180;

  const lat2 = (second[1] * Math.PI) / 180;

  const deltaLat = lat2 - lat1;

  const deltaLng = ((second[0] - first[0]) * Math.PI) / 180;

  const value =
    Math.sin(deltaLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) ** 2;

  const clamped = Math.max(0, Math.min(1, value));

  return (
    EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(clamped), Math.sqrt(1 - clamped))
  );
}

export function mapZoneCenter(zone: KMapZone): KMapPosition {
  if (zone.circle) return [...zone.circle.center];

  const positions = zonePositions(zone);

  const total = positions.reduce(
    (sum, point) => [sum[0] + point[0], sum[1] + point[1]] as KMapPosition,

    [0, 0],
  );

  return positions.length
    ? [total[0] / positions.length, total[1] / positions.length]
    : [0, 0];
}

export function moveMapZone(
  zone: KMapZone,

  from: KMapPosition,

  to: KMapPosition,
): KMapZone {
  const delta: KMapPosition = [to[0] - from[0], to[1] - from[1]];

  const circle = zone.circle
    ? {
        ...zone.circle,

        center: [
          zone.circle.center[0] + delta[0],

          zone.circle.center[1] + delta[1],
        ] as KMapPosition,
      }
    : undefined;

  if (circle)
    return {
      ...zone,

      coordinates: createCircleCoordinates(circle.center, circle.radiusKm),

      polygons: undefined,

      circle,
    };

  return withZonePolygons(
    zone,

    zonePolygons(zone).map((polygon) => ({
      outer: polygon.outer.map(([lng, lat]) => [
        lng + delta[0],

        lat + delta[1],
      ]),

      holes: polygon.holes?.map((ring) =>
        ring.map(([lng, lat]) => [lng + delta[0], lat + delta[1]]),
      ),
    })),
  );
}

function cross(a: KMapPosition, b: KMapPosition, c: KMapPosition) {
  return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}

function orientation(a: KMapPosition, b: KMapPosition, c: KMapPosition) {
  const value = cross(a, b, c);

  const scale = Math.max(
    Math.abs(b[0] - a[0]),

    Math.abs(b[1] - a[1]),

    Math.abs(c[0] - a[0]),

    Math.abs(c[1] - a[1]),

    1e-12,
  );

  const tolerance = Number.EPSILON * 64 * scale * scale;

  return Math.abs(value) <= tolerance ? 0 : Math.sign(value);
}

function samePoint(a: KMapPosition, b: KMapPosition) {
  return (
    Math.abs(a[0] - b[0]) <= COORDINATE_EPSILON &&
    Math.abs(a[1] - b[1]) <= COORDINATE_EPSILON
  );
}

function validationRing(points: readonly KMapPosition[]) {
  const result: KMapPosition[] = [];

  for (const point of points) {
    if (!result.length || !samePoint(result[result.length - 1], point))
      result.push(point);
  }

  while (result.length > 1 && samePoint(result[0], result[result.length - 1]))
    result.pop();

  return result;
}

function pointOnSegment(point: KMapPosition, a: KMapPosition, b: KMapPosition) {
  return (
    orientation(a, b, point) === 0 &&
    point[0] >= Math.min(a[0], b[0]) - COORDINATE_EPSILON &&
    point[0] <= Math.max(a[0], b[0]) + COORDINATE_EPSILON &&
    point[1] >= Math.min(a[1], b[1]) - COORDINATE_EPSILON &&
    point[1] <= Math.max(a[1], b[1]) + COORDINATE_EPSILON
  );
}

function segmentsIntersect(
  a: KMapPosition,

  b: KMapPosition,

  c: KMapPosition,

  d: KMapPosition,
) {
  const abC = orientation(a, b, c);

  const abD = orientation(a, b, d);

  const cdA = orientation(c, d, a);

  const cdB = orientation(c, d, b);

  return (
    (abC !== 0 &&
      abD !== 0 &&
      abC !== abD &&
      cdA !== 0 &&
      cdB !== 0 &&
      cdA !== cdB) ||
    (abC === 0 && pointOnSegment(c, a, b)) ||
    (abD === 0 && pointOnSegment(d, a, b)) ||
    (cdA === 0 && pointOnSegment(a, c, d)) ||
    (cdB === 0 && pointOnSegment(b, c, d))
  );
}

function segmentsProperlyCross(
  a: KMapPosition,

  b: KMapPosition,

  c: KMapPosition,

  d: KMapPosition,
) {
  const abC = orientation(a, b, c);

  const abD = orientation(a, b, d);

  const cdA = orientation(c, d, a);

  const cdB = orientation(c, d, b);

  return (
    abC !== 0 &&
    abD !== 0 &&
    abC !== abD &&
    cdA !== 0 &&
    cdB !== 0 &&
    cdA !== cdB
  );
}

function invalidHoleBoundaryContact(
  outer: readonly KMapPosition[],

  hole: readonly KMapPosition[],
) {
  const contacts: KMapPosition[] = [];

  const addContact = (point: KMapPosition) => {
    if (!contacts.some((contact) => samePoint(contact, point)))
      contacts.push(point);
  };

  for (let outerIndex = 0; outerIndex < outer.length; outerIndex += 1) {
    const outerStart = outer[outerIndex];

    const outerEnd = outer[(outerIndex + 1) % outer.length];

    for (let holeIndex = 0; holeIndex < hole.length; holeIndex += 1) {
      const holeStart = hole[holeIndex];

      const holeEnd = hole[(holeIndex + 1) % hole.length];

      if (segmentsProperlyCross(outerStart, outerEnd, holeStart, holeEnd))
        return true;

      if (pointOnSegment(outerStart, holeStart, holeEnd))
        addContact(outerStart);

      if (pointOnSegment(outerEnd, holeStart, holeEnd)) addContact(outerEnd);

      if (pointOnSegment(holeStart, outerStart, outerEnd))
        addContact(holeStart);

      if (pointOnSegment(holeEnd, outerStart, outerEnd)) addContact(holeEnd);

      if (contacts.length > 1) return true;
    }
  }

  return false;
}

function signedArea(points: readonly KMapPosition[]) {
  const [originLng, originLat] = points[0] ?? [0, 0];

  return (
    points.reduce((area, point, index) => {
      const next = points[(index + 1) % points.length];

      const x = point[0] - originLng;

      const y = point[1] - originLat;

      const nextX = next[0] - originLng;

      const nextY = next[1] - originLat;

      return area + x * nextY - nextX * y;
    }, 0) / 2
  );
}

function parameterOnSegment(
  point: KMapPosition,

  start: KMapPosition,

  end: KMapPosition,
) {
  const deltaLng = end[0] - start[0];

  const deltaLat = end[1] - start[1];

  return Math.abs(deltaLng) >= Math.abs(deltaLat)
    ? (point[0] - start[0]) / deltaLng
    : (point[1] - start[1]) / deltaLat;
}

function hasBoundaryIntervalInside(
  polygon: readonly KMapPosition[],

  other: readonly KMapPosition[],
) {
  for (let index = 0; index < polygon.length; index += 1) {
    const start = polygon[index];

    const end = polygon[(index + 1) % polygon.length];

    const parameters = [0, 1];

    for (const point of other) {
      if (pointOnSegment(point, start, end))
        parameters.push(
          Math.max(0, Math.min(1, parameterOnSegment(point, start, end))),
        );
    }

    parameters.sort((a, b) => a - b);

    const unique = parameters.filter(
      (value, parameterIndex) =>
        parameterIndex === 0 ||
        Math.abs(value - parameters[parameterIndex - 1]) > 1e-12,
    );

    for (
      let parameterIndex = 0;
      parameterIndex < unique.length - 1;
      parameterIndex += 1
    ) {
      const parameter =
        (unique[parameterIndex] + unique[parameterIndex + 1]) / 2;

      const sample: KMapPosition = [
        start[0] + (end[0] - start[0]) * parameter,

        start[1] + (end[1] - start[1]) * parameter,
      ];

      if (pointLocation(sample, other) === "inside") return true;
    }
  }

  return false;
}

function pointLocation(point: KMapPosition, polygon: readonly KMapPosition[]) {
  let inside = false;

  for (let index = 0; index < polygon.length; index += 1) {
    const a = polygon[index];

    const b = polygon[(index + 1) % polygon.length];

    if (pointOnSegment(point, a, b)) return "boundary" as const;

    if (
      a[1] > point[1] !== b[1] > point[1] &&
      point[0] < ((b[0] - a[0]) * (point[1] - a[1])) / (b[1] - a[1]) + a[0]
    )
      inside = !inside;
  }

  return inside ? ("inside" as const) : ("outside" as const);
}

export function zoneHasSelfIntersection(points: readonly KMapPosition[]) {
  const ring = validationRing(points);

  if (ring.length < 3) return true;

  const segments = ring.map((start, index) => {
    const end = ring[(index + 1) % ring.length];

    return {
      index,

      start,

      end,

      minX: Math.min(start[0], end[0]),

      maxX: Math.max(start[0], end[0]),

      minY: Math.min(start[1], end[1]),

      maxY: Math.max(start[1], end[1]),
    };
  });

  const ordered = [...segments].sort(
    (first, second) => first.minX - second.minX,
  );

  for (let firstOffset = 0; firstOffset < ordered.length; firstOffset += 1) {
    const first = ordered[firstOffset];

    for (
      let secondOffset = firstOffset + 1;
      secondOffset < ordered.length;
      secondOffset += 1
    ) {
      const second = ordered[secondOffset];

      if (second.minX > first.maxX) break;

      const adjacent =
        (first.index + 1) % ring.length === second.index ||
        (second.index + 1) % ring.length === first.index;

      if (
        !adjacent &&
        second.maxY >= first.minY &&
        second.minY <= first.maxY &&
        segmentsIntersect(first.start, first.end, second.start, second.end)
      )
        return true;
    }
  }

  return Math.abs(signedArea(ring)) <= Number.EPSILON;
}

export function zonesOverlap(
  first: readonly KMapPosition[],

  second: readonly KMapPosition[],
) {
  for (let firstIndex = 0; firstIndex < first.length; firstIndex += 1) {
    const firstNext = first[(firstIndex + 1) % first.length];

    for (let secondIndex = 0; secondIndex < second.length; secondIndex += 1) {
      const secondNext = second[(secondIndex + 1) % second.length];

      if (
        segmentsProperlyCross(
          first[firstIndex],

          firstNext,

          second[secondIndex],

          secondNext,
        )
      )
        return true;
    }
  }

  if (first.some((point) => pointLocation(point, second) === "inside"))
    return true;

  if (second.some((point) => pointLocation(point, first) === "inside"))
    return true;

  if (hasBoundaryIntervalInside(first, second)) return true;

  if (hasBoundaryIntervalInside(second, first)) return true;

  // Coincident polygons have no strictly-inside vertex, while still sharing area.

  const firstOnBoundary = first.every(
    (point) => pointLocation(point, second) === "boundary",
  );

  const secondOnBoundary = second.every(
    (point) => pointLocation(point, first) === "boundary",
  );

  return (
    firstOnBoundary &&
    secondOnBoundary &&
    Math.abs(Math.abs(signedArea(first)) - Math.abs(signedArea(second))) <=
      Math.max(
        Math.abs(signedArea(first)),

        Math.abs(signedArea(second)),

        1e-12,
      ) *
        1e-12
  );
}

export function validateMapZone(
  zone: KMapZone,

  otherZones: readonly KMapZone[] = [],
): KMapZoneValidationError | null {
  const polygons = zonePolygons(zone);

  const rings = polygons.flatMap((polygon) => [
    polygon.outer,

    ...(polygon.holes ?? []),
  ]);

  if (
    rings

      .flat()

      .some(
        ([lng, lat]) =>
          !Number.isFinite(lng) ||
          !Number.isFinite(lat) ||
          Math.abs(lng) > 180 ||
          Math.abs(lat) > 90,
      )
  )
    return {
      code: "invalid-coordinate",

      message: "Zone coordinates must be valid WGS84 positions.",

      zoneId: zone.id,
    };

  const longitudes = rings.flat().map(([lng]) => lng);

  if (
    longitudes.length &&
    Math.max(...longitudes) - Math.min(...longitudes) > 180
  )
    return {
      code: "invalid-coordinate",

      message: "Zones crossing the antimeridian are unsupported.",

      zoneId: zone.id,
    };

  if (!rings.length || rings.some((ring) => ring.length < 3))
    return {
      code: "minimum-vertices",

      message: "A zone needs at least three vertices.",

      zoneId: zone.id,
    };

  if (rings.some(zoneHasSelfIntersection))
    return {
      code: "self-intersection",

      message: "A zone boundary must not intersect itself or have zero area.",

      zoneId: zone.id,
    };

  for (const polygon of polygons) {
    for (const hole of polygon.holes ?? []) {
      if (
        invalidHoleBoundaryContact(polygon.outer, hole) ||
        hole.some((point) => pointLocation(point, polygon.outer) === "outside")
      )
        return {
          code: "self-intersection",

          message:
            "Zone holes must stay inside their outer ring and may touch it at one point only.",

          zoneId: zone.id,
        };
    }

    const holes = polygon.holes ?? [];

    for (let index = 0; index < holes.length; index += 1)
      for (let other = index + 1; other < holes.length; other += 1)
        if (zonesOverlap(holes[index], holes[other]))
          return {
            code: "self-intersection",

            message: "Zone holes must not overlap.",

            zoneId: zone.id,
          };
  }

  for (let index = 0; index < polygons.length; index += 1) {
    for (let other = index + 1; other < polygons.length; other += 1) {
      const first = polygons[index];

      const second = polygons[other];

      const secondInFirstHole = (first.holes ?? []).some((hole) =>
        second.outer.every((point) => pointLocation(point, hole) === "inside"),
      );

      const firstInSecondHole = (second.holes ?? []).some((hole) =>
        first.outer.every((point) => pointLocation(point, hole) === "inside"),
      );

      if (
        zonesOverlap(first.outer, second.outer) &&
        !secondInFirstHole &&
        !firstInSecondHole
      )
        return {
          code: "self-intersection",

          message: "Zone polygon parts must not overlap.",

          zoneId: zone.id,
        };
    }
  }

  const conflict = otherZones.find(
    (other) =>
      other.id !== zone.id &&
      polygons.some((first) =>
        zonePolygons(other).some((second) =>
          zonesOverlap(first.outer, second.outer),
        ),
      ),
  );

  if (conflict)
    return {
      code: "zone-overlap",

      message: "Zones must not overlap.",

      zoneId: zone.id,

      conflictingZoneId: conflict.id,
    };

  return null;
}
