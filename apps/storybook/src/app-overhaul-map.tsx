import { useMemo } from "react";
import {
  KMap,
  type KMapPin,
  type KMapRoute,
} from "@k-design-system/ui/patterns/map";
import {
  createMapStyle,
  DARK_MAP_TOKENS,
  LIGHT_MAP_TOKENS,
} from "@k-design-system/ui/maps";
import { KIcon } from "@k-design-system/ui";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import markUrl from "./offer-overview-mark.svg";
setWorkerUrl(workerUrl);
const coordinates: [number, number][] = [
  [12.3748, 51.3405],
  [12.3749, 51.3394],
  [12.3754, 51.3386],
  [12.3763, 51.3377],
  [12.3771, 51.3368],
  [12.3774, 51.3356],
];
const routes: KMapRoute[] = [{ id: "gallery-journey", coordinates }];
const pins: KMapPin[] = [
  {
    id: "previous",
    position: coordinates[0],
    label: "Vorheriger Termin",
    icon: "check",
    size: 32,
    shape: "circle",
  },
  {
    id: "next",
    position: coordinates.at(-1)!,
    label: "Nächster Termin",
    imageUrl: markUrl,
    size: 36,
  },
];
export function AppOverhaulMap({
  dark = false,
  large = false,
}: {
  dark?: boolean;
  large?: boolean;
}) {
  const style = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  return (
    <div className={`ao-map ${large ? "ao-map--large" : ""}`}>
      <KMap
        mapStyle={style}
        center={coordinates[0]}
        pins={pins}
        routes={routes}
        fitContent
        fitPadding={42}
        fitMaxZoom={15}
        fitDurationMs={0}
        interactive={false}
        showZoomControls={false}
        label="Galerie-Beispielroute in Leipzig"
      />
      <span className="ao-map-pill">
        <KIcon name="car" size={16} />
        14 Min
      </span>
    </div>
  );
}
