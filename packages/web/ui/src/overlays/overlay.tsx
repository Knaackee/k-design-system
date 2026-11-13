import * as Dialog from "@radix-ui/react-dialog";
import { Sheet, type SheetRef } from "react-modal-sheet";
import {
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type ReactNode,
  type RefObject,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import {
  useSheetScrollHandoff,
  sheetCloseThreshold,
  sheetCloseVelocity,
} from "./use-sheet-scroll-handoff.js";
import { usePageSheetEffect } from "./use-page-sheet-effect.js";
import { handleOverlayPointerOutside } from "./overlay-pointer.js";
import { OverlayLayerContext, useOverlayLayer } from "./overlay-layer.js";
import { SheetHero, type KSheetHeroProps } from "./sheet-hero.js";
import { sheetDetentConfiguration } from "./sheet-detents.js";

// Radix observes Escape in the capture phase, before a nested popover can
// consume it. Leave dismissal to that focused child surface first.
function handleEscape(event: KeyboardEvent, dismissible: boolean) {
  if (
    !dismissible ||
    (event.target instanceof Element &&
      event.target.closest("[data-k-escape-boundary]"))
  ) {
    event.preventDefault();
  }
}

export type KOverlayProps = KSheetHeroProps & {
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
  /** Optional initial field for targeted editing flows. */
  initialFocusRef?: RefObject<HTMLElement | null>;
  /** Long editing journeys can use a full-screen phone dialog instead of a sheet. */
  compactPresentation?: "sheet" | "fullscreen";
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
  if (compact && props.compactPresentation === "fullscreen") {
    return (
      <KDesktopDialog
        {...props}
        className={[props.className, "k-dialog--fullscreen"]
          .filter(Boolean)
          .join(" ")}
      />
    );
  }
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
  hero,
  floatingActions,
  heroOverlays,
  footer,
  dismissible = true,
  closeLabel = "Close",
  className,
  contentInset = true,
  headerless = false,
  showClose = true,
  leading,
  bodyClassName,
  initialFocusRef,
  zIndex,
}: KOverlayProps) {
  const layer = useOverlayLayer(zIndex);
  const contentRef = useRef<HTMLDivElement>(null);
  const dialog = (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay
          className="k-overlay-backdrop"
          style={{ zIndex: layer - 10 }}
        />
        <Dialog.Content
          ref={contentRef}
          className={["k-dialog", hero ? "k-sheet--hero" : null, className]
            .filter(Boolean)
            .join(" ")}
          data-adaptive-surface="dialog"
          onOpenAutoFocus={(event) => {
            if (initialFocusRef?.current) {
              event.preventDefault();
              initialFocusRef.current.focus();
            }
          }}
          style={{ zIndex: layer }}
          onEscapeKeyDown={(event) => handleEscape(event, dismissible)}
          onPointerDownOutside={(event) =>
            handleOverlayPointerOutside(event, contentRef.current, dismissible)
          }
          aria-describedby={description ? undefined : ""}
        >
          <header
            className={
              headerless || hero
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
            {dismissible && showClose && !hero && (
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
              hero || !contentInset ? "k-overlay-body--flush" : null,
              hero ? null : bodyClassName,
            ]
              .filter(Boolean)
              .join(" ")}
          >
            {hero ? (
              <>
                <SheetHero
                  hero={hero}
                  floatingActions={floatingActions}
                  heroOverlays={heroOverlays}
                  dismissible={dismissible && showClose}
                  closeLabel={closeLabel}
                  onClose={() => onOpenChange(false)}
                />
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
              </>
            ) : (
              children
            )}
          </div>
          {(footer ?? actions) && (
            <footer
              className={
                hero
                  ? "k-overlay-actions k-sheet-detail-footer"
                  : "k-overlay-actions"
              }
            >
              {footer ?? actions}
            </footer>
          )}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
  return (
    <OverlayLayerContext.Provider value={layer}>
      {dialog}
    </OverlayLayerContext.Provider>
  );
}

export type KBottomSheetProps = KOverlayProps & {
  /** Dedicated viewport-sized app surface, outside the sheet portal. Enables page presentation. */
  presentationRootId?: string;
};

export function KBottomSheet({
  open,
  onOpenChange,
  title,
  description,
  children,
  actions,
  headerActions,
  hero,
  floatingActions,
  heroOverlays,
  footer,
  dismissible = true,
  closeLabel = "Close",
  className,
  contentInset = true,
  headerless = false,
  showClose = true,
  leading,
  bodyClassName,
  initialFocusRef,
  zIndex,
  presentationRootId,
  detents,
  initialDetent,
}: KBottomSheetProps) {
  const configuration = useMemo(
    () => sheetDetentConfiguration(detents, initialDetent),
    [detents, initialDetent],
  );
  const [activeSnap, setActiveSnap] = useState(configuration.initialSnap);
  const handoffDetents = useMemo(
    () =>
      configuration.enabled
        ? { points: configuration.points, active: activeSnap }
        : undefined,
    [configuration, activeSnap],
  );
  const layer = useOverlayLayer(zIndex);
  const titleId = useId();
  const descriptionId = useId();
  const sheetRef = useRef<SheetRef>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const [scrollElement, setScrollElement] = useState<HTMLDivElement | null>(
    null,
  );
  useSheetScrollHandoff(
    scrollElement,
    sheetRef,
    open,
    dismissible,
    handoffDetents,
  );
  const [effectActive, setEffectActive] = useState(open);
  useEffect(() => {
    if (open) {
      setEffectActive(true);
      setActiveSnap(configuration.initialSnap);
    }
  }, [open, configuration.initialSnap]);
  usePageSheetEffect(sheetRef, presentationRootId, effectActive);
  const latestOpen = useRef(open);
  latestOpen.current = open;
  const containerRef = useRef<HTMLDivElement>(null);
  const closeRef = useRef<HTMLButtonElement>(null);
  const openerRef = useRef<HTMLElement | null>(null);

  const dialog = (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Sheet
        ref={sheetRef}
        snapPoints={configuration.points}
        dragCloseThreshold={sheetCloseThreshold}
        dragVelocityThreshold={sheetCloseVelocity}
        initialSnap={configuration.initialSnap}
        onSnap={setActiveSnap}
        unstyled
        style={{ zIndex: layer }}
        detent={
          presentationRootId || configuration.enabled ? "default" : "content"
        }
        onCloseEnd={() => setEffectActive(false)}
        isOpen={open}
        onClose={() => {
          if (dismissible) onOpenChange(false);
          // A controlled dirty/busy guard may reject dismissal after the drag.
          requestAnimationFrame(() => {
            if (latestOpen.current)
              sheetRef.current?.snapTo(activeSnap || configuration.initialSnap);
          });
        }}
        disableDismiss={!dismissible}
        onOpenEnd={() => {
          setScrollElement(scrollRef.current);
          (
            initialFocusRef?.current ??
            closeRef.current ??
            containerRef.current
          )?.focus();
        }}
        prefersReducedMotion={
          typeof window !== "undefined" &&
          typeof window.matchMedia === "function" &&
          window.matchMedia("(prefers-reduced-motion: reduce)").matches
        }
      >
        <Dialog.Content
          asChild
          aria-label={typeof title === "string" ? title : undefined}
          aria-labelledby={titleId}
          aria-describedby={description ? descriptionId : undefined}
          onOpenAutoFocus={(event) => {
            event.preventDefault();
            openerRef.current =
              document.activeElement instanceof HTMLElement
                ? document.activeElement
                : null;
            (
              initialFocusRef?.current ??
              closeRef.current ??
              containerRef.current
            )?.focus();
          }}
          onCloseAutoFocus={(event) => {
            if (presentationRootId && openerRef.current?.isConnected) {
              event.preventDefault();
              openerRef.current.focus();
            }
          }}
          onEscapeKeyDown={(event) => handleEscape(event, dismissible)}
          onPointerDownOutside={
            dismissible ? undefined : (event) => event.preventDefault()
          }
        >
          <Sheet.Container
            ref={containerRef}
            tabIndex={-1}
            aria-label={typeof title === "string" ? title : undefined}
            aria-labelledby={titleId}
            aria-describedby={description ? descriptionId : undefined}
            className={[
              "k-bottom-sheet",
              hero ? "k-sheet--hero" : null,
              className,
            ]
              .filter(Boolean)
              .join(" ")}
            data-adaptive-surface={presentationRootId ? "page-sheet" : "sheet"}
            data-has-detents={configuration.enabled || undefined}
            data-hero-collapsed={
              (hero &&
                configuration.enabled &&
                activeSnap === configuration.points.length - 1) ||
              undefined
            }
          >
            <Sheet.Header className="k-bottom-sheet-handle">
              {configuration.enabled && configuration.points.length > 2 ? (
                <button
                  type="button"
                  className="k-bottom-sheet-detent-toggle"
                  aria-label={
                    activeSnap === configuration.points.length - 1
                      ? "Collapse sheet"
                      : "Expand sheet"
                  }
                  aria-expanded={activeSnap === configuration.points.length - 1}
                  onClick={() =>
                    sheetRef.current?.snapTo(
                      activeSnap === configuration.points.length - 1
                        ? 1
                        : configuration.points.length - 1,
                    )
                  }
                >
                  <span className="k-bottom-sheet-grip" />
                </button>
              ) : (
                <span className="k-bottom-sheet-grip" />
              )}
            </Sheet.Header>
            <header
              className={
                headerless || hero
                  ? "k-overlay-header k-overlay-header--hidden"
                  : "k-overlay-header"
              }
            >
              {leading}
              <div className="k-overlay-heading">
                <Dialog.Title id={titleId} className="k-overlay-title">
                  {title}
                </Dialog.Title>
                {description && (
                  <Dialog.Description
                    id={descriptionId}
                    className="k-overlay-description"
                  >
                    {description}
                  </Dialog.Description>
                )}
              </div>
              {headerActions && (
                <div className="k-overlay-header-actions">{headerActions}</div>
              )}
              {dismissible && showClose && !hero && (
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
              scrollRef={scrollRef}
              scrollClassName={
                hero ? "k-overlay-body k-overlay-body--flush" : "k-overlay-body"
              }
              scrollStyle={{ overscrollBehavior: "contain" }}
            >
              {hero && (
                <SheetHero
                  hero={hero}
                  floatingActions={floatingActions}
                  heroOverlays={heroOverlays}
                  dismissible={dismissible && showClose}
                  closeLabel={closeLabel}
                  closeRef={closeRef}
                  collapsed={
                    configuration.enabled &&
                    activeSnap === configuration.points.length - 1
                  }
                  onClose={() => onOpenChange(false)}
                />
              )}
              <div
                className={[
                  hero ? "k-sheet-detail-body" : "k-bottom-sheet-body",
                  contentInset ? null : "k-overlay-body--flush",
                  bodyClassName,
                ]
                  .filter(Boolean)
                  .join(" ")}
              >
                {children}
              </div>
            </Sheet.Content>
            {(footer ?? actions) && (
              <footer
                className={
                  hero
                    ? "k-overlay-actions k-sheet-detail-footer"
                    : "k-overlay-actions"
                }
              >
                {footer ?? actions}
              </footer>
            )}
          </Sheet.Container>
        </Dialog.Content>
        <Sheet.Backdrop
          className="k-overlay-backdrop"
          style={{ zIndex: 1 }}
          onTap={dismissible ? () => onOpenChange(false) : undefined}
        />
      </Sheet>
    </Dialog.Root>
  );
  return (
    <OverlayLayerContext.Provider value={layer}>
      {dialog}
    </OverlayLayerContext.Provider>
  );
}
