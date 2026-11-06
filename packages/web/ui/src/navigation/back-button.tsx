import { forwardRef, useLayoutEffect, useRef, useState } from "react";
import { KIconButton, type KIconButtonProps } from "../actions/icon-button.js";
import { KContextMenu } from "../actions/context-menu.js";
import type { KMenuAction } from "../actions/menu-button.js";

export interface KBackButtonProps extends Omit<
  KIconButtonProps,
  "icon" | "label"
> {
  /** Accessible name including the destination, e.g. "Back to Portfolios". */
  label: string;
  /**
   * Levels above the current screen, root first, with icons. A long press or
   * secondary click opens them as a menu, as the iOS back button does; this
   * replaces breadcrumbs on phones (Decision 0015).
   */
  history?: readonly KMenuAction[];
}

/**
 * Standard back control (Decision 0012, Apple HIG Toolbars): the back
 * chevron alone, at the leading edge of the top bar. Never a text label such
 * as "Back"; `label` names the destination for assistive technology. The
 * chevron mirrors in right-to-left layouts. Without `onClick` it goes back in
 * the browser history, like the browser's own back button.
 */
export const KBackButton = forwardRef<HTMLButtonElement, KBackButtonProps>(
  function KBackButton(
    { label, onClick, history = [], className = "", ...rest },
    ref,
  ) {
    const own = useRef<HTMLButtonElement | null>(null);
    // Material navigates up with an arrow; Apple and linear with a chevron.
    const [material, setMaterial] = useState(false);
    useLayoutEffect(() => {
      setMaterial(
        own.current?.closest("[data-style]")?.getAttribute("data-style") ===
          "material",
      );
    }, []);
    const button = (
      <KIconButton
        ref={(element) => {
          own.current = element;
          if (typeof ref === "function") ref(element);
          else if (ref) ref.current = element;
        }}
        icon={material ? "arrow-left" : "chevron-left"}
        label={label}
        className={`k-back-button ${className}`}
        onClick={onClick ?? (() => window.history.back())}
        {...rest}
      />
    );
    return history.length > 0 ? (
      <KContextMenu label={label} actions={history}>
        {button}
      </KContextMenu>
    ) : (
      button
    );
  },
);
