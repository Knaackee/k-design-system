export interface MapSettings {
  lang: "de" | "en" | "fr" | "it" | "es" | "pl" | "nl";
  roadWidthScale: number;
  casingScale: number;
  labelScale: number;
  haloWidth: number;
  showLanduse: boolean;
  showBuildings: boolean;
  buildingMinZoom: number;
  showRail: boolean;
  showPaths: boolean;
  showPois: boolean;
  poiMinZoom: number;
  poiMaxRank: number;
  poiDotScale: number;
  roadLabelMinZoom: number;
  showQuarterLabels: boolean;
}

export const DEFAULT_SETTINGS: MapSettings = {
  lang: "de",
  roadWidthScale: 1,
  casingScale: 1,
  labelScale: 1,
  haloWidth: 1.4,
  showLanduse: true,
  showBuildings: true,
  buildingMinZoom: 14.5,
  showRail: true,
  showPaths: true,
  showPois: true,
  poiMinZoom: 15,
  poiMaxRank: 18,
  poiDotScale: 1,
  roadLabelMinZoom: 13,
  showQuarterLabels: true,
};

export type MapSettingMetadata =
  | {
      key: keyof MapSettings;
      label: string;
      description: string;
      type: "range";
      min: number;
      max: number;
      step: number;
    }
  | {
      key: keyof MapSettings;
      label: string;
      description: string;
      type: "toggle";
    }
  | {
      key: keyof MapSettings;
      label: string;
      description: string;
      type: "select";
      options: readonly MapSettings["lang"][];
    };

export const SETTINGS_SCHEMA: readonly MapSettingMetadata[] = [
  {
    key: "lang",
    label: "Label language",
    description: "Preferred label language with source-name fallback.",
    type: "select",
    options: ["de", "en", "fr", "it", "es", "pl", "nl"],
  },
  {
    key: "roadWidthScale",
    label: "Road width",
    description: "Scale applied to every road fill width.",
    type: "range",
    min: 0.6,
    max: 1.6,
    step: 0.05,
  },
  {
    key: "casingScale",
    label: "Road casing",
    description: "Scale applied to road casing width.",
    type: "range",
    min: 0,
    max: 2,
    step: 0.1,
  },
  {
    key: "labelScale",
    label: "Label size",
    description: "Scale applied to map label sizes.",
    type: "range",
    min: 0.8,
    max: 1.4,
    step: 0.05,
  },
  {
    key: "haloWidth",
    label: "Text halo",
    description: "Text halo width in pixels.",
    type: "range",
    min: 0,
    max: 3,
    step: 0.1,
  },
  {
    key: "showLanduse",
    label: "Land use",
    description: "Show residential, commercial and civic land-use fills.",
    type: "toggle",
  },
  {
    key: "showBuildings",
    label: "Buildings",
    description: "Show building footprints.",
    type: "toggle",
  },
  {
    key: "buildingMinZoom",
    label: "Buildings from zoom",
    description: "Minimum zoom for building footprints.",
    type: "range",
    min: 12,
    max: 17,
    step: 0.5,
  },
  {
    key: "showRail",
    label: "Rail lines",
    description: "Show rail and transit lines.",
    type: "toggle",
  },
  {
    key: "showPaths",
    label: "Foot and cycle paths",
    description: "Show path-class transportation lines.",
    type: "toggle",
  },
  {
    key: "showPois",
    label: "POIs",
    description: "Show points of interest and their labels.",
    type: "toggle",
  },
  {
    key: "poiMinZoom",
    label: "POIs from zoom",
    description: "Minimum zoom for points of interest.",
    type: "range",
    min: 13,
    max: 18,
    step: 0.5,
  },
  {
    key: "poiMaxRank",
    label: "POI density",
    description: "Maximum OpenMapTiles POI rank; lower values show fewer POIs.",
    type: "range",
    min: 1,
    max: 40,
    step: 1,
  },
  {
    key: "poiDotScale",
    label: "POI dot size",
    description: "Scale applied to POI dots.",
    type: "range",
    min: 0.5,
    max: 2,
    step: 0.1,
  },
  {
    key: "roadLabelMinZoom",
    label: "Road names from zoom",
    description:
      "Minimum zoom for major road labels; minor labels start two levels later.",
    type: "range",
    min: 11,
    max: 17,
    step: 0.5,
  },
  {
    key: "showQuarterLabels",
    label: "Quarter labels",
    description: "Show suburb, quarter and neighbourhood labels.",
    type: "toggle",
  },
];
