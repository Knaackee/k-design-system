import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { motion, useReducedMotion } from "motion/react";
import { KMap, type KMapProps } from "./map.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { KInput } from "../forms/input.js";

export interface KMapLocation {
  id: string;
  label: string;
  detail?: string;
  position: [number, number];
}
const defaults = {
  title: "Wo dürfen wir dich besuchen?",
  description: "Suche eine Adresse oder verwende deinen aktuellen Standort.",
  search: "Adresse suchen",
  locate: "Aktuellen Standort verwenden",
  placeholder: "Straße, Hausnummer und Ort",
  back: "Zurück",
  searching: "Adressen werden gesucht …",
  empty: "Keine passende Adresse gefunden.",
  error:
    "Das hat nicht geklappt. Bitte versuche es erneut oder suche eine Adresse.",
  adjusted: "Position angepasst",
  edit: "Adresse ändern",
  hint: "Verschiebe den Pin, um deine Position zu präzisieren.",
  confirm: "Position übernehmen",
};
export interface KMapLocationPickerProps {
  mapProps: KMapProps;
  value?: KMapLocation | null;
  defaultValue?: KMapLocation | null;
  onChange?: (value: KMapLocation) => void;
  onSearch: (
    query: string,
    signal: AbortSignal,
  ) => Promise<readonly KMapLocation[]>;
  onLocate?: (signal: AbortSignal) => Promise<KMapLocation>;
  onReverseGeocode?: (
    position: [number, number],
    signal: AbortSignal,
  ) => Promise<KMapLocation>;
  onConfirm?: (value: KMapLocation) => void;
  /** Lets surrounding map controls yield space to search and address choices. */
  onPanelOpenChange?: (open: boolean) => void;
  labels?: Partial<typeof defaults>;
  leading?: ReactNode;
  hint?: ReactNode;
  transitionMs?: number;
  blur?: number;
  selectedZoom?: number;
  bounce?: boolean;
  markerAppearance?: "default" | "bare";
}

/** Consumer-provided geocoding and location access; no provider or permission side effects on mount. */
export function KMapLocationPicker({
  mapProps,
  value,
  defaultValue = null,
  onChange,
  onSearch,
  onLocate,
  onReverseGeocode,
  onConfirm,
  onPanelOpenChange,
  labels,
  leading,
  hint,
  transitionMs = 700,
  blur = 8,
  selectedZoom = 16,
  bounce = true,
  markerAppearance = "default",
}: KMapLocationPickerProps) {
  const text = { ...defaults, ...labels };
  const [localValue, setLocalValue] = useState(defaultValue);
  const location = value === undefined ? localValue : value;
  // Camera targets change only for address choices, never for pin refinement.
  const [camera, setCamera] = useState({
    center: location?.position ?? mapProps.center,
    zoom: location ? selectedZoom : mapProps.zoom,
  });
  const emittedPosition = useRef<string | null>(null);
  const valuePosition = value?.position.join(",") ?? null;
  useEffect(() => {
    if (value === undefined || valuePosition === emittedPosition.current)
      return;
    setCamera({
      center: value?.position ?? mapProps.center,
      zoom: value ? selectedZoom : mapProps.zoom,
    });
  }, [valuePosition]);
  const [panel, setPanel] = useState<"choice" | "search" | "closed">(
    location ? "closed" : "choice",
  );
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<readonly KMapLocation[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(false);
  const [arrived, setArrived] = useState(!!location);
  const [showHint, setShowHint] = useState(!!location);
  const [arrival, setArrival] = useState(0);
  const operation = useRef<AbortController | null>(null);
  const searchInput = useRef<HTMLInputElement>(null);
  const pill = useRef<HTMLButtonElement>(null);
  const reduced = useReducedMotion();
  const duration = reduced ? 0 : transitionMs;
  const open = panel !== "closed";
  useEffect(() => {
    onPanelOpenChange?.(open);
  }, [open, onPanelOpenChange]);
  if (
    !Number.isFinite(transitionMs) ||
    transitionMs < 0 ||
    !Number.isFinite(blur) ||
    blur < 0
  )
    throw new RangeError(
      "KMapLocationPicker duration and blur must be nonnegative and finite",
    );
  useEffect(() => () => operation.current?.abort(), []);
  useEffect(() => {
    if (panel === "search") {
      searchInput.current?.focus();
      searchInput.current?.select();
    }
  }, [panel]);
  useEffect(() => {
    if (open || !location) return;
    const land = setTimeout(() => setArrived(true), duration);
    const hintTimer = setTimeout(
      () => setShowHint(true),
      duration + (reduced || !bounce ? 0 : 400),
    );
    return () => {
      clearTimeout(land);
      clearTimeout(hintTimer);
    };
  }, [open, arrival, duration, reduced, bounce, !!location]);
  useEffect(() => {
    if (panel !== "search" || query.trim().length < 2) {
      setResults([]);
      setBusy(false);
      return;
    }
    const controller = new AbortController();
    setBusy(true);
    setError(false);
    setResults([]);
    const timer = setTimeout(() => {
      onSearch(query.trim(), controller.signal)
        .then((items) => {
          if (!controller.signal.aborted) setResults(items);
        })
        .catch(() => {
          if (!controller.signal.aborted) setError(true);
        })
        .finally(() => {
          if (!controller.signal.aborted) setBusy(false);
        });
    }, 250);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [query, panel, onSearch]);
  const update = (next: KMapLocation) => {
    emittedPosition.current = next.position.join(",");
    setLocalValue(next);
    onChange?.(next);
  };
  const choose = (next: KMapLocation) => {
    operation.current?.abort();
    update(next);
    setCamera({ center: next.position, zoom: selectedZoom });
    setError(false);
    setBusy(false);
    setArrived(false);
    setShowHint(false);
    setArrival((n) => n + 1);
    setPanel("closed");
    requestAnimationFrame(() => pill.current?.focus({ preventScroll: true }));
  };
  const locate = async () => {
    if (!onLocate) return;
    operation.current?.abort();
    const controller = new AbortController();
    operation.current = controller;
    setBusy(true);
    setError(false);
    try {
      const next = await onLocate(controller.signal);
      if (!controller.signal.aborted) choose(next);
    } catch {
      if (!controller.signal.aborted) setError(true);
    } finally {
      if (!controller.signal.aborted) setBusy(false);
    }
  };
  const edit = () => {
    operation.current?.abort();
    setBusy(false);
    setError(false);
    setQuery(location?.id === "adjusted" ? query : (location?.label ?? query));
    setPanel("search");
  };
  return (
    <section
      className="k-location-picker"
      style={
        {
          "--k-location-blur": `${blur}px`,
          "--k-location-duration": `${duration}ms`,
        } as CSSProperties
      }
      aria-label={text.search}
    >
      <div
        className="k-location-picker__map"
        data-obscured={open}
        inert={open || undefined}
      >
        <KMap
          {...mapProps}
          center={camera.center}
          zoom={camera.zoom}
          cameraTransitionMs={duration}
          interactive={!open}
          showZoomControls={!open}
          pins={
            location && !open && arrived
              ? [
                  {
                    id: "location",
                    label: location.label,
                    position: location.position,
                    draggable: true,
                  },
                ]
              : []
          }
          renderPin={(pin, state) => (
            <motion.span
              key={arrival}
              className="k-location-picker__marker"
              data-appearance={markerAppearance}
              initial={
                bounce && !reduced ? { y: -20, scale: 0.8, opacity: 0 } : false
              }
              animate={{ y: 0, scale: 1, opacity: 1 }}
              transition={{ type: "spring", stiffness: 350, damping: 18 }}
            >
              {mapProps.renderPin ? (
                mapProps.renderPin(pin, state)
              ) : (
                <KIcon name="map-pin" size={28} />
              )}
            </motion.span>
          )}
          onPinMove={async ({ position }) => {
            operation.current?.abort();
            setError(false);
            const next = { id: "adjusted", label: text.adjusted, position };
            update(next);
            if (onReverseGeocode) {
              const controller = new AbortController();
              operation.current = controller;
              setBusy(true);
              try {
                const resolved = await onReverseGeocode(
                  position,
                  controller.signal,
                );
                if (!controller.signal.aborted)
                  update({ ...resolved, position });
              } catch {
                if (!controller.signal.aborted) setError(true);
              } finally {
                if (!controller.signal.aborted) setBusy(false);
              }
            }
            return true;
          }}
        />
      </div>
      <div className="k-location-picker__overlay" data-open={open}>
        <motion.div
          layout
          className="k-location-picker__panel"
          data-state={panel}
          transition={{ duration: reduced ? 0 : 0.3, ease: "easeInOut" }}
        >
          {panel === "closed" && location ? (
            <button
              ref={pill}
              type="button"
              className="k-location-picker__pill"
              onClick={edit}
              aria-label={`${text.edit}: ${location.label}`}
              aria-busy={busy}
            >
              {busy ? (
                <span className="k-button__spinner" aria-hidden="true" />
              ) : (
                <KIcon name="map-pin" />
              )}
              <span role="status">
                {busy ? text.searching : location.label}
              </span>
              <KIcon name="chevron-down" />
            </button>
          ) : (
            <motion.div
              key={panel}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: reduced ? 0 : 0.2 }}
              className="k-location-picker__body"
            >
              {panel === "choice" ? (
                <>
                  {leading ?? (
                    <span className="k-location-picker__symbol">
                      <KIcon name="map-pin" size={28} />
                    </span>
                  )}
                  <h2>{text.title}</h2>
                  <p>{text.description}</p>
                  <KButton
                    fullWidth
                    onClick={() => {
                      operation.current?.abort();
                      setError(false);
                      setBusy(false);
                      setPanel("search");
                    }}
                  >
                    <KIcon name="search" />
                    {text.search}
                  </KButton>
                  {onLocate && (
                    <KButton
                      fullWidth
                      variant="secondary"
                      loading={busy}
                      onClick={locate}
                    >
                      <KIcon name="locate-fixed" />
                      {text.locate}
                    </KButton>
                  )}
                  {location && (
                    <KButton variant="ghost" onClick={() => setPanel("closed")}>
                      {text.back}
                    </KButton>
                  )}
                </>
              ) : (
                <>
                  <KButton variant="ghost" onClick={() => setPanel("choice")}>
                    <KIcon name="arrow-left" />
                    {text.back}
                  </KButton>
                  <h2>{text.search}</h2>
                  <KInput
                    ref={searchInput}
                    aria-label={text.search}
                    placeholder={text.placeholder}
                    value={query}
                    onChange={(event) => setQuery(event.target.value)}
                  />
                  <div
                    className="k-location-picker__results"
                    aria-live="polite"
                  >
                    {busy && (
                      <p
                        role="status"
                        className="k-location-picker__search-status"
                      >
                        <span
                          className="k-button__spinner"
                          aria-hidden="true"
                        />
                        {text.searching}
                      </p>
                    )}
                    {!busy &&
                      !error &&
                      query.trim().length >= 2 &&
                      !results.length && <p>{text.empty}</p>}
                    {!busy &&
                      results.map((result) => (
                        <KButton
                          key={result.id}
                          variant="ghost"
                          fullWidth
                          onClick={() => choose(result)}
                        >
                          <KIcon name="map-pin" />
                          <span className="k-location-picker__result">
                            <strong>{result.label}</strong>
                            {result.detail && <small>{result.detail}</small>}
                          </span>
                          <KIcon name="arrow-up-right" />
                        </KButton>
                      ))}
                  </div>
                </>
              )}
              {error && <p role="alert">{text.error}</p>}
            </motion.div>
          )}
        </motion.div>
      </div>
      {!open && showHint && location && (
        <motion.div
          className="k-location-picker__hint"
          initial={{ opacity: 0, y: reduced ? 0 : 12 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <span role={error ? "alert" : "status"}>
            {error ? text.error : (hint ?? text.hint)}
          </span>
          {onConfirm && (
            <KButton
              disabled={busy || error}
              onClick={() => onConfirm(location)}
            >
              {text.confirm}
              <KIcon name="arrow-right" />
            </KButton>
          )}
        </motion.div>
      )}
    </section>
  );
}
