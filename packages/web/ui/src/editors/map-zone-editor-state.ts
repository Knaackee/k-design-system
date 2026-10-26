import type {
  KMapPosition,
  KMapPostalArea,
  KMapZone,
  KMapZoneValidationError,
} from "../maps/map-zone-geometry.js";
import { createCircleCoordinates } from "../maps/map-zone-geometry.js";
import { copyMapZone, zonePositions } from "../maps/map-zone-shape.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";

export const copyZone = copyMapZone;

const postalAreaName = (area: KMapPostalArea) =>
  area.label.trim() === area.code ? area.code : `${area.code} ${area.label}`;

export function nextZoneId(zones: readonly KMapZone[], prefix: string) {
  let number = 1;
  while (zones.some((zone) => zone.id === `${prefix}-${number}`)) number += 1;
  return `${prefix}-${number}`;
}

export const zoneCoordinates = (zones: readonly KMapZone[]) =>
  zones.flatMap((zone) =>
    zonePositions(zone).map((point) => [...point] as KMapPosition),
  );

export const isZoneChange = (before: KMapZone, after: KMapZone) =>
  JSON.stringify(before) !== JSON.stringify(after);

export const isZoneDraftDirty = (
  draft: KMapZone | null,
  baseSnapshot: string | null | undefined,
) =>
  !!draft &&
  (baseSnapshot === null ||
    (baseSnapshot !== undefined && JSON.stringify(draft) !== baseSnapshot));

export const isZoneDraftStale = (
  draft: KMapZone | null,
  baseSnapshot: string | null | undefined,
  zones: readonly KMapZone[],
) => {
  if (!draft) return false;
  const source = zones.find((zone) => zone.id === draft.id);
  return baseSnapshot === null
    ? !!source
    : baseSnapshot !== undefined && JSON.stringify(source) !== baseSnapshot;
};

export const removeZone = (zones: readonly KMapZone[], id: string) =>
  zones.filter((zone) => zone.id !== id);

export const updateZoneProperties = (
  zones: readonly KMapZone[],
  id: string,
  values: Pick<KMapZone, "name" | "color">,
) => zones.map((zone) => (zone.id === id ? { ...zone, ...values } : zone));

export function editorVisibleZones(
  stage: string,
  zones: readonly KMapZone[],
  draft: KMapZone | null,
  postalAreas: readonly KMapPostalArea[],
  postalSelection: readonly string[],
) {
  if (stage === "postal")
    return [
      ...zones,
      ...postalAreas.map((area) => ({
        id: `__postal:${area.id}`,
        name: postalAreaName(area),
        coordinates: area.coordinates.map(
          (point) => [...point] as KMapPosition,
        ),
        polygons: area.polygons ? structuredClone(area.polygons) : undefined,
        presentation: postalSelection.includes(area.id)
          ? ("template-selected" as const)
          : ("template" as const),
      })),
    ];
  if (!draft) return [...zones];
  return [
    ...zones.filter((zone) => zone.id !== draft.id),
    ...(draft.coordinates.length >= 3 ? [draft] : []),
  ];
}

export function createRadiusZone(
  zones: readonly KMapZone[],
  name: string,
  center: KMapPosition,
  radiusKm: number,
): KMapZone {
  return {
    id: nextZoneId(zones, "radius"),
    name,
    kind: "circle",
    circle: { center: [...center], radiusKm },
    coordinates: createCircleCoordinates(center, radiusKm),
  };
}

export const createPolygonZone = (
  zones: readonly KMapZone[],
  name: string,
): KMapZone => ({
  id: nextZoneId(zones, "area"),
  name,
  kind: "polygon",
  coordinates: [],
});

export const filterPostalAreas = (
  areas: readonly KMapPostalArea[],
  query: string,
) => {
  const needle = query.trim().toLocaleLowerCase();
  return areas.filter((area) =>
    `${area.country} ${area.code} ${area.label}`
      .toLocaleLowerCase()
      .includes(needle),
  );
};

export function createPostalZones(
  zones: readonly KMapZone[],
  areas: readonly KMapPostalArea[],
  selection: readonly string[],
  settings: KMapZone["settings"],
) {
  const additions: KMapZone[] = [];
  for (const area of areas.filter((value) => selection.includes(value.id))) {
    additions.push({
      id: nextZoneId([...zones, ...additions], `postal-${area.code}`),
      name: area.code,
      kind: "postal",
      coordinates: area.coordinates.map((point) => [...point]),
      polygons: area.polygons ? structuredClone(area.polygons) : undefined,
      source: {
        type: "postal",
        id: area.id,
        country: area.country,
        code: area.code,
        label: area.label,
        provider: area.sourceLabel,
        version: area.sourceVersion,
      },
      settings: settings ? structuredClone(settings) : undefined,
    });
  }
  return additions;
}

export const zoneValidationMessage = (
  labels: KMapZoneEditorLabels,
  code: KMapZoneValidationError["code"],
) =>
  ({
    "invalid-coordinate": labels.invalidCoordinate,
    "minimum-vertices": labels.minimumVertices,
    "self-intersection": labels.selfIntersection,
    "zone-overlap": labels.zoneOverlap,
    "external-change": labels.externalChange,
  })[code];
