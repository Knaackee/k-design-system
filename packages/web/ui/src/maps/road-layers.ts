import type { ExpressionSpecification, LayerSpecification } from "maplibre-gl";
import { SRC, isLine, zexp, zlin, type Stops } from "./layer-expressions.js";
import type { MapSettings } from "./settings.js";
import type { MapTokens } from "./tokens.js";

const ROADS = [
  {
    id: "service",
    classes: ["service", "track"],
    minzoom: 15,
    width: [
      [15, 0.8],
      [16, 2],
      [18, 7],
      [20, 16],
    ],
    fill: "roadMinor",
    casing: "roadMinorCasing",
  },
  {
    id: "minor",
    classes: ["minor"],
    minzoom: 13,
    width: [
      [13, 0.6],
      [14, 2.2],
      [16, 6],
      [18, 13],
      [20, 30],
    ],
    fill: "roadMinor",
    casing: "roadMinorCasing",
  },
  {
    id: "secondary",
    classes: ["secondary", "tertiary"],
    minzoom: 10,
    width: [
      [10, 0.4],
      [12, 1.3],
      [14, 4],
      [16, 9],
      [18, 18],
      [20, 40],
    ],
    fill: "road",
    casing: "roadCasing",
  },
  {
    id: "primary",
    classes: ["primary"],
    minzoom: 8,
    width: [
      [8, 0.4],
      [11, 1.2],
      [14, 5],
      [16, 11],
      [18, 22],
      [20, 46],
    ],
    fill: "road",
    casing: "roadCasing",
  },
  {
    id: "trunk",
    classes: ["trunk"],
    minzoom: 6,
    width: [
      [6, 0.5],
      [10, 1.6],
      [14, 5.5],
      [16, 12],
      [18, 24],
      [20, 50],
    ],
    fill: "trunk",
    casing: "trunkCasing",
  },
  {
    id: "motorway",
    classes: ["motorway"],
    minzoom: 5,
    width: [
      [5, 0.6],
      [10, 2],
      [14, 6],
      [16, 13],
      [18, 26],
      [20, 54],
    ],
    fill: "motorway",
    casing: "motorwayCasing",
  },
] as const;

// Casing = Füllbreite + Randzuschlag (abhängig vom Zoom)
const casingExtra = (z: number) => (z < 11 ? 0.8 : z < 14 ? 1.6 : 2.4);
const scaleStops = (stops: Stops, factor: number): Stops =>
  stops.map(([zoom, value]) => [zoom, +(Number(value) * factor).toFixed(3)]);
const withCasing = (stops: Stops, scale: number): Stops =>
  stops.map(([zoom, width]) => [
    zoom,
    +(Number(width) + casingExtra(zoom) * scale).toFixed(3),
  ]);
const vis = (on: boolean): { visibility: "visible" | "none" } => ({
  visibility: on ? "visible" : "none",
});

function roadFilter(
  classes: readonly string[],
  brunnel: "normal" | "bridge" | "tunnel",
): ExpressionSpecification {
  const b = (brunnel === "normal"
    ? ["!", ["match", ["get", "brunnel"], ["bridge", "tunnel"], true, false]]
    : [
        "==",
        ["get", "brunnel"],
        brunnel,
      ]) as unknown as ExpressionSpecification;
  return [
    "all",
    isLine,
    ["match", ["get", "class"], [...classes], true, false],
    b,
  ] as unknown as ExpressionSpecification;
}

export function roadLayers(
  t: MapTokens,
  brunnel: "normal" | "bridge" | "tunnel",
  S: MapSettings,
): LayerSpecification[] {
  const casings: LayerSpecification[] = [];
  const fills: LayerSpecification[] = [];
  const tunnel = brunnel === "tunnel";
  for (const r of ROADS) {
    const width = scaleStops(r.width, S.roadWidthScale);
    const filter = roadFilter(r.classes, brunnel);
    // Bei niedrigem Zoom zeigt Google Nebenstraßen ohne Rand: Casing einblenden
    const casingFade =
      r.id === "motorway" || r.id === "trunk"
        ? 1
        : zlin([
            [Math.max(r.minzoom, 11), 0],
            [Math.max(r.minzoom, 11) + 1.5, 1],
          ]);
    casings.push({
      id: `road-${brunnel}-${r.id}-casing`,
      type: "line",
      source: SRC,
      "source-layer": "transportation",
      minzoom: r.minzoom,
      filter,
      layout: {
        "line-cap": tunnel ? "butt" : "round",
        "line-join": "round",
        ...vis(S.casingScale > 0),
      },
      paint: {
        "line-color": t[r.casing],
        "line-width": zexp(withCasing(width, S.casingScale)),
        "line-opacity": tunnel ? t.tunnelOpacity : casingFade,
        ...(tunnel ? { "line-dasharray": [1.5, 1] } : {}),
      },
    });
    fills.push({
      id: `road-${brunnel}-${r.id}`,
      type: "line",
      source: SRC,
      "source-layer": "transportation",
      minzoom: r.minzoom,
      filter,
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-color": t[r.fill],
        "line-width": zexp(width),
        ...(tunnel ? { "line-opacity": t.tunnelOpacity } : {}),
      },
    });
  }
  return [...casings, ...fills];
}

// ---------------------------------------------------------------------------
// POI-Kategorien (OpenMapTiles `poi.class`)
// ---------------------------------------------------------------------------
