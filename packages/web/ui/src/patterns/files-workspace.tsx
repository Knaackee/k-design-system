import { useEffect, useRef, useState, type ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import {
  KSidebar,
  KSidebarBody,
  KSidebarFooter,
  KSidebarHeader,
} from "../navigation/sidebar.js";

export interface KFilesWorkspaceProps {
  sidebarOpen: boolean;
  onSidebarOpenChange: (open: boolean) => void;
  navigation: ReactNode;
  sidebarHeader?: ReactNode;
  /** Persistent content-area header above file tabs and actions. */
  header?: ReactNode;
  search?: ReactNode;
  title?: ReactNode;
  tabs?: ReactNode;
  sidebarFooter?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
  constrainContentWidth?: boolean;
  sidebarLabel?: string;
  openLabel?: string;
  closeLabel?: string;
}

/** Docked explorer from tablet widths upward; modal explorer on compact screens. */
export function KFilesWorkspace({
  sidebarOpen,
  onSidebarOpenChange,
  navigation,
  sidebarHeader,
  header,
  search,
  title,
  tabs,
  sidebarFooter,
  actions,
  children,
  constrainContentWidth = true,
  sidebarLabel = "Dateien",
  openLabel = "Dateien öffnen",
  closeLabel = "Dateien schließen",
}: KFilesWorkspaceProps) {
  const dialog = useRef<HTMLDialogElement>(null);
  const [mobile, setMobile] = useState(
    () =>
      typeof matchMedia === "function" &&
      matchMedia("(max-width: 599px)").matches,
  );
  useEffect(() => {
    if (typeof matchMedia !== "function") return;
    const query = matchMedia("(max-width: 599px)");
    const update = () => setMobile(query.matches);
    query.addEventListener("change", update);
    return () => query.removeEventListener("change", update);
  }, []);
  useEffect(() => {
    const panel = dialog.current;
    if (mobile && sidebarOpen && !panel?.open) panel?.showModal();
    if (!sidebarOpen && panel?.open) panel.close();
  }, [mobile, sidebarOpen]);
  const sidebar = (
    <KSidebar className="k-files-workspace__sidebar" label={sidebarLabel}>
      <KSidebarHeader>
        <div className="k-files-workspace__drawer-header">
          <div className="k-files-workspace__sidebar-header">
            {sidebarHeader}
          </div>
          <KButton
            variant="ghost"
            aria-label={closeLabel}
            onClick={() => onSidebarOpenChange(false)}
          >
            <KIcon name="menu" />
          </KButton>
        </div>
        {search && <div className="k-files-workspace__search">{search}</div>}
      </KSidebarHeader>
      <KSidebarBody>
        <div className="k-files-workspace__navigation">{navigation}</div>
      </KSidebarBody>
      {sidebarFooter && (
        <KSidebarFooter>
          <div className="k-files-workspace__sidebar-footer">
            {sidebarFooter}
          </div>
        </KSidebarFooter>
      )}
    </KSidebar>
  );
  return (
    <section className="k-files-workspace">
      <div className="k-files-workspace__body">
        {!mobile && (
          <aside
            className="k-files-workspace__dock"
            data-open={sidebarOpen || undefined}
            aria-label={sidebarLabel}
            aria-hidden={!sidebarOpen}
            inert={!sidebarOpen}
          >
            {sidebar}
          </aside>
        )}
        <div className="k-files-workspace__stage">
          {header && (
            <div style={{ flexShrink: 0, position: "relative" }}>
              {header}
              {!sidebarOpen && (
                <div
                  style={{
                    position: "absolute",
                    insetInlineStart: "var(--k-space-control-inset-inline)",
                    top: "50%",
                    transform: "translateY(-50%)",
                  }}
                >
                  <KButton
                    variant="ghost"
                    aria-label={openLabel}
                    aria-expanded={false}
                    onClick={() => onSidebarOpenChange(true)}
                  >
                    <KIcon name="menu" />
                  </KButton>
                </div>
              )}
            </div>
          )}
          {(tabs || title || actions || (!header && !sidebarOpen)) && (
            <header
              className="k-files-workspace__toolbar"
              data-tabs={!!tabs || undefined}
            >
              {!header && !sidebarOpen && (
                <KButton
                  variant="ghost"
                  aria-label={openLabel}
                  aria-expanded={false}
                  onClick={() => onSidebarOpenChange(true)}
                >
                  <KIcon name="menu" />
                </KButton>
              )}
              {tabs ? (
                <div className="k-files-workspace__tabs">{tabs}</div>
              ) : (
                <div className="k-files-workspace__title">{title}</div>
              )}
              {actions && (
                <div
                  className="k-files-workspace__actions"
                  role="group"
                  aria-label="Dateiaktionen"
                >
                  {actions}
                </div>
              )}
            </header>
          )}
          <main className="k-files-workspace__content">
            <div
              className="k-files-workspace__content-inner"
              data-constrained={constrainContentWidth || undefined}
            >
              {children}
            </div>
          </main>
        </div>
      </div>
      {mobile && (
        <dialog
          ref={dialog}
          className="k-files-workspace__drawer"
          aria-label={sidebarLabel}
          onCancel={() => onSidebarOpenChange(false)}
          onClose={() => onSidebarOpenChange(false)}
          onClick={(event) => {
            if (event.target === event.currentTarget) {
              const bounds = event.currentTarget.getBoundingClientRect();
              if (
                event.clientX < bounds.left ||
                event.clientX > bounds.right ||
                event.clientY < bounds.top ||
                event.clientY > bounds.bottom
              )
                onSidebarOpenChange(false);
            }
          }}
        >
          {sidebar}
        </dialog>
      )}
    </section>
  );
}
