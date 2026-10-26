import type {
  KMapPolygon,
  KMapPosition,
  KMapZone,
} from "./map-zone-geometry.js";

const copyRing = (ring: readonly KMapPosition[]) =>
  ring.map((point) => [...point] as KMapPosition);

const copyPolygon = (polygon: KMapPolygon): KMapPolygon => ({
  outer: copyRing(polygon.outer),
  ...(polygon.holes ? { holes: polygon.holes.map(copyRing) } : {}),
});

export function zonePolygons(zone: KMapZone): KMapPolygon[] {
  if (zone.polygons?.length) return zone.polygons.map(copyPolygon);
  return zone.coordinates.length ? [{ outer: copyRing(zone.coordinates) }] : [];
}

export const zonePositions = (zone: KMapZone) =>
  zonePolygons(zone).flatMap((polygon) => [
    ...polygon.outer,
    ...(polygon.holes?.flatMap(copyRing) ?? []),
  ]);

export function withZonePolygons(
  zone: KMapZone,
  polygons: readonly KMapPolygon[],
): KMapZone {
  const copied = polygons.map(copyPolygon);
  return {
    ...zone,
    kind: "polygon",
    circle: undefined,
    coordinates: copyRing(copied[0]?.outer ?? []),
    polygons: copied,
  };
}

export function copyMapZone(zone: KMapZone): KMapZone {
  return {
    ...zone,
    coordinates: copyRing(zone.coordinates),
    ...(zone.polygons ? { polygons: zonePolygons(zone) } : {}),
    ...(zone.circle
      ? { circle: { ...zone.circle, center: [...zone.circle.center] } }
      : {}),
    ...(zone.source ? { source: { ...zone.source } } : {}),
    ...(zone.settings
      ? {
          settings: {
            ...zone.settings,
            ...(zone.settings.surcharge
              ? { surcharge: { ...zone.settings.surcharge } }
              : {}),
            ...(zone.settings.workingHours
              ? {
                  workingHours: zone.settings.workingHours.map((day) => ({
                    ...day,
                    intervals: day.intervals.map((interval) => ({
                      ...interval,
                    })),
                  })),
                }
              : {}),
            ...(zone.settings.availability
              ? { availability: { ...zone.settings.availability } }
              : {}),
          },
        }
      : {}),
  };
}

export const closeRing = (ring: readonly KMapPosition[]) => {
  if (!ring.length) return [];
  const first = ring[0];
  const last = ring.at(-1)!;
  return first[0] === last[0] && first[1] === last[1]
    ? copyRing(ring)
    : [...copyRing(ring), [...first] as KMapPosition];
};

export const openRing = (ring: readonly KMapPosition[]) => {
  if (ring.length < 2) return copyRing(ring);
  const first = ring[0];
  const last = ring.at(-1)!;
  return first[0] === last[0] && first[1] === last[1]
    ? copyRing(ring.slice(0, -1))
    : copyRing(ring);
};
