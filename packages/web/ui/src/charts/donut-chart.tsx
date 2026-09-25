import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { Chart } from "@tanstack/charts/react";
import { polar, pie, radialArc } from "@tanstack/charts/polar";
import { focusDisabled } from "@tanstack/charts/focus/disabled";
import { validSegments, type KChartSegment } from "./chart-family-model.js";
import {
  ChartLegend,
  ChartState,
  ChartTooltip,
  chartColor,
  keyboardIndex,
  useChartSize,
} from "./chart-parts.js";
export interface KDonutChartProps {
  segments: readonly KChartSegment[];
  label: string;
  description?: string;
  selectedId?: string | null;
  onSelectionChange?: (id: string | null) => void;
  visibleSegmentIds?: readonly string[];
  onVisibleSegmentsChange?: (ids: string[]) => void;
  formatValue?: (value: number) => string;
  innerRadiusRatio?: number;
  centerContent?: ReactNode;
  height?: number;
  loading?: boolean;
  loadingContent?: ReactNode;
  error?: string;
  errorContent?: ReactNode;
  emptyContent?: ReactNode;
}
export function KDonutChart({
  segments,
  label,
  description,
  selectedId = null,
  onSelectionChange,
  visibleSegmentIds,
  onVisibleSegmentsChange,
  formatValue = String,
  innerRadiusRatio = 0.65,
  centerContent,
  height,
  ...state
}: KDonutChartProps) {
  const root = useRef<HTMLDivElement>(null),
    id = useId(),
    { ref: plot, size } = useChartSize();
  const [hover, setHover] = useState<string | null>(null);
  const visible = segments.filter(
    (s) => visibleSegmentIds === undefined || visibleSegmentIds.includes(s.id),
  );
  const data = pie(validSegments(visible), { value: "value" });
  const ratio = Number.isFinite(innerRadiusRatio)
    ? Math.max(0, Math.min(0.95, innerRadiusRatio))
    : 0.65;
  const radius = Math.min(size.width, size.height) / 2;
  const selected = data.find((s) => s.id === selectedId);
  const active = data.find((s) => s.id === hover) ?? selected;
  const ready = data.length > 0;
  const commit = (value: string | null) => {
    setHover(null);
    if (value !== selectedId) onSelectionChange?.(value);
  };
  useEffect(() => {
    const outside = (e: PointerEvent) => {
      if (selectedId && !root.current?.contains(e.target as Node))
        onSelectionChange?.(null);
    };
    document.addEventListener("pointerdown", outside);
    return () => document.removeEventListener("pointerdown", outside);
  }, [selectedId, onSelectionChange]);
  const choose = (x: number, y: number) => {
    if (!plot.current) return null;
    const b = plot.current.getBoundingClientRect(),
      dx = x - b.left - b.width / 2,
      dy = y - b.top - b.height / 2,
      distance = Math.hypot(dx, dy);
    if (distance < radius * ratio || distance > radius) return null;
    const angle = (Math.atan2(dx, -dy) + 2 * Math.PI) % (2 * Math.PI);
    return (
      data.find((s) => angle >= s.startAngle && angle < s.endAngle)?.id ?? null
    );
  };
  return (
    <div ref={root} className="k-line-chart k-donut-chart">
      <ChartLegend
        items={segments}
        visible={visible.map((s) => s.id)}
        onChange={onVisibleSegmentsChange}
        label={label}
      />
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
          <div className="k-line-chart__renderer" aria-hidden="true">
            {size.width > 0 && ready && (
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
                  scales: { x: null, y: null },
                  marks: [
                    polar({
                      scales: { angle: null, radius: null },
                      marks: [
                        radialArc(data, {
                          key: "id",
                          startAngle: "startAngle",
                          endAngle: "endAngle",
                          innerRadius: radius * ratio,
                          outerRadius: radius,
                          fill: (s) => chartColor(s.colorIndex),
                          stroke: (s) =>
                            s.id === active?.id
                              ? "var(--k-color-text-primary)"
                              : "var(--k-color-surface-raised)",
                          strokeWidth: size.lineWidth,
                        }),
                      ],
                    }),
                  ],
                }}
              />
            )}
          </div>
          {ratio > 0 && centerContent && (
            <div
              style={{
                position: "absolute",
                left: "50%",
                top: "50%",
                transform: "translate(-50%, -50%)",
                width: radius * ratio * 1.4,
                maxHeight: radius * ratio * 1.4,
                overflow: "hidden",
                textAlign: "center",
                pointerEvents: "none",
              }}
            >
              {centerContent}
            </div>
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
              const next = keyboardIndex(
                e.key,
                data.findIndex((s) => s.id === selectedId),
                data.length,
              );
              if (next !== undefined) {
                e.preventDefault();
                commit(data[next].id);
              }
            }}
          />
        </div>
        {active && !state.loading && !state.error && (
          <ChartTooltip
            title={active.label}
            rows={[{ ...active, value: formatValue(active.value) }]}
          />
        )}
      </div>
      {description && (
        <span className="k-line-chart__sr" id={`${id}-description`}>
          {description}
        </span>
      )}
      <span className="k-line-chart__sr" aria-live="polite">
        {selected ? `${selected.label}: ${formatValue(selected.value)}` : ""}
      </span>
    </div>
  );
}
