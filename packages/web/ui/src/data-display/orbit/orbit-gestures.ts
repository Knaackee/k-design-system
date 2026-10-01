import {
  useEffect,
  useRef,
  type KeyboardEvent,
  type PointerEvent,
  type RefObject,
} from "react";
import {
  kOrbitDefaultView,
  kOrbitZoomAt,
  type KOrbitViewState,
} from "./orbit-model.js";

interface GestureOptions {
  root: RefObject<HTMLDivElement | null>;
  view: RefObject<KOrbitViewState>;
  changeView(view: KOrbitViewState): void;
  clearSelection(): void;
  defaultView?: KOrbitViewState;
  zoomBounds: readonly [number, number];
  reducedMotion: boolean;
  panDisabled?: boolean;
  contextMenuEnabled?: boolean;
  interactionMode?: "dedicated" | "embedded";
  onInteractionStart?(): void;
  onInteractionEnd?(): void;
}

export function useKOrbitGestures(options: GestureOptions) {
  const interacting = useRef(false);
  const dragged = useRef(false);
  const pointers = useRef(new Map<number, { x: number; y: number }>());
  const gesture = useRef<{
    distance: number;
    focal: { x: number; y: number };
  } | null>(null);
  const drag = useRef<{
    x: number;
    y: number;
    time: number;
    rotate: boolean;
  } | null>(null);
  const inertia = useRef({ x: 0, y: 0 });
  useEffect(() => {
    if (options.reducedMotion) inertia.current = { x: 0, y: 0 };
  }, [options.reducedMotion]);

  const begin = () => {
    if (interacting.current) return;
    interacting.current = true;
    inertia.current = { x: 0, y: 0 };
    options.onInteractionStart?.();
  };
  const end = () => {
    if (!interacting.current) return;
    interacting.current = false;
    options.onInteractionEnd?.();
  };
  const onPointerDown = (event: PointerEvent<HTMLDivElement>) => {
    if (
      event.pointerType === "mouse" &&
      event.button !== 0 &&
      event.button !== 2
    )
      return;
    const node = (event.target as HTMLElement).closest<HTMLButtonElement>(
      ".k-orbit__node",
    );
    if (
      (event.target as HTMLElement).closest("input,button:not(.k-orbit__node)")
    )
      return;
    if (node && event.button === 2 && options.contextMenuEnabled) return;
    dragged.current = false;
    pointers.current.set(event.pointerId, {
      x: event.clientX,
      y: event.clientY,
    });
    (node ?? event.currentTarget).setPointerCapture(event.pointerId);
    if (pointers.current.size === 1) {
      drag.current = {
        x: event.clientX,
        y: event.clientY,
        time: performance.now(),
        rotate: event.pointerType === "touch" || event.button === 2,
      };
      if (
        event.pointerType !== "touch" ||
        options.interactionMode !== "embedded"
      )
        begin();
    } else if (pointers.current.size === 2) {
      begin();
      gesture.current = pinch([...pointers.current.values()]);
    }
  };
  const onPointerMove = (event: PointerEvent<HTMLDivElement>) => {
    const previous = pointers.current.get(event.pointerId);
    if (!previous) return;
    pointers.current.set(event.pointerId, {
      x: event.clientX,
      y: event.clientY,
    });
    if (pointers.current.size >= 2) {
      const next = pinch([...pointers.current.values()]);
      if (gesture.current) {
        const rect = event.currentTarget.getBoundingClientRect();
        const zoom =
          options.view.current.zoom *
          (next.distance / gesture.current.distance);
        options.changeView(
          kOrbitZoomAt(
            options.view.current,
            clamp(zoom, options.zoomBounds),
            { x: next.focal.x - rect.left, y: next.focal.y - rect.top },
            { x: rect.width / 2, y: rect.height / 2 },
          ),
        );
      }
      gesture.current = next;
      event.preventDefault();
      return;
    }
    if (!interacting.current || !drag.current) return;
    if (options.panDisabled && !drag.current.rotate) return;
    const dx = event.clientX - previous.x;
    const dy = event.clientY - previous.y;
    if (
      Math.hypot(
        event.clientX - drag.current.x,
        event.clientY - drag.current.y,
      ) > 4
    )
      dragged.current = true;
    options.changeView(
      kOrbitDragView(options.view.current, dx, dy, drag.current.rotate),
    );
    const dt = Math.max(8, performance.now() - drag.current.time) / 1000;
    inertia.current =
      options.reducedMotion || !drag.current.rotate
        ? { x: 0, y: 0 }
        : {
            x: Math.max(-3, Math.min(3, (dx * 0.008) / dt)),
            y: Math.max(-3, Math.min(3, (dy * 0.008) / dt)),
          };
    drag.current.time = performance.now();
  };
  const onPointerEnd = (event: PointerEvent<HTMLDivElement>) => {
    if (event.type === "pointercancel") inertia.current = { x: 0, y: 0 };
    pointers.current.delete(event.pointerId);
    if (event.currentTarget.hasPointerCapture(event.pointerId))
      event.currentTarget.releasePointerCapture(event.pointerId);
    gesture.current =
      pointers.current.size === 2
        ? pinch([...pointers.current.values()])
        : null;
    if (pointers.current.size === 0) {
      drag.current = null;
      end();
    }
  };
  useEffect(() => {
    const element = options.root.current;
    if (!element) return;
    const onWheel = (event: globalThis.WheelEvent) => {
      if (
        options.interactionMode === "embedded" &&
        !element.contains(document.activeElement)
      )
        return;
      event.preventDefault();
      const rect = element.getBoundingClientRect();
      const zoom = clamp(
        options.view.current.zoom * Math.exp(-event.deltaY * 0.001),
        options.zoomBounds,
      );
      options.changeView(
        kOrbitZoomAt(
          options.view.current,
          zoom,
          { x: event.clientX - rect.left, y: event.clientY - rect.top },
          { x: rect.width / 2, y: rect.height / 2 },
        ),
      );
    };
    element.addEventListener("wheel", onWheel, { passive: false });
    return () => element.removeEventListener("wheel", onWheel);
  }, [options]);
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const next = { ...options.view.current };
    if (event.key === "ArrowLeft") next.yaw -= 0.12;
    else if (event.key === "ArrowRight") next.yaw += 0.12;
    else if (event.key === "ArrowUp") next.pitch -= 0.12;
    else if (event.key === "ArrowDown") next.pitch += 0.12;
    else if (event.key === "+" || event.key === "=") next.zoom *= 1.12;
    else if (event.key === "-") next.zoom /= 1.12;
    else if (event.key === "Home") {
      inertia.current = { x: 0, y: 0 };
      Object.assign(next, options.defaultView ?? kOrbitDefaultView);
    } else if (event.key === "Escape") {
      options.clearSelection();
      return;
    } else return;
    event.preventDefault();
    options.changeView(next);
  };

  return {
    interacting,
    dragged,
    inertia,
    onPointerDown,
    onPointerMove,
    onPointerEnd,
    resetView() {
      inertia.current = { x: 0, y: 0 };
      options.changeView(options.defaultView ?? kOrbitDefaultView);
    },
    onKeyDown,
  };
}

function clamp(value: number, bounds: readonly [number, number]): number {
  return Math.max(bounds[0], Math.min(bounds[1], value));
}

function pinch(points: readonly { x: number; y: number }[]) {
  const [a, b] = points;
  return {
    distance: Math.max(1, Math.hypot(b!.x - a!.x, b!.y - a!.y)),
    focal: { x: (a!.x + b!.x) / 2, y: (a!.y + b!.y) / 2 },
  };
}

/** Mouse primary drag pans; secondary drag (or a single touch) rotates. */
export function kOrbitDragView(
  view: KOrbitViewState,
  dx: number,
  dy: number,
  rotate: boolean,
): KOrbitViewState {
  return rotate
    ? { ...view, yaw: view.yaw + dx * 0.008, pitch: view.pitch + dy * 0.008 }
    : { ...view, offset: { x: view.offset.x + dx, y: view.offset.y + dy } };
}
