import * as Dialog from "@radix-ui/react-dialog";
import { Sheet, type SheetRef } from "react-modal-sheet";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { KIconButton } from "../actions/icon-button.js";

export type KOverlayProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: ReactNode;
  description?: ReactNode;
  children: ReactNode;
  actions?: ReactNode;
  headerActions?: ReactNode;
  dismissible?: boolean;
  closeLabel?: string;
  className?: string;
  /** Removes the standard body inset for edge-to-edge compositions. */
  contentInset?: boolean;
  headerless?: boolean;
  showClose?: boolean;
  leading?: ReactNode;
  bodyClassName?: string;
  zIndex?: number;
};

/** Phone sheets and tablet/desktop dialogs share the same controlled dismissal contract. */
export function KAdaptiveDialog(props: KOverlayProps) {
  const [compact, setCompact] = useState(
    () =>
      typeof window !== "undefined" &&
      typeof window.matchMedia === "function" &&
      window.matchMedia("(max-width: 599px)").matches,
  );
  useEffect(() => {
    if (
      typeof window === "undefined" ||
      typeof window.matchMedia !== "function"
    )
      return;
    const media = window.matchMedia("(max-width: 599px)");
    const update = () => setCompact(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  return compact ? (
    <KBottomSheet {...props} showClose={false} />
  ) : (
    <KDesktopDialog {...props} />
  );
}

export const KDialog = KAdaptiveDialog;

export function KDesktopDialog({
  open,
  onOpenChange,
  title,
  description,
  children,
  actions,
  headerActions,
  dismissible = true,
  closeLabel = "Close",
  className,
  contentInset = true,
  headerless = false,
  showClose = true,
  leading,
  bodyClassName,
  zIndex = 3010,
}: KOverlayProps) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay
          className="k-overlay-backdrop"
          style={{ zIndex: zIndex - 10 }}
        />
        <Dialog.Content
          className={["k-dialog", className].filter(Boolean).join(" ")}
          data-adaptive-surface="dialog"
          style={{ zIndex }}
          onEscapeKeyDown={
            dismissible ? undefined : (event) => event.preventDefault()
          }
          onPointerDownOutside={
            dismissible ? undefined : (event) => event.preventDefault()
          }
          aria-describedby={description ? undefined : ""}
        >
          <header
            className={
              headerless
                ? "k-overlay-header k-overlay-header--hidden"
                : "k-overlay-header"
            }
          >
            {leading}
            <div className="k-overlay-heading">
              <Dialog.Title className="k-overlay-title">{title}</Dialog.Title>
              {description && (
                <Dialog.Description className="k-overlay-description">
                  {description}
                </Dialog.Description>
              )}
            </div>
            {headerActions && (
              <div className="k-overlay-header-actions">{headerActions}</div>
            )}
            {dismissible && showClose && (
              <Dialog.Close asChild>
                <KIconButton
                  icon="x"
                  label={closeLabel}
                  className="k-overlay-close"
                />
              </Dialog.Close>
            )}
          </header>
          <div
            className={[
              "k-overlay-body",
              contentInset ? null : "k-overlay-body--flush",
              bodyClassName,
            ]
              .filter(Boolean)
              .join(" ")}
          >
            {children}
          </div>
          {actions && <footer className="k-overlay-actions">{actions}</footer>}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

export type KBottomSheetProps = KOverlayProps;

export function KBottomSheet({
  open,
  onOpenChange,
  title,
  description,
  children,
  actions,
  headerActions,
  dismissible = true,
  closeLabel = "Close",
  className,
  contentInset = true,
  headerless = false,
  showClose = true,
  leading,
  bodyClassName,
  zIndex = 3010,
}: KBottomSheetProps) {
  const sheetRef = useRef<SheetRef>(null);
  const latestOpen = useRef(open);
  latestOpen.current = open;
  const containerRef = useRef<HTMLDivElement>(null);
  const closeRef = useRef<HTMLButtonElement>(null);

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Sheet
        ref={sheetRef}
        snapPoints={[0, 1]}
        initialSnap={1}
        unstyled
        style={{ zIndex }}
        detent="content"
        isOpen={open}
        onClose={() => {
          if (dismissible) onOpenChange(false);
          // A controlled dirty/busy guard may reject dismissal after the drag.
          requestAnimationFrame(() => {
            if (latestOpen.current) sheetRef.current?.snapTo(1);
          });
        }}
        disableDismiss={!dismissible}
        onOpenEnd={() => (closeRef.current ?? containerRef.current)?.focus()}
        prefersReducedMotion={
          typeof window !== "undefined" &&
          typeof window.matchMedia === "function" &&
          window.matchMedia("(prefers-reduced-motion: reduce)").matches
        }
      >
        <Dialog.Content
          asChild
          onOpenAutoFocus={(event) => {
            event.preventDefault();
            (closeRef.current ?? containerRef.current)?.focus();
          }}
          onEscapeKeyDown={
            dismissible ? undefined : (event) => event.preventDefault()
          }
          onPointerDownOutside={
            dismissible ? undefined : (event) => event.preventDefault()
          }
          aria-describedby={description ? undefined : ""}
        >
          <Sheet.Container
            ref={containerRef}
            tabIndex={-1}
            className={["k-bottom-sheet", className].filter(Boolean).join(" ")}
            data-adaptive-surface="sheet"
          >
            <Sheet.Header className="k-bottom-sheet-handle">
              <span className="k-bottom-sheet-grip" />
            </Sheet.Header>
            <header
              className={
                headerless
                  ? "k-overlay-header k-overlay-header--hidden"
                  : "k-overlay-header"
              }
            >
              {leading}
              <div className="k-overlay-heading">
                <Dialog.Title className="k-overlay-title">{title}</Dialog.Title>
                {description && (
                  <Dialog.Description className="k-overlay-description">
                    {description}
                  </Dialog.Description>
                )}
              </div>
              {headerActions && (
                <div className="k-overlay-header-actions">{headerActions}</div>
              )}
              {dismissible && showClose && (
                <Dialog.Close asChild>
                  <KIconButton
                    ref={closeRef}
                    icon="x"
                    label={closeLabel}
                    className="k-overlay-close"
                  />
                </Dialog.Close>
              )}
            </header>
            <Sheet.Content
              className="k-bottom-sheet-content"
              scrollClassName="k-overlay-body"
              scrollStyle={{ overscrollBehavior: "contain" }}
            >
              <div
                className={[
                  "k-bottom-sheet-body",
                  contentInset ? null : "k-overlay-body--flush",
                  bodyClassName,
                ]
                  .filter(Boolean)
                  .join(" ")}
              >
                {children}
              </div>
            </Sheet.Content>
            {actions && (
              <footer className="k-overlay-actions">{actions}</footer>
            )}
          </Sheet.Container>
        </Dialog.Content>
        <Sheet.Backdrop
          className="k-overlay-backdrop"
          style={{ zIndex: zIndex - 10 }}
          onTap={dismissible ? () => onOpenChange(false) : undefined}
        />
      </Sheet>
    </Dialog.Root>
  );
}
