/** Normalize accessibility gaps in the pinned gallery renderer without a fork. */
export function installGanttAccessibility(
  root: HTMLElement,
  labels: {
    taskTable: string;
    chart: string;
    chartOnly: boolean;
  },
) {
  const set = (element: Element, name: string, value: string) => {
    if (element.getAttribute(name) !== value) element.setAttribute(name, value);
  };
  const sync = () => {
    const grid = root.querySelector<HTMLElement>(
      '[role="grid"], [role="treegrid"]',
    );
    if (grid) {
      set(grid, "role", "treegrid");
      set(grid, "aria-label", labels.taskTable);
      set(grid, "aria-hidden", String(labels.chartOnly));
      grid.inert = labels.chartOnly;
      grid.querySelectorAll('[role="row"][data-id]').forEach((row, index) => {
        set(row, "aria-rowindex", String(index + 2));
        if (!row.querySelector(".wx-toggle-icon"))
          row.removeAttribute("aria-expanded");
      });
    }
    const chart = root.querySelector<HTMLElement>(".wx-chart");
    if (chart) {
      set(chart, "tabindex", "0");
      set(chart, "role", "region");
      set(chart, "aria-label", labels.chart);
    }
    root.querySelectorAll<HTMLElement>(".wx-bar[data-id]").forEach((bar) => {
      const text = bar.querySelector("[data-gantt-id]")?.textContent;
      if (text) {
        set(bar, "role", "button");
        set(bar, "tabindex", "0");
        set(bar, "aria-label", text);
      }
    });
  };
  sync();
  const observer = new MutationObserver(sync);
  observer.observe(root, { childList: true, subtree: true });
  return () => observer.disconnect();
}
