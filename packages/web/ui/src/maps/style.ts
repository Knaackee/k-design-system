import type { StyleSpecification } from "maplibre-gl";
import { buildLayers } from "./layers.js";
import { DEFAULT_SETTINGS, type MapSettings } from "./settings.js";
import { LIGHT_MAP_TOKENS, type MapTokens } from "./tokens.js";

export interface MapSources {
  tiles: string;
  glyphs: string;
  attribution: string;
}

export const DEFAULT_MAP_SOURCES: MapSources = {
  tiles: "https://tiles.openfreemap.org/planet",
  glyphs: "https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf",
  attribution:
    '<a href="https://openfreemap.org" target="_blank">OpenFreeMap</a> ' +
    '<a href="https://www.openmaptiles.org/" target="_blank">&copy; OpenMapTiles</a> ' +
    'Data from <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>',
};

export interface CreateMapStyleOptions {
  tokens?: Partial<MapTokens>;
  settings?: Partial<MapSettings>;
  sources?: Partial<MapSources>;
}

/** Builds a MapLibre style without importing or initializing a map renderer. */
export function createMapStyle(
  options: CreateMapStyleOptions = {},
): StyleSpecification {
  const tokens: MapTokens = { ...LIGHT_MAP_TOKENS, ...options.tokens };
  const settings: MapSettings = { ...DEFAULT_SETTINGS, ...options.settings };
  const sources: MapSources = { ...DEFAULT_MAP_SOURCES, ...options.sources };

  return {
    version: 8,
    name: "KDS Map Style",
    metadata: {
      "kds:generator": "@k-design-system/ui/maps",
      "kds:settings": settings,
      "kds:slots": { route: "kds-slot-route" },
    },
    sources: {
      openmaptiles: {
        type: "vector",
        url: sources.tiles,
        attribution: sources.attribution,
      },
    },
    glyphs: sources.glyphs,
    layers: buildLayers(tokens, settings),
  };
}
