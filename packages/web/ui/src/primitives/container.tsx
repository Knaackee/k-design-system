import type { HTMLAttributes } from "react";

export interface KContainerProps extends HTMLAttributes<HTMLDivElement> {
  /** Maximum content width, excluding token-backed horizontal gutters. */
  maxWidth?: number;
}

export function KContainer({
  maxWidth = 760,
  children,
  className = "",
  ...props
}: KContainerProps) {
  if (!Number.isFinite(maxWidth) || maxWidth <= 0)
    throw new RangeError("KContainer maxWidth must be positive and finite");
  return (
    <div {...props} className={`k-container ${className}`}>
      <div className="k-container__content" style={{ maxWidth }}>
        {children}
      </div>
    </div>
  );
}
