import { useEffect, useMemo, useRef, useState } from "react";
import {
  Gantt,
  Willow,
  type IApi,
  type IColumnConfig,
  type ITask,
} from "@svar-ui/react-gantt";
import "@svar-ui/react-gantt/all.css";
import {
  moveGanttTask,
  localDate,
  summarizeTasks,
  type GanttTask,
  type GanttLink,
} from "./gantt-model";
import { installGanttGestures } from "./gantt-gestures";
import { installGanttAccessibility } from "./gantt-accessibility";
import "./gantt.css";

function TaskContent({ data }: { data: ITask }) {
  return (
    <>
      <span className="k-gantt-label" data-gantt-id={String(data.id)}>
        {data.text}
      </span>
      {!data.readOnly && data.type === "task" && (
        <>
          <span
            data-gantt-edge="start"
            className="k-gantt-handle k-gantt-handle--start"
          />
          <span
            data-gantt-edge="end"
            className="k-gantt-handle k-gantt-handle--end"
          />
        </>
      )}
    </>
  );
}

export function GanttCanvas(props: {
  tasks: readonly GanttTask[];
  links: readonly GanttLink[];
  start: string;
  end: string;
  scale: "days" | "weeks" | "months";
  selectedId: string | null;
  expanded: readonly string[];
  onExpandedChange(ids: string[]): void;
  onSelect(id: string): void;
  onOpen(id: string): void;
  onPropose(task: GanttTask): void;
  columns?: IColumnConfig[];
  taskColumnLabel?: string;
  timelineLabel?: string;
  displayMode?: "chart" | "all";
  locale?: string;
}) {
  const root = useRef<HTMLDivElement>(null);
  const apiRef = useRef<IApi | null>(null);
  const latest = useRef(props);
  latest.current = props;
  const [compact, setCompact] = useState(false);
  const [rowHeight, setRowHeight] = useState(44);
  const [active, setActive] = useState<string | null>(null);

  useEffect(
    () =>
      installGanttAccessibility(root.current!, {
        taskTable: props.taskColumnLabel ?? "Tasks",
        chart: props.timelineLabel ?? "Timeline",
        chartOnly: (props.displayMode ?? "chart") === "chart",
      }),
    [
      compact,
      props.displayMode,
      props.tasks,
      props.expanded,
      props.taskColumnLabel,
      props.timelineLabel,
    ],
  );
  const dayWidth =
    props.scale === "days" ? 64 : props.scale === "weeks" ? 32 : 16;
  const widthRef = useRef(dayWidth);
  widthRef.current = dayWidth;
  const compactRef = useRef(compact);
  compactRef.current = compact;
  const tasks = useMemo(
    () =>
      summarizeTasks(props.tasks).map((task) => ({
        ...task,
        start: localDate(task.start),
        end: task.end ? localDate(task.end) : undefined,
        open: props.expanded.includes(task.id),
      })),
    [props.tasks, props.expanded],
  );
  const links = useMemo(
    () => props.links.map((link) => ({ ...link })),
    [props.links],
  );
  const columns = useMemo(
    () =>
      (props.displayMode ?? "chart") === "chart"
        ? []
        : (props.columns ?? [
            {
              id: "text",
              header: props.taskColumnLabel ?? "Task",
              width: compact ? 136 : 240,
            },
          ]),
    [props.columns, props.taskColumnLabel, props.displayMode, compact],
  );

  useEffect(() => {
    apiRef.current?.exec("set-display-mode", {
      mode: props.displayMode ?? "chart",
    });
  }, [compact, props.displayMode]);
  const scales = useMemo(
    () => [
      {
        unit: "month",
        step: 1,
        format: (date: Date) =>
          new Intl.DateTimeFormat(props.locale ?? "en", {
            month: "long",
            year: "numeric",
          }).format(date),
      },
      {
        unit: "day",
        step: props.scale === "months" ? 7 : 1,
        format: (date: Date) => String(date.getDate()),
      },
    ],
    [props.scale, props.locale],
  );

  useEffect(() => {
    const element = root.current!;
    const measure = () => {
      setCompact(window.innerWidth < 600);
      const control =
        parseFloat(
          getComputedStyle(element).getPropertyValue("--k-size-control"),
        ) || 36;
      setRowHeight(control + 12);
    };
    measure();
    window.addEventListener("resize", measure);
    const observer = new MutationObserver(measure);
    let ancestor: HTMLElement | null = element;
    while (ancestor) {
      observer.observe(ancestor, {
        attributes: true,
        attributeFilter: ["class", "style", "data-density", "data-theme"],
      });
      ancestor = ancestor.parentElement;
    }
    return () => {
      window.removeEventListener("resize", measure);
      observer.disconnect();
    };
  }, []);

  useEffect(() => {
    const element = root.current!;
    let ghost: HTMLElement | null = null;
    let source: HTMLElement | null = null;
    let savedVisibility = "";
    const clear = () => {
      ghost?.remove();
      ghost = null;
      if (source) source.style.visibility = savedVisibility;
      source = null;
    };
    const findBar = (id: string) =>
      Array.from(
        element.querySelectorAll<HTMLElement>(".wx-bar[data-id]"),
      ).find(
        (bar) =>
          bar.querySelector<HTMLElement>("[data-gantt-id]")?.dataset.ganttId ===
          id,
      );
    const measuredDayWidth = () => {
      const task = latest.current.tasks.find(
        (task) => task.type === "task" && task.end && findBar(task.id),
      );
      if (!task?.end) return widthRef.current;
      return (
        parseFloat(findBar(task.id)!.style.width) /
        ((Date.parse(task.end) - Date.parse(task.start)) / 86400000)
      );
    };
    const dispose = installGanttGestures(element, {
      compact: () => compactRef.current,
      dayWidth: measuredDayWidth,
      task: (id) => latest.current.tasks.find((task) => task.id === id),
      activate: setActive,
      open: (id) => {
        latest.current.onSelect(id);
        latest.current.onOpen(id);
      },
      pan: (dx, dy) => {
        const api = apiRef.current;
        const state = api?.getState();
        if (state)
          api?.exec("scroll-chart", {
            left: Math.max(0, state.scrollLeft + dx),
            top: Math.max(0, state.scrollTop + dy),
          });
      },
      preview: (task, days, edge) => {
        if (!ghost) {
          source = findBar(task.id) ?? null;
          if (!source) return;
          savedVisibility = source.style.visibility;
          ghost = source.cloneNode(true) as HTMLElement;
          ghost.removeAttribute("data-id");
          ghost.removeAttribute("data-task-id");
          ghost.setAttribute("aria-hidden", "true");
          ghost.classList.add("k-gantt-ghost");
          source.parentElement!.appendChild(ghost);
          source.style.visibility = "hidden";
        }
        const next = moveGanttTask(task, days, edge);
        const diff = (a: string, b: string) =>
          (Date.parse(a) - Date.parse(b)) / 86400000;
        const left = parseFloat(source!.style.left);
        const width = parseFloat(source!.style.width);
        ghost.style.left = `${left + diff(next.start, task.start) * measuredDayWidth()}px`;
        ghost.style.width = `${next.end && task.end ? width + (diff(next.end, task.end) - diff(next.start, task.start)) * measuredDayWidth() : width}px`;
      },
      clear,
      commit: (task, days, edge) => {
        clear();
        latest.current.onPropose(moveGanttTask(task, days, edge));
      },
    });
    return () => {
      dispose();
      clear();
    };
  }, [props.tasks, props.start, props.end, props.scale]);

  useEffect(() => {
    const bars =
      root.current?.querySelectorAll<HTMLElement>(".wx-bar[data-id]");
    bars?.forEach((bar) =>
      bar.classList.toggle(
        "k-gantt-editing",
        bar.querySelector<HTMLElement>("[data-gantt-id]")?.dataset.ganttId ===
          active,
      ),
    );
  }, [active, tasks]);

  return (
    <div
      ref={root}
      onKeyDownCapture={(event) => {
        if (event.key !== "Enter" && event.key !== " ") return;
        const bar = (event.target as HTMLElement).closest(".wx-bar");
        const id =
          bar?.querySelector<HTMLElement>("[data-gantt-id]")?.dataset.ganttId;
        if (id) {
          event.preventDefault();
          event.stopPropagation();
          props.onOpen(id);
        }
      }}
      className={`k-gantt-canvas${compact ? " k-gantt-compact" : ""}`}
    >
      <Willow fonts={false}>
        <Gantt
          tasks={tasks}
          links={links}
          columns={columns}
          readonly
          displayMode={props.displayMode ?? "chart"}
          start={localDate(props.start)}
          end={localDate(props.end)}
          scales={scales}
          cellWidth={dayWidth}
          cellHeight={rowHeight}
          scaleHeight={28}
          gridWidth={compact ? 136 : 240}
          selected={props.selectedId ? [props.selectedId] : []}
          taskTemplate={TaskContent}
          init={(api) => {
            apiRef.current = api;
            api.intercept("show-editor", ({ id }) => {
              latest.current.onOpen(String(id));
              return false;
            });
            api.on("select-task", ({ id }) =>
              latest.current.onSelect(String(id)),
            );
            api.on("open-task", ({ id, mode }) => {
              const expanded = latest.current.expanded.filter(
                (value) => value !== String(id),
              );
              if (mode) expanded.push(String(id));
              latest.current.onExpandedChange(expanded);
            });
          }}
        />
      </Willow>
    </div>
  );
}
