import type { ExpressionSpecification } from "maplibre-gl";
import type { MapSettings } from "./settings.js";

export const SRC = "openmaptiles";
export const isLine = [
  "match",
  ["geometry-type"],
  ["LineString", "MultiLineString"],
  true,
  false,
] as ExpressionSpecification;
export const isPoly = [
  "match",
  ["geometry-type"],
  ["Polygon", "MultiPolygon"],
  true,
  false,
] as ExpressionSpecification;
export const isPoint = [
  "match",
  ["geometry-type"],
  ["Point", "MultiPoint"],
  true,
  false,
] as ExpressionSpecification;

export const nameField = (
  lang: MapSettings["lang"],
): ExpressionSpecification => [
  "coalesce",
  ["get", `name:${lang}`],
  ["get", `name_${lang}`],
  ["get", "name"],
];

export type StopValue = number | ExpressionSpecification;
export type Stops = ReadonlyArray<readonly [number, StopValue]>;

export const zexp = (stops: Stops, base = 1.55): ExpressionSpecification =>
  [
    "interpolate",
    ["exponential", base],
    ["zoom"],
    ...stops.flat(),
  ] as ExpressionSpecification;

export const zlin = (stops: Stops): ExpressionSpecification =>
  [
    "interpolate",
    ["linear"],
    ["zoom"],
    ...stops.flat(),
  ] as ExpressionSpecification;

export const scaleStops = (stops: Stops, factor: number): Stops =>
  stops.map(([zoom, value]) => [zoom, +(Number(value) * factor).toFixed(3)]);

export const vis = (on: boolean): { visibility: "visible" | "none" } => ({
  visibility: on ? "visible" : "none",
});
