import { useEffect, useRef } from "react";
import {
  Timeline,
  type TimelineItem as VisItem,
} from "vis-timeline/standalone";
import { localDate, dateKey, type TimelineItem } from "./timeline-model.js";
import "vis-timeline/styles/vis-timeline-graph2d.css";
import "./timeline.css";
import { installTimelineTouch } from "./timeline-touch";
import { createTimelinePreview } from "./timeline-preview";

export interface TimelineCanvasProps {
  items: readonly TimelineItem[];
  groups: readonly { id: string; label: string }[];
  selectedId: string | null;
  onSelect(id: string | null): void;
  onPropose(next: TimelineItem): void;
  onItemOpen?(id: string): void;
  window: { start: string; end: string };
  onWindowChange?(window: { start: string; end: string }): void;
  locale?: string;
  today?: string;
}

function midnight(value: Date): Date {
  return new Date(
    value.getFullYear(),
    value.getMonth(),
    value.getDate() + (value.getHours() >= 12 ? 1 : 0),
  );
}

function axisStep(
  start: string,
  end: string,
  element: HTMLElement | null,
): number {
  const calendarDay = (value: string) => {
    const date = localDate(value);
    return (
      Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86_400_000
    );
  };
  const days = Math.max(1, calendarDay(end) - calendarDay(start));
  const labelWidth =
    element?.querySelector(".vis-panel.vis-left")?.getBoundingClientRect()
      .width ||
    (globalThis.matchMedia("(max-width: 480px)").matches ? 96 : 120);
  const availableWidth = Math.max(
    28,
    (element?.clientWidth ?? 600) - labelWidth,
  );
  const requiredStep = Math.ceil(
    days / Math.max(1, Math.floor(availableWidth / 28)),
  );
  return (
    [1, 2, 3, 7, 14, 28].find((step) => step >= requiredStep) ?? requiredStep
  );
}

function label(value: string, className: string): HTMLElement {
  const node = document.createElement("span");
  node.className = className;
  node.textContent = value;
  return node;
}

function project(item: TimelineItem): VisItem {
  const content = label(item.label, "k-timeline-label");
  content.dataset.timelineId = item.id;
  const tone =
    item.tone && ["primary", "info", "success"].includes(item.tone)
      ? item.tone
      : undefined;
  return {
    id: item.id,
    group: item.group,
    content,
    start: localDate(item.start),
    ...(item.end ? { end: localDate(item.end) } : {}),
    type: item.end ? "range" : "point",
    editable: {
      updateTime: !item.readOnly,
      updateGroup: !item.readOnly,
      remove: false,
    },
    className: [
      "k-timeline-item",
      item.readOnly ? "vis-readonly" : "",
      tone ? `tone-${tone}` : "",
    ]
      .filter(Boolean)
      .join(" "),
  };
}

/** Gallery adapter: vis owns temporary previews; React owns accepted records. */
export function TimelineCanvas(props: TimelineCanvasProps) {
  const root = useRef<HTMLDivElement>(null);
  const latest = useRef(props);
  latest.current = props;
  const instance = useRef<Timeline | null>(null);
  const touch = useRef<ReturnType<typeof installTimelineTouch> | null>(null);
  const lastAxisStep = useRef<number | null>(null);

  useEffect(() => {
    if (!root.current) return;
    const element = root.current;
    let alive = true;
    let cancelled = false;
    let previewing = false;
    let redrawFrame = 0;
    let initialRangeRedrawn = false;
    let pending: TimelineItem | null = null;
    let preview: ReturnType<typeof createTimelinePreview> | null = null;

    const proposal = (candidate: VisItem): TimelineItem | null => {
      const original = latest.current.items.find(
        (item) => item.id === String(candidate.id),
      );
      if (!alive || cancelled || !original || original.readOnly) return null;
      const startDate = new Date(candidate.start);
      const endDate =
        candidate.end === undefined ? undefined : new Date(candidate.end);
      if (
        !Number.isFinite(startDate.getTime()) ||
        (endDate && !Number.isFinite(endDate.getTime()))
      )
        return null;
      const start = dateKey(startDate);
      const end = endDate ? dateKey(endDate) : undefined;
      const group = String(candidate.group);
      if (!latest.current.groups.some((entry) => entry.id === group))
        return null;
      if (original.end && (!end || end <= start)) return null;
      return { ...original, start, ...(original.end ? { end } : {}), group };
    };

    const timeline = new Timeline(element, [], [], {
      start: localDate(latest.current.window.start),
      end: localDate(latest.current.window.end),
      locale: latest.current.locale ?? "en",
      height: "100%",
      orientation: "top",
      timeAxis: {
        scale: "day",
        step: axisStep(
          latest.current.window.start,
          latest.current.window.end,
          element,
        ),
      },
      stack: true,
      selectable: true,
      multiselect: false,
      editable: {
        add: false,
        remove: false,
        updateTime: true,
        updateGroup: true,
        overrideItems: false,
      },
      groupEditable: false,
      itemsAlwaysDraggable: false,
      horizontalScroll: true,
      verticalScroll: true,
      zoomKey: "ctrlKey",
      zoomMin: 24 * 60 * 60 * 1000,
      zoomMax: 366 * 24 * 60 * 60 * 1000,
      showCurrentTime: false,
      snap: midnight,
      onMoving(candidate, callback) {
        const next = proposal(candidate);
        previewing = next !== null;
        pending = next;
        if (next) {
          const original = latest.current.items.find(
            (item) => item.id === next.id,
          )!;
          preview?.show(next, original);
        } else preview?.clear();
        // Keep vis's layout dataset unchanged throughout the gesture.
        callback(null);
      },
      onMove(candidate, callback) {
        const next =
          !cancelled && pending?.id === String(candidate.id) ? pending : null;
        pending = null;
        preview?.clear();
        previewing = false;
        // Reject the renderer's write even when the consumer accepts the proposal.
        callback(null);
        if (next && alive) latest.current.onPropose(next);
        touch.current?.finish();
      },
      onAdd(_candidate, callback) {
        callback(null);
      },
      onRemove(_candidate, callback) {
        callback(null);
      },
      onUpdate(_candidate, callback) {
        callback(null);
      },
    });
    instance.current = timeline;
    preview = createTimelinePreview(element, timeline);
    touch.current = installTimelineTouch(element, timeline, {
      selected: () => latest.current.selectedId,
      editable: (id) =>
        latest.current.items.some((item) => item.id === id && !item.readOnly),
      select: (id) => latest.current.onSelect(id),
      open: (id) => latest.current.onItemOpen?.(id),
    });
    lastAxisStep.current = axisStep(
      latest.current.window.start,
      latest.current.window.end,
      element,
    );
    const resizeObserver = new ResizeObserver(() => {
      if (!alive) return;
      const nextStep = axisStep(
        latest.current.window.start,
        latest.current.window.end,
        element,
      );
      if (nextStep !== lastAxisStep.current) {
        lastAxisStep.current = nextStep;
        timeline.setOptions({ timeAxis: { scale: "day", step: nextStep } });
      }
    });
    resizeObserver.observe(element);

    const select = (event: { items: (string | number)[] }) => {
      if (alive)
        latest.current.onSelect(
          event.items.length ? String(event.items[0]) : null,
        );
    };
    const rangeChanged = (event: {
      start: Date;
      end: Date;
      byUser: boolean;
    }) => {
      if (alive && !initialRangeRedrawn) {
        initialRangeRedrawn = true;
        // vis marks the initial range ready on this delayed event, but does
        // not redraw. Complete its first-draw visibility lifecycle explicitly.
        timeline.redraw();
      }
      const start = dateKey(event.start);
      const end = dateKey(event.end);
      if (alive && event.byUser && end > start)
        latest.current.onWindowChange?.({
          start,
          end,
        });
    };
    const begin = () => {
      cancelled = false;
    };
    const resetPreview = () => {
      if (!alive || !previewing) return;
      cancelled = true;
      previewing = false;
      pending = null;
      preview?.clear();
      timeline.setItems(latest.current.items.map(project));
      timeline.setSelection(
        latest.current.selectedId ? [latest.current.selectedId] : [],
      );
      timeline.redraw();
    };
    const cancel = (event: KeyboardEvent) => {
      if (event.key !== "Escape" || !previewing) return;
      event.preventDefault();
      resetPreview();
    };
    const observer = new MutationObserver(() => {
      cancelAnimationFrame(redrawFrame);
      redrawFrame = requestAnimationFrame(() => {
        if (alive) timeline.redraw();
      });
    });
    // Theme and density may be applied to the document or a gallery ancestor.
    for (
      let ancestor: HTMLElement | null = element;
      ancestor;
      ancestor = ancestor.parentElement
    ) {
      observer.observe(ancestor, { attributes: true });
    }
    timeline.on("select", select);
    timeline.on("rangechanged", rangeChanged);
    element.addEventListener("pointerdown", begin, true);
    element.addEventListener("pointercancel", resetPreview, true);
    document.addEventListener("keydown", cancel, true);

    return () => {
      alive = false;
      preview?.clear();
      observer.disconnect();
      resizeObserver.disconnect();
      cancelAnimationFrame(redrawFrame);
      element.removeEventListener("pointerdown", begin, true);
      element.removeEventListener("pointercancel", resetPreview, true);
      document.removeEventListener("keydown", cancel, true);
      timeline.off("select", select);
      timeline.off("rangechanged", rangeChanged);
      touch.current?.dispose();
      touch.current = null;
      timeline.destroy();
      instance.current = null;
    };
  }, []);

  useEffect(() => {
    instance.current?.setGroups(
      props.groups.map((group, order) => {
        const content = label(group.label, "k-timeline-group-label");
        content.dataset.timelineGroup = group.id;
        return {
          id: group.id,
          content,
          order,
        };
      }),
    );
  }, [props.groups]);

  useEffect(() => {
    // Replacing records also clears optional fields removed by the consumer.
    instance.current?.setItems(props.items.map(project));
    touch.current?.syncSelection();
  }, [props.items]);

  useEffect(() => {
    touch.current?.syncSelection();
  }, [props.selectedId, props.groups]);

  useEffect(() => {
    const timeline = instance.current;
    if (!timeline || !props.today) return;
    timeline.addCustomTime(localDate(props.today), "today");
    timeline.setCustomTimeTitle(props.today, "today");
    return () => {
      if (instance.current === timeline) timeline.removeCustomTime("today");
    };
  }, [props.today]);

  useEffect(() => {
    const step = axisStep(props.window.start, props.window.end, root.current);
    lastAxisStep.current = step;
    instance.current?.setOptions({
      timeAxis: {
        scale: "day",
        step,
      },
    });
    instance.current?.setWindow(
      localDate(props.window.start),
      localDate(props.window.end),
      { animation: false },
    );
  }, [props.window.start, props.window.end]);

  useEffect(() => {
    instance.current?.setOptions({ locale: props.locale ?? "en" });
  }, [props.locale]);

  return (
    <div
      ref={root}
      className="k-timeline-canvas"
      role="region"
      aria-label="Planning timeline"
    />
  );
}
