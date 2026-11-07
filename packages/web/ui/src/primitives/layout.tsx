import { useEffect, useRef, useState, type HTMLAttributes } from "react";

export type KLayoutGap = "control" | "action" | "section";
export type KLayoutAlign = "start" | "center" | "end" | "stretch";

export interface KStackProps extends HTMLAttributes<HTMLDivElement> {
  gap?: KLayoutGap;
  align?: KLayoutAlign;
}

export interface KInlineProps extends KStackProps {
  wrap?: boolean;
}

export function KStack({
  gap = "control",
  align = "start",
  className = "",
  ...props
}: KStackProps) {
  return (
    <div
      {...props}
      className={`k-layout k-stack k-layout--gap-${gap} k-layout--align-${align} ${className}`}
    />
  );
}

export function KInline({
  gap = "control",
  align = "start",
  wrap = false,
  className = "",
  ...props
}: KInlineProps) {
  if (wrap && align === "stretch") {
    throw new Error("KInline does not support wrap with stretch alignment");
  }
  return (
    <div
      {...props}
      className={`k-layout k-inline k-layout--gap-${gap} k-layout--align-${align} ${wrap ? "k-inline--wrap" : ""} ${className}`}
    />
  );
}

export interface KPageProps extends HTMLAttributes<HTMLElement> {
  /**
   * `content` (default): lists, details, dashboards (`--k-layout-page-width`).
   * `form`: sign-in and single forms (`--k-layout-form-width`), centred
   * vertically when shorter than the screen.
   */
  width?: "content" | "form";
  /**
   * Pull to refresh on touch screens, as on iOS and Android. Desktops get no
   * gesture: refresh there on focus or from the page's More menu. Never add
   * a refresh button to the page actions.
   */
  onRefresh?: () => Promise<unknown>;
}

const K_PULL_THRESHOLD = 64;

function kScrollTop(element: HTMLElement) {
  for (let node = element.parentElement; node; node = node.parentElement) {
    const overflow = getComputedStyle(node).overflowY;
    if (overflow === "auto" || overflow === "scroll") return node.scrollTop;
  }
  return window.scrollY;
}

/**
 * The scrolling body of a screen (Decision 0015): page gutter, safe areas, a
 * readable maximum width on tablets and desktops, and section spacing
 * between children. Mirrors `KPage` in Flutter.
 */
export function KPage({
  width = "content",
  onRefresh,
  className = "",
  children,
  ...props
}: KPageProps) {
  const ref = useRef<HTMLElement>(null);
  const [pull, setPull] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  useEffect(() => {
    const element = ref.current;
    if (!element || !onRefresh) return;
    let start: number | null = null;
    let distance = 0;
    const down = (event: TouchEvent) => {
      start =
        kScrollTop(element) <= 0 && event.touches.length === 1
          ? event.touches[0]!.clientY
          : null;
    };
    const move = (event: TouchEvent) => {
      if (start === null) return;
      // Resistance like the native controls: the indicator lags the finger.
      distance = Math.max(0, (event.touches[0]!.clientY - start) * 0.5);
      setPull(Math.min(distance, K_PULL_THRESHOLD * 1.5));
    };
    const up = () => {
      if (start === null) return;
      start = null;
      setPull(0);
      if (distance < K_PULL_THRESHOLD) return;
      distance = 0;
      setRefreshing(true);
      void onRefresh().finally(() => setRefreshing(false));
    };
    element.addEventListener("touchstart", down, { passive: true });
    element.addEventListener("touchmove", move, { passive: true });
    element.addEventListener("touchend", up);
    element.addEventListener("touchcancel", up);
    return () => {
      element.removeEventListener("touchstart", down);
      element.removeEventListener("touchmove", move);
      element.removeEventListener("touchend", up);
      element.removeEventListener("touchcancel", up);
    };
  }, [onRefresh]);
  return (
    <main
      {...props}
      ref={ref}
      className={`k-page ${className}`}
      data-width={width}
      aria-busy={refreshing || undefined}
    >
      {onRefresh && (pull > 0 || refreshing) ? (
        <div
          className="k-page__refresh"
          aria-hidden
          data-refreshing={refreshing || undefined}
          style={{
            height: refreshing ? K_PULL_THRESHOLD : pull,
            opacity: refreshing ? 1 : Math.min(1, pull / K_PULL_THRESHOLD),
          }}
        >
          <span className="k-page__refresh-spinner" />
        </div>
      ) : null}
      <div className="k-layout k-stack k-layout--gap-section k-layout--align-stretch k-page__body">
        {children}
      </div>
    </main>
  );
}
