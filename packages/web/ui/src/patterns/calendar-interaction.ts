import {
  useEffect,
  useRef,
  useState,
  type RefObject,
  type PointerEvent as ReactPointerEvent,
} from "react";
import {
  orderedSelection,
  shiftSlot,
  slot,
  slotNumber,
  kCalendarSlotToDate,
  instantSlot,
  type CalendarEntry,
} from "./calendar-model.js";
import type {
  KCalendarProps,
  KCalendarSelection,
  KCalendarSlot,
} from "./calendar-types.js";

type Kind = "create" | "move" | "resize";
interface Gesture<T> {
  kind: Kind;
  entry?: CalendarEntry<T>;
  edge?: "start" | "end";
  origin: KCalendarSlot;
  selection: KCalendarSelection;
  x: number;
  y: number;
  initialX: number;
  initialY: number;
  active: boolean;
  moved: boolean;
  touch: boolean;
}
export function useCalendarInteraction<T>(
  root: RefObject<HTMLDivElement | null>,
  props: KCalendarProps<T>,
  zone: string,
) {
  const current = useRef(props);
  current.current = props;
  const [preview, setPreview] = useState<KCalendarSelection | null>(null);
  const [previewEntryId, setPreviewEntryId] = useState<string | null>(null);
  const [previewPoint, setPreviewPoint] = useState<{ x: number; y: number } | null>(null);
  const gesture = useRef<Gesture<T> | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const step = props.stepMinutes ?? 30;
  function hit(x: number, y: number): KCalendarSlot | null {
    for (const node of root.current?.querySelectorAll<HTMLElement>(
      "[data-calendar-slot]",
    ) ?? []) {
      const r = node.getBoundingClientRect();
      if (x < r.left || x >= r.right || y < r.top || y >= r.bottom) continue;
      const allDay = node.dataset.allDay === "true";
      const minute = allDay
        ? 0
        : Math.max(
            (props.startHour ?? 0) * 60,
            Math.min(
              (props.endHour ?? 24) * 60 - step,
              Math.floor(
                ((props.startHour ?? 0) * 60 +
                  ((y - r.top) / (props.hourHeight ?? 56)) * 60) /
                  step,
              ) * step,
            ),
          );
      return slot(node.dataset.calendarSlot!, minute, allDay, zone);
    }
    return null;
  }
  const hitRef = useRef(hit);
  hitRef.current = hit;
  function emit(
    g: Gesture<T>,
    phase: "start" | "preview" | "commit" | "cancel",
  ) {
    current.current.onInteraction?.({
      kind: g.kind,
      phase,
      selection: g.selection,
      event: g.entry?.event,
    });
  }
  function allowed(g: Gesture<T>) {
    const p = current.current;
    if (slotNumber(g.selection.end) <= slotNumber(g.selection.start))
      return false;
    if (
      !kCalendarSlotToDate(g.selection.start) ||
      !kCalendarSlotToDate(g.selection.end)
    )
      return false;
    if (g.kind === "create")
      return !!p.onCreate && p.canCreate?.(g.selection) !== false;
    if (g.kind === "move")
      return (
        !!p.onEventMove &&
        p.canMove?.({
          event: g.entry!.event,
          eventId: g.entry!.id,
          target: g.selection.start,
          durationMinutes: duration(g.selection),
        }) !== false
      );
    return (
      !!p.onEventResize &&
      p.canResize?.({
        event: g.entry!.event,
        eventId: g.entry!.id,
        ...g.selection,
        edge: g.edge!,
      }) !== false
    );
  }
  function commit(g: Gesture<T>) {
    if (!allowed(g)) {
      emit(g, "cancel");
      return;
    }
    const p = current.current;
    if (g.kind === "create") p.onCreate?.(g.selection);
    else if (g.kind === "move")
      p.onEventMove?.({
        event: g.entry!.event,
        eventId: g.entry!.id,
        target: g.selection.start,
        durationMinutes: duration(g.selection),
      });
    else
      p.onEventResize?.({
        event: g.entry!.event,
        eventId: g.entry!.id,
        ...g.selection,
        edge: g.edge!,
      });
    emit(g, "commit");
  }
  const handlers = useRef({ emit, commit });
  handlers.current = { emit, commit };
  useEffect(() => {
    let frame = 0;
    function update(g: Gesture<T>) {
      const target = hitRef.current(g.x, g.y);
      if (!target) return;
      const p = current.current,
        snap = p.stepMinutes ?? 30;
      if (g.kind === "create") {
        if (target.allDay !== g.origin.allDay) return;
        g.selection = g.moved
          ? orderedSelection(g.origin, target, snap)
          : {
              start: target,
              end: shiftSlot(
                target,
                target.allDay ? 1440 : (p.defaultDurationMinutes ?? snap),
              ),
            };
      } else if (g.kind === "move") {
        const original = g.entry!;
        const a = p.getEventStart(original.event),
          b = p.getEventEnd(original.event);
        const duration =
          !original.start.allDay && a && b
            ? (b.getTime() - a.getTime()) / 60000
            : slotNumber(original.end) - slotNumber(original.start);
        // Keep the grab offset when moving within the same kind of lane.
        const offset =
          target.allDay === g.origin.allDay
            ? slotNumber(g.origin) - slotNumber(original.start)
            : 0;
        const start = shiftSlot(target, -offset);
        const targetInstant = kCalendarSlotToDate(start);
        const minutes = target.allDay
          ? Math.max(1440, Math.ceil(duration / 1440) * 1440)
          : original.start.allDay
            ? (p.defaultDurationMinutes ?? snap)
            : duration;
        g.selection = {
          start,
          end:
            !target.allDay && targetInstant
              ? instantSlot(
                  new Date(targetInstant.getTime() + minutes * 60000),
                  false,
                  start.timeZone,
                )
              : shiftSlot(start, minutes),
        };
      } else {
        if (!target.allDay && g.entry!.start.allDay) return;
        const next =
          target.allDay && !g.entry!.start.allDay
            ? slot(
                target.date,
                g.entry![g.edge!].minutes,
                false,
                target.timeZone,
              )
            : g.edge === "end"
              ? shiftSlot(target, target.allDay ? 1440 : snap)
              : target;
        const selection = { ...g.entry!, [g.edge!]: next };
        if (slotNumber(selection.end) <= slotNumber(selection.start)) return;
        g.selection = { start: selection.start, end: selection.end };
      }
      setPreview(g.selection);
      setPreviewPoint({ x: g.x, y: g.y });
      handlers.current.emit(g, "preview");
    }
    function scroll() {
      const g = gesture.current,
        node = root.current;
      if (g?.active && g.moved && node) {
        const r = node.getBoundingClientRect(),
          margin = 36;
        const dx =
          g.x < r.left + margin ? -12 : g.x > r.right - margin ? 12 : 0;
        const dy =
          g.y < r.top + margin ? -12 : g.y > r.bottom - margin ? 12 : 0;
        if (dx || dy) {
          node.scrollBy(dx, dy);
          update(g);
        }
      }
      frame = requestAnimationFrame(scroll);
    }
    function move(e: PointerEvent) {
      const g = gesture.current;
      if (!g) return;
      const previousX = g.x,
        previousY = g.y;
      g.x = e.clientX;
      g.y = e.clientY;
      const distance = Math.hypot(g.x - g.initialX, g.y - g.initialY);
      if (distance > 4) g.moved = true;
      if (!g.active && current.current.requireLongPress && g.moved) {
        clearTimeout(timer.current);
        root.current?.scrollBy(previousX - g.x, previousY - g.y);
        e.preventDefault();
        return;
      }
      if (!g.active) return;
      e.preventDefault();
      update(g);
    }
    function finish(e: PointerEvent) {
      const g = gesture.current;
      clearTimeout(timer.current);
      if (!g) return;
      gesture.current = null;
      setPreviewEntryId(null);
      setPreviewPoint(null);
      const p = current.current;
      const keepCreatePreview =
        g.kind === "create" &&
        p.requireLongPress &&
        !g.moved &&
        !g.active;
      if (!keepCreatePreview) setPreview(null);
      if (e.type === "pointercancel") {
        if (g.active) handlers.current.emit(g, "cancel");
        return;
      }
      if (!g.moved && g.entry && g.kind === "move") {
        if (g.active) handlers.current.emit(g, "cancel");
        current.current.onEventOpen?.(g.entry.event);
        return;
      }
      if (g.kind === "resize" && !g.moved) {
        if (g.active) handlers.current.emit(g, "cancel");
        return;
      }
      if (!g.active) {
        if (g.kind === "create" && p.requireLongPress && !g.moved) {
          handlers.current.commit(g);
          return;
        }
        handlers.current.emit(g, "cancel");
        return;
      }
      handlers.current.commit(g);
    }
    function escape(e: KeyboardEvent) {
      if (e.key !== "Escape" || !gesture.current) return;
      handlers.current.emit(gesture.current, "cancel");
      gesture.current = null;
      clearTimeout(timer.current);
      setPreview(null);
    }
    function touchMove(e: TouchEvent) {
      if (gesture.current?.active) e.preventDefault();
    }
    window.addEventListener("touchmove", touchMove, { passive: false });
    window.addEventListener("pointermove", move, { passive: false });
    window.addEventListener("pointerup", finish);
    window.addEventListener("pointercancel", finish);
    window.addEventListener("keydown", escape);
    frame = requestAnimationFrame(scroll);
    return () => {
      clearTimeout(timer.current);
      cancelAnimationFrame(frame);
      window.removeEventListener("touchmove", touchMove);
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", finish);
      window.removeEventListener("pointercancel", finish);
      window.removeEventListener("keydown", escape);
    };
  }, [root]);
  function begin(
    e: ReactPointerEvent,
    entry?: CalendarEntry<T>,
    edge?: "start" | "end",
  ) {
    const p = current.current;
    if (e.button !== 0) return;
    const target = e.target as HTMLElement;
    if (
      !edge &&
      target.closest("button,input,select,textarea,a,[contenteditable=true]")
    )
      return;
    const origin = hit(e.clientX, e.clientY);
    if (!origin) return;
    e.stopPropagation();
    (e.currentTarget as HTMLElement).setPointerCapture?.(e.pointerId);
    const kind = edge ? "resize" : entry ? "move" : "create";
    if (kind === "create" && !p.onCreate) return;
    setPreview(null);
    setPreviewEntryId(entry?.id ?? null);
    setPreviewPoint({ x: e.clientX, y: e.clientY });
    const selection = entry
      ? { start: entry.start, end: entry.end }
      : {
          start: origin,
          end: shiftSlot(
            origin,
            origin.allDay ? 1440 : (props.defaultDurationMinutes ?? step),
          ),
        };
    const g: Gesture<T> = {
      kind,
      entry,
      edge,
      origin,
      selection,
      x: e.clientX,
      y: e.clientY,
      initialX: e.clientX,
      initialY: e.clientY,
      // Existing events remain draggable with a mouse in compact/mobile
      // layouts. Long-press is only needed for creating a new range there;
      // otherwise a mouse drag would never become active because the compact
      // scrolling gesture intentionally does not arm a creation timer.
      active:
        e.pointerType !== "touch" &&
        (kind !== "create" || !p.requireLongPress),
      moved: false,
      touch: e.pointerType === "touch",
    };
    gesture.current = g;
    if (g.active) {
      e.preventDefault();
      emit(g, "start");
      if (kind === "create") setPreview(selection);
    } else if (
      g.touch ||
      (kind === "create" && p.requireLongPress) ||
      !p.requireLongPress
    )
      timer.current = setTimeout(() => {
        if (gesture.current === g) {
          g.active = true;
          emit(g, "start");
          setPreview(g.selection);
        }
      }, 400);
  }
  function create(selection: KCalendarSelection) {
    const g = { kind: "create", selection } as Gesture<T>;
    setPreview(selection);
    emit(g, "start");
    commit(g);
  }
  function change(
    kind: "move" | "resize",
    entry: CalendarEntry<T>,
    selection: KCalendarSelection,
    edge?: "start" | "end",
  ) {
    const g = { kind, entry, selection, edge } as Gesture<T>;
    emit(g, "start");
    commit(g);
  }
  return { preview, previewEntryId, previewPoint, begin, create, change };
}

function duration(selection: KCalendarSelection) {
  const a = kCalendarSlotToDate(selection.start),
    b = kCalendarSlotToDate(selection.end);
  return a && b ? (b.getTime() - a.getTime()) / 60000 : 0;
}
