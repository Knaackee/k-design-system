import { useEffect, useRef, type HTMLAttributes } from "react";
export interface KLongPressPoint {
  x: number;
  y: number;
  target: HTMLElement;
}
/** Hold to reorder while retaining ordinary scrolling before activation. */
export function useKLongPressDrag(options: {
  canStart: (target: HTMLElement) => boolean;
  onStart: (point: KLongPressPoint) => void;
  onMove: (point: KLongPressPoint) => void;
  onEnd: (point: KLongPressPoint) => void;
  onCancel: () => void;
  delay?: number;
}): Pick<
  HTMLAttributes<HTMLElement>,
  | "onPointerDown"
  | "onPointerMove"
  | "onPointerUp"
  | "onPointerCancel"
  | "onLostPointerCapture"
  | "onClickCapture"
  | "onContextMenu"
> {
  const latest = useRef(options);
  latest.current = options;
  const state = useRef<{
    timer?: ReturnType<typeof setTimeout>;
    point?: KLongPressPoint;
    active: boolean;
    pointer?: number;
    root?: HTMLElement;
    suppress: number;
  }>({ active: false, suppress: 0 });
  const stop = (cancel: boolean) => {
    const s = state.current;
    clearTimeout(s.timer);
    if (s.active) {
      s.suppress = Date.now() + 700;
      if (cancel) latest.current.onCancel();
    }
    s.active = false;
    s.point = undefined;
    if (
      s.root &&
      s.pointer !== undefined &&
      s.root.hasPointerCapture(s.pointer)
    )
      s.root.releasePointerCapture(s.pointer);
    s.pointer = undefined;
    s.root = undefined;
  };
  useEffect(() => {
    const scroll = () => {
      if (!state.current.active) stop(false);
    };
    const cancel = () => stop(true);
    const outsideUp = (e: PointerEvent) => {
      if (!state.current.active && state.current.pointer === e.pointerId)
        stop(false);
    };
    const key = (e: KeyboardEvent) => {
      if (e.key === "Escape") cancel();
    };
    const touch = (e: TouchEvent) => {
      if (state.current.active && e.cancelable) e.preventDefault();
    };
    window.addEventListener("pointerup", outsideUp);
    window.addEventListener("pointercancel", cancel);
    window.addEventListener("scroll", scroll, true);
    window.addEventListener("blur", cancel);
    window.addEventListener("keydown", key);
    window.addEventListener("touchmove", touch, { passive: false });
    return () => {
      stop(true);
      window.removeEventListener("pointerup", outsideUp);
      window.removeEventListener("pointercancel", cancel);
      window.removeEventListener("scroll", scroll, true);
      window.removeEventListener("blur", cancel);
      window.removeEventListener("keydown", key);
      window.removeEventListener("touchmove", touch);
    };
  }, []);
  return {
    onPointerDown(e) {
      if (e.button !== 0 || !e.isPrimary || !(e.target instanceof Element))
        return;
      const target =
        e.target instanceof HTMLElement ? e.target : e.target.parentElement;
      if (!target) return;
      if (!latest.current.canStart(target)) return;
      stop(true);
      const s = state.current;
      const point = { x: e.clientX, y: e.clientY, target };
      s.point = point;
      s.pointer = e.pointerId;
      const root = e.currentTarget;
      const pointer = e.pointerId;
      s.root = root;
      s.timer = setTimeout(() => {
        if (!root.isConnected || s.pointer !== pointer) return;
        try {
          root.setPointerCapture(pointer);
        } catch {
          stop(false);
          return;
        }
        s.active = true;
        latest.current.onStart(point);
      }, latest.current.delay ?? 450);
    },
    onPointerMove(e) {
      const s = state.current;
      if (!s.point || e.pointerId !== s.pointer) return;
      if (!s.active) {
        if (Math.hypot(e.clientX - s.point.x, e.clientY - s.point.y) > 8)
          stop(false);
        return;
      }
      e.preventDefault();
      latest.current.onMove({
        x: e.clientX,
        y: e.clientY,
        target: s.point.target,
      });
    },
    onPointerUp(e) {
      const s = state.current;
      if (e.pointerId !== s.pointer) return;
      if (s.active && s.point)
        latest.current.onEnd({
          x: e.clientX,
          y: e.clientY,
          target: s.point.target,
        });
      stop(false);
    },
    onPointerCancel() {
      stop(true);
    },
    onLostPointerCapture() {
      if (state.current.active) stop(true);
    },
    onClickCapture(e) {
      if (Date.now() < state.current.suppress) {
        e.preventDefault();
        e.stopPropagation();
      }
    },
    onContextMenu(e) {
      if (state.current.point || Date.now() < state.current.suppress)
        e.preventDefault();
    },
  };
}
