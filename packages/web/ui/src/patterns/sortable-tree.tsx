import { TreeRow, DropTarget, type Target } from "./sortable-tree-row.js";
import {
  DragDropProvider,
  DragOverlay,
  useDraggable,
  useDroppable,
} from "@dnd-kit/react";
import { AnimatePresence, useReducedMotion } from "motion/react";
import {
  useCallback,
  useEffect,
  useId,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { type KMenuAction } from "../actions/menu-button.js";
import {
  flattenKSortableTree,
  moveKSortableTree,
  type KSortableTreeEntry,
  type KSortableTreeMove,
  type KSortableTreeNode,
} from "./sortable-tree-model.js";

export * from "./sortable-tree-model.js";

export interface KSortableTreeLabels {
  drag: string;
  expand: string;
  collapse: string;
  move: string;
  up: string;
  down: string;
  indent: string;
  outdent: string;
  moveTo: string;
  root: string;
  drop: string;
  empty: string;
  moved: (label: string) => string;
}
const defaultLabels: KSortableTreeLabels = {
  drag: "Drag",
  expand: "Expand",
  collapse: "Collapse",
  move: "Move",
  up: "Move up",
  down: "Move down",
  indent: "Nest in previous group",
  outdent: "Move out one level",
  moveTo: "Move to",
  root: "Top level",
  drop: "Drop here",
  empty: "No items",
  moved: (label) => `Moved ${label}`,
};
export interface KSortableTreeContext<T = unknown> {
  node: KSortableTreeNode<T>;
  depth: number;
  expanded: boolean;
}
export interface KSortableTreeProps<T = unknown> {
  nodes: readonly KSortableTreeNode<T>[];
  onMove: (move: KSortableTreeMove) => void;
  renderContent?: (context: KSortableTreeContext<T>) => ReactNode;
  renderActions?: (context: KSortableTreeContext<T>) => ReactNode;
  /** Product actions merged before the built-in movement actions in one menu. */
  getActions?: (context: KSortableTreeContext<T>) => readonly KMenuAction[];
  /** Omit to expand all containers initially and manage expansion internally. */
  expandedIds?: readonly string[];
  onExpandedChange?: (ids: readonly string[]) => void;
  /** Maximum node depth, with root at 0. Moving a subtree checks every descendant. */
  maxDepth?: number;
  /** Minimum complete row height for custom content. */
  minRowHeight?: number;
  canMove?: (move: KSortableTreeMove) => boolean;
  disabled?: boolean;
  labels?: Partial<KSortableTreeLabels>;
  ariaLabel?: string;
  className?: string;
  /** Display root leaves in a fixed visual group; move events still use parentId null. */
  ungroupedLabel?: string;
  defaultUngroupedExpanded?: boolean;
}
/** Controlled recursive data with flat, stable row keys so reparenting preserves row state. */
export function KSortableTree<T>({
  nodes,
  onMove,
  renderContent,
  renderActions,
  getActions,
  expandedIds,
  onExpandedChange,
  maxDepth,
  minRowHeight,
  canMove,
  disabled = false,
  labels: customLabels,
  ariaLabel = "Sortable hierarchy",
  className,
  ungroupedLabel,
  defaultUngroupedExpanded = true,
}: KSortableTreeProps<T>) {
  const id = useId();
  const rowHeights = useRef(new Map<string, number>());
  const [rowHeight, setRowHeight] = useState(0);
  const onMeasure = useCallback((nodeId: string, height: number | null) => {
    if (height === null) rowHeights.current.delete(nodeId);
    else rowHeights.current.set(nodeId, height);
    setRowHeight(Math.max(0, ...rowHeights.current.values()));
  }, []);
  const rootRef = useRef<HTMLDivElement>(null);
  const [duration, setDuration] = useState(0);
  useEffect(() => {
    if (!rootRef.current) return;
    const value = getComputedStyle(rootRef.current)
      .getPropertyValue("--k-motion-moderate")
      .trim();
    const parsed = parseFloat(value);
    setDuration(
      Number.isFinite(parsed) ? parsed / (value.endsWith("ms") ? 1000 : 1) : 0,
    );
  }, []);
  const all = flattenKSortableTree(nodes);
  const [internalExpanded, setInternalExpanded] = useState<readonly string[]>(
    () =>
      all
        .filter(({ node }) => node.children !== undefined)
        .map(({ node }) => node.id),
  );
  const expanded = expandedIds ?? internalExpanded;
  const ungroupedId = `${id}:ungrouped`;
  const [ungroupedExpanded, setUngroupedExpanded] = useState(
    defaultUngroupedExpanded,
  );
  const rootLeaves = nodes.filter((node) => node.children === undefined);
  const grouped = ungroupedLabel !== undefined && rootLeaves.length > 0;
  const baseVisible = flattenKSortableTree(nodes, expanded);
  const visible: KSortableTreeEntry<T>[] = grouped
    ? [
        ...baseVisible.filter(
          (entry) =>
            entry.parentId !== null || entry.node.children !== undefined,
        ),
        {
          node: {
            id: ungroupedId,
            label: ungroupedLabel,
            children: rootLeaves,
          },
          parentId: null,
          index: nodes.length,
          depth: 0,
        },
        ...(ungroupedExpanded
          ? baseVisible
              .filter(
                (entry) =>
                  entry.parentId === null && entry.node.children === undefined,
              )
              .map((entry) => ({ ...entry, depth: 1 }))
          : []),
      ]
    : baseVisible;
  const [dragId, setDragId] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState("");
  const labels = { ...defaultLabels, ...customLabels };
  const reduced = useReducedMotion();
  const allowed = (move: KSortableTreeMove) =>
    !disabled &&
    moveKSortableTree(nodes, move, { maxDepth }) !== nodes &&
    canMove?.(move) !== false;
  function toggle(nodeId: string) {
    const next = expanded.includes(nodeId)
      ? expanded.filter((value) => value !== nodeId)
      : [...expanded, nodeId];
    if (expandedIds === undefined) setInternalExpanded(next);
    onExpandedChange?.(next);
  }
  function commit(move: KSortableTreeMove) {
    if (!allowed(move)) return;
    onMove(move);
    if (move.parentId === null) setUngroupedExpanded(true);
    // Keep the moved row visible, including when its destination was collapsed.
    const ancestors: string[] = [];
    let parent = move.parentId;
    while (parent !== null) {
      ancestors.push(parent);
      parent = all.find(({ node }) => node.id === parent)?.parentId ?? null;
    }
    const next = [...new Set([...expanded, ...ancestors])];
    if (next.length !== expanded.length) {
      if (expandedIds === undefined) setInternalExpanded(next);
      onExpandedChange?.(next);
    }
    setAnnouncement(
      labels.moved(
        all.find(({ node }) => node.id === move.id)?.node.label ?? move.id,
      ),
    );
  }
  function moveForTarget(sourceId: string, target: Target): KSortableTreeMove {
    const source = all.find(({ node }) => node.id === sourceId);
    return {
      id: sourceId,
      parentId: target.parentId,
      index:
        target.index -
        (source?.parentId === target.parentId && source.index < target.index
          ? 1
          : 0),
    };
  }
  function targetAllowed(target: Target) {
    return dragId !== null && allowed(moveForTarget(dragId, target));
  }
  function actionsFor(entry: KSortableTreeEntry<T>): KMenuAction[] {
    const siblings = all.filter(
      (item) =>
        item.parentId === entry.parentId &&
        !(
          ungroupedLabel &&
          entry.parentId === null &&
          (item.node.children === undefined) !==
            (entry.node.children === undefined)
        ),
    );
    const position = siblings.findIndex(
      (item) => item.node.id === entry.node.id,
    );
    const action = (
      key: string,
      label: string,
      move: KSortableTreeMove | null,
    ): KMenuAction => ({
      id: key,
      label,
      separatorBefore: key === "up",
      iconContent: (
        <KIcon
          name={key === "up" ? "arrow-up" : "arrow-down"}
          strokeWidth={1.5}
        />
      ),
      disabled: !move || !allowed(move),
      onSelect: () => {
        if (move) commit(move);
      },
    });
    return [
      action(
        "up",
        labels.up,
        position > 0
          ? {
              id: entry.node.id,
              parentId: entry.parentId,
              index: siblings[position - 1]!.index,
            }
          : null,
      ),
      action(
        "down",
        labels.down,
        position < siblings.length - 1
          ? {
              id: entry.node.id,
              parentId: entry.parentId,
              index: siblings[position + 1]!.index,
            }
          : null,
      ),
      ...(() => {
        const destinations = all
          .filter(
            ({ node }) =>
              node.children !== undefined && node.id !== entry.parentId,
          )
          .map(({ node }) => ({
            node,
            move: moveForTarget(entry.node.id, {
              parentId: node.id,
              index: node.children!.length,
            }),
          }))
          .filter(({ move }) => allowed(move))
          .map(({ node, move }) => ({
            id: `to:${node.id}`,
            label: node.label,
            onSelect: () => commit(move),
          }));
        const rootMove = moveForTarget(entry.node.id, {
          parentId: null,
          index: nodes.length,
        });
        if (
          ungroupedLabel &&
          entry.parentId !== null &&
          entry.node.children === undefined &&
          allowed(rootMove)
        )
          destinations.push({
            id: "to:root",
            label: ungroupedLabel,
            onSelect: () => commit(rootMove),
          });
        return destinations.length
          ? [
              {
                id: "move-to",
                label: labels.moveTo,
                iconContent: <KIcon name="arrow-right" strokeWidth={1.5} />,
                children: destinations,
              },
            ]
          : [];
      })(),
    ];
  }

  return (
    <DragDropProvider
      onDragStart={({ operation }) =>
        setDragId(String(operation.source?.id ?? ""))
      }
      onDragEnd={({ operation, canceled }) => {
        setDragId(null);
        if (canceled || !operation.source || !operation.target) return;
        commit(
          moveForTarget(
            String(operation.source.id),
            operation.target.data as Target,
          ),
        );
      }}
    >
      <div
        ref={rootRef}
        className={`k-sortable-tree ${className ?? ""}`}
        style={
          {
            "--k-tree-row-content-height": `${rowHeight}px`,
            "--k-tree-min-row-height": `${minRowHeight ?? 0}px`,
          } as CSSProperties
        }
        data-drag-active={dragId !== null || undefined}
      >
        <div role="list" aria-label={ariaLabel}>
          <AnimatePresence initial={false}>
            {visible.map((entry) => {
              const fixed = entry.node.id === ungroupedId;
              const context = {
                node: entry.node,
                depth: entry.depth,
                expanded: fixed
                  ? ungroupedExpanded
                  : expanded.includes(entry.node.id),
              };
              const before = { parentId: entry.parentId, index: entry.index };
              const consumerActions = fixed
                ? []
                : (getActions?.(context) ?? []);
              const inside = {
                parentId: fixed ? null : entry.node.id,
                index: fixed
                  ? nodes.length
                  : (entry.node.children?.length ?? 0),
              };
              return (
                <TreeRow
                  key={entry.node.id}
                  entry={entry}
                  fixed={fixed}
                  expanded={context.expanded}
                  toggle={() =>
                    fixed
                      ? setUngroupedExpanded((value) => !value)
                      : toggle(entry.node.id)
                  }
                  actions={[
                    ...consumerActions.filter((action) => !action.destructive),
                    ...(fixed ? [] : actionsFor(entry)),
                    ...consumerActions
                      .filter((action) => action.destructive)
                      .map((action) => ({ ...action, separatorBefore: true })),
                  ]}
                  onMeasure={onMeasure}
                  disabled={disabled}
                  labels={labels}
                  duration={duration}
                >
                  <DropTarget
                    id={`${id}:before:${entry.node.id}`}
                    target={before}
                    active={!fixed && targetAllowed(before)}
                    label={labels.drop}
                    className="k-sortable-tree__before"
                  />
                  <DropTarget
                    id={`${id}:inside:${entry.node.id}`}
                    target={inside}
                    active={
                      entry.node.children !== undefined && targetAllowed(inside)
                    }
                    label={labels.drop}
                    className="k-sortable-tree__inside"
                  />
                  <div className="k-sortable-tree__content">
                    {renderContent?.(context) ?? (
                      <span className="k-sortable-tree__label">
                        {entry.node.label}
                      </span>
                    )}
                  </div>
                  {renderActions && !fixed && (
                    <div className="k-sortable-tree__actions">
                      {renderActions(context)}
                    </div>
                  )}
                </TreeRow>
              );
            })}
          </AnimatePresence>
        </div>
        {!nodes.length && (
          <div className="k-sortable-tree__empty">{labels.empty}</div>
        )}
        <DropTarget
          id={`${id}:end`}
          target={{ parentId: null, index: nodes.length }}
          active={targetAllowed({ parentId: null, index: nodes.length })}
          label={labels.root}
          className="k-sortable-tree__end"
        />
        <span
          className="k-sortable-tree__announcement"
          role="status"
          aria-live="polite"
        >
          {announcement}
        </span>
      </div>
      <DragOverlay disabled dropAnimation={reduced ? null : undefined}>
        {null}
      </DragOverlay>
    </DragDropProvider>
  );
}
