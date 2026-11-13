import { useEffect, useId, useRef } from "react";
import { KIconButton } from "../actions/icon-button.js";
import type { KOverlayProps } from "./overlay.js";
import { SheetHero } from "./sheet-hero.js";

/** A non-modal detail pane in the host's grid; it never covers the master list. */
export function KInlineSideSheet({
  open,
  onOpenChange,
  title,
  description,
  children,
  actions,
  footer,
  hero,
  floatingActions,
  heroOverlays,
  dismissible = true,
  closeLabel = "Close",
  className,
  contentInset = true,
  bodyClassName,
  initialFocusRef,
}: KOverlayProps) {
  const titleId = useId();
  const pane = useRef<HTMLElement>(null);
  const close = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    if (!open) return;
    const opener =
      document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null;
    const element = pane.current;
    (initialFocusRef?.current ?? close.current ?? element)?.focus();
    return () => {
      if (element?.contains(document.activeElement) && opener?.isConnected)
        opener.focus();
    };
  }, [open, initialFocusRef]);
  if (!open) return null;
  return (
    <aside
      ref={pane}
      tabIndex={-1}
      role="region"
      aria-labelledby={titleId}
      className={[
        "k-inline-side-sheet",
        hero ? "k-sheet--hero" : null,
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      data-adaptive-surface="inline-side-sheet"
      onKeyDown={(event) => {
        if (
          event.key === "Escape" &&
          !event.defaultPrevented &&
          dismissible &&
          !(
            event.target instanceof Element &&
            event.target.closest("[data-k-escape-boundary]")
          )
        ) {
          event.stopPropagation();
          onOpenChange(false);
        }
      }}
    >
      <header
        className={
          hero
            ? "k-overlay-header k-overlay-header--hidden"
            : "k-overlay-header"
        }
      >
        <div className="k-overlay-heading">
          <h2 id={titleId} className="k-overlay-title">
            {title}
          </h2>
          {description && (
            <p className="k-overlay-description">{description}</p>
          )}
        </div>
        {!hero && dismissible && (
          <KIconButton
            ref={close}
            icon="x"
            label={closeLabel}
            onClick={() => onOpenChange(false)}
          />
        )}
      </header>
      <div className="k-inline-side-sheet__scroll">
        {hero && (
          <SheetHero
            hero={hero}
            floatingActions={floatingActions}
            heroOverlays={heroOverlays}
            dismissible={dismissible}
            closeLabel={closeLabel}
            closeRef={close}
            onClose={() => onOpenChange(false)}
          />
        )}
        <div
          className={[
            "k-sheet-detail-body",
            contentInset ? null : "k-overlay-body--flush",
            bodyClassName,
          ]
            .filter(Boolean)
            .join(" ")}
        >
          {children}
        </div>
      </div>
      {(footer ?? actions) && (
        <footer className="k-overlay-actions k-sheet-detail-footer">
          {footer ?? actions}
        </footer>
      )}
    </aside>
  );
}
