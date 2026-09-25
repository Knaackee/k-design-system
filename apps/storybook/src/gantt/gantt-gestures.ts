import type { GanttTask } from "./gantt-model";

/** SVAR owns rendering; this adapter owns temporary pointer state, never records. */
export function installGanttGestures(
  root: HTMLElement,
  options: {
    compact(): boolean;
    task(id: string): GanttTask | undefined;
    dayWidth(): number;
    preview(task: GanttTask, days: number, edge: string): void;
    clear(): void;
    commit(task: GanttTask, days: number, edge: string): void;
    open(id: string): void;
    activate(id: string | null): void;
    pan(dx: number, dy: number): void;
  },
) {
  let active: string | null = null;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let pointer: {
    id: number;
    task: GanttTask | undefined;
    x: number;
    y: number;
    lastX: number;
    lastY: number;
    edge: string;
    editing: boolean;
    moved: boolean;
    held: boolean;
    days: number;
  } | null = null;
  const finish = () => {
    clearTimeout(timer);
    if (pointer && root.hasPointerCapture(pointer.id))
      root.releasePointerCapture(pointer.id);
    pointer = null;
    options.clear();
    active = null;
    options.activate(null);
  };
  const down = (event: PointerEvent) => {
    if (event.button !== 0 || !event.isPrimary) return;
    const target = event.target as HTMLElement;
    const bar = target.closest<HTMLElement>(".wx-bar[data-id]");
    const surface = target.closest<HTMLElement>(".wx-area, .wx-scale");
    const hit = bar ?? surface;
    if (!hit || !root.contains(hit)) {
      finish();
      return;
    }
    const id =
      bar?.querySelector<HTMLElement>("[data-gantt-id]")?.dataset.ganttId;
    const task = id ? options.task(id) : undefined;
    if (bar && !task) return;
    if (!task) finish();
    clearTimeout(timer);
    const editable = task && !task.readOnly && task.type !== "summary";
    const edge =
      target.closest<HTMLElement>("[data-gantt-edge]")?.dataset.ganttEdge ??
      "move";
    pointer = {
      id: event.pointerId,
      task,
      x: event.clientX,
      y: event.clientY,
      lastX: event.clientX,
      lastY: event.clientY,
      edge,
      editing: !!editable && (!options.compact() || active === task.id),
      moved: false,
      held: false,
      days: 0,
    };
    root.setPointerCapture(event.pointerId);
    if (options.compact() && task && editable && active !== task.id) {
      timer = setTimeout(() => {
        if (!pointer || pointer.moved) return;
        active = task.id;
        pointer.editing = true;
        pointer.held = true;
        options.activate(active);
      }, 500);
    }
  };
  const move = (event: PointerEvent) => {
    if (!pointer || event.pointerId !== pointer.id) return;
    const p = pointer;
    const dx = event.clientX - p.x;
    if (Math.hypot(dx, event.clientY - p.y) > 8) {
      p.moved = true;
      clearTimeout(timer);
    }
    if (p.moved) {
      if (p.editing && p.task) {
        p.days = Math.round(dx / options.dayWidth());
        options.preview(p.task, p.days, p.edge);
      } else options.pan(p.lastX - event.clientX, p.lastY - event.clientY);
      event.preventDefault();
    }
    p.lastX = event.clientX;
    p.lastY = event.clientY;
  };
  const up = (event: PointerEvent) => {
    if (!pointer || pointer.id !== event.pointerId) return;
    const p = pointer;
    clearTimeout(timer);
    pointer = null;
    if (root.hasPointerCapture(event.pointerId))
      root.releasePointerCapture(event.pointerId);
    if (p.moved) {
      if (p.editing && p.task && p.days) options.commit(p.task, p.days, p.edge);
      finish();
    } else if (p.task && !p.held && active !== p.task.id) {
      finish();
      options.open(p.task.id);
    }
  };
  const outside = (event: PointerEvent) => {
    if (!root.contains(event.target as Node)) finish();
  };
  const key = (event: KeyboardEvent) => {
    if (event.key === "Escape") finish();
  };
  const context = (event: Event) => {
    if (pointer || active) event.preventDefault();
  };
  root.addEventListener("pointerdown", down, true);
  root.addEventListener("pointermove", move, { passive: false });
  root.addEventListener("pointerup", up);
  root.addEventListener("pointercancel", finish);
  root.addEventListener("contextmenu", context);
  document.addEventListener("pointerdown", outside, true);
  document.addEventListener("keydown", key);
  return () => {
    finish();
    root.removeEventListener("pointerdown", down, true);
    root.removeEventListener("pointermove", move);
    root.removeEventListener("pointerup", up);
    root.removeEventListener("pointercancel", finish);
    root.removeEventListener("contextmenu", context);
    document.removeEventListener("pointerdown", outside, true);
    document.removeEventListener("keydown", key);
  };
}
