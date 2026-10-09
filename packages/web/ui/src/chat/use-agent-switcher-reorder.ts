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

interface PointerGesture {
  id: string;
  pointerId: number;
  pointerType: string;
  startX: number;
  startY: number;
  scrollLeft: number;
  panning: boolean;
  activated: boolean;
}

interface ReorderFeedback {
  announce: (name: string, position: number, count: number) => string;
}

export function useAgentSwitcherReorder({
  ids,
  orientation,
  onReorder,
  onLongPress,
  feedback,
}: {
  ids: readonly string[];
  orientation: "horizontal" | "vertical";
  onReorder?: (ids: string[]) => void;
  onLongPress?: (id: string) => void;
  feedback: ReorderFeedback;
}) {
  const [announcement, setAnnouncement] = useState("");
  const gesture = useRef<PointerGesture | undefined>(undefined);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const suppressClick = useRef<string | undefined>(undefined);
  const rootRef = useRef<HTMLElement>(null);
  const dragActive = useRef(false);

  const clearTimer = useCallback(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = undefined;
  }, []);

  const resetPointer = useCallback(() => {
    clearTimer();
    gesture.current = undefined;
  }, [clearTimer]);

  useEffect(() => resetPointer, [resetPointer]);

  useEffect(() => {
    if (orientation !== "horizontal") return;
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
  }, [orientation]);

  const pointerDown = useCallback(
    (event: ReactPointerEvent<HTMLButtonElement>, id: string) => {
      if (event.button !== 0) return;
      suppressClick.current = undefined;
      clearTimer();
      const list = rootRef.current?.querySelector<HTMLElement>(
        ".k-agent-switcher__list",
      );
      gesture.current = {
        id,
        pointerId: event.pointerId,
        pointerType: event.pointerType,
        startX: event.clientX,
        startY: event.clientY,
        scrollLeft: list?.scrollLeft ?? 0,
        panning: false,
        activated: false,
      };
      if (!onReorder && onLongPress) {
        timer.current = setTimeout(() => {
          const current = gesture.current;
          if (!current || current.pointerId !== event.pointerId) return;
          current.activated = true;
          suppressClick.current = current.id;
          onLongPress(current.id);
        }, longPressDelay);
      }
    },
    [clearTimer, onLongPress, onReorder],
  );

  const pointerMove = useCallback(
    (event: ReactPointerEvent<HTMLElement>) => {
      const current = gesture.current;
      if (
        !current ||
        current.pointerId !== event.pointerId ||
        dragActive.current
      )
        return;
      const deltaX = event.clientX - current.startX;
      const deltaY = event.clientY - current.startY;
      if (orientation === "vertical") {
        if (Math.hypot(deltaX, deltaY) > movementTolerance) {
          clearTimer();
          gesture.current = undefined;
        }
        return;
      }
      if (!current.panning) {
        if (Math.hypot(deltaX, deltaY) <= movementTolerance) return;
        clearTimer();
        if (
          current.pointerType !== "mouse" ||
          Math.abs(deltaX) < Math.abs(deltaY)
        ) {
          gesture.current = undefined;
          return;
        }
        current.panning = true;
      }
      event.preventDefault();
      const list = rootRef.current?.querySelector<HTMLElement>(
        ".k-agent-switcher__list",
      );
      if (list) list.scrollLeft = current.scrollLeft - deltaX;
    },
    [clearTimer, orientation],
  );

  const pointerUp = useCallback(
    (event: ReactPointerEvent<HTMLButtonElement>) => {
      const current = gesture.current;
      if (!current || current.pointerId !== event.pointerId) return;
      if (current.panning || current.activated || dragActive.current) {
        suppressClick.current = current.id;
      }
      resetPointer();
    },
    [resetPointer],
  );

  const cancelPointer = useCallback(() => {
    const current = gesture.current;
    if (current?.activated || current?.panning || dragActive.current) {
      suppressClick.current = current?.id;
    }
    resetPointer();
  }, [resetPointer]);

  const pointerLeave = useCallback(() => {
    if (gesture.current?.pointerType === "touch" && !dragActive.current) {
      resetPointer();
    }
  }, [resetPointer]);

  const startReorder = useCallback(
    (id: string, name: string) => {
      dragActive.current = true;
      suppressClick.current = id;
      onLongPress?.(id);
      setAnnouncement(feedback.announce(name, ids.indexOf(id) + 1, ids.length));
    },
    [feedback, ids, onLongPress],
  );

  const finishReorder = useCallback(
    (
      id: string,
      name: string,
      overId: string | undefined,
      sourceIds: readonly string[],
      canceled: boolean,
    ) => {
      dragActive.current = false;
      suppressClick.current = id;
      resetPointer();
      if (canceled || !onReorder || !overId) return;
      const next = moveAgentId(sourceIds, id, overId);
      if (!next.some((nextId, index) => nextId !== sourceIds[index])) return;
      onReorder(next);
      setAnnouncement(
        feedback.announce(name, next.indexOf(id) + 1, next.length),
      );
    },
    [feedback, onReorder, resetPointer],
  );

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
    announcement,
    pointerDown,
    pointerMove,
    pointerUp,
    cancelPointer,
    pointerLeave,
    startReorder,
    finishReorder,
    keyboardMove,
    consumeClick,
  };
}
