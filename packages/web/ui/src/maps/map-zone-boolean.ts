import polygonClipping from "polygon-clipping";
import type { MultiPolygon } from "polygon-clipping";
import type {
  KMapPolygon,
  KMapPosition,
  KMapZone,
} from "./map-zone-geometry.js";
import {
  closeRing,
  copyMapZone,
  openRing,
  withZonePolygons,
  zonePolygons,
} from "./map-zone-shape.js";

const { difference, intersection } = polygonClipping;

export interface KMapZoneCommitImpact {
  zoneId: string;
  zoneName: string;
  outcome: "reduced" | "removed";
}

export interface KMapZoneCommitPlan {
  zones: KMapZone[];
  previousZones: KMapZone[];
  impacts: KMapZoneCommitImpact[];
}

const toMultiPolygon = (zone: KMapZone): MultiPolygon =>
  zonePolygons(zone).map((polygon) => [
    closeRing(polygon.outer),
    ...(polygon.holes?.map(closeRing) ?? []),
  ]);

const fromMultiPolygon = (geometry: MultiPolygon): KMapPolygon[] =>
  geometry
    .map((polygon) => ({
      outer: openRing(polygon[0] as KMapPosition[]),
      holes: polygon.slice(1).map((ring) => openRing(ring as KMapPosition[])),
    }))
    .filter((polygon) => polygon.outer.length >= 3);

const geometryKey = (zone: KMapZone) => JSON.stringify(toMultiPolygon(zone));

const ringArea = (ring: readonly [number, number][]) =>
  Math.abs(
    ring.reduce((area, point, index) => {
      const next = ring[(index + 1) % ring.length];
      return area + point[0] * next[1] - next[0] * point[1];
    }, 0) / 2,
  );

const geometryArea = (geometry: MultiPolygon) =>
  geometry.reduce(
    (total, polygon) =>
      total +
      Math.max(
        0,
        ringArea(polygon[0]) -
          polygon.slice(1).reduce((sum, ring) => sum + ringArea(ring), 0),
      ),
    0,
  );

export function subtractZoneGeometry(subject: KMapZone, clip: KMapZone) {
  if (
    geometryArea(intersection(toMultiPolygon(subject), toMultiPolygon(clip))) <=
    1e-18
  )
    return zonePolygons(subject);
  const result = difference(toMultiPolygon(subject), toMultiPolygon(clip));
  return fromMultiPolygon(result);
}

/** The candidate wins. Every conflicting saved zone is reduced or removed. */
export function planMapZoneCommit(
  zones: readonly KMapZone[],
  candidate: KMapZone,
): KMapZoneCommitPlan {
  const previousZones = zones.map(copyMapZone);
  const impacts: KMapZoneCommitImpact[] = [];
  const next: KMapZone[] = [];
  let candidateIndex = zones.findIndex((zone) => zone.id === candidate.id);
  if (candidateIndex < 0) candidateIndex = zones.length;

  for (const zone of zones) {
    if (zone.id === candidate.id) continue;
    const polygons = subtractZoneGeometry(zone, candidate);
    if (!polygons.length) {
      impacts.push({
        zoneId: zone.id,
        zoneName: zone.name,
        outcome: "removed",
      });
      continue;
    }
    const reduced = withZonePolygons(zone, polygons);
    if (geometryKey(reduced) !== geometryKey(zone)) {
      impacts.push({
        zoneId: zone.id,
        zoneName: zone.name,
        outcome: "reduced",
      });
      next.push(reduced);
    } else next.push(zone);
  }

  next.splice(Math.min(candidateIndex, next.length), 0, copyMapZone(candidate));
  return { zones: next, previousZones, impacts };
}

export function planMapZoneCommits(
  zones: readonly KMapZone[],
  candidates: readonly KMapZone[],
): KMapZoneCommitPlan {
  const previousZones = zones.map(copyMapZone);
  let next = [...zones];
  const impacts = new Map<string, KMapZoneCommitImpact>();
  for (const candidate of candidates) {
    const plan = planMapZoneCommit(next, candidate);
    next = plan.zones;
    for (const impact of plan.impacts) impacts.set(impact.zoneId, impact);
  }
  return { zones: next, previousZones, impacts: [...impacts.values()] };
}
