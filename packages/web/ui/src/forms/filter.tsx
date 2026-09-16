import { useKLocalization } from "../localization/provider.js";
import type { ReactNode } from "react";
import { KIcon } from "../primitives/icon.js";
import { KButton } from "../primitives/button.js";
export interface KFilterChipProps {
  label: string;
  onRemove: () => void;
  removeLabel?: string;
}
export function KFilterChip({
  label,
  onRemove,
  removeLabel,
}: KFilterChipProps) {
  const { messages } = useKLocalization();
  return (
    <span className="k-filter-chip-target">
      <button
        type="button"
        className="k-filter-chip"
        aria-label={removeLabel ?? messages.remove.replace("{label}", label)}
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
  resetLabel,
  resetEnabled = true,
}: KFilterBarProps) {
  const { messages } = useKLocalization();
  return (
    <div className="k-filter-bar" role="group" aria-label={label}>
      {children}
      {onReset && (
        <KButton variant="ghost" onClick={onReset} disabled={!resetEnabled}>
          {resetLabel ?? messages.resetAll}
        </KButton>
      )}
    </div>
  );
}
