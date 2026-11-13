import { useEffect, useRef, useState } from "react";
import { Map, type StyleSpecification } from "maplibre-gl";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { KSpinner } from "../extended-components.js";
import { MapOverlays, type KMapOverlayProps } from "../maps/map-overlays.js";
export type {
  KMapPin,
  KMapRoute,
  KMapRouteSegment,
  KMapPinMove,
  KMapPinDragOptions,
  KMapZone,
} from "../maps/map-overlays.js";

function collapseAttribution(instance: Map) {
  // MapLibre 6 opens compact attribution initially; retain its accessible toggle.
  instance
    .getContainer()
    .querySelector<HTMLElement>(
      ".maplibregl-compact-show > .maplibregl-ctrl-attrib-button",
    )
    ?.click();
}

export interface KMapAttributionState {
  open: boolean;
  height: number;
}

export interface KMapView {
  center: [number, number];
  zoom: number;
  /** Visible geographic extent as west, south, east, north. */
  bounds?: [number, number, number, number];
}

function observeAttribution(
  container: HTMLElement,
  onChange: (state: KMapAttributionState) => void,
) {
  let element: HTMLElement | null = null;
  let discovered = false;
  let previous = "";
  const publish = () => {
    const style = element ? getComputedStyle(element) : null;
    const height = element
      ? Math.ceil(
          element.getBoundingClientRect().height +
            Number.parseFloat(style?.marginBlockStart || "0") +
            Number.parseFloat(style?.marginBlockEnd || "0"),
        )
      : 0;
    const state = {
      open: !!element?.classList.contains("maplibregl-compact-show"),
      height,
    };
    const serialized = `${state.open}:${state.height}`;
    if (serialized !== previous) {
      previous = serialized;
      onChange(state);
    }
  };
  const resize = new ResizeObserver(publish);
  const attributes = new MutationObserver(publish);
  const discover = () => {
    const next = container.querySelector<HTMLElement>(
      ".maplibregl-ctrl-attrib",
    );
    if (discovered && next === element) return;
    discovered = true;
    resize.disconnect();
    attributes.disconnect();
    element = next;
    if (element) {
      resize.observe(element);
      attributes.observe(element, {
        attributes: true,
        attributeFilter: ["class", "style"],
      });
    }
    publish();
  };
  const children = new MutationObserver(discover);
  children.observe(container, {
    childList: true,
    subtree: true,
  });
  discover();
  return () => {
    children.disconnect();
    attributes.disconnect();
    resize.disconnect();
  };
}

export interface KMapProps extends KMapOverlayProps {
  mapStyle: string | StyleSpecification;
  center: [number, number];
  zoom?: number;
  label?: string;
  showZoomControls?: boolean;
  interactive?: boolean;
  /** Remove the viewport radius when an enclosing surface owns its shape. */
  embedded?: boolean;
  /** Camera movement when center/zoom changes. Zero preserves immediate updates. */
  cameraTransitionMs?: number;
  onViewChange?: (view: KMapView) => void;
  onMapClick?: (position: [number, number]) => void;
  onAttributionChange?: (state: KMapAttributionState) => void;
}

/** The host supplies tiles and configures the MapLibre worker and stylesheet. */
export function KMap({
  mapStyle,
  center,
  zoom = 13,
  label = "Karte",
  showZoomControls = true,
  interactive = true,
  embedded = false,
  cameraTransitionMs = 0,
  onViewChange,
  onMapClick,
  onAttributionChange,
  ...overlays
}: KMapProps) {
  const canvas = useRef<HTMLDivElement>(null);
  const map = useRef<Map | null>(null);
  const [instance, setInstance] = useState<Map | null>(null);
  const [status, setStatus] = useState<"loading" | "ready" | "error">(
    "loading",
  );
  const [attempt, setAttempt] = useState(0);
  const [longitude, latitude] = center;
  const initial = useRef({ mapStyle, longitude, latitude, zoom });
  const appliedStyle = useRef(mapStyle);
  const viewChange = useRef(onViewChange);
  viewChange.current = onViewChange;
  const mapClick = useRef(onMapClick);
  mapClick.current = onMapClick;
  const attributionChange = useRef(onAttributionChange);
  attributionChange.current = onAttributionChange;

  useEffect(() => {
    if (!canvas.current) return;
    setStatus("loading");
    let instance: Map;
    try {
      instance = new Map({
        container: canvas.current,
        style: initial.current.mapStyle,
        center: [initial.current.longitude, initial.current.latitude],
        zoom: initial.current.zoom,
        attributionControl: { compact: true },
      });
    } catch {
      setStatus("error");
      return;
    }
    map.current = instance;
    setInstance(instance);
    appliedStyle.current = initial.current.mapStyle;
    const timeout = window.setTimeout(() => setStatus("error"), 20000);
    const publishView = () => {
      const position = instance.getCenter();
      const bounds = instance.getBounds();
      viewChange.current?.({
        center: [position.lng, position.lat],
        zoom: instance.getZoom(),
        bounds: [
          bounds.getWest(),
          bounds.getSouth(),
          bounds.getEast(),
          bounds.getNorth(),
        ],
      });
    };
    instance.on("load", () => {
      window.clearTimeout(timeout);
      collapseAttribution(instance);
      setStatus("ready");
      publishView();
    });
    instance.on("error", () => setStatus("error"));
    instance.on("moveend", publishView);
    instance.on("click", (event) => {
      const position: [number, number] = [event.lngLat.lng, event.lngLat.lat];
      // Layer-specific click handlers run in the same dispatch and may claim the click.
      queueMicrotask(() => mapClick.current?.(position));
    });
    instance.on("idle", () => {
      if (instance.isStyleLoaded()) {
        window.clearTimeout(timeout);
        setStatus("ready");
      }
    });
    const resize = new ResizeObserver(() => instance.resize());
    resize.observe(canvas.current);
    const stopObservingAttribution = observeAttribution(
      instance.getContainer(),
      (state) => attributionChange.current?.(state),
    );
    return () => {
      window.clearTimeout(timeout);
      resize.disconnect();
      stopObservingAttribution();
      setInstance(null);
      instance.remove();
      map.current = null;
    };
  }, [attempt]);

  useEffect(() => {
    const instance = map.current;
    if (!instance || appliedStyle.current === mapStyle) return;
    appliedStyle.current = mapStyle;
    setStatus("loading");
    // setStyle preserves the camera; recreating the map would reset user gestures.
    instance.once("idle", () => collapseAttribution(instance));
    instance.setStyle(mapStyle);
  }, [mapStyle, attempt]);

  useEffect(() => {
    const instance = map.current;
    if (!instance) return;
    const position = instance.getCenter();
    if (
      Math.abs(position.lng - longitude) > 1e-8 ||
      Math.abs(position.lat - latitude) > 1e-8 ||
      Math.abs(instance.getZoom() - zoom) > 1e-8
    ) {
      const duration = window.matchMedia("(prefers-reduced-motion: reduce)")
        .matches
        ? 0
        : cameraTransitionMs;
      if (duration > 0)
        instance.flyTo({ center: [longitude, latitude], zoom, duration });
      else instance.jumpTo({ center: [longitude, latitude], zoom });
    }
  }, [longitude, latitude, zoom, attempt, cameraTransitionMs]);

  useEffect(() => {
    const instance = map.current;
    if (!instance) return;
    for (const handler of [
      instance.scrollZoom,
      instance.boxZoom,
      instance.dragRotate,
      instance.dragPan,
      instance.keyboard,
      instance.doubleClickZoom,
      instance.touchZoomRotate,
    ]) {
      if (interactive) handler.enable();
      else handler.disable();
    }
  }, [interactive, attempt]);

  return (
    <section
      className="k-map"
      data-embedded={embedded || undefined}
      aria-label={label}
    >
      <div ref={canvas} className="k-map__canvas" />
      <MapOverlays map={instance} {...overlays} />
      {showZoomControls && (
        <div
          className="k-map__controls"
          role="toolbar"
          aria-label="Kartenansicht"
        >
          <KButton
            variant="secondary"
            aria-label="Vergrößern"
            title="Vergrößern"
            onClick={() => map.current?.zoomIn({ duration: 0 })}
          >
            <KIcon name="plus" />
          </KButton>
          <KButton
            variant="secondary"
            aria-label="Verkleinern"
            title="Verkleinern"
            onClick={() => map.current?.zoomOut({ duration: 0 })}
          >
            <KIcon name="minus" />
          </KButton>
        </div>
      )}
      {status !== "ready" && (
        <div className="k-map__status" role="status">
          {status === "loading" && <KSpinner aria-hidden="true" />}
          {status === "loading"
            ? "Karte wird geladen …"
            : "Karte konnte nicht geladen werden."}
          {status === "error" && (
            <KButton
              variant="secondary"
              onClick={() => setAttempt((value) => value + 1)}
            >
              Erneut versuchen
            </KButton>
          )}
        </div>
      )}
    </section>
  );
}
