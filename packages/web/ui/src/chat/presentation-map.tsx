import { useState } from "react";
import { KCard } from "../primitives/card.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";

export interface KPresentationMapProps {
  title: string;
  latitude: number;
  longitude: number;
  description?: string;
  onOpen: () => void;
  loadLabel?: string;
  openLabel?: string;
}

/** Explicit activation loads the real OSM map, never a fabricated map image. */
export function KPresentationMap({
  title,
  latitude,
  longitude,
  description,
  onOpen,
  loadLabel = "Load map",
  openLabel = "Open map",
}: KPresentationMapProps) {
  const [loaded, setLoaded] = useState(false);
  const valid =
    Number.isFinite(latitude) &&
    Math.abs(latitude) <= 90 &&
    Number.isFinite(longitude) &&
    Math.abs(longitude) <= 180;
  if (!valid) return null;
  const bbox = [
    Math.max(-180, longitude - 0.02),
    Math.max(-90, latitude - 0.01),
    Math.min(180, longitude + 0.02),
    Math.min(90, latitude + 0.01),
  ].join(",");
  const src = `https://www.openstreetmap.org/export/embed.html?${new URLSearchParams({ bbox, layer: "mapnik", marker: `${latitude},${longitude}` })}`;
  return (
    <KCard className="k-presentation-media">
      <header className="k-presentation-media__heading">
        <KIcon name="map-pin" />
        <strong>{title}</strong>
      </header>
      {loaded ? (
        <iframe
          className="k-presentation-video__player"
          title={title}
          src={src}
          loading="lazy"
          sandbox="allow-scripts allow-same-origin allow-popups"
          referrerPolicy="no-referrer"
        />
      ) : (
        <div className="k-presentation-video__placeholder">
          <KButton variant="secondary" onClick={() => setLoaded(true)}>
            <KIcon name="map" />
            {loadLabel}
          </KButton>
        </div>
      )}
      <div className="k-presentation-media__caption">
        {description && <p>{description}</p>}
        <KButton variant="ghost" onClick={onOpen}>
          {openLabel}
          <KIcon name="arrow-up-right" />
        </KButton>
      </div>
    </KCard>
  );
}
