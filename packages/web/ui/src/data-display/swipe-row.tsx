import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react";

import { KIcon, type KIconName } from "../primitives/icon.js";

export type KSwipeActionTone =
  "neutral" | "info" | "success" | "warning" | "destructive";

/** One action behind a list row (KListItem `leadingActions` / `trailingActions`). */
export interface KSwipeAction {
  id: string;
  label: string;
  icon?: KIconName;
  tone?: KSwipeActionTone;
  /** Apple style: swiping across the row triggers this action. */
  fullSwipe?: boolean;
  onSelect?: () => void;
}

export interface KSwipeRowProps {
  leadingActions?: readonly KSwipeAction[];
  trailingActions?: readonly KSwipeAction[];
  disabled?: boolean;
  children: ReactNode;
}

type Style = "apple" | "material" | "linear";

function token(element: Element, name: string, fallback: number) {
  return (
    parseFloat(getComputedStyle(element).getPropertyValue(name)) || fallback
  );
}

/**
 * Swipe actions on a list row (Decision 0016). The style decides the
 * behaviour: Apple shows buttons behind the row (full swipe triggers the
 * `fullSwipe` action), Material reveals one coloured layer per side and
 * triggers past the threshold, Linear and keyboard users get the actions
 * inline at the end of the row.
 */
export function KSwipeRow({
  leadingActions = [],
  trailingActions = [],
  disabled = false,
  children,
}: KSwipeRowProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [style, setStyle] = useState<Style>("linear");
  const [offset, setOffset] = useState(0);
  const [dragging, setDragging] = useState(false);
  const drag = useRef({
    x: 0,
    y: 0,
    base: 0,
    decided: false,
    horizontal: false,
    moved: false,
  });

  useLayoutEffect(() => {
    const value = ref.current
      ?.closest("[data-style]")
      ?.getAttribute("data-style");
    setStyle(value === "apple" || value === "material" ? value : "linear");
  }, []);

  // One open row at a time: a press anywhere else closes this one.
  useEffect(() => {
    if (offset === 0 || dragging) return;
    const close = (event: PointerEvent) => {
      if (!ref.current?.contains(event.target as Node)) setOffset(0);
    };
    document.addEventListener("pointerdown", close);
    return () => document.removeEventListener("pointerdown", close);
  }, [offset, dragging]);

  const swipes = style !== "linear" && !disabled;
  const width = () => ref.current?.clientWidth ?? 1;
  const actionWidth = () =>
    ref.current
      ? token(ref.current, "--k-component-swipe-action-width", 76)
      : 76;
  const threshold = (name: string, fallback: number) =>
    ref.current ? token(ref.current, name, fallback) : fallback;

  const run = (action: KSwipeAction | undefined, out: number) => {
    if (!action) return setOffset(0);
    setOffset(out);
    window.setTimeout(() => {
      action.onSelect?.();
      setOffset(0);
    }, 220);
  };

  const onPointerDown = (event: ReactPointerEvent) => {
    if (!swipes || event.button !== 0) return;
    drag.current = {
      x: event.clientX,
      y: event.clientY,
      base: offset,
      decided: false,
      horizontal: false,
      moved: false,
    };
    setDragging(true);
  };
  const onPointerMove = (event: ReactPointerEvent) => {
    if (!dragging) return;
    const d = drag.current;
    const dx = event.clientX - d.x;
    const dy = event.clientY - d.y;
    if (!d.decided && Math.hypot(dx, dy) > 6) {
      d.decided = true;
      d.horizontal = Math.abs(dx) > Math.abs(dy);
      if (d.horizontal)
        (event.currentTarget as Element).setPointerCapture(event.pointerId);
    }
    if (!d.horizontal) return;
    d.moved = true;
    let next = d.base + dx;
    if (!leadingActions.length) next = Math.min(0, next);
    if (!trailingActions.length) next = Math.max(0, next);
    setOffset(Math.max(-width(), Math.min(width(), next)));
  };
  const onPointerUp = () => {
    if (!dragging) return;
    setDragging(false);
    if (!drag.current.horizontal) return;
    const w = width();
    const side = offset > 0 ? leadingActions : trailingActions;
    const sign = Math.sign(offset);
    if (style === "material") {
      const reveal = threshold(
        "--k-component-swipe-action-reveal-threshold",
        0.35,
      );
      return Math.abs(offset) > w * reveal
        ? run(side[0], sign * w)
        : setOffset(0);
    }
    const full = threshold(
      "--k-component-swipe-action-full-swipe-threshold",
      0.6,
    );
    const fullAction = side.find((action) => action.fullSwipe);
    if (fullAction && Math.abs(offset) > w * full)
      return run(fullAction, sign * w);
    const open = actionWidth() * side.length;
    setOffset(Math.abs(offset) > actionWidth() / 2 ? sign * open : 0);
  };

  const fullSwipe =
    style === "apple" &&
    Math.abs(offset) >
      width() *
        threshold("--k-component-swipe-action-full-swipe-threshold", 0.6);
  const armed =
    style === "material" &&
    Math.abs(offset) >
      width() * threshold("--k-component-swipe-action-reveal-threshold", 0.35);
  const side = offset > 0 ? "leading" : "trailing";
  const shown = offset > 0 ? leadingActions : trailingActions;

  const button = (action: KSwipeAction, inline = false) => (
    <button
      key={action.id}
      type="button"
      className="k-swipe-row__action"
      data-tone={action.tone ?? "neutral"}
      data-full={fullSwipe && action.fullSwipe ? true : undefined}
      tabIndex={inline ? undefined : -1}
      aria-label={inline ? action.label : undefined}
      title={inline ? action.label : undefined}
      onClick={(event) => {
        event.stopPropagation();
        action.onSelect?.();
        setOffset(0);
      }}
    >
      {action.icon ? <KIcon name={action.icon} size={20} /> : null}
      {inline ? null : <span>{action.label}</span>}
    </button>
  );

  return (
    <div
      ref={ref}
      className="k-swipe-row"
      data-swipe-style={style}
      data-dragging={dragging || undefined}
      style={{ "--k-swipe-offset": `${offset}px` } as CSSProperties}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
      onClickCapture={(event) => {
        // A drag is not a tap on the row.
        if (drag.current.moved) {
          event.preventDefault();
          event.stopPropagation();
          drag.current.moved = false;
        }
      }}
    >
      {style === "apple" && offset !== 0 ? (
        <div
          className="k-swipe-row__behind"
          data-side={side}
          data-full={fullSwipe || undefined}
          aria-hidden
        >
          {shown.map((action) => button(action))}
        </div>
      ) : null}
      {style === "material" && offset !== 0 && shown[0] ? (
        <div
          className="k-swipe-row__reveal"
          data-side={side}
          data-tone={shown[0].tone ?? "neutral"}
          data-armed={armed || undefined}
          aria-hidden
        >
          {shown[0].icon ? <KIcon name={shown[0].icon} size={24} /> : null}
          <span>{shown[0].label}</span>
        </div>
      ) : null}
      <div className="k-swipe-row__content">{children}</div>
      {/* Pointer and keyboard: the same actions inline at the row end. */}
      <div className="k-swipe-row__inline">
        {[...leadingActions, ...trailingActions].map((action) =>
          button(action, true),
        )}
      </div>
    </div>
  );
}
