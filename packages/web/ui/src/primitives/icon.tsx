import type { HTMLAttributes } from "react";
import { iconSvg, type KIconName } from "../generated/icons.js";
export type { KIconName } from "../generated/icons.js";
export interface KIconProps extends Omit<
  HTMLAttributes<HTMLSpanElement>,
  "children" | "color"
> {
  name: KIconName;
  size?: number;
  strokeWidth?: number;
  color?: string;
  /** Omit for decorative icons; label meaningful standalone icons. */
  label?: string;
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
  const svg =
    strokeWidth === undefined
      ? iconSvg[name]
      : iconSvg[name].replace(
          /stroke-width="[^"]*"/g,
          `stroke-width="${strokeWidth}"`,
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
        width: size,
        height: size,
        color,
        maskImage: mask,
        WebkitMaskImage: mask,
      }}
    />
  );
}
