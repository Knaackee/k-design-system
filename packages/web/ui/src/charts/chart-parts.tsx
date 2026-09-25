import { useEffect, useRef, useState, type ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KSurface } from "../primitives/surface.js";
import { KSpinner } from "../extended-components.js";

const chartPalette = [
  "--k-component-chart-series-primary",
  "--k-component-chart-series-secondary",
  "--k-color-status-success-accent",
  "--k-color-status-warning-accent",
  "--k-color-status-info-accent",
  "--k-color-status-error-accent",
];
export const chartColor = (index = 0) =>
  `var(${chartPalette[((Math.trunc(index) % chartPalette.length) + chartPalette.length) % chartPalette.length] ?? chartPalette[0]})`;
export function useChartSize() {
  const ref = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({
    width: 0,
    height: 0,
    lineWidth: 2,
    duration: 0,
    fillOpacity: 0.28,
  });
  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    const update = () => {
      const rect = element.getBoundingClientRect(),
        css = getComputedStyle(element);
      setSize({
        width: rect.width,
        height: rect.height,
        lineWidth:
          parseFloat(css.getPropertyValue("--k-component-chart-line-width")) ||
          2,
        duration: parseFloat(css.getPropertyValue("--k-motion-fast")) || 0,
        fillOpacity:
          parseFloat(css.getPropertyValue("--k-opacity-medium")) || 0.28,
      });
    };
    const resize = new ResizeObserver(update);
    resize.observe(element);
    const theme = new MutationObserver(update);
    theme.observe(document.documentElement, { attributes: true });
    update();
    return () => {
      resize.disconnect();
      theme.disconnect();
    };
  }, []);
  return { ref, size };
}
export function ChartLegend({
  items,
  visible,
  onChange,
  label,
}: {
  items: readonly { id: string; label: string; colorIndex?: number }[];
  visible: readonly string[];
  onChange?: (ids: string[]) => void;
  label: string;
}) {
  return (
    <div className="k-line-chart__legend" aria-label={label}>
      {items.map((item) => (
        <KButton
          key={item.id}
          variant="ghost"
          aria-pressed={visible.includes(item.id)}
          disabled={!onChange}
          onClick={() =>
            onChange?.(
              items
                .filter((i) =>
                  i.id === item.id
                    ? !visible.includes(i.id)
                    : visible.includes(i.id),
                )
                .map((i) => i.id),
            )
          }
        >
          <span
            className="k-line-chart__swatch"
            aria-hidden="true"
            style={{ background: chartColor(item.colorIndex) }}
          />
          <span className="k-line-chart__legend-label">{item.label}</span>
        </KButton>
      ))}
    </div>
  );
}
export function ChartState({
  loading,
  loadingContent,
  error,
  errorContent,
  emptyContent,
}: {
  loading?: boolean;
  loadingContent?: ReactNode;
  error?: string;
  errorContent?: ReactNode;
  emptyContent?: ReactNode;
}) {
  return (
    <div className="k-line-chart__state" role="status">
      {loading
        ? (loadingContent ?? <KSpinner />)
        : error
          ? (errorContent ?? error)
          : (emptyContent ?? "No data to display")}
    </div>
  );
}
export function ChartTooltip({
  title,
  rows,
}: {
  title: string;
  rows: readonly {
    id: string;
    label: string;
    value: string;
    colorIndex?: number;
  }[];
}) {
  return (
    <KSurface
      className="k-line-chart__tooltip"
      radius="overlay"
      elevation="overlay"
    >
      <strong>{title}</strong>
      {rows.map((r) => (
        <div key={r.id}>
          <span
            className="k-line-chart__swatch"
            style={{ background: chartColor(r.colorIndex) }}
          />
          <span>{r.label}</span>
          <b>{r.value}</b>
        </div>
      ))}
    </KSurface>
  );
}
export function keyboardIndex(key: string, index: number, length: number) {
  if (!length) return undefined;
  if (key === "Home") return 0;
  if (key === "End") return length - 1;
  if (key === "ArrowRight" || key === "ArrowDown")
    return index < 0 ? 0 : Math.min(index + 1, length - 1);
  if (key === "ArrowLeft" || key === "ArrowUp")
    return index < 0 ? length - 1 : Math.max(index - 1, 0);
  return undefined;
}
