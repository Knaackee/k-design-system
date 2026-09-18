import * as Dialog from "@radix-ui/react-dialog";
import { Sheet } from "react-modal-sheet";
import { useRef, type ReactNode } from "react";
import { KIconButton } from "../actions/icon-button.js";

export type KOverlayProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: ReactNode;
  description?: ReactNode;
  children: ReactNode;
  actions?: ReactNode;
  dismissible?: boolean;
  closeLabel?: string;
  className?: string;
};

export function KDialog({
  open,
  onOpenChange,
  title,
  description,
  children,
  actions,
  dismissible = true,
  closeLabel = "Close",
  className,
}: KOverlayProps) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="k-overlay-backdrop" />
        <Dialog.Content
          className={["k-dialog", className].filter(Boolean).join(" ")}
          onEscapeKeyDown={
            dismissible ? undefined : (event) => event.preventDefault()
          }
          onPointerDownOutside={
            dismissible ? undefined : (event) => event.preventDefault()
          }
          aria-describedby={description ? undefined : ""}
        >
          <header className="k-overlay-header">
            <div className="k-overlay-heading">
              <Dialog.Title className="k-overlay-title">{title}</Dialog.Title>
              {description && (
                <Dialog.Description className="k-overlay-description">
                  {description}
                </Dialog.Description>
              )}
            </div>
            {dismissible && (
              <Dialog.Close asChild>
                <KIconButton
                  icon="x"
                  label={closeLabel}
                  className="k-overlay-close"
                />
              </Dialog.Close>
            )}
          </header>
          <div className="k-overlay-body">{children}</div>
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
  dismissible = true,
  closeLabel = "Close",
  className,
}: KBottomSheetProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const closeRef = useRef<HTMLButtonElement>(null);

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Sheet
        unstyled
        detent="content"
        isOpen={open}
        onClose={() => {
          if (dismissible) onOpenChange(false);
        }}
        disableDismiss={!dismissible}
        onOpenEnd={() => (closeRef.current ?? containerRef.current)?.focus()}
        prefersReducedMotion={
          typeof window !== "undefined" &&
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
          >
            <Sheet.Header className="k-bottom-sheet-handle">
              <span className="k-bottom-sheet-grip" />
            </Sheet.Header>
            <Sheet.Content className="k-bottom-sheet-content">
              <header className="k-overlay-header">
                <div className="k-overlay-heading">
                  <Dialog.Title className="k-overlay-title">
                    {title}
                  </Dialog.Title>
                  {description && (
                    <Dialog.Description className="k-overlay-description">
                      {description}
                    </Dialog.Description>
                  )}
                </div>
                {dismissible && (
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
              <div className="k-overlay-body">{children}</div>
              {actions && (
                <footer className="k-overlay-actions">{actions}</footer>
              )}
            </Sheet.Content>
          </Sheet.Container>
        </Dialog.Content>
        <Sheet.Backdrop
          className="k-overlay-backdrop"
          onTap={dismissible ? () => onOpenChange(false) : undefined}
        />
      </Sheet>
    </Dialog.Root>
  );
}
