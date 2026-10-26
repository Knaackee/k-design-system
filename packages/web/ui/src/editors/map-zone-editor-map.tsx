import { useRef, useState } from "react";
import {
  createCircleCoordinates,
  distanceKm,
  mapZoneCenter,
  moveMapZone,
  type KMapPosition,
  type KMapZone,
} from "../maps/map-zone-geometry.js";
import { KIcon } from "../primitives/icon.js";
import {
  KMap,
  type KMapAttributionState,
  type KMapPin,
  type KMapProps,
  type KMapView,
} from "../patterns/map.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import { mapZoneCssColor } from "../maps/map-zone-colors.js";
import type { KMapZoneEditorStage } from "./map-zone-editor-types.js";
import type { KMapPinEdgePanOptions } from "../maps/map-pin-drag.js";
import { withZonePolygons, zonePolygons } from "../maps/map-zone-shape.js";

// Each visible vertex also creates one midpoint handle, so keep the pair under
// roughly 200 controls even for very large imported rings.
const MAX_VISIBLE_ZONE_HANDLES = 100;
const MINIMUM_HANDLE_SPACING = 44;

function visibleRingIndices(
  ring: readonly KMapPosition[],
  view: KMapView,
  maxHandles: number,
  activeIndex?: number,
) {
  if (maxHandles <= 0)
    return activeIndex !== undefined &&
      activeIndex >= 0 &&
      activeIndex < ring.length
      ? [activeIndex]
      : [];
  if (ring.length <= maxHandles) return ring.map((_, index) => index);
  const [west, south, east, north] = view.bounds ?? [-180, -90, 180, 90];
  const visible = ring
    .map((point, index) => ({ point, index }))
    .filter(
      ({ point }) =>
        point[0] >= west &&
        point[0] <= east &&
        point[1] >= south &&
        point[1] <= north,
    )
    .map(({ index }) => index);
  const candidates = visible.length ? visible : ring.map((_, index) => index);
  const step = Math.max(1, Math.ceil(candidates.length / maxHandles));
  const selected = candidates.filter((_, index) => index % step === 0);
  if (
    activeIndex !== undefined &&
    activeIndex >= 0 &&
    activeIndex < ring.length &&
    !selected.includes(activeIndex)
  ) {
    selected.splice(Math.max(0, selected.length - 1), 1, activeIndex);
  }
  return selected;
}

function projectedPosition(position: KMapPosition, zoom: number) {
  const worldSize = 512 * 2 ** zoom;
  const latitude = Math.max(-85.051129, Math.min(85.051129, position[1]));
  const sin = Math.sin((latitude * Math.PI) / 180);
  return {
    x: ((position[0] + 180) / 360) * worldSize,
    y: (0.5 - Math.log((1 + sin) / (1 - sin)) / (4 * Math.PI)) * worldSize,
  };
}

type RingHandle = { kind: "vertex" | "midpoint"; index: number };
interface ScreenPosition {
  x: number;
  y: number;
}

/** Keeps handle density usable without changing ring data or vertex indices. */
export function screenSpacedRingHandles(
  ring: readonly KMapPosition[],
  indices: readonly number[],
  zoom: number,
  active?: RingHandle,
  minimumSpacing = MINIMUM_HANDLE_SPACING,
  occupied: ScreenPosition[] = [],
) {
  const vertices: number[] = [];
  const midpoints: number[] = [];
  const positionFor = ({ kind, index }: RingHandle) => {
    const position = ring[index];
    const next = ring[(index + 1) % ring.length];
    return projectedPosition(
      kind === "vertex"
        ? position
        : [(position[0] + next[0]) / 2, (position[1] + next[1]) / 2],
      zoom,
    );
  };
  // Prioritize useful vertex edits. Midpoints are optional and only fill space
  // that remains after every candidate vertex has been considered.
  const candidates: RingHandle[] = [
    ...indices.map((index) => ({ kind: "vertex" as const, index })),
    ...indices.map((index) => ({ kind: "midpoint" as const, index })),
  ];
  if (active && indices.includes(active.index)) {
    const match = candidates.findIndex(
      ({ kind, index }) => kind === active.kind && index === active.index,
    );
    if (match >= 0) candidates.unshift(...candidates.splice(match, 1));
  }
  for (const handle of candidates) {
    const position = positionFor(handle);
    const isActive =
      active?.kind === handle.kind && active.index === handle.index;
    if (
      !isActive &&
      occupied.some(
        (other) =>
          Math.hypot(position.x - other.x, position.y - other.y) <
          minimumSpacing,
      )
    )
      continue;
    (handle.kind === "vertex" ? vertices : midpoints).push(handle.index);
    occupied.push(position);
  }
  return { vertices, midpoints };
}

export type ZoneMapProps = Omit<
  KMapProps,
  | "zones"
  | "selectedZoneId"
  | "onZoneClick"
  | "onMapClick"
  | "pins"
  | "selectedPinId"
  | "onPinMove"
>;

interface ZoneEditorMapProps {
  mapProps: ZoneMapProps;
  zones: readonly KMapZone[];
  visibleZones: readonly KMapZone[];
  selectedZoneId: string | null;
  stage: KMapZoneEditorStage;
  draft: KMapZone | null;
  baseSnapshot: string | null | undefined;
  postalSelection: readonly string[];
  fitCoordinates: readonly KMapPosition[];
  fitMaxZoom: number;
  fitDurationMs: number;
  fitRevision: number;
  edgePan: false | KMapPinEdgePanOptions;
  invalid: boolean;
  disabled: boolean;
  labels: KMapZoneEditorLabels;
  onUpdateDraft: (zone: KMapZone) => void;
  onPreviewDraft: (zone: KMapZone) => void;
  onBeginDraftGesture: () => void;
  onEndDraftGesture: () => void;
  onCancelDraftGesture: () => void;
  onBegin: (zone: KMapZone) => void;
  onTogglePostal: (id: string) => void;
  onAttributionChange: (state: KMapAttributionState) => void;
}

export function ZoneEditorMap({
  mapProps,
  zones,
  visibleZones,
  selectedZoneId,
  stage,
  draft,
  baseSnapshot,
  postalSelection,
  fitCoordinates,
  fitMaxZoom,
  fitDurationMs,
  fitRevision,
  edgePan,
  invalid,
  disabled,
  labels,
  onUpdateDraft,
  onPreviewDraft,
  onBeginDraftGesture,
  onEndDraftGesture,
  onCancelDraftGesture,
  onBegin,
  onTogglePostal,
  onAttributionChange,
}: ZoneEditorMapProps) {
  const suppressMapClick = useRef(false);
  const suppressZoneClick = useRef(false);
  const activeDragPinId = useRef<string | null>(null);
  const [view, setView] = useState<KMapView>({
    center: mapProps.center,
    zoom: mapProps.zoom ?? 13,
  });
  const pins: KMapPin[] = [];
  if (draft?.circle) {
    pins.push({
      id: "zone-center",
      label: labels.moveCenter,
      position: draft.circle.center,
      draggable: !disabled,
      size: 28,
      shape: "circle",
      anchor: "center",
      color: draft.color,
    });
    pins.push({
      id: "zone-radius",
      label: labels.resizeRadius,
      position: draft.coordinates[Math.floor(draft.coordinates.length / 4)],
      draggable: !disabled,
      size: 28,
      shape: "circle",
      anchor: "center",
      color: draft.color,
    });
  } else if (draft) {
    if (draft.coordinates.length >= 3)
      pins.push({
        id: "zone-move",
        label: labels.moveZone,
        position: mapZoneCenter(draft),
        draggable: !disabled,
        size: 30,
        shape: "circle",
        anchor: "center",
        color: draft.color,
      });
    const ringEntries = zonePolygons(draft).flatMap((polygon, polygonIndex) =>
      [polygon.outer, ...(polygon.holes ?? [])].map((ring, ringIndex) => ({
        polygonIndex,
        ringIndex,
        ring,
      })),
    );
    let remaining = view.zoom >= 14 ? MAX_VISIBLE_ZONE_HANDLES : 64;
    const occupiedHandlePositions: ScreenPosition[] = [];
    ringEntries.forEach(({ polygonIndex, ringIndex, ring }, entryIndex) => {
      const budget = Math.floor(remaining / (ringEntries.length - entryIndex));
      const activeMatch = activeDragPinId.current?.match(
        /^zone-(vertex|midpoint)-(\d+)-(\d+)-(\d+)$/,
      );
      const activeIndex =
        activeMatch &&
        Number(activeMatch[2]) === polygonIndex &&
        Number(activeMatch[3]) === ringIndex
          ? Number(activeMatch[4])
          : undefined;
      const handles = screenSpacedRingHandles(
        ring,
        visibleRingIndices(ring, view, budget, activeIndex),
        view.zoom,
        activeIndex === undefined
          ? undefined
          : {
              kind: activeMatch?.[1] as "vertex" | "midpoint",
              index: activeIndex,
            },
        MINIMUM_HANDLE_SPACING,
        occupiedHandlePositions,
      );
      const renderedIndices = new Set([
        ...handles.vertices,
        ...handles.midpoints,
      ]);
      remaining -= renderedIndices.size;
      renderedIndices.forEach((index) => {
        const position = ring[index];
        const path = `${polygonIndex}-${ringIndex}-${index}`;
        if (handles.vertices.includes(index))
          pins.push({
            id: `zone-vertex-${path}`,
            label: `${labels.vertices} ${index + 1}`,
            position,
            draggable: !disabled,
            size: 28,
            shape: "circle",
            anchor: "center",
            color: draft.color,
          });
        if (ring.length >= 2 && handles.midpoints.includes(index)) {
          const next = ring[(index + 1) % ring.length];
          pins.push({
            id: `zone-midpoint-${path}`,
            label: `${labels.addPointAfter} ${index + 1}`,
            position: [
              (position[0] + next[0]) / 2,
              (position[1] + next[1]) / 2,
            ],
            size: 24,
            shape: "circle",
            anchor: "center",
            color: draft.color,
          });
        }
      });
    });
  }

  return (
    <KMap
      {...mapProps}
      onAttributionChange={(state) => {
        mapProps.onAttributionChange?.(state);
        onAttributionChange(state);
      }}
      onViewChange={(next) => {
        setView(next);
        mapProps.onViewChange?.(next);
      }}
      fitContent={fitCoordinates.length > 0}
      fitCoordinates={fitCoordinates}
      fitMaxZoom={fitMaxZoom}
      fitDurationMs={fitDurationMs}
      fitRevision={fitRevision}
      pinDrag={{ ...mapProps.pinDrag, edgePan }}
      zones={visibleZones}
      selectedZoneId={
        stage === "postal"
          ? postalSelection.at(-1)
            ? `__postal:${postalSelection.at(-1)}`
            : null
          : (draft?.id ?? selectedZoneId)
      }
      invalidZoneIds={draft && invalid ? [draft.id] : []}
      pins={pins}
      selectedPinId={null}
      renderPin={(pin) => (
        <span
          className="k-map-zone-editor__handle"
          data-kind={pin.id.replace(/^zone-/, "")}
          style={pin.color ? { color: mapZoneCssColor(pin.color) } : undefined}
          aria-hidden="true"
        >
          {pin.id.startsWith("zone-midpoint") ? (
            <KIcon name="plus" />
          ) : pin.id === "zone-move" || pin.id === "zone-center" ? (
            <KIcon name="map-pin" />
          ) : null}
        </span>
      )}
      onPinMove={({ id, position, source }) => {
        if (!draft || disabled) return false;
        const next = updateDraftForPin(draft, id, position);
        if (!next) return false;
        if (source === "keyboard") onUpdateDraft(next);
        else onPreviewDraft(next);
        return true;
      }}
      onPinDragStart={({ id }) => {
        activeDragPinId.current = id;
        suppressZoneClick.current = true;
        onBeginDraftGesture();
      }}
      onPinDrag={({ id, position }) => {
        if (!draft || disabled) return;
        const next = updateDraftForPin(draft, id, position);
        if (next) onPreviewDraft(next);
      }}
      onPinDragEnd={() => {
        activeDragPinId.current = null;
        onEndDraftGesture();
        queueMicrotask(() => (suppressZoneClick.current = false));
      }}
      onPinDragCancel={() => {
        activeDragPinId.current = null;
        onCancelDraftGesture();
        queueMicrotask(() => (suppressZoneClick.current = false));
      }}
      onPinClick={(id) => {
        if (!draft || disabled || !id.startsWith("zone-midpoint-")) return;
        const point = pins.find((pin) => pin.id === id)?.position;
        const next = point ? insertDraftPoint(draft, id, point) : null;
        if (next) onUpdateDraft(next);
      }}
      onZoneClick={(id) => {
        if (disabled || suppressZoneClick.current) return;
        suppressMapClick.current = true;
        queueMicrotask(() => (suppressMapClick.current = false));
        if (stage === "postal" && id.startsWith("__postal:"))
          onTogglePostal(id.slice(9));
        else {
          const zone = selectableZoneForMapClick(zones, draft, id);
          if (zone) onBegin(zone);
        }
      }}
      onMapClick={(position) => {
        if (
          !draft ||
          stage !== "polygon" ||
          baseSnapshot !== null ||
          zones.some((zone) => zone.id === draft.id) ||
          suppressMapClick.current ||
          disabled
        )
          return;
        onUpdateDraft({
          ...draft,
          coordinates: [...draft.coordinates, position],
        });
      }}
    />
  );
}

export function selectableZoneForMapClick(
  zones: readonly KMapZone[],
  draft: KMapZone | null,
  id: string,
) {
  return draft?.id === id
    ? null
    : (zones.find((zone) => zone.id === id) ?? null);
}

export function updateDraftForPin(
  draft: KMapZone,
  id: string,
  position: KMapPosition,
): KMapZone | null {
  if (id === "zone-radius" && draft.circle) {
    const radiusKm = Math.max(
      0.5,
      Math.min(100, distanceKm(draft.circle.center, position)),
    );
    return {
      ...draft,
      circle: { ...draft.circle, radiusKm },
      coordinates: createCircleCoordinates(draft.circle.center, radiusKm),
    };
  }
  if (id === "zone-center" || id === "zone-move") {
    const moved = moveMapZone(draft, mapZoneCenter(draft), position);
    return {
      ...moved,
      kind:
        id === "zone-move" && moved.kind === "postal" ? "polygon" : moved.kind,
    };
  }
  if (id.startsWith("zone-vertex-")) {
    const path = parseRingPath(id, "zone-vertex-");
    if (!path) return null;
    return updateDraftRing(draft, path, (ring) =>
      ring.map((point, index) => (index === path.vertex ? position : point)),
    );
  }
  return null;
}

interface RingPath {
  polygon: number;
  ring: number;
  vertex: number;
}

function parseRingPath(id: string, prefix: string): RingPath | null {
  const parts = id.slice(prefix.length).split("-").map(Number);
  if (parts.length === 1 && Number.isInteger(parts[0]))
    return { polygon: 0, ring: 0, vertex: parts[0] };
  if (parts.length !== 3 || parts.some((value) => !Number.isInteger(value)))
    return null;
  return { polygon: parts[0], ring: parts[1], vertex: parts[2] };
}

function updateDraftRing(
  draft: KMapZone,
  path: RingPath,
  update: (ring: KMapPosition[]) => KMapPosition[],
) {
  const polygons = zonePolygons(draft);
  const polygon = polygons[path.polygon];
  if (!polygon) return null;
  const rings = [polygon.outer, ...(polygon.holes ?? [])];
  if (!rings[path.ring]?.[path.vertex]) return null;
  rings[path.ring] = update(rings[path.ring]);
  polygons[path.polygon] = {
    outer: rings[0],
    holes: rings.length > 1 ? rings.slice(1) : undefined,
  };
  return withZonePolygons(draft, polygons);
}

function insertDraftPoint(draft: KMapZone, id: string, position: KMapPosition) {
  const path = parseRingPath(id, "zone-midpoint-");
  if (!path) return null;
  return updateDraftRing(draft, path, (ring) => [
    ...ring.slice(0, path.vertex + 1),
    position,
    ...ring.slice(path.vertex + 1),
  ]);
}
