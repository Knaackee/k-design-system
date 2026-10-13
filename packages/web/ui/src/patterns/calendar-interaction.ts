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
  calendarMoveDuration,
  type CalendarEntry,
} from "./calendar-model.js";
import type {
  KCalendarProps,
  KCalendarMove,
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
  held?: boolean;
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
  const [previewEntry, setPreviewEntry] = useState<CalendarEntry<T> | null>(
    null,
  );
  const [previewPoint, setPreviewPoint] = useState<{
    x: number;
    y: number;
  } | null>(null);
  const gesture = useRef<Gesture<T> | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const [portrait, setPortrait] = useState(false);
  const portraitRef = useRef(false);
  const [localSelected, setLocalSelected] = useState<string | null>(null);
  const selected = props.onSelectedEventChange
    ? (props.selectedEventId ?? null)
    : localSelected;
  const selectedRef = useRef(selected);
  selectedRef.current = selected;
  function select(id: string | null) {
    if (current.current.onSelectedEventChange)
      current.current.onSelectedEventChange(id);
    else {
      selectedRef.current = id;
      setLocalSelected(id);
    }
  }
  const selectRef = useRef(select);
  selectRef.current = select;
  useEffect(() => {
    const node = root.current;
    if (!node) return;
    const measure = () => {
      portraitRef.current =
        window.innerWidth < 600 && window.innerWidth < window.innerHeight;
      setPortrait(portraitRef.current);
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(node);
    window.addEventListener("resize", measure);
    const dismiss = (event: PointerEvent) => {
      if (
        !(event.target instanceof Element) ||
        !event.target.closest("[data-calendar-event-id]")
      )
        selectRef.current(null);
    };
    window.addEventListener("pointerdown", dismiss);
    return () => {
      observer.disconnect();
      window.removeEventListener("resize", measure);
      window.removeEventListener("pointerdown", dismiss);
    };
  }, [root]);
  const step = props.stepMinutes ?? 30;
  function hit(x: number, y: number): KCalendarSlot | null {
    const rootRect = root.current?.getBoundingClientRect();
    if (
      !rootRect ||
      x < rootRect.left ||
      x >= rootRect.right ||
      y < rootRect.top ||
      y >= rootRect.bottom
    )
      return null;
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
  function moveFor(
    event: T,
    target: KCalendarSlot,
    durationOverride?: number,
  ): KCalendarMove<T> {
    const p = current.current;
    const start = p.getEventStart(event),
      end = p.getEventEnd(event);
    const sourceAllDay = p.getEventAllDay?.(event) ?? false;
    return {
      event,
      eventId: p.getEventId(event),
      target,
      durationMinutes: calendarMoveDuration(
        start,
        end,
        sourceAllDay,
        target.allDay,
        durationOverride,
        p.defaultDurationMinutes ?? step,
        step,
      ),
    };
  }
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
    if (g.kind === "create") {
      p.onPendingCreateSelectionChange?.(g.selection);
      p.onCreate?.(g.selection);
    } else if (g.kind === "move")
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
  const committedExternalId = useRef<string | null>(null);
  const activeExternalId = useRef<string | null>(null);
  useEffect(() => {
    const drag = props.externalDrag;
    const clearExternal = () => {
      if (activeExternalId.current == null) return;
      activeExternalId.current = null;
      setPreview(null);
      setPreviewEntryId(null);
      setPreviewEntry(null);
      setPreviewPoint(null);
    };
    if (!drag || drag.phase === "cancel") {
      clearExternal();
      committedExternalId.current = null;
      return;
    }
    const target = hitRef.current(drag.clientX, drag.clientY);
    if (drag.phase === "commit") {
      if (committedExternalId.current === drag.id) return;
      committedExternalId.current = drag.id;
      if (target) {
        const move = moveFor(drag.event, target, drag.durationMinutes);
        const selection = {
          start: target,
          end: shiftSlot(target, move.durationMinutes),
        };
        const valid =
          kCalendarSlotToDate(selection.start) != null &&
          kCalendarSlotToDate(selection.end) != null;
        const allowed =
          valid &&
          current.current.onEventMove != null &&
          current.current.canMove?.(move) !== false;
        current.current.onInteraction?.({
          kind: "move",
          phase: allowed ? "commit" : "cancel",
          selection,
          event: drag.event,
        });
        if (allowed) current.current.onEventMove?.(move);
      }
      clearExternal();
      return;
    }
    if (activeExternalId.current !== drag.id) {
      committedExternalId.current = null;
      current.current.onPendingCreateSelectionChange?.(null);
    }
    activeExternalId.current = drag.id;
    if (!target) {
      setPreview(null);
      setPreviewEntryId(null);
      setPreviewEntry(null);
      setPreviewPoint(null);
      return;
    }
    const move = moveFor(drag.event, target, drag.durationMinutes);
    const selection = {
      start: target,
      end: shiftSlot(target, move.durationMinutes),
    };
    if (
      !kCalendarSlotToDate(selection.start) ||
      !kCalendarSlotToDate(selection.end)
    ) {
      clearExternal();
      return;
    }
    setPreview(selection);
    setPreviewEntryId(move.eventId);
    setPreviewEntry({ event: drag.event, id: move.eventId, ...selection });
    setPreviewPoint({ x: drag.clientX, y: drag.clientY });
    current.current.onInteraction?.({
      kind: "move",
      phase: "preview",
      selection,
      event: drag.event,
    });
  }, [
    props.externalDrag?.id,
    props.externalDrag?.event,
    props.externalDrag?.phase,
    props.externalDrag?.clientX,
    props.externalDrag?.clientY,
    props.externalDrag?.durationMinutes,
  ]);
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
      setPreviewEntryId(g.entry?.id ?? null);
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
      if (
        !g.active &&
        (portraitRef.current || current.current.requireLongPress) &&
        g.moved
      ) {
        clearTimeout(timer.current);
        root.current?.scrollBy(previousX - g.x, previousY - g.y);
        e.preventDefault();
        return;
      }
      if (!g.active || !g.moved) return;
      e.preventDefault();
      update(g);
    }
    function finish(e: PointerEvent) {
      const g = gesture.current;
      clearTimeout(timer.current);
      if (!g) return;
      gesture.current = null;
      setPreviewEntryId(null);
      setPreviewEntry(null);
      setPreviewPoint(null);
      const p = current.current;
      const keepCreatePreview =
        g.kind === "create" &&
        !p.onPendingCreateSelectionChange &&
        (p.requireLongPress || portraitRef.current) &&
        !g.moved &&
        !g.active;
      if (!keepCreatePreview) setPreview(null);
      if (e.type === "pointercancel") {
        if (g.active) handlers.current.emit(g, "cancel");
        return;
      }
      if (
        g.active &&
        g.moved &&
        g.kind === "move" &&
        !hitRef.current(e.clientX, e.clientY)
      ) {
        const drop = {
          event: g.entry!.event,
          eventId: g.entry!.id,
          clientX: e.clientX,
          clientY: e.clientY,
        };
        if (p.onEventDropOutside && p.canDropOutside?.(drop) !== false) {
          p.onEventDropOutside(drop);
          handlers.current.emit(g, "commit");
        } else {
          handlers.current.emit(g, "cancel");
        }
        selectRef.current(null);
        return;
      }
      if (!g.moved && g.entry && g.kind === "move") {
        if (g.active) handlers.current.emit(g, "cancel");
        if (!g.held) current.current.onEventOpen?.(g.entry.event);
        return;
      }
      if (g.kind === "resize" && !g.moved) {
        if (g.active) handlers.current.emit(g, "cancel");
        return;
      }
      if (!g.active) {
        if (
          g.kind === "create" &&
          (p.requireLongPress || portraitRef.current) &&
          !g.moved
        ) {
          handlers.current.commit(g);
          return;
        }
        handlers.current.emit(g, "cancel");
        return;
      }
      handlers.current.commit(g);
      if (g.kind === "move" && g.moved) selectRef.current(null);
    }
    function escape(e: KeyboardEvent) {
      if (e.key !== "Escape") return;
      selectRef.current(null);
      current.current.onPendingCreateSelectionChange?.(null);
      if (!gesture.current) return;
      handlers.current.emit(gesture.current, "cancel");
      gesture.current = null;
      clearTimeout(timer.current);
      setPreview(null);
      setPreviewEntryId(null);
      setPreviewEntry(null);
      setPreviewPoint(null);
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
    // The source event is replaced by its preview during a drag. Capture on
    // the stable calendar root so removing that source cannot end the gesture.
    root.current?.setPointerCapture?.(e.pointerId);
    const kind = edge ? "resize" : entry ? "move" : "create";
    if (kind === "create" && !p.onCreate) return;
    if (kind === "move" && !p.onEventMove && !p.onEventDropOutside) return;
    p.onPendingCreateSelectionChange?.(null);
    setPreview(null);
    setPreviewEntryId(null);
    setPreviewEntry(null);
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
      active:
        entry && portraitRef.current
          ? selectedRef.current === entry.id
          : e.pointerType !== "touch" &&
            (kind !== "create" || !(p.requireLongPress || portraitRef.current)),
      moved: false,
      touch: e.pointerType === "touch",
    };
    gesture.current = g;
    if (g.active) {
      e.preventDefault();
      emit(g, "start");
      if (kind === "create") setPreview(selection);
    } else if (
      (entry && portraitRef.current) ||
      g.touch ||
      (kind === "create" && p.requireLongPress) ||
      !p.requireLongPress
    )
      timer.current = setTimeout(() => {
        if (gesture.current === g && !g.moved) {
          if (entry && portraitRef.current) {
            g.held = true;
            selectRef.current(entry.id);
          }
          g.active = true;
          emit(g, "start");
          if (!entry) setPreview(g.selection);
        }
      }, 500);
  }
  function create(selection: KCalendarSelection) {
    const g = { kind: "create", selection } as Gesture<T>;
    setPreview(selection);
    emit(g, "start");
    commit(g);
    if (current.current.onPendingCreateSelectionChange) setPreview(null);
  }
  function change(
    kind: "move" | "resize",
    entry: CalendarEntry<T>,
    selection: KCalendarSelection,
    edge?: "start" | "end",
  ) {
    current.current.onPendingCreateSelectionChange?.(null);
    const g = { kind, entry, selection, edge } as Gesture<T>;
    emit(g, "start");
    commit(g);
  }
  return {
    preview:
      preview ??
      (props.onPendingCreateSelectionChange
        ? (props.pendingCreateSelection ?? null)
        : null),
    previewEntryId,
    previewEntry,
    previewPoint,
    begin,
    create,
    change,
    portrait,
    selected,
  };
}

function duration(selection: KCalendarSelection) {
  const a = kCalendarSlotToDate(selection.start),
    b = kCalendarSlotToDate(selection.end);
  return a && b ? (b.getTime() - a.getTime()) / 60000 : 0;
}
