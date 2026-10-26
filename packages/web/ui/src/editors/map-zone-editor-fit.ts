import { useEffect, useRef, useState } from "react";
import type { KMapPosition, KMapZone } from "../maps/map-zone-geometry.js";
import { zoneCoordinates } from "./map-zone-editor-state.js";

export function zoneEditorFitCoordinates(
  zones: readonly KMapZone[],
  selectedZoneId: string | null,
  initial: boolean,
) {
  const selected = initial
    ? undefined
    : zones.find((zone) => zone.id === selectedZoneId);
  return zoneCoordinates(selected ? [selected] : zones);
}

export function useZoneEditorFit(
  zones: readonly KMapZone[],
  selectedZoneId: string | null,
  draft: KMapZone | null,
) {
  const [coordinates, setCoordinates] = useState<readonly KMapPosition[]>(() =>
    zoneEditorFitCoordinates(zones, selectedZoneId, true),
  );
  const initialFitComplete = useRef(false);
  const geometryRevision = JSON.stringify(
    zones.map(({ id, coordinates: points, polygons, circle }) => ({
      id,
      coordinates: points,
      polygons,
      circle,
    })),
  );
  useEffect(() => {
    if (draft) return;
    if (!initialFitComplete.current && zones.length > 0) {
      initialFitComplete.current = true;
      setCoordinates(zoneEditorFitCoordinates(zones, selectedZoneId, true));
      return;
    }
    setCoordinates(zoneEditorFitCoordinates(zones, selectedZoneId, false));
  }, [draft, selectedZoneId, geometryRevision]);
  return [coordinates, setCoordinates] as const;
}

export function useZoneEditorPanel(
  panelOpen: boolean | undefined,
  defaultPanelOpen: boolean,
  onPanelOpenChange: ((open: boolean) => void) | undefined,
  onLayoutChange: () => void,
) {
  const [localOpen, setLocalOpen] = useState(defaultPanelOpen);
  const open = panelOpen ?? localOpen;
  const setOpen = (next: boolean) => {
    if (panelOpen === undefined) setLocalOpen(next);
    onPanelOpenChange?.(next);
    onLayoutChange();
  };
  return [open, setOpen] as const;
}
