import {
  useLayoutEffect,
  useRef,
  type CSSProperties,
  type ReactNode,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import { KPopover } from "../extended-components.js";
import type { KMapZone } from "../maps/map-zone-geometry.js";
import { KAnimatedIcon } from "../primitives/animated-icon.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";

export function ZoneEditorToolbar({
  zones,
  selectedZoneId,
  draft,
  open,
  dirty,
  canUndo,
  disabled,
  canFinish,
  labels,
  panelTitle,
  panelSubtitle,
  panelMode = "list",
  panel,
  panelActions,
  onPanelBack,
  panelBackFocusId,
  onPanelEscape,
  onOpenChange,
  onAdd,
  onProperties,
  onUndo,
  onDiscard,
  onFinish,
}: {
  zones: readonly KMapZone[];
  selectedZoneId: string | null;
  draft: KMapZone | null;
  open: boolean;
  dirty: boolean;
  canUndo: boolean;
  disabled: boolean;
  canFinish: boolean;
  labels: KMapZoneEditorLabels;
  panelTitle: string;
  panelSubtitle?: string;
  panelMode?: "list" | "create" | "postal" | "properties";
  panel: ReactNode;
  panelActions?: ReactNode;
  onPanelBack?: () => void;
  panelBackFocusId?: string;
  onPanelEscape?: () => void;
  onOpenChange: (open: boolean) => void;
  onAdd: () => void;
  onProperties: () => void;
  onUndo: () => void;
  onDiscard: () => void;
  onFinish: () => void;
}) {
  const showDirty = dirty && !(open && panelMode === "properties");
  const dirtyBar = useRef<HTMLDivElement>(null);
  const normalBar = useRef<HTMLDivElement>(null);
  const focusedSlot = useRef<"dirty" | "normal" | null>(null);
  useLayoutEffect(() => {
    const previous = showDirty ? "normal" : "dirty";
    if (focusedSlot.current !== previous) return;
    const target = showDirty ? dirtyBar.current : normalBar.current;
    target
      ?.querySelector<HTMLButtonElement>("button:not(:disabled)")
      ?.focus({ preventScroll: true });
  }, [showDirty]);
  const selected = zones.find((zone) => zone.id === selectedZoneId);
  const name = draft?.name ?? selected?.name;
  const hasSelection = !!selectedZoneId && (!!draft || !!selected);
  return (
    <>
      <div
        ref={dirtyBar}
        className="k-map-zone-editor__dirty-actions"
        data-visible={showDirty || undefined}
        inert={!showDirty}
        aria-hidden={!showDirty}
        onFocusCapture={() => {
          focusedSlot.current = "dirty";
        }}
        onBlurCapture={(event) => {
          if (
            event.relatedTarget &&
            !event.currentTarget.contains(event.relatedTarget)
          )
            focusedSlot.current = null;
        }}
      >
        {canUndo && (
          <KIconButton
            icon="undo-2"
            label={labels.undo}
            variant="ghost"
            disabled={disabled}
            onClick={onUndo}
          />
        )}
        <KIconButton
          icon="x"
          label={labels.discard}
          variant="secondary"
          disabled={disabled}
          onClick={onDiscard}
        />
        <KButton disabled={disabled || !canFinish} onClick={onFinish}>
          {labels.acceptChanges}
        </KButton>
      </div>
      {(!!zones.length || !!draft || open) && (
        <div
          ref={normalBar}
          className="k-map-zone-editor__toolbar"
          data-visible={!showDirty || undefined}
          inert={showDirty}
          aria-hidden={showDirty}
          onFocusCapture={() => {
            focusedSlot.current = "normal";
          }}
          onBlurCapture={(event) => {
            if (
              event.relatedTarget &&
              !event.currentTarget.contains(event.relatedTarget)
            )
              focusedSlot.current = null;
          }}
        >
          <span
            className="k-map-zone-editor__toolbar-count"
            aria-label={`${zones.length} ${zones.length === 1 ? labels.zone : labels.zonePlural}`}
          >
            <KIcon name="layers" />
          </span>
          <KPopover
            portal
            anchorRef={normalBar}
            open={open}
            placement="top"
            closeOnInteractOutside={false}
            onOpenChange={onOpenChange}
            label={panelTitle}
            trigger={
              <KButton variant="ghost" className="k-map-zone-editor__toggle">
                <span className="k-map-zone-editor__toggle-label">
                  {hasSelection ? (name ?? labels.all) : labels.all}
                </span>
                <KAnimatedIcon name={open ? "chevron-down" : "chevron-up"} />
              </KButton>
            }
          >
            <div
              className="k-map-zone-editor__floating-dialog"
              data-mode={panelMode}
              style={
                {
                  "--k-zone-list-height": `${Math.min(500, 190 + zones.length * 64)}px`,
                } as CSSProperties
              }
              onKeyDown={(event) => {
                if (event.key !== "Escape" || !onPanelEscape) return;
                event.preventDefault();
                event.stopPropagation();
                onPanelEscape();
              }}
            >
              <header className="k-map-zone-editor__floating-dialog-header">
                {onPanelBack ? (
                  <KIconButton
                    className="k-map-zone-editor__floating-dialog-back"
                    icon="arrow-left"
                    label={labels.back}
                    variant="ghost"
                    onClick={(event) => {
                      const surface = event.currentTarget.closest(
                        ".k-map-zone-editor__floating-dialog",
                      );
                      onPanelBack();
                      requestAnimationFrame(() => {
                        const target = Array.from(
                          surface?.querySelectorAll<HTMLElement>(
                            "[data-zone-editor-edit]",
                          ) ?? [],
                        ).find(
                          (element) =>
                            element.dataset.zoneEditorEdit === panelBackFocusId,
                        );
                        target?.focus({ preventScroll: true });
                      });
                    }}
                  />
                ) : null}
                <div>
                  <h2>
                    {panelMode === "properties"
                      ? (panelSubtitle ?? panelTitle)
                      : panelTitle}
                  </h2>
                </div>
                <KIconButton
                  className="k-map-zone-editor__floating-dialog-close"
                  icon="x"
                  label={labels.closePanel}
                  variant="ghost"
                  onClick={() => onOpenChange(false)}
                />
              </header>
              <div className="k-map-zone-editor__floating-dialog-body">
                {panel}
              </div>
              {panelActions && (
                <footer className="k-map-zone-editor__floating-dialog-actions">
                  {panelActions}
                </footer>
              )}
            </div>
          </KPopover>
          <span
            className="k-map-zone-editor__properties-segment"
            data-visible={hasSelection || undefined}
            aria-hidden={!hasSelection}
          >
            <KIconButton
              icon="pencil"
              label={labels.editZoneProperties}
              disabled={disabled || !hasSelection}
              onClick={onProperties}
            />
          </span>
          <KIconButton
            className="k-map-zone-editor__add"
            icon="plus"
            label={labels.addZone}
            disabled={disabled}
            data-dirty={dirty || undefined}
            onClick={onAdd}
          />
        </div>
      )}
    </>
  );
}
