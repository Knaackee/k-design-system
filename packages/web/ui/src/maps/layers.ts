import type { ExpressionSpecification, LayerSpecification } from "maplibre-gl";
import { buildLabelLayers } from "./label-layers.js";
import { SRC, isLine, isPoly, vis, zexp, zlin } from "./layer-expressions.js";
import { roadLayers } from "./road-layers.js";
import { DEFAULT_SETTINGS, type MapSettings } from "./settings.js";
import type { MapTokens } from "./tokens.js";

export function buildLayers(
  t: MapTokens,
  settings: Partial<MapSettings> = {},
): LayerSpecification[] {
  const S = { ...DEFAULT_SETTINGS, ...settings };

  const fillLayer = (
    id: string,
    sourceLayer: string,
    filter: boolean | ExpressionSpecification,
    color: string,
    extra: {
      visible?: boolean;
      paint?: Record<string, unknown>;
      layer?: Record<string, unknown>;
    } = {},
  ): LayerSpecification =>
    ({
      id,
      type: "fill",
      source: SRC,
      "source-layer": sourceLayer,
      filter: ["all", isPoly, filter],
      layout: vis(extra.visible ?? true),
      paint: { "fill-color": color, "fill-antialias": true, ...extra.paint },
      ...extra.layer,
    }) as LayerSpecification;
  const LU = S.showLanduse;
  const byClass = (classes: readonly string[]): ExpressionSpecification =>
    [
      "match",
      ["get", "class"],
      [...classes],
      true,
      false,
    ] as ExpressionSpecification;

  return [
    {
      id: "background",
      type: "background",
      paint: { "background-color": t.background },
    },

    // --- Flächen -----------------------------------------------------------
    fillLayer(
      "landuse-residential",
      "landuse",
      byClass(["residential", "suburb", "neighbourhood", "quarter"]),
      t.landuseResidential,
      { visible: LU },
    ),
    fillLayer(
      "landuse-commercial",
      "landuse",
      byClass(["commercial", "retail"]),
      t.landuseCommercial,
      { visible: LU, layer: { minzoom: 12 } },
    ),
    fillLayer(
      "landuse-industrial",
      "landuse",
      byClass(["industrial", "railway", "garages"]),
      t.landuseIndustrial,
      { visible: LU, layer: { minzoom: 12 } },
    ),
    fillLayer(
      "landuse-hospital",
      "landuse",
      byClass(["hospital"]),
      t.landuseHospital,
      { visible: LU, layer: { minzoom: 12 } },
    ),
    fillLayer(
      "landuse-school",
      "landuse",
      byClass(["school", "university", "college", "kindergarten"]),
      t.landuseSchool,
      { visible: LU, layer: { minzoom: 12 } },
    ),
    fillLayer(
      "landuse-cemetery",
      "landuse",
      byClass(["cemetery"]),
      t.cemetery,
      { visible: LU, layer: { minzoom: 11 } },
    ),
    fillLayer("landcover-sand", "landcover", byClass(["sand"]), t.sand),
    fillLayer(
      "landcover-grass",
      "landcover",
      byClass(["grass", "farmland", "wetland"]),
      t.grass,
      {
        paint: {
          "fill-opacity": zlin([
            [8, 0.4],
            [12, 0.9],
          ]),
        },
      },
    ),
    fillLayer("landcover-wood", "landcover", byClass(["wood"]), t.wood, {
      paint: {
        "fill-opacity": zlin([
          [6, 0.5],
          [12, 1],
        ]),
      },
    }),
    fillLayer("park", "park", true, t.park, {
      paint: {
        "fill-opacity": zlin([
          [6, 0.6],
          [11, 1],
        ]),
      },
    }),
    fillLayer(
      "landuse-pitch",
      "landuse",
      byClass(["pitch", "stadium", "playground"]),
      t.grass,
      { layer: { minzoom: 13 } },
    ),
    fillLayer(
      "aeroway-area",
      "aeroway",
      byClass(["runway", "taxiway", "aerodrome", "apron"]),
      t.aeroway,
      { layer: { minzoom: 11 } },
    ),

    // --- Wasser ------------------------------------------------------------
    fillLayer("water", "water", ["!=", ["get", "brunnel"], "tunnel"], t.water),
    {
      id: "waterway",
      type: "line",
      source: SRC,
      "source-layer": "waterway",
      filter: ["all", isLine, ["!=", ["get", "brunnel"], "tunnel"]],
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-color": t.water,
        // Ein Zoom-Interpolate außen, Klassenunterscheidung innen (Style-Spec-Regel)
        "line-width": zexp(
          [8, 12, 15, 18].map((z, i) => [
            z,
            [
              "match",
              ["get", "class"],
              ["river", "canal"],
              [0.6, 1.6, 4, 10][i],
              [0, 0.4, 1.4, 4][i],
            ],
          ]),
        ),
      },
    },

    // --- Gebäude -----------------------------------------------------------
    {
      id: "building",
      type: "fill",
      source: SRC,
      "source-layer": "building",
      minzoom: S.buildingMinZoom,
      layout: vis(S.showBuildings),
      paint: {
        "fill-color": t.building,
        "fill-outline-color": t.buildingOutline,
        "fill-opacity": zlin([
          [S.buildingMinZoom, 0],
          [S.buildingMinZoom + 1.5, 1],
        ]),
      },
    },

    // --- Bahn & Flughafen-Linien --------------------------------------------
    {
      id: "aeroway-runway",
      type: "line",
      source: SRC,
      "source-layer": "aeroway",
      minzoom: 11,
      filter: ["all", isLine, byClass(["runway", "taxiway"])],
      paint: {
        "line-color": t.aeroway,
        "line-width": zexp([
          [11, 2],
          [14, 12],
          [17, 40],
        ]),
      },
    },

    // --- Straßen: Tunnel → normal → Bahn → Brücken ---------------------------
    ...roadLayers(t, "tunnel", S),
    {
      id: "road-path",
      type: "line",
      source: SRC,
      "source-layer": "transportation",
      minzoom: 15,
      filter: [
        "all",
        isLine,
        byClass(["path"]),
        ["!=", ["get", "brunnel"], "tunnel"],
      ],
      layout: {
        "line-cap": "round",
        "line-join": "round",
        ...vis(S.showPaths),
      },
      paint: {
        "line-color": t.path,
        "line-width": zexp([
          [15, 0.6],
          [18, 1.6],
        ]),
        "line-dasharray": [2, 2],
      },
    },
    ...roadLayers(t, "normal", S),
    {
      id: "rail",
      type: "line",
      source: SRC,
      "source-layer": "transportation",
      minzoom: 11,
      filter: [
        "all",
        isLine,
        byClass(["rail", "transit"]),
        ["!=", ["get", "brunnel"], "tunnel"],
        ["!", ["has", "service"]],
      ],
      layout: vis(S.showRail),
      paint: {
        "line-color": t.rail,
        "line-width": zexp([
          [11, 0.6],
          [15, 1.4],
          [18, 2.4],
        ]),
      },
    },
    ...roadLayers(t, "bridge", S),

    // --- Grenzen -------------------------------------------------------------
    {
      id: "boundary-state",
      type: "line",
      source: SRC,
      "source-layer": "boundary",
      minzoom: 5,
      filter: [
        "all",
        ["==", ["get", "admin_level"], 4],
        ["!=", ["get", "maritime"], 1],
      ],
      layout: { "line-join": "round" },
      paint: {
        "line-color": t.boundary,
        "line-width": zlin([
          [5, 0.6],
          [10, 1.2],
        ]),
        "line-dasharray": [3, 2],
      },
    },
    {
      id: "boundary-country",
      type: "line",
      source: SRC,
      "source-layer": "boundary",
      filter: [
        "all",
        ["==", ["get", "admin_level"], 2],
        ["!=", ["get", "maritime"], 1],
      ],
      layout: { "line-join": "round" },
      paint: {
        "line-color": t.boundary,
        "line-width": zlin([
          [3, 0.8],
          [10, 2],
        ]),
      },
    },

    // --- Einfügepunkt für App-Daten (Routen, Verkehr) -------------------------
    // Unsichtbarer Anker: map.addLayer(layer, "kds-slot-route") legt Routen unter alle Labels.
    {
      id: "kds-slot-route",
      type: "background",
      layout: { visibility: "none" },
      paint: { "background-color": "rgba(0,0,0,0)" },
    },

    ...buildLabelLayers(t, S),
  ] as LayerSpecification[];
}
