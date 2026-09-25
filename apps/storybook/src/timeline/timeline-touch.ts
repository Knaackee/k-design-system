import type { Timeline } from "vis-timeline/standalone";

/** Keep mobile editing separate from ordinary selection and axis panning. */
export function installTimelineTouch(
  element: HTMLElement,
  timeline: Timeline,
  callbacks: {
    selected(): string | null;
    editable(id: string): boolean;
    select(id: string): void;
    open(id: string): void;
  },
) {
  let compact = false;
  let active: string | null = null;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let pointer: { id: number; x: number; y: number } | null = null;
  let held = false;
  let moved = false;
  const clear = () => {
    clearTimeout(timer);
    timer = undefined;
  };
  const syncSelection = () => {
    const id = compact ? active : callbacks.selected();
    timeline.setSelection(id ? [id] : []);
  };
  const finish = () => {
    clear();
    active = null;
    syncSelection();
  };
  const measure = () => {
    const next =
      window.innerWidth < 600 && window.innerWidth < window.innerHeight;
    if (next === compact) return;
    compact = next;
    active = null;
    clear();
    element.classList.toggle("k-timeline--touch", compact);
    timeline.setOptions({ selectable: !compact });
    syncSelection();
  };
  const itemAt = (event: Event) => {
    const id = timeline.getEventProperties(event).item;
    return id == null ? null : String(id);
  };
  const down = (event: PointerEvent) => {
    if (!compact) return;
    clear();
    held = false;
    moved = false;
    pointer = null;
    if (event.button !== 0 || !event.isPrimary) return;
    const id = element.contains(event.target as Node) ? itemAt(event) : null;
    if (id !== active) finish();
    if (!id) return;
    pointer = { id: event.pointerId, x: event.clientX, y: event.clientY };
    if (active === id || !callbacks.editable(id)) return;
    timer = setTimeout(() => {
      held = true;
      active = id;
      callbacks.select(id);
      syncSelection();
    }, 500);
  };
  const move = (event: PointerEvent) => {
    if (!pointer || event.pointerId !== pointer.id) return;
    if (Math.hypot(event.clientX - pointer.x, event.clientY - pointer.y) > 8) {
      moved = true;
      clear();
    }
  };
  const up = () => {
    clear();
    pointer = null;
  };
  const cancel = () => {
    up();
    held = true;
    finish();
  };
  const click = (event: MouseEvent) => {
    if (!compact) return;
    // Do not let the release after a hold (or a pan) open the details.
    if (held || moved) {
      event.preventDefault();
      return;
    }
    const id = itemAt(event);
    if (id && active !== id) callbacks.open(id);
  };
  const context = (event: Event) => {
    if (compact) event.preventDefault();
  };
  const key = (event: KeyboardEvent) => {
    if (event.key === "Escape") finish();
  };
  document.addEventListener("pointerdown", down, true);
  document.addEventListener("pointermove", move, true);
  document.addEventListener("pointerup", up, true);
  document.addEventListener("pointercancel", cancel, true);
  document.addEventListener("keydown", key);
  element.addEventListener("click", click, true);
  element.addEventListener("contextmenu", context);
  window.addEventListener("resize", measure);
  measure();
  return {
    syncSelection,
    finish,
    dispose() {
      clear();
      document.removeEventListener("pointerdown", down, true);
      document.removeEventListener("pointermove", move, true);
      document.removeEventListener("pointerup", up, true);
      document.removeEventListener("pointercancel", cancel, true);
      document.removeEventListener("keydown", key);
      element.removeEventListener("click", click, true);
      element.removeEventListener("contextmenu", context);
      window.removeEventListener("resize", measure);
      element.classList.remove("k-timeline--touch");
    },
  };
}
