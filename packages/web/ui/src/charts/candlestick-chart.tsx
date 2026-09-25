import {
  useEffect,
  useId,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { Chart } from "@tanstack/charts/react";
import { rect } from "@tanstack/charts/rect";
import { lineY } from "@tanstack/charts/line";
import { scaleLinear } from "@tanstack/charts/scales/linear";
import { focusDisabled } from "@tanstack/charts/focus/disabled";
import { KSurface } from "../primitives/surface.js";
import { chartRatio, validChartAxis, type KChartAxis } from "./chart-model.js";
import {
  validCandles,
  candleSpan,
  nearestCandle,
  type KChartCandle,
  type KChartVisibleRange,
} from "./candle-model.js";
import { ChartState, keyboardIndex, useChartSize } from "./chart-parts.js";

export interface KCandlestickChartProps {
  data: readonly KChartCandle[];
  xAxis: KChartAxis;
  yAxis: KChartAxis;
  label: string;
  description?: string;
  height?: number;
  selectedId?: string | null;
  onSelectionChange?: (id: string | null) => void;
  visibleRange?: KChartVisibleRange;
  ohlcLabels?: Partial<
    Record<"open" | "high" | "low" | "close" | "volume", string>
  >;
  formatVolume?: (volume: number) => string;
  loading?: boolean;
  loadingContent?: ReactNode;
  error?: string;
  errorContent?: ReactNode;
  emptyContent?: ReactNode;
}
const color = (c: KChartCandle) =>
  c.close > c.open
    ? "var(--k-color-status-success-accent)"
    : c.close < c.open
      ? "var(--k-color-status-error-accent)"
      : "var(--k-color-text-muted)";
/** Controlled OHLC chart. Range, selection, data and formatting belong to the consumer. */
export function KCandlestickChart({
  data,
  xAxis: inputXAxis,
  yAxis,
  label,
  description,
  height,
  selectedId = null,
  onSelectionChange,
  visibleRange,
  ohlcLabels,
  formatVolume = String,
  ...state
}: KCandlestickChartProps) {
  const xAxis = visibleRange ? { ...inputXAxis, ...visibleRange } : inputXAxis;
  const root = useRef<HTMLDivElement>(null),
    id = useId();
  const { ref: plot, size } = useChartSize();
  const [hover, setHover] = useState<string | null>(null);
  const candles = validCandles(data, visibleRange).filter(
    (c) => c.x >= xAxis.min && c.x <= xAxis.max,
  );
  const ready =
    validChartAxis(xAxis) && validChartAxis(yAxis) && candles.length > 0;
  const available = ready && !state.loading && !state.error;
  const selected = candles.find((c) => c.id === selectedId);
  const active = candles.find((c) => c.id === hover) ?? selected;
  const span = candleSpan(candles, xAxis.max - xAxis.min);
  const halfMinHeight =
    ((yAxis.max - yAxis.min) * size.lineWidth) / Math.max(1, size.height) / 2;
  const labels = {
    open: "Open",
    high: "High",
    low: "Low",
    close: "Close",
    volume: "Volume",
    ...ohlcLabels,
  };
  const commit = (next: string | null) => {
    setHover(null);
    if (next !== selectedId) onSelectionChange?.(next);
  };
  useEffect(() => {
    const outside = (e: PointerEvent) => {
      if (selectedId && !root.current?.contains(e.target as Node))
        onSelectionChange?.(null);
    };
    document.addEventListener("pointerdown", outside);
    return () => document.removeEventListener("pointerdown", outside);
  }, [selectedId, onSelectionChange]);
  const choose = (clientX: number) => {
    if (!available || !plot.current) return null;
    const bounds = plot.current.getBoundingClientRect();
    return (
      nearestCandle(
        candles,
        xAxis.min +
          ((clientX - bounds.left) / bounds.width) * (xAxis.max - xAxis.min),
      )?.id ?? null
    );
  };
  const rows = (c: KChartCandle) => [
    ...(["open", "high", "low", "close"] as const).map((key) => ({
      key,
      label: labels[key],
      value: yAxis.format(c[key]),
    })),
    ...(c.volume !== undefined && Number.isFinite(c.volume)
      ? [{ key: "volume", label: labels.volume, value: formatVolume(c.volume) }]
      : []),
  ];
  return (
    <div ref={root} className="k-line-chart k-candlestick-chart">
      <div
        className="k-line-chart__canvas"
        style={height ? { height } : undefined}
      >
        {!available && <ChartState {...state} />}
        <div
          ref={plot}
          className="k-line-chart__plot"
          style={!available ? { visibility: "hidden" } : undefined}
        >
          {yAxis.ticks
            .filter((v) => v >= yAxis.min && v <= yAxis.max)
            .map((v) => (
              <i
                key={v}
                aria-hidden="true"
                style={{
                  position: "absolute",
                  top: `${(1 - chartRatio(v, yAxis)) * 100}%`,
                  left: 0,
                  right: 0,
                  borderTop:
                    "var(--k-border-width-default) solid var(--k-component-chart-grid-color)",
                }}
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
                  marks: candles.flatMap((c) => [
                    lineY(
                      [
                        { x: c.x, y: c.low },
                        { x: c.x, y: c.high },
                      ],
                      {
                        id: `${c.id}-wick`,
                        x: "x",
                        y: "y",
                        stroke: () => color(c),
                        strokeWidth: size.lineWidth,
                        points: false,
                      },
                    ),
                    rect(
                      [
                        {
                          ...c,
                          left: c.x - span / 2,
                          right: c.x + span / 2,
                          bottom: Math.min(c.open, c.close),
                          top: Math.max(c.open, c.close),
                        },
                      ].map((b) =>
                        b.top - b.bottom < halfMinHeight * 2
                          ? {
                              ...b,
                              bottom: (c.open + c.close) / 2 - halfMinHeight,
                              top: (c.open + c.close) / 2 + halfMinHeight,
                            }
                          : b,
                      ),
                      {
                        id: `${c.id}-body`,
                        x1: "left",
                        x2: "right",
                        y1: "bottom",
                        y2: "top",
                        key: "id",
                        fill: color(c),
                        inset: 0,
                      },
                    ),
                  ]),
                }}
              />
            )}
          </div>
          {active && available && (
            <div
              className="k-line-chart__crosshair"
              style={{ left: `${chartRatio(active.x, xAxis) * 100}%` }}
            />
          )}
          <div
            className="k-line-chart__interaction"
            role="group"
            tabIndex={available ? 0 : -1}
            aria-label={label}
            aria-describedby={description ? `${id}-description` : undefined}
            onPointerMove={(e) => {
              if (e.pointerType === "mouse") setHover(choose(e.clientX));
            }}
            onPointerLeave={() => setHover(null)}
            onClick={(e) => commit(choose(e.clientX))}
            onKeyDown={(e) => {
              if (!available) return;
              if (e.key === "Escape") {
                e.preventDefault();
                commit(null);
                return;
              }
              if (e.key === "ArrowUp" || e.key === "ArrowDown") return;
              const next = keyboardIndex(
                e.key,
                candles.findIndex((c) => c.id === selectedId),
                candles.length,
              );
              if (next !== undefined) {
                e.preventDefault();
                commit(candles[next].id);
              }
            }}
          />
        </div>
        {available && (
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
                </div>
              ))}
            <div className="k-line-chart__x">
              {xAxis.ticks
                .filter((v) => v >= xAxis.min && v <= xAxis.max)
                .map((v) => (
                  <span
                    key={v}
                    style={{
                      left: `${chartRatio(v, xAxis) * 100}%`,
                      transform:
                        v === xAxis.min
                          ? "none"
                          : v === xAxis.max
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
                {rows(active).map((r) => (
                  <div key={r.key}>
                    <span
                      style={{
                        flex: 1,
                        minWidth: 0,
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {r.label}
                    </span>
                    <b>{r.value}</b>
                  </div>
                ))}
              </KSurface>
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
        {available && selected
          ? `${xAxis.format(selected.x)}. ${rows(selected)
              .map((r) => `${r.label}: ${r.value}`)
              .join(". ")}`
          : ""}
      </span>
    </div>
  );
}
