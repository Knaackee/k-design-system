import { DragDropProvider, useDraggable, useDroppable } from "@dnd-kit/react";
import type { KeyboardEvent, MouseEvent, ReactNode } from "react";

export interface KKanbanColumn<T> {
  id: string;
  title: ReactNode;
  items: readonly T[];
  leading?: ReactNode;
  trailing?: ReactNode;
  addLabel?: string;
}

export interface KKanbanCardContext<T> {
  item: T;
  itemId: string;
  columnId: string;
  index: number;
  selected: boolean;
  toggleSelected: () => void;
}

export interface KKanbanMove<T> {
  item: T;
  itemId: string;
  sourceColumnId: string;
  sourceIndex: number;
  targetColumnId: string;
  targetIndex: number;
}

export interface KKanbanProps<T> {
  columns: readonly KKanbanColumn<T>[];
  getItemId: (item: T) => string;
  renderCard: (context: KKanbanCardContext<T>) => ReactNode;
  getItemLabel?: (item: T) => string;
  onCardOpen?: (item: T, columnId: string) => void;
  onCardMove?: (move: KKanbanMove<T>) => void;
  canMove?: (move: KKanbanMove<T>) => boolean;
  onAddCard?: (columnId: string) => void;
  selectedItemIds?: readonly string[];
  onSelectionChange?: (itemIds: readonly string[]) => void;
  dragEnabled?: boolean;
  columnWidth?: number;
  ariaLabel?: string;
  className?: string;
}

type DragData = {
  kind: "card" | "column";
  itemId?: string;
  columnId: string;
  index: number;
};

function isInteractiveTarget(target: EventTarget | null) {
  return (
    target instanceof Element &&
    Boolean(
      target.closest("button, a, input, select, textarea, [role='button']"),
    )
  );
}

function KKanbanCard<T>({
  item,
  itemId,
  columnId,
  index,
  label,
  selected,
  dragEnabled,
  renderCard,
  onOpen,
  onToggleSelected,
}: {
  item: T;
  itemId: string;
  columnId: string;
  index: number;
  label: string;
  selected: boolean;
  dragEnabled: boolean;
  renderCard: KKanbanProps<T>["renderCard"];
  onOpen?: () => void;
  onToggleSelected: () => void;
}) {
  const { ref: draggableRef, isDragging } = useDraggable<DragData>({
    id: itemId,
    type: "k-kanban-card",
    disabled: !dragEnabled,
    data: { kind: "card", itemId, columnId, index },
  });
  const { ref: droppableRef, isDropTarget } = useDroppable<DragData>({
    id: `card:${itemId}`,
    type: "k-kanban-card-target",
    accept: "k-kanban-card",
    disabled: !dragEnabled,
    data: { kind: "card", itemId, columnId, index },
  });

  const open = () => onOpen?.();
  const onClick = (event: MouseEvent<HTMLElement>) => {
    if (!isInteractiveTarget(event.target)) open();
  };
  const onKeyDown = (event: KeyboardEvent<HTMLElement>) => {
    if (
      (event.key === "Enter" || event.key === " ") &&
      event.target === event.currentTarget
    ) {
      event.preventDefault();
      open();
    }
  };

  return (
    <article
      ref={(element) => {
        draggableRef(element);
        droppableRef(element);
      }}
      className="k-kanban-card"
      data-dragging={isDragging || undefined}
      data-drop-target={(isDropTarget && !isDragging) || undefined}
      data-selected={selected || undefined}
      aria-label={label}
      aria-selected={selected}
      tabIndex={onOpen || dragEnabled ? 0 : undefined}
      onClick={onClick}
      onKeyDown={onKeyDown}
    >
      {renderCard({
        item,
        itemId,
        columnId,
        index,
        selected,
        toggleSelected: onToggleSelected,
      })}
    </article>
  );
}

function KKanbanColumnView<T>({
  column,
  ...props
}: {
  column: KKanbanColumn<T>;
  getItemId: KKanbanProps<T>["getItemId"];
  getItemLabel?: KKanbanProps<T>["getItemLabel"];
  renderCard: KKanbanProps<T>["renderCard"];
  onCardOpen?: KKanbanProps<T>["onCardOpen"];
  onAddCard?: KKanbanProps<T>["onAddCard"];
  selected: ReadonlySet<string>;
  toggleSelected: (itemId: string) => void;
  dragEnabled: boolean;
}) {
  const { ref, isDropTarget } = useDroppable<DragData>({
    id: `column:${column.id}`,
    type: "k-kanban-column",
    accept: "k-kanban-card",
    data: {
      kind: "column",
      columnId: column.id,
      index: column.items.length,
    },
  });

  return (
    <section
      ref={ref}
      className="k-kanban-column"
      data-drop-target={isDropTarget || undefined}
      aria-labelledby={`k-kanban-column-${column.id}`}
    >
      <header className="k-kanban-column-header">
        {column.leading}
        <h3
          id={`k-kanban-column-${column.id}`}
          className="k-kanban-column-title"
        >
          {column.title}
        </h3>
        <span
          className="k-kanban-column-count"
          aria-label={`${column.items.length} items`}
        >
          {column.items.length}
        </span>
        {column.trailing && (
          <div className="k-kanban-column-trailing">{column.trailing}</div>
        )}
      </header>
      <div className="k-kanban-column-items">
        {column.items.map((item, index) => {
          const itemId = props.getItemId(item);
          return (
            <KKanbanCard
              key={itemId}
              item={item}
              itemId={itemId}
              columnId={column.id}
              index={index}
              label={props.getItemLabel?.(item) ?? itemId}
              selected={props.selected.has(itemId)}
              dragEnabled={props.dragEnabled}
              renderCard={props.renderCard}
              onOpen={
                props.onCardOpen
                  ? () => props.onCardOpen?.(item, column.id)
                  : undefined
              }
              onToggleSelected={() => props.toggleSelected(itemId)}
            />
          );
        })}
        {column.items.length === 0 && <div className="k-kanban-empty" />}
      </div>
      {props.onAddCard && (
        <button
          type="button"
          className="k-kanban-add"
          onClick={() => props.onAddCard?.(column.id)}
        >
          {column.addLabel ?? "Add item"}
        </button>
      )}
    </section>
  );
}

export function KKanban<T>({
  columns,
  getItemId,
  renderCard,
  getItemLabel,
  onCardOpen,
  onCardMove,
  canMove,
  onAddCard,
  selectedItemIds = [],
  onSelectionChange,
  dragEnabled = true,
  columnWidth = 280,
  ariaLabel = "Kanban board",
  className,
}: KKanbanProps<T>) {
  const selected = new Set(selectedItemIds);
  const itemsById = new Map<
    string,
    { item: T; columnId: string; index: number }
  >();
  for (const column of columns) {
    column.items.forEach((item, index) => {
      itemsById.set(getItemId(item), { item, columnId: column.id, index });
    });
  }

  const toggleSelected = (itemId: string) => {
    if (!onSelectionChange) return;
    const next = new Set(selected);
    if (next.has(itemId)) next.delete(itemId);
    else next.add(itemId);
    onSelectionChange([...next]);
  };

  return (
    <DragDropProvider
      onDragEnd={({ operation, canceled }) => {
        if (canceled || !onCardMove) return;
        const source = operation.source?.data as DragData | undefined;
        const target = operation.target?.data as DragData | undefined;
        if (!source?.itemId || !target) return;
        const entry = itemsById.get(source.itemId);
        if (!entry) return;
        const targetIndex =
          target.kind === "column"
            ? target.index
            : target.columnId === entry.columnId && target.index > entry.index
              ? target.index - 1
              : target.index;
        const move: KKanbanMove<T> = {
          item: entry.item,
          itemId: source.itemId,
          sourceColumnId: entry.columnId,
          sourceIndex: entry.index,
          targetColumnId: target.columnId,
          targetIndex,
        };
        if (
          move.sourceColumnId === move.targetColumnId &&
          move.sourceIndex === move.targetIndex
        )
          return;
        if (canMove?.(move) === false) return;
        onCardMove(move);
      }}
    >
      <div
        className={["k-kanban", className].filter(Boolean).join(" ")}
        style={
          {
            "--k-kanban-column-width": `${columnWidth}px`,
          } as React.CSSProperties
        }
        role="region"
        aria-label={ariaLabel}
      >
        {columns.map((column) => (
          <KKanbanColumnView
            key={column.id}
            column={column}
            getItemId={getItemId}
            getItemLabel={getItemLabel}
            renderCard={renderCard}
            onCardOpen={onCardOpen}
            onAddCard={onAddCard}
            selected={selected}
            toggleSelected={toggleSelected}
            dragEnabled={dragEnabled}
          />
        ))}
      </div>
    </DragDropProvider>
  );
}
