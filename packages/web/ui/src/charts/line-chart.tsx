import {
  useEffect,
  useId,
  useRef,
  useState,
  type ReactNode,
  type CSSProperties,
} from "react";
import { Chart } from "@tanstack/charts/react";
import { lineY } from "@tanstack/charts/line";
import { scaleLinear } from "@tanstack/charts/scales/linear";
import { focusDisabled } from "@tanstack/charts/focus/disabled";
import { KButton } from "../primitives/button.js";
import { KSurface } from "../primitives/surface.js";
import { KSpinner } from "../extended-components.js";
import {
  chartCandidates,
  chartPoint,
  chartRatio,
  validChartAxis,
  type KChartAxis,
  type KChartSeries,
  type KChartSelection,
} from "./chart-model.js";

export interface KLineChartProps {
  series: readonly KChartSeries[];
  xAxis: KChartAxis;
  yAxis: KChartAxis;
  label: string;
  description?: string;
  selectedPoint?: KChartSelection | null;
  onSelectionChange?: (point: KChartSelection | null) => void;
  visibleSeriesIds?: readonly string[];
  onVisibleSeriesChange?: (ids: string[]) => void;
  height?: number;
  showDataTable?: boolean;
  dataTableLabel?: string;
  dataTableXAxisLabel?: string;
  emptyContent?: ReactNode;
  loading?: boolean;
  loadingContent?: ReactNode;
  errorContent?: ReactNode;
  error?: string;
}

/** Controlled chart: the consumer owns selection, visibility, formatting and data. */
export function KLineChart({
  series,
  xAxis,
  yAxis,
  label,
  description,
  selectedPoint = null,
  onSelectionChange,
  visibleSeriesIds,
  onVisibleSeriesChange,
  height,
  showDataTable = false,
  dataTableLabel = "Data table",
  dataTableXAxisLabel = "Date",
  emptyContent = "No data to display",
  loading = false,
  loadingContent,
  errorContent,
  error,
}: KLineChartProps) {
  const root = useRef<HTMLDivElement>(null);
  const plot = useRef<HTMLDivElement>(null);
  const [hover, setHover] = useState<KChartSelection | null>(null);
  const [size, setSize] = useState({
    width: 0,
    height: 0,
    lineWidth: 2,
    duration: 0,
  });
  const id = useId();
  const visible = series.filter(
    (s) => visibleSeriesIds === undefined || visibleSeriesIds.includes(s.id),
  );
  const candidates = chartCandidates(visible, xAxis, yAxis);
  const validSelection = (value: KChartSelection | null) =>
    candidates.some(
      (p) => p.seriesId === value?.seriesId && p.pointId === value?.pointId,
    )
      ? chartPoint(visible, value)
      : undefined;
  const selected = validSelection(selectedPoint);
  const active = validSelection(hover) ?? selected;
  const ready =
    validChartAxis(xAxis) && validChartAxis(yAxis) && candidates.length > 0;
  const color = (s: KChartSeries) =>
    `var(--k-component-chart-series-${(s.colorIndex ?? 0) % 2 === 0 ? "primary" : "secondary"})`;
  useEffect(() => {
    if (!plot.current) return;
    const element = plot.current;
    const update = () => {
      const bounds = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      setSize({
        width: bounds.width,
        height: bounds.height,
        duration: parseFloat(style.getPropertyValue("--k-motion-fast")) || 0,
        lineWidth:
          parseFloat(
            style.getPropertyValue("--k-component-chart-line-width"),
          ) || 2,
      });
    };
    const observer = new ResizeObserver(update);
    observer.observe(element);
    update();
    const themeObserver = new MutationObserver(update);
    themeObserver.observe(document.documentElement, { attributes: true });
    return () => {
      observer.disconnect();
      themeObserver.disconnect();
    };
  }, [height, ready, loading, errorContent, error]);
  useEffect(() => {
    const outside = (event: PointerEvent) => {
      if (selectedPoint && !root.current?.contains(event.target as Node))
        onSelectionChange?.(null);
    };
    document.addEventListener("pointerdown", outside);
    return () => document.removeEventListener("pointerdown", outside);
  }, [selectedPoint, onSelectionChange]);
  const choose = (clientX: number, clientY: number) => {
    if (!plot.current || !candidates.length) return null;
    const bounds = plot.current.getBoundingClientRect();
    const distance = (p: (typeof candidates)[number]) =>
      Math.hypot(
        bounds.left + chartRatio(p.x, xAxis) * bounds.width - clientX,
        bounds.top + (1 - chartRatio(p.y, yAxis)) * bounds.height - clientY,
      );
    const nearest = candidates.reduce((a, b) =>
      distance(a) <= distance(b) ? a : b,
    );
    return { seriesId: nearest.seriesId, pointId: nearest.pointId };
  };
  const commit = (value: KChartSelection | null) => {
    setHover(null);
    if (
      value?.seriesId !== selectedPoint?.seriesId ||
      value?.pointId !== selectedPoint?.pointId
    )
      onSelectionChange?.(value);
  };
  const rows = [
    ...new Set(series.flatMap((s) => s.points.map((p) => p.x))),
  ].sort((a, b) => a - b);
  const activeValues = active
    ? visible.flatMap((s) => {
        const p = s.points.find(
          (p) =>
            p.x === active.x &&
            p.y !== null &&
            Number.isFinite(p.y) &&
            p.y >= yAxis.min &&
            p.y <= yAxis.max,
        );
        return p ? [{ s, p }] : [];
      })
    : [];
  return (
    <div ref={root} className="k-line-chart">
      <div className="k-line-chart__legend" aria-label={label}>
        {series.map((s) => (
          <KButton
            key={s.id}
            variant="ghost"
            aria-pressed={visible.includes(s)}
            disabled={!onVisibleSeriesChange}
            onClick={() =>
              onVisibleSeriesChange?.(
                series
                  .filter((item) =>
                    item.id === s.id
                      ? !visible.includes(item)
                      : visible.includes(item),
                  )
                  .map((item) => item.id),
              )
            }
          >
            <span
              className="k-line-chart__swatch"
              style={{ background: color(s) }}
              aria-hidden="true"
            />
            <span className="k-line-chart__legend-label">{s.label}</span>
          </KButton>
        ))}
      </div>
      <div
        className="k-line-chart__canvas"
        style={height ? { height } : undefined}
      >
        {loading || error || !ready ? (
          <div className="k-line-chart__state" role="status">
            {loading
              ? (loadingContent ?? <KSpinner />)
              : error
                ? (errorContent ?? error)
                : emptyContent}
          </div>
        ) : (
          <>
            {yAxis.ticks
              .filter((v) => v >= yAxis.min && v <= yAxis.max)
              .map((v) => (
                <div
                  key={v}
                  className="k-line-chart__y"
                  style={
                    {
                      "--chart-position": 1 - chartRatio(v, yAxis),
                    } as CSSProperties
                  }
                >
                  <span>{yAxis.format(v)}</span>
                  <i />
                </div>
              ))}
            <div className="k-line-chart__plot" ref={plot}>
              <div className="k-line-chart__renderer" aria-hidden="true">
                {size.width > 0 && (
                  <Chart
                    ariaLabel={label}
                    tabIndex={-1}
                    width={size.width}
                    height={size.height}
                    definition={{
                      margin: 0,
                      guides: false,
                      pointer: false,
                      keyboard: false,
                      tooltip: false,
                      svgAnimation: {
                        duration: size.duration,
                        easing: "linear",
                        respectReducedMotion: true,
                      },
                      focus: focusDisabled,
                      theme: { focusRing: false },
                      scales: {
                        x: {
                          scale: scaleLinear().domain([xAxis.min, xAxis.max]),
                          nice: false,
                          axis: false,
                        },
                        y: {
                          scale: scaleLinear().domain([yAxis.min, yAxis.max]),
                          nice: false,
                          axis: false,
                        },
                      },
                      marks: visible.map((s) =>
                        lineY(
                          s.points
                            .filter((p) => Number.isFinite(p.x))
                            .map((p) => ({
                              ...p,
                              y:
                                p.y !== null && Number.isFinite(p.y)
                                  ? p.y
                                  : null,
                            }))
                            .sort((a, b) => a.x - b.x),
                          {
                            id: s.id,
                            x: "x",
                            y: "y",
                            key: "id",
                            stroke: () => color(s),
                            strokeWidth: size.lineWidth,
                            points: false,
                          },
                        ),
                      ),
                    }}
                  />
                )}
              </div>
              {active && (
                <div
                  className="k-line-chart__crosshair"
                  style={{ left: `${chartRatio(active.x, xAxis) * 100}%` }}
                />
              )}
              {activeValues.map(({ s, p }) => (
                <span
                  key={s.id}
                  aria-hidden="true"
                  className="k-line-chart__marker"
                  style={{
                    left: `${chartRatio(p.x, xAxis) * 100}%`,
                    top: `${(1 - chartRatio(p.y!, yAxis)) * 100}%`,
                    background: color(s),
                  }}
                />
              ))}
              <div
                className="k-line-chart__interaction"
                tabIndex={0}
                role="group"
                aria-label={label}
                aria-describedby={description ? `${id}-description` : undefined}
                onPointerMove={(event) => {
                  if (event.pointerType === "mouse")
                    setHover(choose(event.clientX, event.clientY));
                }}
                onPointerLeave={() => setHover(null)}
                onClick={(event) =>
                  commit(choose(event.clientX, event.clientY))
                }
                onKeyDown={(event) => {
                  if (event.key === "Escape") {
                    event.preventDefault();
                    commit(null);
                    return;
                  }
                  const keyboardPoints = candidates.filter(
                    (p) =>
                      p.seriesId ===
                      (selected
                        ? selectedPoint?.seriesId
                        : visible.find((s) =>
                            candidates.some((p) => p.seriesId === s.id),
                          )?.id),
                  );
                  if (!keyboardPoints.length) return;
                  const index = keyboardPoints.findIndex(
                    (p) => p.pointId === selectedPoint?.pointId,
                  );
                  let next: number | undefined;
                  if (event.key === "ArrowRight")
                    next =
                      index < 0
                        ? 0
                        : Math.min(index + 1, keyboardPoints.length - 1);
                  if (event.key === "ArrowLeft")
                    next =
                      index < 0
                        ? keyboardPoints.length - 1
                        : Math.max(0, index - 1);
                  if (event.key === "Home") next = 0;
                  if (event.key === "End") next = keyboardPoints.length - 1;
                  if (next !== undefined) {
                    event.preventDefault();
                    const p = keyboardPoints[next];
                    commit({ seriesId: p.seriesId, pointId: p.pointId });
                  }
                }}
              />
            </div>
            <div className="k-line-chart__x">
              {xAxis.ticks
                .filter((v) => v >= xAxis.min && v <= xAxis.max)
                .map((v, i, array) => (
                  <span
                    key={v}
                    style={{
                      left: `${chartRatio(v, xAxis) * 100}%`,
                      transform:
                        i === 0
                          ? "none"
                          : i === array.length - 1
                            ? "translateX(-100%)"
                            : "translateX(-50%)",
                    }}
                  >
                    {xAxis.format(v)}
                  </span>
                ))}
            </div>
            {active && (
              <KSurface
                className="k-line-chart__tooltip"
                radius="overlay"
                elevation="overlay"
              >
                <strong>{xAxis.format(active.x)}</strong>
                {activeValues.map(({ s, p }) => (
                  <div key={s.id}>
                    <span
                      className="k-line-chart__swatch"
                      style={{ background: color(s) }}
                    />
                    <span>{s.label}</span>
                    <b>{yAxis.format(p.y!)}</b>
                  </div>
                ))}
              </KSurface>
            )}
          </>
        )}
      </div>
      {description && (
        <span id={`${id}-description`} className="k-line-chart__sr">
          {description}
        </span>
      )}
      <span className="k-line-chart__sr" aria-live="polite">
        {selected
          ? `${xAxis.format(selected.x)}. ${visible
              .flatMap((s) => {
                const p = s.points.find(
                  (p) => p.x === selected.x && p.y !== null,
                );
                return p ? [`${s.label}: ${yAxis.format(p.y!)}`] : [];
              })
              .join(". ")}`
          : ""}
      </span>
      {showDataTable && (
        <div className="k-line-chart__table">
          <table>
            <caption>{dataTableLabel}</caption>
            <thead>
              <tr>
                <th scope="col">{dataTableXAxisLabel}</th>
                {series.map((s) => (
                  <th key={s.id} scope="col">
                    {s.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((x) => (
                <tr key={x}>
                  <th scope="row">{xAxis.format(x)}</th>
                  {series.map((s) => (
                    <td key={s.id}>
                      {s.points.find((p) => p.x === x)?.y == null
                        ? "—"
                        : yAxis.format(s.points.find((p) => p.x === x)!.y!)}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
