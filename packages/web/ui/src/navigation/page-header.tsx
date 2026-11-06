import { useRef, type HTMLAttributes, type ReactNode } from "react";
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
  /**
   * A navigation button at the start (menu, chat history) for screens
   * without a back control: on phones it sits at the start of the top bar,
   * as in Gmail or ChatGPT; wider, before the title. Never place such a
   * button in the page content (Decision 0015).
   */
  leading?: ReactNode;
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
  leading,
  className,
  ...props
}: KPageHeaderProps) {
  // Phones inside the shell: back and actions live in the top bar; the
  // header shows only the large title (Decision 0015).
  const root = useRef<HTMLElement>(null);
  const inBar = useKTopBarEntry(
    { backLabel, onBack, backHistory, leading, actions },
    root,
  );
  const shownBack = inBar ? undefined : backLabel;
  const shownLeading = inBar || backLabel ? undefined : leading;
  const shownActions = inBar ? undefined : actions;
  return (
    <header
      ref={root}
      className={["k-page-header", className].filter(Boolean).join(" ")}
      data-back={shownBack || shownLeading ? true : undefined}
      data-actions={shownActions ? true : undefined}
      {...props}
    >
      <div className="k-page-header__layout">
        {shownBack ? (
          <div className="k-page-header__back">
            <KBackButton
              label={shownBack}
              onClick={onBack}
              history={backHistory}
            />
          </div>
        ) : shownLeading ? (
          <div className="k-page-header__back">{shownLeading}</div>
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
        {shownActions ? (
          <div className="k-page-header__actions">{shownActions}</div>
        ) : null}
      </div>
    </header>
  );
}
