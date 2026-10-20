import type { ExpressionSpecification, LayerSpecification } from "maplibre-gl";
import {
  SRC,
  isLine,
  isPoint,
  nameField,
  scaleStops,
  vis,
  zlin,
  type Stops,
} from "./layer-expressions.js";
import type { MapSettings } from "./settings.js";
import type { MapTokens } from "./tokens.js";

const POI_GROUPS = {
  poiFood: [
    "restaurant",
    "fast_food",
    "cafe",
    "bar",
    "beer",
    "ice_cream",
    "bakery",
  ],
  poiShop: [
    "shop",
    "grocery",
    "clothing_store",
    "alcohol_shop",
    "jewelry",
    "furniture",
    "hardware",
    "mobile_phone",
    "florist",
    "gift",
    "shoe",
    "music",
    "car",
    "bicycle",
    "electronics",
    "optician",
  ],
  poiHealth: ["hospital", "doctors", "pharmacy", "dentist", "veterinary"],
  poiEducation: ["school", "college", "library", "kindergarten"],
  poiLeisure: [
    "park",
    "attraction",
    "museum",
    "theatre",
    "cinema",
    "art_gallery",
    "zoo",
    "stadium",
    "sports",
    "swimming",
    "playground",
    "garden",
    "castle",
    "monument",
  ],
  poiTransport: [
    "bus",
    "railway",
    "airport",
    "aerialway",
    "ferry_terminal",
    "parking",
    "fuel",
    "bicycle_rental",
  ],
} as const;

const poiColor = (t: MapTokens): ExpressionSpecification =>
  [
    "match",
    ["get", "class"],
    ...Object.entries(POI_GROUPS).flatMap(([key, classes]) => [
      classes,
      t[key as keyof typeof POI_GROUPS],
    ]),
    t.poiOther,
  ] as unknown as ExpressionSpecification;

export function buildLabelLayers(
  t: MapTokens,
  S: MapSettings,
): LayerSpecification[] {
  const name = nameField(S.lang);
  const halo = {
    "text-halo-color": t.labelHalo,
    "text-halo-width": S.haloWidth,
    "text-halo-blur": 0.3,
  };
  const ts = (stops: Stops) => zlin(scaleStops(stops, S.labelScale));
  const tc = (value: number) => +(value * S.labelScale).toFixed(2);
  const byClass = (classes: readonly string[]): ExpressionSpecification =>
    [
      "match",
      ["get", "class"],
      [...classes],
      true,
      false,
    ] as ExpressionSpecification;

  return [
    // --- Labels ----------------------------------------------------------------
    {
      id: "label-water",
      type: "symbol",
      source: SRC,
      "source-layer": "water_name",
      filter: isPoint,
      layout: {
        "text-field": name,
        "text-font": t.fontItalic,
        "text-size": ts([
          [8, 11],
          [14, 13],
        ]),
        "text-max-width": 6,
      },
      paint: { "text-color": t.waterLabel, ...halo },
    },
    {
      id: "label-waterway",
      type: "symbol",
      source: SRC,
      "source-layer": "waterway",
      minzoom: 13,
      filter: ["all", isLine, byClass(["river", "canal"])],
      layout: {
        "text-field": name,
        "text-font": t.fontItalic,
        "text-size": tc(12),
        "symbol-placement": "line",
        "symbol-spacing": 500,
        "text-letter-spacing": 0.05,
      },
      paint: { "text-color": t.waterLabel, ...halo },
    },
    {
      id: "label-road-minor",
      type: "symbol",
      source: SRC,
      "source-layer": "transportation_name",
      minzoom: S.roadLabelMinZoom + 2,
      filter: ["all", isLine, byClass(["minor", "service"])],
      layout: {
        "text-field": name,
        "text-font": t.fontRegular,
        "text-size": ts([
          [15, 10],
          [18, 12.5],
        ]),
        "symbol-placement": "line",
        "symbol-spacing": 400,
        "text-max-angle": 30,
        "text-padding": 4,
      },
      paint: { "text-color": t.labelSubtle, ...halo },
    },
    {
      id: "label-road-major",
      type: "symbol",
      source: SRC,
      "source-layer": "transportation_name",
      minzoom: S.roadLabelMinZoom,
      filter: [
        "all",
        isLine,
        byClass(["primary", "secondary", "tertiary", "trunk"]),
      ],
      layout: {
        "text-field": name,
        "text-font": t.fontRegular,
        "text-size": ts([
          [13, 10.5],
          [17, 13],
        ]),
        "symbol-placement": "line",
        "symbol-spacing": 400,
        "text-max-angle": 30,
        "text-padding": 4,
      },
      paint: { "text-color": t.label, ...halo },
    },
    // POIs: farbiger Punkt + Text in Kategoriefarbe
    {
      id: "poi-dot",
      type: "circle",
      source: SRC,
      "source-layer": "poi",
      minzoom: S.poiMinZoom,
      filter: ["all", isPoint, ["<=", ["get", "rank"], S.poiMaxRank]],
      layout: vis(S.showPois),
      paint: {
        "circle-color": poiColor(t),
        "circle-radius": zlin(
          scaleStops(
            [
              [15, 3.5],
              [18, 5.5],
            ],
            S.poiDotScale,
          ),
        ),
        "circle-stroke-color": t.poiStroke,
        "circle-stroke-width": 1.5,
      },
    },
    {
      id: "poi-label",
      type: "symbol",
      source: SRC,
      "source-layer": "poi",
      minzoom: S.poiMinZoom,
      filter: [
        "all",
        isPoint,
        ["<=", ["get", "rank"], S.poiMaxRank],
        ["has", "name"],
      ],
      layout: {
        ...vis(S.showPois),
        "text-field": name,
        "text-font": t.fontBold,
        "text-size": tc(11.5),
        "text-max-width": 8,
        "text-variable-anchor": ["left", "right"],
        "text-radial-offset": 0.8,
        "text-justify": "auto",
        "symbol-sort-key": ["get", "rank"],
        "text-padding": 6,
      },
      paint: { "text-color": poiColor(t), ...halo },
    },
    // Orte
    {
      id: "label-quarter",
      type: "symbol",
      source: SRC,
      "source-layer": "place",
      minzoom: 12,
      filter: byClass(["suburb", "quarter", "neighbourhood"]),
      layout: {
        "text-field": name,
        "text-font": t.fontRegular,
        "text-transform": "uppercase",
        "text-letter-spacing": 0.12,
        "text-size": ts([
          [12, 10],
          [15, 11.5],
        ]),
        "text-max-width": 8,
        ...vis(S.showQuarterLabels),
      },
      paint: { "text-color": t.labelSubtle, ...halo },
    },
    {
      id: "label-village",
      type: "symbol",
      source: SRC,
      "source-layer": "place",
      minzoom: 10,
      filter: byClass(["village", "hamlet"]),
      layout: {
        "text-field": name,
        "text-font": t.fontRegular,
        "text-size": ts([
          [10, 10.5],
          [14, 13],
        ]),
        "text-max-width": 8,
      },
      paint: { "text-color": t.label, ...halo },
    },
    {
      id: "label-town",
      type: "symbol",
      source: SRC,
      "source-layer": "place",
      minzoom: 7,
      filter: byClass(["town"]),
      layout: {
        "text-field": name,
        "text-font": t.fontRegular,
        "text-size": ts([
          [7, 11],
          [12, 15],
        ]),
        "text-max-width": 8,
      },
      paint: { "text-color": t.labelStrong, ...halo },
    },
    {
      id: "label-city",
      type: "symbol",
      source: SRC,
      "source-layer": "place",
      minzoom: 3,
      maxzoom: 16,
      filter: byClass(["city"]),
      layout: {
        "text-field": name,
        "text-font": t.fontBold,
        "text-size": ts([
          [4, 11],
          [8, 15],
          [13, 22],
        ]),
        "text-max-width": 8,
        "symbol-sort-key": ["get", "rank"],
      },
      paint: { "text-color": t.labelStrong, ...halo },
    },
    {
      id: "label-state",
      type: "symbol",
      source: SRC,
      "source-layer": "place",
      minzoom: 5,
      maxzoom: 8,
      filter: byClass(["state"]),
      layout: {
        "text-field": name,
        "text-font": t.fontRegular,
        "text-transform": "uppercase",
        "text-letter-spacing": 0.15,
        "text-size": tc(11),
        "text-max-width": 8,
      },
      paint: { "text-color": t.labelSubtle, ...halo },
    },
    {
      id: "label-country",
      type: "symbol",
      source: SRC,
      "source-layer": "place",
      maxzoom: 9,
      filter: byClass(["country"]),
      layout: {
        "text-field": name,
        "text-font": t.fontBold,
        "text-size": ts([
          [2, 11],
          [6, 15],
        ]),
        "text-max-width": 8,
      },
      paint: { "text-color": t.labelStrong, ...halo },
    },
  ] as LayerSpecification[];
}
