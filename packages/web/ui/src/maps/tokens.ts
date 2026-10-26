import {
  cssVariable,
  mapTokenValues,
  type KTokenName,
} from "@k-design-system/tokens";

export interface MapTokens {
  background: string;
  water: string;
  waterLabel: string;
  park: string;
  wood: string;
  grass: string;
  cemetery: string;
  landuseResidential: string;
  landuseIndustrial: string;
  landuseCommercial: string;
  landuseHospital: string;
  landuseSchool: string;
  sand: string;
  aeroway: string;
  building: string;
  buildingOutline: string;
  road: string;
  roadCasing: string;
  roadMinor: string;
  roadMinorCasing: string;
  path: string;
  motorway: string;
  motorwayCasing: string;
  trunk: string;
  trunkCasing: string;
  tunnelOpacity: number;
  rail: string;
  boundary: string;
  label: string;
  labelStrong: string;
  labelSubtle: string;
  labelHalo: string;
  poiFood: string;
  poiShop: string;
  poiHealth: string;
  poiEducation: string;
  poiLeisure: string;
  poiTransport: string;
  poiOther: string;
  poiStroke: string;
  fontRegular: string[];
  fontBold: string[];
  fontItalic: string[];
}

type MapTokenType = "color" | "number" | "fontFamily";

const MAP_TOKEN_DEFINITIONS = [
  ["background", "map.color.background", "color", "Map canvas"],
  ["water", "map.color.water", "color", "Water fill"],
  ["waterLabel", "map.color.waterLabel", "color", "Water labels"],
  ["park", "map.color.park", "color", "Park fill"],
  ["wood", "map.color.wood", "color", "Woodland fill"],
  ["grass", "map.color.grass", "color", "Grass and farmland fill"],
  ["cemetery", "map.color.cemetery", "color", "Cemetery fill"],
  [
    "landuseResidential",
    "map.color.landuseResidential",
    "color",
    "Residential land use",
  ],
  [
    "landuseIndustrial",
    "map.color.landuseIndustrial",
    "color",
    "Industrial land use",
  ],
  [
    "landuseCommercial",
    "map.color.landuseCommercial",
    "color",
    "Commercial land use",
  ],
  [
    "landuseHospital",
    "map.color.landuseHospital",
    "color",
    "Hospital land use",
  ],
  ["landuseSchool", "map.color.landuseSchool", "color", "School land use"],
  ["sand", "map.color.sand", "color", "Sand fill"],
  ["aeroway", "map.color.aeroway", "color", "Airport areas and runways"],
  ["building", "map.color.building", "color", "Building fill"],
  ["buildingOutline", "map.color.buildingOutline", "color", "Building outline"],
  ["road", "map.color.road", "color", "Major road fill"],
  ["roadCasing", "map.color.roadCasing", "color", "Major road casing"],
  ["roadMinor", "map.color.roadMinor", "color", "Minor road fill"],
  [
    "roadMinorCasing",
    "map.color.roadMinorCasing",
    "color",
    "Minor road casing",
  ],
  ["path", "map.color.path", "color", "Foot and cycle paths"],
  ["motorway", "map.color.motorway", "color", "Motorway fill"],
  ["motorwayCasing", "map.color.motorwayCasing", "color", "Motorway casing"],
  ["trunk", "map.color.trunk", "color", "Trunk road fill"],
  ["trunkCasing", "map.color.trunkCasing", "color", "Trunk road casing"],
  ["tunnelOpacity", "map.opacity.tunnel", "number", "Tunnel road opacity"],
  ["rail", "map.color.rail", "color", "Rail lines"],
  ["boundary", "map.color.boundary", "color", "Administrative boundaries"],
  ["label", "map.color.label", "color", "Default labels"],
  ["labelStrong", "map.color.labelStrong", "color", "Prominent labels"],
  ["labelSubtle", "map.color.labelSubtle", "color", "Secondary labels"],
  ["labelHalo", "map.color.labelHalo", "color", "Label halo"],
  ["poiFood", "map.color.poiFood", "color", "Food POIs"],
  ["poiShop", "map.color.poiShop", "color", "Shopping POIs"],
  ["poiHealth", "map.color.poiHealth", "color", "Health POIs"],
  ["poiEducation", "map.color.poiEducation", "color", "Education POIs"],
  ["poiLeisure", "map.color.poiLeisure", "color", "Leisure POIs"],
  ["poiTransport", "map.color.poiTransport", "color", "Transport POIs"],
  ["poiOther", "map.color.poiOther", "color", "Other POIs"],
  ["poiStroke", "map.color.poiStroke", "color", "POI dot outline"],
  ["fontRegular", "map.font.regular", "fontFamily", "Regular map glyph stack"],
  ["fontBold", "map.font.bold", "fontFamily", "Bold map glyph stack"],
  ["fontItalic", "map.font.italic", "fontFamily", "Italic map glyph stack"],
] as const satisfies ReadonlyArray<
  readonly [keyof MapTokens, KTokenName, MapTokenType, string]
>;

const readFontStack = (value: string) =>
  value
    .split(",")
    .map((font) => font.trim().replace(/^['"]|['"]$/g, ""))
    .filter(Boolean);

function mapTokensFromTheme(
  values: (typeof mapTokenValues)[keyof typeof mapTokenValues],
): MapTokens {
  return Object.fromEntries(
    MAP_TOKEN_DEFINITIONS.map(([key, token, type]) => {
      const value = values[token];
      return [
        key,
        type === "fontFamily" ? readFontStack(String(value)) : value,
      ];
    }),
  ) as unknown as MapTokens;
}

export const LIGHT_MAP_TOKENS = mapTokensFromTheme(mapTokenValues.light);
export const DARK_MAP_TOKENS = mapTokensFromTheme(mapTokenValues.dark);

export type MapTokenMetadata = {
  key: keyof MapTokens;
  token: KTokenName;
  cssVariable: string;
  type: MapTokenType;
  description: string;
  defaults: {
    light: MapTokens[keyof MapTokens];
    dark: MapTokens[keyof MapTokens];
  };
};

export const MAP_TOKEN_METADATA: readonly MapTokenMetadata[] =
  MAP_TOKEN_DEFINITIONS.map(([key, token, type, description]) => ({
    key,
    token,
    cssVariable: cssVariable(token),
    type,
    description,
    defaults: {
      light: LIGHT_MAP_TOKENS[key],
      dark: DARK_MAP_TOKENS[key],
    },
  }));

export function readMapTokens(
  element: Element | undefined = typeof document === "undefined"
    ? undefined
    : document.documentElement,
  overrides: Partial<MapTokens> = {},
): MapTokens {
  const result: MapTokens = { ...LIGHT_MAP_TOKENS };
  const writable = result as unknown as Record<keyof MapTokens, unknown>;
  const styles = element ? getComputedStyle(element) : undefined;

  for (const metadata of MAP_TOKEN_METADATA) {
    const value = styles?.getPropertyValue(metadata.cssVariable).trim();
    if (!value) continue;
    writable[metadata.key] =
      metadata.type === "number"
        ? Number(value)
        : metadata.type === "fontFamily"
          ? readFontStack(value)
          : value;
  }

  return { ...result, ...overrides };
}
