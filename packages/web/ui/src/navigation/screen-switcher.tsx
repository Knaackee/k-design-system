import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { KButton } from "../primitives/button.js";
import { KIconButton } from "../actions/icon-button.js";

export type KScreenSwitcherMode = "overview" | "screen" | "minimized";
export interface KScreenSwitcherItem {
  id: string;
  title: string;
  icon?: ReactNode;
  content: ReactNode;
  closable?: boolean;
}
export interface KScreenSwitcherProps {
  items: KScreenSwitcherItem[];
  activeId: string | null;
  mode: KScreenSwitcherMode;
  onStateChange: (state: {
    activeId: string | null;
    mode: KScreenSwitcherMode;
  }) => void;
  onCloseRequest?: (id: string) => void;
  /** Called after the chosen card has reached the front of the stack. */
  onOpenRequested?: (id: string) => void;
  maximizeOnOpen?: boolean;
  showOverviewButton?: boolean;
  children?: ReactNode;
  label?: string;
  overviewLabel?: string;
  minimizeLabel?: string;
  closeLabel?: string;
  emptyLabel?: string;
  className?: string;
  style?: CSSProperties;
}

/** Content stays mounted; the consumer owns screen identity and navigation. */
export function KScreenSwitcher({
  items,
  activeId,
  mode,
  onStateChange,
  onCloseRequest,
  onOpenRequested,
  maximizeOnOpen = true,
  showOverviewButton = true,
  children,
  label = "Open screens",
  overviewLabel = "Show screens",
  minimizeLabel = "Minimize",
  closeLabel = "Close",
  emptyLabel = "No open screens",
  className = "",
  style,
}: KScreenSwitcherProps) {
  const root = useRef<HTMLDivElement>(null);
  const [layout, setLayout] = useState({
    width: 390,
    height: 844,
    gap: 16,
    step: 32,
    peek: 3,
    shade: 0.08,
    tilt: -12,
    perspective: 1000,
  });
  useEffect(() => {
    const element = root.current;
    if (!element) return;
    const observer = new ResizeObserver(([entry]) => {
      const css = getComputedStyle(element);
      const number = (name: string, fallback: number) =>
        parseFloat(css.getPropertyValue(name)) || fallback;
      setLayout({
        width: entry.contentRect.width,
        height: entry.contentRect.height,
        gap: number("--k-screen-switcher-inset", 16),
        step: number("--k-screen-switcher-peek", 32),
        peek: number("--k-screen-switcher-visible-behind", 3),
        shade: number("--k-screen-switcher-depth-shade", 0.08),
        tilt: number("--k-screen-switcher-tilt", -12),
        perspective: number("--k-screen-switcher-perspective", 1000),
      });
    });
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const latest = useRef({
    items,
    mode,
    onOpenRequested,
    onStateChange,
    maximizeOnOpen,
  });
  latest.current = {
    items,
    mode,
    onOpenRequested,
    onStateChange,
    maximizeOnOpen,
  };
  const gesture = useRef<{ y: number; time: number; pointer: number } | null>(
    null,
  );
  const moved = useRef(false);
  const [drag, setDrag] = useState(0);
  const [pending, setPending] = useState<string | null>(null);
  const activeIndex = Math.max(
    0,
    items.findIndex((item) => item.id === activeId),
  );
  const effectiveMode =
    mode === "screen" && !items.some((item) => item.id === activeId)
      ? "overview"
      : mode;
  const change = (
    next: KScreenSwitcherMode,
    id = items[activeIndex]?.id ?? null,
  ) => onStateChange({ mode: next, activeId: id });
  useEffect(() => () => clearTimeout(timer.current), []);
  useEffect(() => {
    if (effectiveMode === "screen")
      root.current
        ?.querySelector<HTMLElement>('[data-active="true"] [data-screen-title]')
        ?.focus({ preventScroll: true });
    else if (effectiveMode === "overview")
      root.current
        ?.querySelector<HTMLElement>(
          '[data-front="true"] .k-screen-switcher__select',
        )
        ?.focus({ preventScroll: true });
  }, [effectiveMode, activeId]);
  function select(id: string) {
    if (pending) return;
    setPending(id);
    change("overview", id);
    const reduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;
    const duration =
      parseFloat(
        getComputedStyle(root.current!).getPropertyValue(
          "--k-screen-switcher-center-duration",
        ),
      ) || 350;
    timer.current = setTimeout(
      () => {
        setPending(null);
        const current = latest.current;
        if (
          current.mode !== "overview" ||
          !current.items.some((item) => item.id === id)
        )
          return;
        current.onOpenRequested?.(id);
        if (current.maximizeOnOpen)
          current.onStateChange({ activeId: id, mode: "screen" });
      },
      id === activeId || reduced ? 0 : duration,
    );
  }
  function step(direction: number) {
    if (!items.length || pending) return;
    const index = (activeIndex + direction + items.length) % items.length;
    change("overview", items[index].id);
  }
  return (
    <div
      ref={root}
      className={`k-screen-switcher ${className}`}
      style={style}
      data-mode={effectiveMode}
      data-dragging={drag !== 0}
      role="region"
      aria-label={label}
      onKeyDown={(event) => {
        if (event.defaultPrevented) return;
        if (event.key === "Escape") {
          event.preventDefault();
          change(effectiveMode === "screen" ? "overview" : "minimized");
        }
        if (
          effectiveMode === "overview" &&
          (event.key === "ArrowDown" || event.key === "ArrowUp")
        ) {
          event.preventDefault();
          step(event.key === "ArrowDown" ? 1 : -1);
        }
      }}
    >
      <div
        className="k-screen-switcher__background"
        inert={effectiveMode !== "minimized"}
      >
        {children}
      </div>
      <div className="k-screen-switcher__toolbar">
        {effectiveMode === "minimized" ? (
          <KButton onClick={() => change("overview")}>
            {overviewLabel} · {items.length}
          </KButton>
        ) : (
          <span>
            {label} · {items.length ? activeIndex + 1 : 0} / {items.length}
          </span>
        )}
      </div>
      <div
        className="k-screen-switcher__viewport"
        onPointerDown={(event) => {
          if (
            effectiveMode !== "overview" ||
            pending ||
            event.button !== 0 ||
            (event.target as HTMLElement).closest("[data-screen-close]")
          )
            return;
          moved.current = false;
          gesture.current = {
            y: event.clientY,
            time: performance.now(),
            pointer: event.pointerId,
          };
        }}
        onPointerMove={(event) => {
          const start = gesture.current;
          if (!start || start.pointer !== event.pointerId) return;
          const delta = event.clientY - start.y;
          if (Math.abs(delta) > 6) {
            moved.current = true;
            event.currentTarget.setPointerCapture(event.pointerId);
            setDrag(delta);
          }
        }}
        onPointerUp={(event) => {
          const start = gesture.current;
          if (!start || start.pointer !== event.pointerId) return;
          const delta = event.clientY - start.y;
          const velocity = delta / Math.max(1, performance.now() - start.time);
          gesture.current = null;
          setDrag(0);
          if (
            Math.abs(delta) > 48 ||
            (Math.abs(delta) > 8 && Math.abs(velocity) > 0.4)
          )
            step(delta > 0 ? 1 : -1);
          if (event.currentTarget.hasPointerCapture(event.pointerId))
            event.currentTarget.releasePointerCapture(event.pointerId);
        }}
        onPointerCancel={() => {
          gesture.current = null;
          setDrag(0);
        }}
        onClickCapture={(event) => {
          if (moved.current) {
            event.preventDefault();
            event.stopPropagation();
            moved.current = false;
          }
        }}
      >
        {!items.length && <p>{emptyLabel}</p>}
        {items.map((item, index) => {
          const offset =
            ((index - activeIndex - drag / 160 + items.length * 1.5) %
              items.length) -
            items.length / 2;
          const depth = Math.abs(offset);
          const peeks = Math.min(
            layout.peek,
            items.length - 1,
            layout.height < 500 ? 2 : 3,
          );
          const stepHeight = Math.min(layout.step, layout.height * 0.06);
          const top = 54 + peeks * stepHeight;
          const available = Math.max(1, layout.height - top - layout.gap);
          const angle = (layout.tilt * Math.PI) / 180;
          const projectedFactor =
            Math.cos(angle) +
            (available * Math.sin(angle)) / layout.perspective;
          const scale = Math.max(
            0.05,
            Math.min(
              (layout.width - layout.gap * 2) / Math.max(1, layout.width),
              available / Math.max(1, layout.height * projectedFactor),
            ),
          );
          const cardScale = Math.max(
            0.05,
            scale - (depth * 32) / Math.max(1, layout.width),
          );
          const front = index === activeIndex;
          const selected = effectiveMode === "screen" && front;
          return (
            <section
              key={item.id}
              className="k-screen-switcher__card"
              data-active={selected}
              data-front={front}
              aria-label={item.title}
              inert={
                effectiveMode === "minimized" ||
                (effectiveMode === "screen" && !selected) ||
                (effectiveMode === "overview" &&
                  (offset < -0.01 || depth > peeks + 0.5))
              }
              style={
                {
                  "--screen-depth": depth,
                  "--screen-offset": offset,
                  "--screen-top": `${top - Math.max(0, offset) * stepHeight}px`,
                  "--screen-scale": cardScale,
                  "--screen-shade": Math.min(0.4, depth * layout.shade),
                  zIndex: front ? 20 : 10 - Math.round(depth),
                  visibility: depth > peeks + 0.5 ? "hidden" : undefined,
                  opacity:
                    effectiveMode === "overview" && offset < -0.01
                      ? 0
                      : undefined,
                } as CSSProperties
              }
            >
              <div className="k-screen-switcher__depth" aria-hidden="true" />
              <header className="k-screen-switcher__header">
                <span data-screen-title tabIndex={-1}>
                  {item.icon}
                  {item.title}
                </span>
                {selected && showOverviewButton && (
                  <KIconButton
                    icon="chevron-down"
                    label={minimizeLabel}
                    onClick={() => change("overview")}
                  />
                )}
                {item.closable !== false && onCloseRequest && (
                  <KIconButton
                    data-screen-close
                    icon="x"
                    label={`${closeLabel}: ${item.title}`}
                    onClick={() => onCloseRequest(item.id)}
                  />
                )}
              </header>
              <div className="k-screen-switcher__body" inert={!selected}>
                {item.content}
              </div>
              {effectiveMode === "overview" && (
                <button
                  className="k-screen-switcher__select"
                  aria-label={item.title}
                  disabled={!!pending}
                  onClick={() => select(item.id)}
                />
              )}
            </section>
          );
        })}
      </div>
    </div>
  );
}
