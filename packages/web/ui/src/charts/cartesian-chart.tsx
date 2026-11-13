import { useEffect, useId, useRef, useState, type CSSProperties } from "react";
import { Chart } from "@tanstack/charts/react";
import { rect } from "@tanstack/charts/rect";
import { lineY } from "@tanstack/charts/line";
import { areaY } from "@tanstack/charts/area";
import { scaleLinear } from "@tanstack/charts/scales/linear";
import { focusDisabled } from "@tanstack/charts/focus/disabled";
import type { KLineChartProps } from "./line-chart.js";
import {
  chartRatio,
  validChartAxis,
  type KChartSelection,
} from "./chart-model.js";
import { chartBands, chartCategorySpan } from "./chart-family-model.js";
import {
  ChartLegend,
  ChartState,
  ChartTooltip,
  chartColor,
  keyboardIndex,
  useChartSize,
} from "./chart-parts.js";

export interface KBarChartProps extends KLineChartProps {
  compact?: boolean;
  orientation?: "vertical" | "horizontal";
  stacked?: boolean;
}
export interface KAreaChartProps extends KLineChartProps {
  stacked?: boolean;
}
export function KBarChart(props: KBarChartProps) {
  return <CartesianChart {...props} kind="bar" />;
}
export function KAreaChart(props: KAreaChartProps) {
  return <CartesianChart {...props} kind="area" />;
}
function CartesianChart({
  kind,
  orientation = "vertical",
  stacked = false,
  compact = false,
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
  ...state
}: KBarChartProps & { kind: "bar" | "area" }) {
  const root = useRef<HTMLDivElement>(null),
    id = useId();
  const { ref: plot, size } = useChartSize();
  const [hover, setHover] = useState<KChartSelection | null>(null);
  const visible = series.filter(
    (s) => visibleSeriesIds === undefined || visibleSeriesIds.includes(s.id),
  );
  const bands = chartBands(visible, stacked),
    span = chartCategorySpan(visible, xAxis.max - xAxis.min);
  const horizontal = kind === "bar" && orientation === "horizontal";
  const candidates = bands.flatMap((b, si) =>
    b.points
      .filter(
        (p) =>
          p.from !== null &&
          p.to !== null &&
          p.x >= xAxis.min &&
          p.x <= xAxis.max,
      )
      .map((p) => {
        const width = stacked ? span : span / Math.max(1, visible.length),
          start = p.x - span / 2 + (stacked ? 0 : si * width);
        return {
          seriesId: b.series.id,
          pointId: p.id,
          x: p.x,
          y: p.y!,
          from: p.from!,
          to: p.to!,
          start,
          end: start + width,
        };
      }),
  );
  const ready =
    validChartAxis(xAxis) && validChartAxis(yAxis) && candidates.length > 0;
  const selected = candidates.find(
    (p) =>
      p.seriesId === selectedPoint?.seriesId &&
      p.pointId === selectedPoint?.pointId,
  );
  const active =
    candidates.find(
      (p) => p.seriesId === hover?.seriesId && p.pointId === hover?.pointId,
    ) ?? selected;
  const commit = (selection: KChartSelection | null) => {
    setHover(null);
    if (
      selection?.seriesId !== selectedPoint?.seriesId ||
      selection?.pointId !== selectedPoint?.pointId
    )
      onSelectionChange?.(selection);
  };
  useEffect(() => {
    const outside = (e: PointerEvent) => {
      if (selectedPoint && !root.current?.contains(e.target as Node))
        onSelectionChange?.(null);
    };
    document.addEventListener("pointerdown", outside);
    return () => document.removeEventListener("pointerdown", outside);
  }, [selectedPoint, onSelectionChange]);
  const choose = (clientX: number, clientY: number) => {
    if (!plot.current || !ready) return null;
    const bounds = plot.current.getBoundingClientRect(),
      rx = (clientX - bounds.left) / bounds.width,
      ry = (clientY - bounds.top) / bounds.height;
    const category =
        xAxis.min + (horizontal ? ry : rx) * (xAxis.max - xAxis.min),
      value = yAxis.min + (horizontal ? rx : 1 - ry) * (yAxis.max - yAxis.min);
    const distance = (p: (typeof candidates)[number]) =>
      Math.hypot(
        (chartRatio(p.x, xAxis) - rx) * bounds.width,
        (1 - chartRatio(p.to, yAxis) - ry) * bounds.height,
      );
    const nearest =
      kind === "bar"
        ? candidates.find(
            (p) =>
              category >= p.start &&
              category <= p.end &&
              value >= Math.min(p.from, p.to) &&
              value <= Math.max(p.from, p.to),
          )
        : candidates.reduce((a, b) => (distance(a) <= distance(b) ? a : b));
    return nearest
      ? { seriesId: nearest.seriesId, pointId: nearest.pointId }
      : null;
  };
  const categoryAxis = horizontal
    ? { ...xAxis, min: -xAxis.max, max: -xAxis.min }
    : xAxis;
  const renderX = horizontal ? yAxis : xAxis,
    renderY = horizontal ? categoryAxis : yAxis;
  const marks =
    kind === "area"
      ? bands.flatMap((b) => [
          areaY(b.points, {
            id: b.series.id,
            x: "x",
            y1: "from",
            y2: "to",
            key: "id",
            fill: () => chartColor(b.series.colorIndex),
            fillOpacity: size.fillOpacity,
            strokeWidth: 0,
          }),
          lineY(b.points, {
            id: `${b.series.id}-line`,
            x: "x",
            y: "to",
            key: "id",
            stroke: () => chartColor(b.series.colorIndex),
            strokeWidth: size.lineWidth,
            points: false,
          }),
        ])
      : bands.map((b) =>
          rect(
            candidates
              .filter((p) => p.seriesId === b.series.id)
              .map((p) =>
                horizontal
                  ? {
                      ...p,
                      left: Math.min(p.from, p.to),
                      right: Math.max(p.from, p.to),
                      bottom: -p.end,
                      top: -p.start,
                    }
                  : {
                      ...p,
                      left: p.start,
                      right: p.end,
                      bottom: Math.min(p.from, p.to),
                      top: Math.max(p.from, p.to),
                    },
              ),
            {
              id: b.series.id,
              x1: "left",
              x2: "right",
              y1: "bottom",
              y2: "top",
              key: "pointId",
              fill: chartColor(b.series.colorIndex),
              inset: 0,
            },
          ),
        );
  const rows = [
    ...new Set(
      series.flatMap((s) =>
        s.points.filter((p) => Number.isFinite(p.x)).map((p) => p.x),
      ),
    ),
  ].sort((a, b) => a - b);
  return (
    <div
      ref={root}
      className="k-line-chart k-cartesian-chart"
      data-compact={compact || undefined}
      data-axis-free={
        (compact && xAxis.ticks.length === 0 && yAxis.ticks.length === 0) ||
        undefined
      }
    >
      {(!compact || series.length !== 1 || onVisibleSeriesChange) && (
        <ChartLegend
          items={series}
          visible={visible.map((s) => s.id)}
          onChange={onVisibleSeriesChange}
          label={label}
        />
      )}
      <div
        className="k-line-chart__canvas"
        style={height ? { height } : undefined}
      >
        {(!ready || state.loading || state.error) && <ChartState {...state} />}
        <div
          className="k-line-chart__plot"
          ref={plot}
          style={
            !ready || state.loading || state.error
              ? { visibility: "hidden" }
              : undefined
          }
        >
          {yAxis.ticks
            .filter((v) => v >= yAxis.min && v <= yAxis.max)
            .map((v) => (
              <i
                key={v}
                aria-hidden="true"
                style={
                  horizontal
                    ? {
                        position: "absolute",
                        left: `${chartRatio(v, yAxis) * 100}%`,
                        top: 0,
                        bottom: 0,
                        borderLeft:
                          "var(--k-border-width-default) solid var(--k-component-chart-grid-color)",
                      }
                    : {
                        position: "absolute",
                        top: `${(1 - chartRatio(v, yAxis)) * 100}%`,
                        left: 0,
                        right: 0,
                        borderTop:
                          "var(--k-border-width-default) solid var(--k-component-chart-grid-color)",
                      }
                }
              />
            ))}
          <div className="k-line-chart__renderer" aria-hidden="true">
            {ready && size.width > 0 && (
              <Chart
                tabIndex={-1}
                ariaLabel={label}
                width={size.width}
                height={size.height}
                definition={{
                  margin: 0,
                  guides: false,
                  pointer: false,
                  keyboard: false,
                  tooltip: false,
                  focus: focusDisabled,
                  theme: { focusRing: false },
                  svgAnimation: {
                    duration: size.duration,
                    easing: "linear",
                    respectReducedMotion: true,
                  },
                  scales: {
                    x: {
                      scale: scaleLinear().domain([renderX.min, renderX.max]),
                      nice: false,
                      axis: false,
                    },
                    y: {
                      scale: scaleLinear().domain([renderY.min, renderY.max]),
                      nice: false,
                      axis: false,
                    },
                  },
                  marks,
                }}
              />
            )}
          </div>
          {active && (
            <div
              className="k-line-chart__crosshair"
              style={
                horizontal
                  ? {
                      top: `${chartRatio(active.x, xAxis) * 100}%`,
                      left: 0,
                      right: 0,
                      bottom: "auto",
                      borderLeft: 0,
                      borderTop:
                        "var(--k-border-width-default) solid var(--k-color-border-strong)",
                    }
                  : { left: `${chartRatio(active.x, xAxis) * 100}%` }
              }
            />
          )}
          <div
            className="k-line-chart__interaction"
            tabIndex={ready && !state.loading && !state.error ? 0 : -1}
            role="group"
            aria-label={label}
            aria-describedby={description ? `${id}-description` : undefined}
            onPointerMove={(e) => {
              if (e.pointerType === "mouse")
                setHover(choose(e.clientX, e.clientY));
            }}
            onPointerLeave={() => setHover(null)}
            onClick={(e) => commit(choose(e.clientX, e.clientY))}
            onKeyDown={(e) => {
              if (e.key === "Escape") {
                e.preventDefault();
                commit(null);
                return;
              }
              if (e.key === "ArrowUp" || e.key === "ArrowDown") return;
              const keyboardPoints = candidates.filter(
                (p) =>
                  p.seriesId ===
                  (selected?.seriesId ?? candidates[0]?.seriesId),
              );
              const next = keyboardIndex(
                e.key,
                keyboardPoints.findIndex(
                  (p) => p.pointId === selectedPoint?.pointId,
                ),
                keyboardPoints.length,
              );
              if (next !== undefined) {
                e.preventDefault();
                const p = keyboardPoints[next];
                commit({ seriesId: p.seriesId, pointId: p.pointId });
              }
            }}
          />
        </div>
        {ready && !state.loading && !state.error && (
          <>
            {(horizontal ? xAxis : yAxis).ticks
              .filter(
                (v) =>
                  v >= (horizontal ? xAxis : yAxis).min &&
                  v <= (horizontal ? xAxis : yAxis).max,
              )
              .map((v) => (
                <div
                  key={v}
                  className="k-line-chart__y"
                  style={
                    {
                      "--chart-position": horizontal
                        ? chartRatio(v, xAxis)
                        : 1 - chartRatio(v, yAxis),
                    } as CSSProperties
                  }
                >
                  <span>{(horizontal ? xAxis : yAxis).format(v)}</span>
                </div>
              ))}
            <div className="k-line-chart__x">
              {(horizontal ? yAxis : xAxis).ticks
                .filter((v) => v >= renderX.min && v <= renderX.max)
                .map((v) => (
                  <span
                    key={v}
                    style={{
                      left: `${chartRatio(v, renderX) * 100}%`,
                      transform:
                        v === renderX.min
                          ? "none"
                          : v === renderX.max
                            ? "translateX(-100%)"
                            : "translateX(-50%)",
                    }}
                  >
                    {renderX.format(v)}
                  </span>
                ))}
            </div>
            {active && (
              <ChartTooltip
                title={xAxis.format(active.x)}
                rows={visible.flatMap((s) => {
                  const p = s.points.find(
                    (p) =>
                      p.x === active.x && p.y !== null && Number.isFinite(p.y),
                  );
                  return p
                    ? [
                        {
                          id: s.id,
                          label: s.label,
                          value: yAxis.format(p.y!),
                          colorIndex: s.colorIndex,
                        },
                      ]
                    : [];
                })}
              />
            )}
          </>
        )}
      </div>
      {description && (
        <span className="k-line-chart__sr" id={`${id}-description`}>
          {description}
        </span>
      )}
      <span className="k-line-chart__sr" aria-live="polite">
        {selected
          ? `${xAxis.format(selected.x)}. ${series.find((s) => s.id === selected.seriesId)?.label}: ${yAxis.format(selected.y)}`
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
                  {series.map((s) => {
                    const y = s.points.find((p) => p.x === x)?.y;
                    return (
                      <td key={s.id}>
                        {y == null || !Number.isFinite(y)
                          ? "—"
                          : yAxis.format(y)}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
