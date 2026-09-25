import { useRef, useState, type MouseEvent, type PointerEvent } from "react";

const dragThreshold = 4;

/** Adds mouse drag scrolling while preserving native touch and trackpad scroll. */
export function useHorizontalDragScroll<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const gesture = useRef({
    pointerId: -1,
    startX: 0,
    startScrollLeft: 0,
    dragged: false,
  });
  const [dragging, setDragging] = useState(false);

  function onPointerDown(event: PointerEvent<T>) {
    if (event.pointerType !== "mouse" || event.button !== 0) return;
    const element = ref.current;
    if (!element || element.scrollWidth <= element.clientWidth) return;
    gesture.current = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startScrollLeft: element.scrollLeft,
      dragged: false,
    };
  }

  function onPointerMove(event: PointerEvent<T>) {
    const element = ref.current;
    const current = gesture.current;
    if (!element || current.pointerId !== event.pointerId) return;
    const delta = event.clientX - current.startX;
    if (!current.dragged && Math.abs(delta) < dragThreshold) return;
    if (!current.dragged) element.setPointerCapture(event.pointerId);
    current.dragged = true;
    setDragging(true);
    element.scrollLeft = current.startScrollLeft - delta;
    event.preventDefault();
  }

  function finishPointer(event: PointerEvent<T>) {
    const element = ref.current;
    if (gesture.current.pointerId !== event.pointerId) return;
    if (element?.hasPointerCapture(event.pointerId)) {
      element.releasePointerCapture(event.pointerId);
    }
    gesture.current.pointerId = -1;
    setDragging(false);
  }

  function onClickCapture(event: MouseEvent<T>) {
    if (!gesture.current.dragged) return;
    event.preventDefault();
    event.stopPropagation();
    gesture.current.dragged = false;
  }

  return {
    ref,
    onPointerDown,
    onPointerMove,
    onPointerUp: finishPointer,
    onPointerCancel: finishPointer,
    onClickCapture,
    "data-dragging": dragging || undefined,
  };
}
