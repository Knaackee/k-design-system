import { forwardRef } from "react";
import { KIconButton, type KIconButtonProps } from "../actions/icon-button.js";

export interface KBackButtonProps extends Omit<
  KIconButtonProps,
  "icon" | "label"
> {
  /** Accessible name including the destination, e.g. "Back to Portfolios". */
  label: string;
}

/**
 * Standard back control (Decision 0012, Apple HIG Toolbars): the back
 * chevron alone, at the leading edge of the top bar. Never a text label such
 * as "Back"; `label` names the destination for assistive technology. The
 * chevron mirrors in right-to-left layouts. Without `onClick` it goes back in
 * the browser history, like the browser's own back button.
 */
export const KBackButton = forwardRef<HTMLButtonElement, KBackButtonProps>(
  function KBackButton({ label, onClick, className = "", ...rest }, ref) {
    return (
      <KIconButton
        ref={ref}
        icon="chevron-left"
        label={label}
        className={`k-back-button ${className}`}
        onClick={onClick ?? (() => window.history.back())}
        {...rest}
      />
    );
  },
);
