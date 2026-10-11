import { useEffect, useRef, useState, type ReactNode } from "react";
import { DragDropProvider, PointerSensor } from "@dnd-kit/react";
import { PointerActivationConstraints } from "@dnd-kit/dom";
import { isSortable, useSortable } from "@dnd-kit/react/sortable";
import { KIcon } from "../primitives/icon.js";
import { KContextMenu } from "../actions/context-menu.js";
import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";

export interface KTabStripItem {
  id: string;
  label: string;
  icon?: ReactNode;
  closable?: boolean;
  modified?: boolean;
}
const tabSensors = [
  PointerSensor.configure({
    activationConstraints: [
      new PointerActivationConstraints.Distance({ value: 6 }),
    ],
  }),
];
export interface KTabStripProps {
  items: readonly KTabStripItem[];
  selectedId?: string;
  onSelect: (id: string) => void;
  onClose?: (id: string) => void;
  onReorder?: (ids: string[]) => void;
  menuActions?: (
    item: KTabStripItem,
    presentation: "tabs" | "dropdown",
  ) => readonly KMenuAction[];
  label?: string;
  overflowLabel?: string;
  closeLabel?: (item: KTabStripItem) => string;
}
function Tab({
  item,
  index,
  selected,
  onSelect,
  onClose,
  reorderable,
  actions,
  closeLabel,
  onKeyDown,
}: {
  item: KTabStripItem;
  index: number;
  selected: boolean;
  onSelect: () => void;
  onClose?: () => void;
  reorderable: boolean;
  actions: readonly KMenuAction[];
  closeLabel: string;
  onKeyDown: React.KeyboardEventHandler<HTMLButtonElement>;
}) {
  const { ref, handleRef, isDragging } = useSortable({
    id: item.id,
    index,
    disabled: !reorderable,
    data: { id: item.id },
    group: "tab-strip",
  });
  return (
    <div
      ref={ref}
      className="k-tab-strip__slot"
      data-tab-id={item.id}
      data-active={selected || undefined}
      data-dragging={isDragging || undefined}
    >
      <KContextMenu
        label={item.label}
        actions={actions}
        disabled={!actions.length}
      >
        <div className="k-tab-strip__item">
          <button
            ref={handleRef}
            role="tab"
            aria-selected={selected}
            tabIndex={selected ? 0 : -1}
            className="k-tab-strip__select"
            onClick={onSelect}
            onKeyDown={onKeyDown}
            title={item.label}
          >
            {item.icon}
            <span>{item.label}</span>
            {item.modified && (
              <span aria-label="Ungespeicherte Änderungen">●</span>
            )}
          </button>
          {onClose && item.closable !== false && (
            <button
              className="k-tab-strip__close"
              aria-label={closeLabel}
              onClick={onClose}
            >
              <KIcon name="x" size={14} />
            </button>
          )}
        </div>
      </KContextMenu>
    </div>
  );
}
/** Consumer-controlled editor tabs; closing never deletes the underlying content. */
export function KTabStrip({
  items,
  selectedId,
  onSelect,
  onClose,
  onReorder,
  menuActions,
  label = "Geöffnete Dateien",
  overflowLabel = "Weitere geöffnete Dateien",
  closeLabel = (item) => `${item.label} schließen`,
}: KTabStripProps) {
  const viewport = useRef<HTMLDivElement>(null);
  const [overflow, setOverflow] = useState(false);
  const ids = items.map((item) => item.id);
  const activeItem = items.find((item) => item.id === selectedId);
  const activeActions = activeItem
    ? (menuActions?.(activeItem, "tabs") ?? [])
    : [];
  const dropdownActions = activeItem
    ? (menuActions?.(activeItem, "dropdown") ?? [])
    : [];
  useEffect(() => {
    const el = viewport.current;
    if (!el) return;
    const measure = () => setOverflow(el.scrollWidth > el.clientWidth + 1);
    const observer = new ResizeObserver(measure);
    observer.observe(el);
    Array.from(el.children).forEach((child) => observer.observe(child));
    measure();
    return () => observer.disconnect();
  }, [items]);
  useEffect(() => {
    const selected = Array.from(
      viewport.current?.querySelectorAll<HTMLElement>("[data-tab-id]") ?? [],
    ).find((el) => el.dataset.tabId === selectedId);
    selected?.scrollIntoView({ block: "nearest", inline: "nearest" });
  }, [selectedId]);
  function focus(id: string) {
    onSelect(id);
    const slot = Array.from(
      viewport.current?.querySelectorAll<HTMLElement>("[data-tab-id]") ?? [],
    ).find((el) => el.dataset.tabId === id);
    slot?.querySelector<HTMLButtonElement>('[role="tab"]')?.focus();
  }
  return (
    <DragDropProvider
      sensors={tabSensors}
      onDragEnd={({ operation, canceled }) => {
        if (canceled || !onReorder) return;
        const source = String(operation.source?.id ?? ""),
          target = String(operation.target?.id ?? "");
        // Optimistic sorting moves the source over itself before drag end.
        // Commit its final sortable index rather than that transient target ID.
        const from = ids.indexOf(source),
          to = isSortable(operation.source)
            ? operation.source.index
            : ids.indexOf(target);
        if (from < 0 || to < 0 || from === to) return;
        const next = [...ids];
        next.splice(to, 0, ...next.splice(from, 1));
        onReorder(next);
      }}
    >
      <div className="k-tab-strip">
        <div className="k-tab-strip__mobile">
          <KMenuButton
            label={label}
            fullWidth
            triggerVariant="ghost"
            triggerClassName="k-tab-strip__picker"
            triggerContent={
              <span className="k-tab-strip__picker-content">
                {activeItem?.icon}
                <span>{activeItem?.label ?? label}</span>
                <KIcon name="chevron-down" size={14} />
              </span>
            }
            actions={[
              ...items.map((item) => ({
                id: `select-${item.id}`,
                label: item.label,
                iconContent: item.icon,
                onSelect: () => onSelect(item.id),
              })),
              ...dropdownActions.map((action, index) => ({
                ...action,
                id: `selected-${action.id}`,
                separatorBefore: index === 0 || action.separatorBefore,
              })),
            ]}
          />
        </div>
        <div
          ref={viewport}
          className="k-tab-strip__viewport"
          role="tablist"
          aria-label={label}
        >
          {items.map((item, index) => (
            <Tab
              key={item.id}
              item={item}
              index={index}
              selected={item.id === selectedId}
              onSelect={() => onSelect(item.id)}
              onClose={onClose ? () => onClose(item.id) : undefined}
              closeLabel={closeLabel(item)}
              reorderable={!!onReorder}
              actions={menuActions?.(item, "tabs") ?? []}
              onKeyDown={(event) => {
                const direction =
                  event.key === "ArrowRight"
                    ? 1
                    : event.key === "ArrowLeft"
                      ? -1
                      : 0;
                if (direction && event.altKey && onReorder) {
                  event.preventDefault();
                  const to = Math.max(
                    0,
                    Math.min(ids.length - 1, index + direction),
                  );
                  const next = [...ids];
                  next.splice(to, 0, ...next.splice(index, 1));
                  onReorder(next);
                  return;
                }
                if (direction || event.key === "Home" || event.key === "End") {
                  event.preventDefault();
                  focus(
                    ids[
                      event.key === "Home"
                        ? 0
                        : event.key === "End"
                          ? ids.length - 1
                          : (index + direction + ids.length) % ids.length
                    ],
                  );
                }
                if (
                  event.key === "Delete" &&
                  onClose &&
                  item.closable !== false
                ) {
                  event.preventDefault();
                  onClose(item.id);
                }
              }}
            />
          ))}
        </div>
        {overflow && (
          <div className="k-tab-strip__overflow">
            <KMenuButton
              overflow
              align="end"
              label={overflowLabel}
              actions={[
                ...items.map((item) => ({
                  id: `tab-${item.id}`,
                  label: item.label,
                  iconContent: item.icon,
                  onSelect: () => focus(item.id),
                })),
                ...activeActions.map((action, index) => ({
                  ...action,
                  id: `active-${action.id}`,
                  separatorBefore: index === 0 || action.separatorBefore,
                })),
              ]}
            />
          </div>
        )}
      </div>
    </DragDropProvider>
  );
}
