import { useEffect, useId, useRef } from "react";
import type { GeoJSONSource, Map, MapLayerMouseEvent } from "maplibre-gl";
import type { KMapZone } from "./map-zone-geometry.js";
import { closeRing, zonePolygons } from "./map-zone-shape.js";
import { resolveMapZoneColor } from "./map-zone-colors.js";

export function MapZoneLayer({
  map,
  zones,
  selectedZoneId,
  invalidZoneIds = [],
  onZoneClick,
}: {
  map: Map;
  zones: readonly KMapZone[];
  selectedZoneId?: string | null;
  invalidZoneIds?: readonly string[];
  onZoneClick?: (id: string) => void;
}) {
  const prefix = useId().replaceAll(":", "");
  const zoneClick = useRef(onZoneClick);
  zoneClick.current = onZoneClick;
  const latest = useRef({ zones, selectedZoneId, invalidZoneIds });
  latest.current = { zones, selectedZoneId, invalidZoneIds };
  const sourceId = `${prefix}-zones`;
  const fillId = `${sourceId}-fill`;
  const lineId = `${sourceId}-line`;

  const data = () => {
    const theme = getComputedStyle(map.getContainer());
    const dark = theme.colorScheme.split(" ").includes("dark");
    const fallback =
      theme.getPropertyValue("--k-map-zone-color").trim() ||
      theme.getPropertyValue("--k-color-brand-primary-accent").trim() ||
      "#2563eb";
    const errorColor =
      theme.getPropertyValue("--k-map-zone-invalid-color").trim() ||
      theme.getPropertyValue("--k-color-status-error-accent").trim() ||
      "#ef4444";
    const templateColor =
      theme.getPropertyValue("--k-color-text-muted").trim() || "#64748b";
    return {
      type: "FeatureCollection" as const,
      features: latest.current.zones.map((zone) => ({
        type: "Feature" as const,
        properties: {
          id: zone.id,
          color: latest.current.invalidZoneIds.includes(zone.id)
            ? errorColor
            : zone.presentation === "template"
              ? templateColor
              : resolveMapZoneColor(zone.color ?? fallback, dark),
        },
        geometry: {
          type: "MultiPolygon" as const,
          coordinates: zonePolygons(zone).map((polygon) => [
            closeRing(polygon.outer),
            ...(polygon.holes?.map(closeRing) ?? []),
          ]),
        },
      })),
    };
  };

  useEffect(() => {
    let removed = false;
    const onRemove = () => {
      removed = true;
    };
    const clear = () => {
      if (removed) return;
      if (map.getLayer(lineId)) map.removeLayer(lineId);
      if (map.getLayer(fillId)) map.removeLayer(fillId);
      if (map.getSource(sourceId)) map.removeSource(sourceId);
    };
    const draw = () => {
      if (map.getSource(sourceId)) {
        (map.getSource(sourceId) as GeoJSONSource).setData(data());
        return;
      }
      const theme = getComputedStyle(map.getContainer());
      const numberToken = (name: string, fallbackValue: number) => {
        const value = Number.parseFloat(theme.getPropertyValue(name));
        return Number.isFinite(value) ? value : fallbackValue;
      };
      const fillOpacity = numberToken("--k-map-zone-fill-opacity", 0.16);
      const selectedFillOpacity = numberToken(
        "--k-map-zone-selected-fill-opacity",
        0.3,
      );
      const strokeWidth = numberToken("--k-map-zone-stroke-width", 2);
      const selectedStrokeWidth = numberToken(
        "--k-map-zone-selected-stroke-width",
        4,
      );
      map.addSource(sourceId, {
        type: "geojson",
        data: data(),
      });
      const before = map.getLayer("kds-slot-route")
        ? "kds-slot-route"
        : undefined;
      map.addLayer(
        {
          id: fillId,
          type: "fill",
          source: sourceId,
          paint: {
            "fill-color": ["get", "color"],
            "fill-opacity": [
              "case",
              ["==", ["get", "id"], latest.current.selectedZoneId ?? ""],
              selectedFillOpacity,
              fillOpacity,
            ],
          },
        },
        before,
      );
      map.addLayer(
        {
          id: lineId,
          type: "line",
          source: sourceId,
          layout: { "line-cap": "round", "line-join": "round" },
          paint: {
            "line-color": ["get", "color"],
            "line-width": [
              "case",
              ["==", ["get", "id"], latest.current.selectedZoneId ?? ""],
              selectedStrokeWidth,
              strokeWidth,
            ],
          },
        },
        before,
      );
    };
    const click = (event: MapLayerMouseEvent) => {
      const id = event.features?.[0]?.properties?.id;
      if (typeof id === "string") zoneClick.current?.(id);
    };
    const enter = () => {
      map.getCanvas().style.cursor = "pointer";
    };
    const leave = () => {
      map.getCanvas().style.cursor = "";
    };
    map.on("remove", onRemove);
    if (map.isStyleLoaded()) draw();
    else map.once("idle", draw);
    map.on("style.load", draw);
    map.on("click", fillId, click);
    map.on("mouseenter", fillId, enter);
    map.on("mouseleave", fillId, leave);
    const themeObserver = new MutationObserver(() => {
      const source = map.getSource(sourceId) as GeoJSONSource | undefined;
      source?.setData(data());
    });
    themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class", "style", "data-theme"],
    });
    return () => {
      themeObserver.disconnect();
      map.off("style.load", draw);
      map.off("idle", draw);
      map.off("click", fillId, click);
      map.off("mouseenter", fillId, enter);
      map.off("mouseleave", fillId, leave);
      map.off("remove", onRemove);
      clear();
    };
  }, [map, prefix]);

  useEffect(() => {
    const source = map.getSource(sourceId) as GeoJSONSource | undefined;
    source?.setData(data());
  }, [map, sourceId, zones, invalidZoneIds]);

  useEffect(() => {
    const selected = selectedZoneId ?? "";
    if (map.getLayer(fillId))
      map.setPaintProperty(fillId, "fill-opacity", [
        "case",
        ["==", ["get", "id"], selected],
        Number.parseFloat(
          getComputedStyle(map.getContainer()).getPropertyValue(
            "--k-map-zone-selected-fill-opacity",
          ),
        ) || 0.3,
        Number.parseFloat(
          getComputedStyle(map.getContainer()).getPropertyValue(
            "--k-map-zone-fill-opacity",
          ),
        ) || 0.16,
      ]);
    if (map.getLayer(lineId))
      map.setPaintProperty(lineId, "line-width", [
        "case",
        ["==", ["get", "id"], selected],
        Number.parseFloat(
          getComputedStyle(map.getContainer()).getPropertyValue(
            "--k-map-zone-selected-stroke-width",
          ),
        ) || 4,
        Number.parseFloat(
          getComputedStyle(map.getContainer()).getPropertyValue(
            "--k-map-zone-stroke-width",
          ),
        ) || 2,
      ]);
  }, [map, fillId, lineId, selectedZoneId]);

  return null;
}
