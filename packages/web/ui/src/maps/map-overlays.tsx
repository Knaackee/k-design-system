import { useEffect, useId, useState, type ReactNode } from "react";
import { LngLatBounds, type Map } from "maplibre-gl";
import { type KIconName } from "../primitives/icon.js";

import { Pin } from "./map-pin.js";
import { resolvePinDrag, type KMapPinDragOptions } from "./map-pin-drag.js";
export type { KMapPinDragOptions } from "./map-pin-drag.js";

export interface KMapPin {
  id: string;
  /** Longitude, latitude (WGS84). */
  position: [number, number];
  label: string;
  icon?: KIconName;
  imageUrl?: string;
  color?: string;
  size?: number;
  shape?: "pin" | "circle" | "square";
  /** Position stays controlled; accept onPinMove by updating position. */
  draggable?: boolean;
  drag?: KMapPinDragOptions;
}

export interface KMapRouteSegment {
  id: string;
  /** Inclusive point indices in the parent route geometry. Adjacent segments share an endpoint. */
  startIndex: number;
  endIndex: number;
  color?: string;
  width?: number;
  dashed?: boolean;
  traffic?: "free" | "slow" | "congested";
}

export interface KMapRoute {
  id: string;
  /** Already calculated geometry: longitude, latitude (WGS84). */
  coordinates: [number, number][];
  color?: string;
  width?: number;
  dashed?: boolean;
  segments?: readonly KMapRouteSegment[];
}

export interface KMapPinMove {
  id: string;
  position: [number, number];
  source: "drag" | "keyboard";
}

export interface KMapOverlayProps {
  pins?: readonly KMapPin[];
  routes?: readonly KMapRoute[];
  selectedPinId?: string | null;
  defaultSelectedPinId?: string | null;
  selectedRouteId?: string | null;
  onPinClick?: (id: string) => void;
  onSelectionChange?: (id: string) => void;
  /** Return false (also asynchronously) to reject and animate back. */
  onPinMove?: (event: KMapPinMove) => void | boolean | Promise<void | boolean>;
  pinDrag?: KMapPinDragOptions;
  onPinDragStart?: (event: KMapPinMove) => void;
  onPinDrag?: (event: KMapPinMove) => void;
  onPinDragEnd?: (event: KMapPinMove) => void;
  /** Visual content only (including Rive); KMap owns the accessible button and dragging. */
  renderPin?: (
    pin: KMapPin,
    state: { selected: boolean; draggable: boolean; dragging: boolean },
  ) => ReactNode;
  /** Reframes when overlay geometry changes, not when a pin is selected. */
  fitContent?: boolean;
  fitPadding?: number;
}

/** Base geometry preserves gaps; ordered, non-overlapping segments paint above it. */
export function routeParts(route: KMapRoute) {
  const ids = new Set<string>();
  let previousEnd = 0;
  for (const segment of route.segments ?? []) {
    if (!segment.id || ids.has(segment.id))
      throw new Error("KMap segment IDs must be nonempty and unique per route");
    ids.add(segment.id);
    if (
      !Number.isInteger(segment.startIndex) ||
      !Number.isInteger(segment.endIndex) ||
      segment.startIndex < previousEnd ||
      segment.endIndex <= segment.startIndex ||
      segment.endIndex >= route.coordinates.length
    )
      throw new RangeError(
        "KMap segments need ordered, non-overlapping valid point indices",
      );
    if (
      segment.width !== undefined &&
      (!Number.isFinite(segment.width) || segment.width <= 0)
    )
      throw new RangeError("KMap segment width must be positive and finite");
    previousEnd = segment.endIndex;
  }
  return [
    { ...route, routeId: route.id, traffic: undefined },
    ...(route.segments ?? []).map((segment) => ({
      ...route,
      ...segment,
      routeId: route.id,
      color: segment.color ?? (segment.traffic ? undefined : route.color),
      coordinates: route.coordinates.slice(
        segment.startIndex,
        segment.endIndex + 1,
      ),
    })),
  ];
}

export function overlayCoordinates(
  pins: readonly KMapPin[],
  routes: readonly KMapRoute[],
): [number, number][] {
  for (const collection of [pins, routes]) {
    const ids = new Set<string>();
    for (const entry of collection) {
      if (!entry.id || ids.has(entry.id))
        throw new Error(
          "KMap overlay IDs must be nonempty and unique per type",
        );
      ids.add(entry.id);
    }
  }
  for (const pin of pins) {
    if (!pin.label.trim())
      throw new Error("KMap pins need an accessible label");
    if (pin.size !== undefined && (!Number.isFinite(pin.size) || pin.size <= 0))
      throw new RangeError("KMap pin size must be positive and finite");
  }
  for (const route of routes) {
    if (route.coordinates.length < 2)
      throw new RangeError("KMap routes need at least two positions");
    if (
      route.width !== undefined &&
      (!Number.isFinite(route.width) || route.width <= 0)
    )
      throw new RangeError("KMap route width must be positive and finite");
    routeParts(route);
  }
  const positions = [
    ...pins.map((pin) => pin.position),
    ...routes.flatMap((route) => route.coordinates),
  ];
  for (const [lng, lat] of positions) {
    if (
      !Number.isFinite(lng) ||
      !Number.isFinite(lat) ||
      Math.abs(lng) > 180 ||
      Math.abs(lat) > 90
    )
      throw new RangeError("KMap coordinates must be valid WGS84 positions");
  }
  return positions;
}

const EMPTY_PINS: readonly KMapPin[] = [];
const EMPTY_ROUTES: readonly KMapRoute[] = [];

export function MapOverlays({
  map,
  pins = EMPTY_PINS,
  routes = EMPTY_ROUTES,
  selectedPinId,
  defaultSelectedPinId = null,
  selectedRouteId,
  onPinClick,
  onSelectionChange,
  onPinMove,
  pinDrag,
  onPinDragStart,
  onPinDrag,
  onPinDragEnd,
  renderPin,
  fitContent = false,
  fitPadding = 64,
}: KMapOverlayProps & { map: Map | null }) {
  const prefix = useId().replaceAll(":", "");
  const [localSelection, setLocalSelection] = useState(defaultSelectedPinId);
  const selected = selectedPinId === undefined ? localSelection : selectedPinId;
  const positions = overlayCoordinates(pins, routes);
  if (!Number.isFinite(fitPadding) || fitPadding < 0)
    throw new RangeError("KMap fitPadding must be nonnegative and finite");
  const geometryKey = JSON.stringify(positions);

  useEffect(() => {
    if (!map || !fitContent || !positions.length) return;
    const bounds = positions.reduce(
      (result, point) => result.extend(point),
      new LngLatBounds(),
    );
    map.fitBounds(bounds, { padding: fitPadding, maxZoom: 16, duration: 0 });
  }, [map, fitContent, fitPadding, geometryKey]);

  useEffect(() => {
    if (!map) return;
    let removed = false;
    const onRemove = () => {
      removed = true;
    };
    map.on("remove", onRemove);
    const parts = routes.flatMap(routeParts);
    const ids = parts.map((_, index) => `${prefix}-route-${index}`);
    const clear = () => {
      if (removed) return;
      for (const id of ids) {
        if (map.getLayer(id)) map.removeLayer(id);
        if (map.getSource(id)) map.removeSource(id);
      }
    };
    const draw = () => {
      clear();
      const theme = getComputedStyle(map.getContainer());
      const color =
        theme.getPropertyValue("--k-map-route-color").trim() ||
        theme.getPropertyValue("--k-color-brand-primary-accent").trim() ||
        "#2563eb";
      const trafficColors = {
        free:
          theme.getPropertyValue("--k-map-traffic-free").trim() ||
          theme.getPropertyValue("--k-color-status-success-accent").trim() ||
          "#10b981",
        slow:
          theme.getPropertyValue("--k-map-traffic-slow").trim() ||
          theme.getPropertyValue("--k-color-status-warning-accent").trim() ||
          "#eab308",
        congested:
          theme.getPropertyValue("--k-map-traffic-congested").trim() ||
          theme.getPropertyValue("--k-color-status-error-accent").trim() ||
          "#ef4444",
      };
      parts.forEach((route, index) => {
        const id = ids[index];
        map.addSource(id, {
          type: "geojson",
          data: {
            type: "Feature",
            properties: {},
            geometry: { type: "LineString", coordinates: route.coordinates },
          },
        });
        map.addLayer({
          id,
          type: "line",
          source: id,
          layout: { "line-cap": "round", "line-join": "round" },
          paint: {
            "line-color":
              route.color ??
              (route.traffic ? trafficColors[route.traffic] : color),
            "line-width":
              (route.width ?? 5) + (selectedRouteId === route.routeId ? 3 : 0),
            "line-opacity":
              selectedRouteId && selectedRouteId !== route.routeId ? 0.45 : 1,
            ...(route.dashed ? { "line-dasharray": [1, 2] } : {}),
          },
        });
      });
    };
    if (map.isStyleLoaded()) draw();
    map.on("style.load", draw);
    return () => {
      map.off("style.load", draw);
      map.off("remove", onRemove);
      clear();
    };
  }, [map, routes, selectedRouteId, prefix]);

  if (!map) return null;
  return pins.map((pin) => (
    <Pin
      key={pin.id}
      map={map}
      pin={pin}
      selected={selected === pin.id}
      onMove={onPinMove}
      dragOptions={resolvePinDrag({ ...pinDrag, ...pin.drag })}
      onDragStart={onPinDragStart}
      onDrag={onPinDrag}
      onDragEnd={onPinDragEnd}
      renderPin={renderPin}
      onClick={() => {
        if (selected !== pin.id) {
          setLocalSelection(pin.id);
          onSelectionChange?.(pin.id);
        }
        onPinClick?.(pin.id);
      }}
    />
  ));
}
