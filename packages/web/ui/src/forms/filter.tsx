import type { ReactNode } from "react";
import { KIcon } from "../primitives/icon.js";
import { KButton } from "../primitives/button.js";
export interface KFilterChipProps {
  label: string;
  onRemove: () => void;
}
export function KFilterChip({ label, onRemove }: KFilterChipProps) {
  return (
    <span className="k-filter-chip-target">
      <button
        type="button"
        className="k-filter-chip"
        aria-label={`Remove ${label}`}
        onClick={onRemove}
      >
        <span>{label}</span>
        <KIcon name="x" size={16} />
      </button>
    </span>
  );
}
export interface KFilterBarProps {
  label: string;
  children: ReactNode;
  onReset?: () => void;
  resetLabel?: string;
  resetEnabled?: boolean;
}
export function KFilterBar({
  label,
  children,
  onReset,
  resetLabel = "Reset all",
  resetEnabled = true,
}: KFilterBarProps) {
  return (
    <div className="k-filter-bar" role="group" aria-label={label}>
      {children}
      {onReset && (
        <KButton variant="ghost" onClick={onReset} disabled={!resetEnabled}>
          {resetLabel}
        </KButton>
      )}
    </div>
  );
}
