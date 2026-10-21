import { useEffect, useState } from "react";
import type { KMapPosition, KMapZone } from "../maps/map-zone-geometry.js";
import { zoneCoordinates } from "./map-zone-editor-state.js";

export function useZoneEditorFit(
  zones: readonly KMapZone[],
  selectedZoneId: string | null,
  draft: KMapZone | null,
) {
  const [coordinates, setCoordinates] = useState<readonly KMapPosition[]>(
    () => {
      const selected = zones.find((zone) => zone.id === selectedZoneId);
      return zoneCoordinates(selected ? [selected] : zones);
    },
  );
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
    const selected = zones.find((zone) => zone.id === selectedZoneId);
    setCoordinates(zoneCoordinates(selected ? [selected] : zones));
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
