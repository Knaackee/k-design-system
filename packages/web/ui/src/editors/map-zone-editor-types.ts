import type { KMapPinEdgePanOptions } from "../maps/map-pin-drag.js";
import type { KIconName } from "../primitives/icon.js";
import type { KDateFormat, KPickerLocale } from "../pickers/date-values.js";
import type {
  KMapPosition,
  KMapPostalArea,
  KMapZone,
  KMapZoneTravelCost,
  KMapZoneWorkingDay,
  KMapZoneValidationError,
} from "../maps/map-zone-geometry.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import type { ZoneMapProps } from "./map-zone-editor-map.js";

export interface KMapZonePropertyOption {
  value: string;
  label: string;
  shortLabel?: string;
  disabled?: boolean;
  icon?: KIconName;
}

export interface KMapZoneTravelCostSource {
  id: string;
  label: string;
  travelCost: KMapZoneTravelCost;
}

export interface KMapZonePropertyOptions {
  weekdayOptions: readonly KMapZonePropertyOption[];
  currency: string;
  timeZone: string;
  defaultTravelCost?: KMapZoneTravelCost;
  /** Consumer fallback for legacy zones without explicit hours. Never implies 24h. */
  workingHoursLabels?: Partial<
    typeof import("./map-zone-editor-working-hours.js").defaultZoneWorkingHoursLabels
  >;
  defaultWorkingHours?: readonly KMapZoneWorkingDay[];
  workingHoursSources?: readonly {
    id: string;
    label: string;
    workingHours: readonly KMapZoneWorkingDay[];
  }[];
  locale?: KPickerLocale;
  dateFormat?: KDateFormat;
  formatDate?: (isoDate: string) => string;
  /** Existing zone values that can be copied once into the active zone draft. */
  travelCostSources?: readonly KMapZoneTravelCostSource[];
}

export type KMapZoneEditorStage = "home" | "radius" | "postal" | "polygon";

export interface KMapZoneUndoAction {
  message: string;
  label: string;
  /** Invalidated automatically by newer edits or an external document change. */
  undo: () => void;
}

export interface KMapZoneEditorProps {
  zones: readonly KMapZone[];
  selectedZoneId: string | null;
  mapProps: ZoneMapProps;
  onChange: (zones: readonly KMapZone[]) => void;
  onSelect: (id: string | null) => void;
  onValidationError?: (error: KMapZoneValidationError) => void;
  postalAreas?: readonly KMapPostalArea[];
  /** The consumer displays this action in its application snackbar; null dismisses it. */
  onUndoActionChange?: (action: KMapZoneUndoAction | null) => void;
  onPendingChangesChanged?: (pending: boolean) => void;
  onPostalQueryChange?: (query: string) => void;
  startCenter?: KMapPosition;
  defaultRadiusKm?: number;
  labels?: Partial<KMapZoneEditorLabels>;
  disabled?: boolean;
  panelOpen?: boolean;
  defaultPanelOpen?: boolean;
  onPanelOpenChange?: (open: boolean) => void;
  /** Additional clearance in CSS pixels for consumer-owned bottom overlays. */
  bottomOverlayInset?: number;
  fitMaxZoom?: number;
  fitDurationMs?: number;
  edgePan?: false | KMapPinEdgePanOptions;
  propertyOptions?: KMapZonePropertyOptions;
  defaultZoneSettings?: KMapZone["settings"];
}
