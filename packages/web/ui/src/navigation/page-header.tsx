import type { HTMLAttributes, ReactNode } from "react";
import { KText } from "../primitives/text.js";
import { KBackButton } from "./back-button.js";
import type { KMenuAction } from "../actions/menu-button.js";
import { useKTopBarEntry } from "./top-bar.js";

export interface KPageHeaderProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  title: ReactNode;
  subtitle?: ReactNode;
  /** Shows a `KBackButton`; the label names the destination. */
  backLabel?: string;
  /** Defaults to `history.back()`. */
  onBack?: () => void;
  /** At most three; one of them may be prominent. */
  actions?: ReactNode;
  /** Shown above the title from 600 px (deep desktop hierarchies). */
  breadcrumb?: ReactNode;
  /**
   * Levels above this screen for the back button's long-press menu; give it
   * whenever `breadcrumb` is set so phones keep the path (Decision 0015).
   */
  backHistory?: readonly KMenuAction[];
}

/**
 * Header of a screen (Decision 0012). Below 600 px the back chevron and the
 * actions share a top row and the title sits underneath as a large title;
 * from 600 px the title sits between back and actions. From 1.3× text the
 * actions move under the title and wrap.
 */
export function KPageHeader({
  title,
  subtitle,
  backLabel,
  onBack,
  actions,
  breadcrumb,
  backHistory,
  className,
  ...props
}: KPageHeaderProps) {
  // Phones: back and actions stay in the shell's top bar while scrolled.
  useKTopBarEntry({ backLabel, onBack, backHistory, actions });
  return (
    <header
      className={["k-page-header", className].filter(Boolean).join(" ")}
      data-back={backLabel ? true : undefined}
      data-actions={actions ? true : undefined}
      {...props}
    >
      <div className="k-page-header__layout">
        {backLabel ? (
          <div className="k-page-header__back">
            <KBackButton
              label={backLabel}
              onClick={onBack}
              history={backHistory}
            />
          </div>
        ) : null}
        <div className="k-page-header__copy">
          {breadcrumb ? (
            <div className="k-page-header__breadcrumb">{breadcrumb}</div>
          ) : null}
          <KText as="h1" variant="heading1" className="k-page-header__title">
            {title}
          </KText>
          {subtitle ? (
            <KText
              as="p"
              variant="bodySmall"
              className="k-page-header__subtitle"
            >
              {subtitle}
            </KText>
          ) : null}
        </div>
        {actions ? (
          <div className="k-page-header__actions">{actions}</div>
        ) : null}
      </div>
    </header>
  );
}
