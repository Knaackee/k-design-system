export type KMapPosition = [number, number];
export interface KMapPolygon {
  outer: KMapPosition[];
  holes?: KMapPosition[][];
}
export type KMapZoneAvailability =
  | { kind: "recurring"; rrule: string; startDate: string; timeZone: string }
  | { kind: "date-range"; from: string; to: string };
export type KMapZoneTravelCost =
  | { kind: "per-kilometer"; amount: number; currency: string }
  | { kind: "flat-rate"; amount: number; currency: string }
  | { kind: "free" };
export interface KMapZoneWorkingDay {
  /** ISO weekday: Monday=1, Sunday=7. A complete week contains seven unique days. */
  day: number;
  intervals: { start: string; end: string }[];
}
export interface KMapZoneSettings {
  workingHours?: KMapZoneWorkingDay[];
  requestRequired?: boolean;
  travelCost?: KMapZoneTravelCost;
  surcharge?: { amount: number; currency: string };
  availability?: KMapZoneAvailability;
}
export interface KMapZone {
  id: string;
  name: string;
  coordinates: KMapPosition[];
  polygons?: KMapPolygon[];
  color?: string;
  presentation?: "template" | "template-selected";
  kind?: "circle" | "postal" | "polygon";
  circle?: { center: KMapPosition; radiusKm: number };
  source?: {
    type: "postal";
    id?: string;
    country: string;
    code: string;
    label: string;
    provider?: string;
    version?: string;
  };
  settings?: KMapZoneSettings;
}
export interface KMapPostalArea {
  polygons?: KMapPolygon[];
  id: string;
  country: string;
  code: string;
  label: string;
  coordinates: KMapPosition[];
  sourceLabel: string;
  sourceVersion?: string;
  assignedZoneId?: string;
}
export type KMapZoneValidationCode =
  | "invalid-coordinate"
  | "minimum-vertices"
  | "self-intersection"
  | "zone-overlap"
  | "external-change";
export interface KMapZoneValidationError {
  code: KMapZoneValidationCode;
  message: string;
  zoneId?: string;
  conflictingZoneId?: string;
}
