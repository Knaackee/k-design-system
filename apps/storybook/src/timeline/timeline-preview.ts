import type { Timeline } from "vis-timeline/standalone";
import type { TimelineItem } from "./timeline-model";

/** Paint proposals independently so the renderer only stacks accepted data. */
export function createTimelinePreview(root: HTMLElement, timeline: Timeline) {
  let source: HTMLElement | null = null;
  let overlay: HTMLElement | null = null;
  let clone: HTMLElement | null = null;
  let sourceGroup: string | null = null;
  let sourceTop = 0;
  let oldVisibility = "";
  const clear = () => {
    if (source) source.style.visibility = oldVisibility;
    overlay?.remove();
    source = overlay = clone = null;
    sourceGroup = null;
  };
  return {
    clear,
    show(next: TimelineItem, original: TimelineItem) {
      const base = root.getBoundingClientRect();
      const plot = root.querySelector<HTMLElement>(".vis-panel.vis-center");
      if (!plot) return;
      const bounds = plot.getBoundingClientRect();
      if (!source) {
        const content = [
          ...root.querySelectorAll<HTMLElement>("[data-timeline-id]"),
        ].find((node) => node.dataset.timelineId === next.id);
        source = content?.closest<HTMLElement>(".vis-item") ?? null;
        if (!source) return;
        sourceTop = source.getBoundingClientRect().top - base.top;
        sourceGroup = original.group;
        oldVisibility = source.style.visibility;
        clone = source.cloneNode(true) as HTMLElement;
        clone
          .querySelectorAll("[data-timeline-id]")
          .forEach((node) => node.removeAttribute("data-timeline-id"));
        overlay = document.createElement("div");
        overlay.className = "k-timeline-proposal";
        overlay.setAttribute("aria-hidden", "true");
        overlay.appendChild(clone);
        root.appendChild(overlay);
        source.style.visibility = "hidden";
      }
      if (!clone || !overlay) return;
      const range = timeline.getWindow();
      const x = (date: string) =>
        bounds.left -
        base.left +
        ((new Date(`${date}T00:00:00`).getTime() - range.start.getTime()) /
          (range.end.getTime() - range.start.getTime())) *
          bounds.width;
      const group = [
        ...root.querySelectorAll<HTMLElement>("[data-timeline-group]"),
      ]
        .find((node) => node.dataset.timelineGroup === next.group)
        ?.closest(".vis-label");
      const top =
        next.group === sourceGroup
          ? sourceTop
          : (group?.getBoundingClientRect().top ?? bounds.top) - base.top + 5;
      overlay.style.clipPath = `inset(${bounds.top - base.top}px 0 0 ${bounds.left - base.left}px)`;
      Object.assign(clone.style, {
        left: `${x(next.start)}px`,
        top: `${top}px`,
        bottom: "auto",
        width: `${next.end ? Math.max(1, x(next.end) - x(next.start)) : source.getBoundingClientRect().width}px`,
        visibility: "visible",
        opacity: "0.7",
        transform: "none",
      });
    },
  };
}
