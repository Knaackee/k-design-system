export interface GanttTask {
  id: string;
  text: string;
  parent?: string;
  start: string;
  /** Exclusive calendar-date boundary; milestones have no end. */
  end?: string;
  type: "task" | "summary" | "milestone";
  /** Percentage, from 0 through 100. */
  progress: number;
  readOnly?: boolean;
}

export interface GanttLink {
  id: string;
  source: string;
  target: string;
  type: "e2s" | "s2s" | "e2e" | "s2e";
}

export function localDate(value: string): Date {
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(0);
  date.setFullYear(year!, month! - 1, day!);
  date.setHours(0, 0, 0, 0);
  return date;
}

export function dateKey(value: Date): string {
  return `${String(value.getFullYear()).padStart(4, "0")}-${String(value.getMonth() + 1).padStart(2, "0")}-${String(value.getDate()).padStart(2, "0")}`;
}

export function addDays(value: string, days: number): string {
  const date = localDate(value);
  date.setDate(date.getDate() + days);
  return dateKey(date);
}

export function isDateKey(value: string): boolean {
  return (
    /^\d{4}-\d{2}-\d{2}$/.test(value) && dateKey(localDate(value)) === value
  );
}

/** Build a snapped preview; range edges cannot cross or become zero-length. */
export function moveGanttTask(
  task: GanttTask,
  days: number,
  edge: string,
): GanttTask {
  let start = edge === "end" ? task.start : addDays(task.start, days);
  let end = task.end && (edge === "start" ? task.end : addDays(task.end, days));
  if (end && start >= end) {
    if (edge === "start") start = addDays(end, -1);
    else end = addDays(start, 1);
  }
  return { ...task, start, ...(end ? { end } : {}) };
}

/** Validate editable values against canonical identity and task kind. */
export function validateGanttProposal(
  tasks: readonly GanttTask[],
  proposed: GanttTask,
): boolean {
  const current = tasks.find((task) => task.id === proposed.id);
  if (
    !current ||
    current.readOnly ||
    current.type === "summary" ||
    !isDateKey(proposed.start) ||
    !Number.isFinite(proposed.progress) ||
    proposed.progress < 0 ||
    proposed.progress > 100
  )
    return false;
  return current.type === "milestone"
    ? proposed.end === undefined
    : proposed.end !== undefined &&
        isDateKey(proposed.end) &&
        proposed.end > proposed.start;
}

/** Consumer decides acceptance; rejection preserves the exact canonical array. */
export function applyGanttProposal(
  tasks: readonly GanttTask[],
  proposed: GanttTask,
  accept = true,
): readonly GanttTask[] {
  if (!accept || !validateGanttProposal(tasks, proposed)) return tasks;
  return tasks.map((task) =>
    task.id === proposed.id
      ? {
          ...task,
          start: proposed.start,
          end: proposed.end,
          progress: proposed.progress,
        }
      : task,
  );
}

function duration(task: GanttTask): number {
  if (!task.end) return 0;
  const utc = (value: string) => {
    const date = localDate(value);
    return Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
  };
  return (utc(task.end) - utc(task.start)) / 86_400_000;
}

/** Derive summaries without writing into consumer records or scheduling tasks. */
export function summarizeTasks(
  tasks: readonly GanttTask[],
): readonly GanttTask[] {
  const descendants = (
    parent: string,
    visited = new Set<string>(),
  ): GanttTask[] => {
    if (visited.has(parent)) return [];
    const nextVisited = new Set(visited).add(parent);
    return tasks
      .filter((task) => task.parent === parent)
      .flatMap((task) =>
        task.type === "summary" ? descendants(task.id, nextVisited) : [task],
      );
  };
  return tasks.map((task) => {
    if (task.type !== "summary") return task;
    const children = descendants(task.id);
    if (children.length === 0) return task;
    const start = children.reduce(
      (value, child) => (child.start < value ? child.start : value),
      children[0]!.start,
    );
    const end = children.reduce((value, child) => {
      const boundary = child.end ?? addDays(child.start, 1);
      return boundary > value ? boundary : value;
    }, start);
    const total = children.reduce((value, child) => value + duration(child), 0);
    const progress =
      total > 0
        ? Math.round(
            children.reduce(
              (value, child) => value + duration(child) * child.progress,
              0,
            ) / total,
          )
        : Math.round(
            children.reduce((value, child) => value + child.progress, 0) /
              children.length,
          );
    return { ...task, start, end, progress };
  });
}
