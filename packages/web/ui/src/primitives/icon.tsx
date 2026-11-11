import { type HTMLAttributes, useContext, useSyncExternalStore } from "react";
import { iconSvg, type KIconName } from "../generated/icons.js";
import { KIconStrokeTokenContext } from "../internal/icon-token-context.js";
export type { KIconName } from "../generated/icons.js";
export interface KIconProps extends Omit<
  HTMLAttributes<HTMLSpanElement>,
  "children" | "color"
> {
  name: KIconName;
  size?: number;
  /**
   * Stroke in the icon's 24-unit grid. Leave it unset: the style's
   * `--k-size-icon-stroke` then draws the same screen stroke at every size
   * (Decision 0015). App code must not set it (UI rule gate).
   */
  strokeWidth?: number;
  color?: string;
  /** Omit for decorative icons; label meaningful standalone icons. */
  label?: string;
}
/** Fallback before styles load and during server rendering (linear). */
const kDefaultIconStroke = 1.5;

export function readIconStroke(tokenName = "--k-size-icon-stroke"): number {
  if (typeof document === "undefined") return kDefaultIconStroke;
  const value = parseFloat(
    getComputedStyle(document.documentElement).getPropertyValue(tokenName),
  );
  return Number.isFinite(value) && value > 0 ? value : kDefaultIconStroke;
}

/** Re-reads the stroke when the root's style or theme attributes change. */
function subscribeIconStroke(onChange: () => void) {
  if (typeof MutationObserver === "undefined") return () => {};
  const observer = new MutationObserver(onChange);
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["data-style", "data-brand", "data-theme", "style"],
  });
  return () => observer.disconnect();
}

export function KIcon({
  name,
  size = 16,
  strokeWidth,
  color,
  label,
  className = "",
  style,
  ...props
}: KIconProps) {
  if (!Number.isFinite(size) || size <= 0)
    throw new RangeError("KIcon size must be positive and finite");
  if (
    strokeWidth !== undefined &&
    (!Number.isFinite(strokeWidth) || strokeWidth <= 0)
  )
    throw new RangeError("KIcon strokeWidth must be positive and finite");
  const strokeTokenName = useContext(KIconStrokeTokenContext);
  const tokenStroke = useSyncExternalStore(
    subscribeIconStroke,
    () => readIconStroke(strokeTokenName),
    () => kDefaultIconStroke,
  );
  // Absolute stroke: the token is in screen pixels, the SVG grid is 24.
  const stroke = strokeWidth ?? (tokenStroke * 24) / size;
  const svg = iconSvg[name].replace(
    /stroke-width="[^"]*"/g,
    `stroke-width="${Number(stroke.toFixed(3))}"`,
  );
  const mask = `url("data:image/svg+xml,${encodeURIComponent(svg)}")`;
  return (
    <span
      {...props}
      className={`k-icon ${className}`}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      style={{
        ...style,
        // Text-adjacent icons (16–24) grow with the text up to
        // --k-text-scale-max-icon; glyphs and display icons keep their size.
        width:
          size >= 16 && size <= 24
            ? `calc(${size}px * var(--k-icon-scale, 1))`
            : size,
        height:
          size >= 16 && size <= 24
            ? `calc(${size}px * var(--k-icon-scale, 1))`
            : size,
        color,
        maskImage: mask,
        WebkitMaskImage: mask,
      }}
    />
  );
}

// A stable name: page headers and rows recognise it across bundles.
KIcon.displayName = "KIcon";
