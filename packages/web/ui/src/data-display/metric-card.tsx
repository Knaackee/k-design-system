import { useId, type ReactNode } from "react";
import { KBadge } from "../basic-components.js";
import { KProgress } from "../extended-components.js";
import { KSurface } from "../primitives/surface.js";
import { KText } from "../primitives/text.js";
import { metricTrendPath } from "./metric-trend.js";

export interface KMetricCardProps {
  label: string;
  /** Already formatted by the consumer, including currency/unit. */
  value: ReactNode;
  description: ReactNode;
  comparison?: {
    label: string;
    description: string;
    sentiment: "positive" | "negative" | "neutral";
  };
  /** Ordered observations; null represents missing data, never zero. */
  trend?: { values: readonly (number | null)[]; label: string };
  progress?: { value: number; max?: number; label: string };
}

/** Compact dashboard KPI. Independent of KCard's shape and chart defaults. */
export function KMetricCard({
  label,
  value,
  description,
  comparison,
  trend,
  progress,
}: KMetricCardProps) {
  const labelId = useId();
  const path = trend ? metricTrendPath(trend.values) : "";
  return (
    <KSurface
      as="article"
      border="none"
      className="k-metric-card"
      aria-labelledby={labelId}
    >
      <KText
        as="h3"
        id={labelId}
        variant="bodySmall"
        className="k-metric-card__label"
      >
        {label}
      </KText>
      <div className="k-metric-card__reading">
        <KText as="span" variant="heading2" className="k-metric-card__value">
          {value}
        </KText>
        {comparison && (
          <KBadge
            variant={
              comparison.sentiment === "positive"
                ? "success"
                : comparison.sentiment === "negative"
                  ? "destructive"
                  : "secondary"
            }
            title={comparison.description}
            aria-label={`${comparison.label}: ${comparison.description}`}
          >
            {comparison.label}
          </KBadge>
        )}
      </div>
      {progress ? (
        <div className="k-metric-card__visual">
          <KProgress
            value={progress.value}
            max={progress.max}
            aria-label={progress.label}
          />
        </div>
      ) : path && trend ? (
        <svg
          className="k-metric-card__trend"
          viewBox="-1 -2 102 28"
          preserveAspectRatio="none"
          role="img"
          aria-label={trend.label}
        >
          <path d={path} vectorEffect="non-scaling-stroke" />
        </svg>
      ) : (
        <div className="k-metric-card__visual" aria-hidden />
      )}
      <KText as="p" variant="bodySmall" className="k-metric-card__description">
        {description}
      </KText>
    </KSurface>
  );
}
