import { useEffect, type RefObject } from "react";
import type { SheetRef } from "react-modal-sheet";

// Keep header dragging and scroll handoff on the same dismissal policy.
export const sheetCloseThreshold = 0.25;
export const sheetCloseVelocity = 700;

/** Continue the same finger gesture after native scrolling reaches the top. */
export function useSheetScrollHandoff(
  scroller: HTMLDivElement | null,
  sheetRef: RefObject<SheetRef | null>,
  open: boolean,
  dismissible: boolean,
) {
  useEffect(() => {
    if (!open || !scroller) return;
    let previousY = 0;
    let previousTop = 0;
    let eligible = false;
    let dragging = false;
    let velocity = 0;
    let previousTime = 0;
    const start = (event: TouchEvent) => {
      eligible = event.touches.length === 1 && scroller.scrollTop > 0;
      dragging = false;
      previousY = event.touches[0]?.clientY ?? 0;
      previousTop = scroller.scrollTop;
      previousTime = event.timeStamp;
      velocity = 0;
    };
    const move = (event: TouchEvent) => {
      if (!eligible || event.touches.length !== 1 || !sheetRef.current) return;
      const y = event.touches[0].clientY;
      const delta = y - previousY;
      const elapsed = Math.max(1, event.timeStamp - previousTime);
      // Consume the remaining inner scroll before moving the surface.
      const overflow = Math.max(0, delta - previousTop);
      if (dragging || (scroller.scrollTop <= 0 && overflow > 0)) {
        if (event.cancelable) event.preventDefault();
        const current = sheetRef.current.y.get();
        sheetRef.current.y.set(
          Math.max(0, current + (dragging ? delta : overflow)),
        );
        dragging = true;
        velocity = delta / elapsed;
      }
      previousY = y;
      previousTop = scroller.scrollTop;
      previousTime = event.timeStamp;
    };
    const finish = (event: TouchEvent) => {
      if (dragging && sheetRef.current) {
        const offset = sheetRef.current.y.get();
        const height =
          scroller.closest(".k-bottom-sheet")?.getBoundingClientRect().height ??
          scroller.clientHeight;
        const dismiss =
          event.type !== "touchcancel" &&
          dismissible &&
          (offset > height * sheetCloseThreshold ||
            (offset > 24 &&
              event.timeStamp - previousTime < 100 &&
              velocity > sheetCloseVelocity / 1000));
        sheetRef.current.snapTo(dismiss ? 0 : 1);
      }
      eligible = dragging = false;
    };
    scroller.addEventListener("touchstart", start, { passive: true });
    scroller.addEventListener("touchmove", move, { passive: false });
    scroller.addEventListener("touchend", finish);
    scroller.addEventListener("touchcancel", finish);
    return () => {
      scroller.removeEventListener("touchstart", start);
      scroller.removeEventListener("touchmove", move);
      scroller.removeEventListener("touchend", finish);
      scroller.removeEventListener("touchcancel", finish);
    };
  }, [open, dismissible, scroller, sheetRef]);
}
