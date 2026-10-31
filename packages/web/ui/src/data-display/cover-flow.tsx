import {
  type CSSProperties,
  type ReactNode,
  useRef,
  useState,
  useEffect,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import {
  clampCoverFlowIndex,
  coverFlowTransform,
} from "./cover-flow-layout.js";

export interface KCoverFlowItem {
  id: string;
  label: string;
  /** Consumer-owned artwork, image, animation or composition. */
  content: ReactNode;
}

export interface KCoverFlowProps {
  items: readonly KCoverFlowItem[];
  label: string;
  selectedIndex?: number;
  initialIndex?: number;
  onIndexChange?: (index: number) => void;
  previousLabel?: string;
  nextLabel?: string;
  /** Maximum cover width in pixels; shrinks to fit narrow viewports. */
  itemWidth?: number;
  /** Maximum fraction of the viewport occupied by a cover (0–1). */
  itemWidthFraction?: number;
  height?: CSSProperties["height"];
  /** Space around each cover's content, in pixels. */
  contentPadding?: number;
  /** Clip neighboring covers at the horizontal viewport edges only. */
  clipSides?: boolean;
  sideAngle?: number;
  /** First neighbor's horizontal offset as a percentage of cover width. */
  sideOffset?: number;
  /** Neighbor size relative to the front item, before perspective. */
  sideScale?: number;
  /** Maximum visible neighbors on each side. */
  visibleNeighbors?: number;
  /** Prepare and retain hidden consumer content for seamless selection. */
  keepMounted?: boolean;
  depth?: number;
  /** Distance between successive side covers, as a percentage of cover width. */
  spacing?: number;
  perspective?: number;
  showControls?: boolean;
  showCaption?: boolean;
  reducedMotion?: boolean;
  /** Reveal visible covers, selected first. Change revealKey to replay. */
  reveal?: boolean;
  revealKey?: number;
  revealDurationMs?: number;
  revealStaggerMs?: number;
  revealDistance?: number;
  revealScale?: number;
  onRevealComplete?: () => void;
  className?: string;
  style?: CSSProperties;
}

/** Controlled or uncontrolled selection; never rotates automatically. */
export function KCoverFlow({
  items,
  label,
  selectedIndex,
  initialIndex = 0,
  onIndexChange,
  previousLabel = "Previous cover",
  nextLabel = "Next cover",
  itemWidth = 380,
  itemWidthFraction = 0.66,
  height = "clamp(260px, 52dvh, 560px)",
  contentPadding = 16,
  clipSides = true,
  sideAngle = 55,
  sideOffset = 68,
  sideScale = 1,
  visibleNeighbors = 3,
  keepMounted = false,
  depth = 120,
  spacing = 28,
  perspective = 1100,
  showControls = true,
  showCaption = true,
  reducedMotion = false,
  reveal = false,
  revealKey = 0,
  revealDurationMs = 1100,
  revealStaggerMs = 200,
  revealDistance = 36,
  revealScale = 0.94,
  onRevealComplete,
  className,
  style,
}: KCoverFlowProps) {
  const root = useRef<HTMLElement>(null);
  const complete = useRef(onRevealComplete);
  complete.current = onRevealComplete;
  const [internalIndex, setInternalIndex] = useState(initialIndex);
  const index = clampCoverFlowIndex(
    selectedIndex ?? internalIndex,
    items.length,
  );
  useEffect(() => {
    if (!reveal || !items.length) return;
    const media = matchMedia("(prefers-reduced-motion: reduce)");
    const animations: Animation[] = [];
    let cancelled = false;
    if (!reducedMotion && !media.matches) {
      root.current
        ?.querySelectorAll<HTMLElement>("[data-cover-reveal-index]")
        .forEach((element) => {
          const delay =
            Math.abs(Number(element.dataset.coverRevealIndex) - index) *
            Math.max(0, revealStaggerMs);
          animations.push(
            element.animate(
              [
                {
                  opacity: 0,
                  transform: `translateY(${Math.max(0, revealDistance)}px) scale(${Math.max(0.1, Math.min(1, revealScale))})`,
                },
                { opacity: 1, transform: "translateY(0) scale(1)" },
              ],
              {
                duration: Math.max(0, revealDurationMs),
                delay,
                easing: "cubic-bezier(.22,1,.36,1)",
                fill: "backwards",
              },
            ),
          );
        });
    }
    const reduce = () => {
      if (media.matches) animations.forEach((animation) => animation.finish());
    };
    media.addEventListener("change", reduce);
    void Promise.all(animations.map((animation) => animation.finished))
      .then(() => {
        if (!cancelled) complete.current?.();
      })
      .catch(() => {});
    return () => {
      cancelled = true;
      media.removeEventListener("change", reduce);
      animations.forEach((animation) => animation.cancel());
    };
    // Selection and content edits must not replay the entrance.
  }, [
    reveal,
    revealKey,
    reducedMotion,
    revealDurationMs,
    revealStaggerMs,
    revealDistance,
    revealScale,
    items.length,
  ]);
  const [dragOffset, setDragOffset] = useState(0);
  const drag = useRef<{
    id: number;
    x: number;
    y: number;
    step: number;
    start: number;
    moved: boolean;
  } | null>(null);
  const suppressClickUntil = useRef(0);
  function select(next: number) {
    const safe = clampCoverFlowIndex(next, items.length);
    setDragOffset(0);
    if (safe === index || !items.length) return;
    if (selectedIndex === undefined) setInternalIndex(safe);
    onIndexChange?.(safe);
  }
  const position = Math.max(0, Math.min(items.length - 1, index + dragOffset));
  return (
    <section
      ref={root}
      className={["k-cover-flow", className].filter(Boolean).join(" ")}
      aria-label={label}
      aria-roledescription="carousel"
      data-reduced-motion={reducedMotion || undefined}
      style={
        {
          ...style,
          "--k-cover-flow-item-fraction": `${Math.max(0.1, Math.min(1, itemWidthFraction)) * 100}%`,
          "--k-cover-flow-item-width": `${Math.max(1, itemWidth)}px`,
          "--k-cover-flow-perspective": `${Math.max(1, perspective)}px`,
          "--k-cover-flow-content-padding": `${Math.max(0, contentPadding)}px`,
        } as CSSProperties
      }
    >
      <div
        className="k-cover-flow__viewport"
        tabIndex={items.length ? 0 : -1}
        aria-label={label}
        style={{ height }}
        data-clip-sides={clipSides || undefined}
        data-dragging={drag.current?.moved || undefined}
        onKeyDown={(event) => {
          if (event.target !== event.currentTarget) return;
          const next =
            event.key === "ArrowRight"
              ? index + 1
              : event.key === "ArrowLeft"
                ? index - 1
                : event.key === "Home"
                  ? 0
                  : event.key === "End"
                    ? items.length - 1
                    : null;
          if (next !== null) {
            event.preventDefault();
            select(next);
          }
        }}
        onPointerDown={(event) => {
          if (!event.isPrimary || event.button !== 0 || items.length < 2)
            return;
          if (
            (event.target as HTMLElement).closest(
              "button,a,input,select,textarea,[contenteditable=true]",
            )
          )
            return;
          const width =
            event.currentTarget.querySelector<HTMLElement>(
              ".k-cover-flow__item",
            )?.offsetWidth ?? itemWidth;
          drag.current = {
            id: event.pointerId,
            x: event.clientX,
            y: event.clientY,
            step: Math.max(1, (width * Math.max(0, sideOffset)) / 100),
            start: index,
            moved: false,
          };
        }}
        onPointerMove={(event) => {
          const pointer = drag.current;
          if (!pointer || pointer.id !== event.pointerId) return;
          const dx = event.clientX - pointer.x;
          const dy = event.clientY - pointer.y;
          if (
            !pointer.moved &&
            Math.abs(dy) > Math.abs(dx) &&
            Math.abs(dy) > 8
          ) {
            drag.current = null;
            return;
          }
          if (!pointer.moved && Math.abs(dx) < 8) return;
          if (!pointer.moved) {
            pointer.moved = true;
            event.currentTarget.setPointerCapture(event.pointerId);
          }
          setDragOffset(pointer.start - index - dx / pointer.step);
        }}
        onPointerUp={(event) => {
          const pointer = drag.current;
          if (!pointer || pointer.id !== event.pointerId) return;
          drag.current = null;
          if (pointer.moved) {
            suppressClickUntil.current = performance.now() + 300;
            select(pointer.start - (event.clientX - pointer.x) / pointer.step);
            if (event.currentTarget.hasPointerCapture(event.pointerId))
              event.currentTarget.releasePointerCapture(event.pointerId);
          }
        }}
        onPointerCancel={() => {
          drag.current = null;
          setDragOffset(0);
        }}
        onLostPointerCapture={(event) => {
          // Touch begins with implicit capture on the card's child. Transferring
          // capture to the viewport must not cancel the drag via its bubbled loss.
          if (event.target !== event.currentTarget) return;
          drag.current = null;
          setDragOffset(0);
        }}
        onClickCapture={(event) => {
          if (performance.now() < suppressClickUntil.current) {
            event.preventDefault();
            event.stopPropagation();
          }
        }}
      >
        {items.map((item, itemIndex) => {
          const offset = itemIndex - position;
          // Mount only the visible neighborhood, including consumer animations.
          const visibility = Math.max(
            0,
            Math.min(
              1,
              Math.max(1, Math.floor(visibleNeighbors)) + 1 - Math.abs(offset),
            ),
          );
          const hidden = visibility === 0;
          if (hidden && !keepMounted) return null;
          return (
            <div
              key={item.id}
              className="k-cover-flow__item"
              role="group"
              aria-roledescription="slide"
              aria-label={item.label}
              aria-hidden={itemIndex !== index}
              data-selected={itemIndex === index || undefined}
              style={{
                transform: coverFlowTransform(
                  offset,
                  Math.max(0, Math.min(85, sideAngle)),
                  Math.max(0, depth),
                  Math.max(0, spacing),
                  Math.max(0, sideOffset),
                  Math.max(0.1, Math.min(1, sideScale)),
                ),
                opacity: visibility,
                pointerEvents: hidden ? "none" : undefined,
                zIndex: hidden ? -1 : 100 - Math.round(Math.abs(offset) * 10),
              }}
              onClickCapture={(event) => {
                // A side cover is navigation, never activation of its content.
                if (itemIndex !== index) {
                  event.preventDefault();
                  event.stopPropagation();
                  select(itemIndex);
                }
              }}
              onClick={() => select(itemIndex)}
            >
              <div
                className="k-cover-flow__content"
                data-cover-reveal-index={hidden ? undefined : itemIndex}
                inert={itemIndex !== index}
              >
                {item.content}
              </div>
            </div>
          );
        })}
      </div>
      <div className="k-cover-flow__navigation">
        {showControls && (
          <KIconButton
            icon="chevron-left"
            label={previousLabel}
            variant="ghost"
            disabled={index === 0 || !items.length}
            onClick={() => select(index - 1)}
          />
        )}
        <div
          className={
            showCaption ? "k-cover-flow__caption" : "k-cover-flow__announcement"
          }
          aria-live="polite"
          aria-atomic="true"
        >
          {items[index]?.label}
          {items.length > 0 && (
            <span className="k-cover-flow__count">
              {index + 1} / {items.length}
            </span>
          )}
        </div>
        {showControls && (
          <KIconButton
            icon="chevron-right"
            label={nextLabel}
            variant="ghost"
            disabled={index >= items.length - 1}
            onClick={() => select(index + 1)}
          />
        )}
      </div>
    </section>
  );
}
