import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
} from "react";

const longPressDelay = 450;
const movementTolerance = 8;

export function moveAgentId(
  ids: readonly string[],
  activeId: string,
  overId: string,
) {
  const from = ids.indexOf(activeId);
  const to = ids.indexOf(overId);
  if (from < 0 || to < 0 || from === to) return [...ids];
  const next = [...ids];
  next.splice(to, 0, next.splice(from, 1)[0]);
  return next;
}

interface Gesture {
  id: string;
  name: string;
  pointerId: number;
  startX: number;
  startY: number;
  element: HTMLButtonElement;
  activated: boolean;
  reordering: boolean;
  panning: boolean;
  overId: string;
  clientX: number;
  clientY: number;
  scrollLeft: number;
}

interface ReorderFeedback {
  announce: (name: string, position: number, count: number) => string;
}

export function useAgentSwitcherReorder({
  ids,
  onReorder,
  onLongPress,
  feedback,
}: {
  ids: readonly string[];
  onReorder?: (ids: string[]) => void;
  onLongPress?: (id: string) => void;
  feedback: ReorderFeedback;
}) {
  const [draggingId, setDraggingId] = useState<string>();
  const [overId, setOverId] = useState<string>();
  const [announcement, setAnnouncement] = useState("");
  const gesture = useRef<Gesture | undefined>(undefined);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const suppressClick = useRef<string | undefined>(undefined);
  const rootRef = useRef<HTMLElement>(null);
  const autoScrollDirection = useRef(0);
  const autoScrollFrame = useRef<number | undefined>(undefined);

  const clearTimer = useCallback(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = undefined;
  }, []);

  const stopAutoScroll = useCallback(() => {
    autoScrollDirection.current = 0;
    if (autoScrollFrame.current !== undefined) {
      cancelAnimationFrame(autoScrollFrame.current);
      autoScrollFrame.current = undefined;
    }
  }, []);

  const reset = useCallback(() => {
    clearTimer();
    stopAutoScroll();
    gesture.current = undefined;
    setDraggingId(undefined);
    setOverId(undefined);
  }, [clearTimer, stopAutoScroll]);

  useEffect(() => reset, [reset]);

  useEffect(() => {
    const stopActiveTouchDrag = (event: TouchEvent) => {
      if (gesture.current?.reordering) event.preventDefault();
    };
    window.addEventListener("touchmove", stopActiveTouchDrag, {
      passive: false,
    });
    return () => window.removeEventListener("touchmove", stopActiveTouchDrag);
  }, []);

  useEffect(() => {
    const list = rootRef.current?.querySelector<HTMLElement>(
      ".k-agent-switcher__list",
    );
    if (!list) return;
    const translateVerticalWheel = (event: WheelEvent) => {
      if (event.deltaX !== 0 || event.deltaY === 0) return;
      const maximum = list.scrollWidth - list.clientWidth;
      const canScroll =
        (event.deltaY < 0 && list.scrollLeft > 0) ||
        (event.deltaY > 0 && list.scrollLeft < maximum);
      if (!canScroll) return;
      event.preventDefault();
      list.scrollLeft = Math.max(
        0,
        Math.min(maximum, list.scrollLeft + event.deltaY),
      );
    };
    list.addEventListener("wheel", translateVerticalWheel, { passive: false });
    return () => list.removeEventListener("wheel", translateVerticalWheel);
  }, []);

  const pointerDown = useCallback(
    (event: ReactPointerEvent<HTMLButtonElement>, id: string, name: string) => {
      if (event.button !== 0) return;
      suppressClick.current = undefined;
      clearTimer();
      gesture.current = {
        id,
        name,
        pointerId: event.pointerId,
        startX: event.clientX,
        startY: event.clientY,
        element: event.currentTarget,
        activated: false,
        reordering: false,
        panning: false,
        overId: id,
        clientX: event.clientX,
        clientY: event.clientY,
        scrollLeft:
          rootRef.current?.querySelector<HTMLElement>(".k-agent-switcher__list")
            ?.scrollLeft ?? 0,
      };
      if (event.pointerType === "mouse")
        event.currentTarget.setPointerCapture?.(event.pointerId);
      if (!onReorder && !onLongPress) return;
      timer.current = setTimeout(() => {
        const current = gesture.current;
        if (!current || current.pointerId !== event.pointerId) return;
        current.activated = true;
        onLongPress?.(current.id);
        if (onReorder) {
          current.reordering = true;
          current.element.setPointerCapture?.(current.pointerId);
          setDraggingId(current.id);
          setOverId(current.id);
          setAnnouncement(
            feedback.announce(
              current.name,
              ids.indexOf(current.id) + 1,
              ids.length,
            ),
          );
        }
      }, longPressDelay);
    },
    [clearTimer, feedback, ids, onLongPress, onReorder],
  );

  const updateOver = useCallback(
    (clientX: number, clientY: number) => {
      const target = document
        .elementFromPoint(clientX, clientY)
        ?.closest<HTMLElement>("[data-agent-id]");
      const nextOver = target?.dataset.agentId;
      if (
        target &&
        rootRef.current?.contains(target) &&
        nextOver &&
        ids.includes(nextOver)
      ) {
        if (gesture.current) gesture.current.overId = nextOver;
        setOverId(nextOver);
      }
    },
    [ids],
  );

  const startAutoScroll = useCallback(() => {
    if (autoScrollFrame.current !== undefined) return;
    const tick = () => {
      const current = gesture.current;
      const list = rootRef.current?.querySelector<HTMLElement>(
        ".k-agent-switcher__list",
      );
      if (!current?.reordering || !list || !autoScrollDirection.current) {
        autoScrollFrame.current = undefined;
        return;
      }
      list.scrollLeft += autoScrollDirection.current * 8;
      updateOver(current.clientX, current.clientY);
      autoScrollFrame.current = requestAnimationFrame(tick);
    };
    autoScrollFrame.current = requestAnimationFrame(tick);
  }, [updateOver]);

  const pointerMove = useCallback(
    (event: ReactPointerEvent<HTMLButtonElement>) => {
      const current = gesture.current;
      if (!current || current.pointerId !== event.pointerId) return;
      current.clientX = event.clientX;
      current.clientY = event.clientY;
      if (current.panning) {
        event.preventDefault();
        const list = rootRef.current?.querySelector<HTMLElement>(
          ".k-agent-switcher__list",
        );
        if (list)
          list.scrollLeft =
            current.scrollLeft - (event.clientX - current.startX);
        return;
      }
      if (!current.activated) {
        const deltaX = event.clientX - current.startX;
        const deltaY = event.clientY - current.startY;
        if (Math.hypot(deltaX, deltaY) > movementTolerance) {
          clearTimer();
          if (
            event.pointerType === "mouse" &&
            Math.abs(deltaX) >= Math.abs(deltaY)
          ) {
            current.panning = true;
            current.element.setPointerCapture?.(current.pointerId);
            const list = rootRef.current?.querySelector<HTMLElement>(
              ".k-agent-switcher__list",
            );
            if (list) list.scrollLeft = current.scrollLeft - deltaX;
          } else {
            gesture.current = undefined;
          }
        }
        return;
      }
      if (!current.reordering) return;
      event.preventDefault();
      updateOver(event.clientX, event.clientY);
      const list = rootRef.current?.querySelector<HTMLElement>(
        ".k-agent-switcher__list",
      );
      if (list) {
        const bounds = list.getBoundingClientRect();
        const edge = Math.min(48, bounds.width * 0.15);
        autoScrollDirection.current =
          event.clientX < bounds.left + edge
            ? -1
            : event.clientX > bounds.right - edge
              ? 1
              : 0;
        if (autoScrollDirection.current) startAutoScroll();
        else stopAutoScroll();
      }
    },
    [clearTimer, startAutoScroll, stopAutoScroll, updateOver],
  );

  const pointerUp = useCallback(
    (event: ReactPointerEvent<HTMLButtonElement>) => {
      const current = gesture.current;
      if (!current || current.pointerId !== event.pointerId) return;
      if (current.panning) {
        const list = rootRef.current?.querySelector<HTMLElement>(
          ".k-agent-switcher__list",
        );
        if (list)
          list.scrollLeft =
            current.scrollLeft - (event.clientX - current.startX);
        reset();
        suppressClick.current = current.id;
        return;
      }
      const activated = current.activated;
      const next = moveAgentId(ids, current.id, current.overId);
      reset();
      if (!activated && !current.panning) return;
      suppressClick.current = current.id;
      if (
        current.reordering &&
        onReorder &&
        next.some((id, index) => id !== ids[index])
      ) {
        onReorder(next);
        setAnnouncement(
          feedback.announce(
            current.name,
            next.indexOf(current.id) + 1,
            next.length,
          ),
        );
      }
    },
    [feedback, ids, onReorder, reset],
  );

  const cancel = useCallback(() => {
    const current = gesture.current;
    if (current?.activated) {
      suppressClick.current = current.id;
    }
    reset();
  }, [feedback, reset]);

  const pointerLeave = useCallback(() => {
    if (
      gesture.current &&
      !gesture.current.activated &&
      !gesture.current.panning
    )
      reset();
  }, [reset]);

  useEffect(() => {
    const endOutside = (event: PointerEvent) => {
      const current = gesture.current;
      if (!current || current.pointerId !== event.pointerId) return;
      if (current.reordering) {
        const next = moveAgentId(ids, current.id, current.overId);
        suppressClick.current = current.id;
        reset();
        if (onReorder && next.some((id, index) => id !== ids[index])) {
          onReorder(next);
          setAnnouncement(
            feedback.announce(
              current.name,
              next.indexOf(current.id) + 1,
              next.length,
            ),
          );
        }
      } else {
        if (current.panning) suppressClick.current = current.id;
        reset();
      }
    };
    const cancelOutside = (event: PointerEvent) => {
      if (gesture.current?.pointerId === event.pointerId) cancel();
    };
    window.addEventListener("pointerup", endOutside);
    window.addEventListener("pointercancel", cancelOutside);
    return () => {
      window.removeEventListener("pointerup", endOutside);
      window.removeEventListener("pointercancel", cancelOutside);
    };
  }, [cancel, feedback, ids, onReorder, reset]);

  const keyboardMove = useCallback(
    (id: string, name: string, direction: -1 | 1) => {
      if (!onReorder) return;
      const from = ids.indexOf(id);
      const to = Math.max(0, Math.min(ids.length - 1, from + direction));
      if (from < 0 || from === to) return;
      const next = moveAgentId(ids, id, ids[to]);
      onReorder(next);
      setAnnouncement(feedback.announce(name, to + 1, next.length));
    },
    [feedback, ids, onReorder],
  );

  const consumeClick = useCallback((id: string) => {
    if (suppressClick.current !== id) return false;
    suppressClick.current = undefined;
    return true;
  }, []);

  return {
    rootRef,
    draggingId,
    overId,
    announcement,
    pointerDown,
    pointerMove,
    pointerUp,
    cancel,
    pointerLeave,
    keyboardMove,
    consumeClick,
  };
}
