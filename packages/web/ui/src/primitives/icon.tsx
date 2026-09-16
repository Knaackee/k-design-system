import type { HTMLAttributes } from "react";
import { iconSvg, type KIconName } from "../generated/icons.js";
export type { KIconName } from "../generated/icons.js";
export interface KIconProps extends Omit<
  HTMLAttributes<HTMLSpanElement>,
  "children" | "color"
> {
  name: KIconName;
  size?: number;
  color?: string;
  /** Omit for decorative icons; label meaningful standalone icons. */
  label?: string;
}
export function KIcon({
  name,
  size = 16,
  color,
  label,
  className = "",
  style,
  ...props
}: KIconProps) {
  if (!Number.isFinite(size) || size <= 0)
    throw new RangeError("KIcon size must be positive and finite");
  const mask = `url("data:image/svg+xml,${encodeURIComponent(iconSvg[name])}")`;
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
