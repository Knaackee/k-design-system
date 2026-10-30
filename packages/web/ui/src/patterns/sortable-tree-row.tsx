import { useDraggable, useDroppable } from "@dnd-kit/react";
import {
  PointerSensor,
  PointerActivationConstraints,
  KeyboardSensor,
} from "@dnd-kit/dom";
import { motion, useReducedMotion } from "motion/react";
import { useEffect, useRef, type CSSProperties, type ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";
import type { KSortableTreeEntry } from "./sortable-tree-model.js";
import type { KSortableTreeLabels } from "./sortable-tree.js";
export type Target = { parentId: string | null; index: number };
const treeSensors = [
  PointerSensor.configure({
    activationConstraints: () => [
      new PointerActivationConstraints.Delay({ value: 300, tolerance: 8 }),
    ],
  }),
  KeyboardSensor,
];

export function DropTarget({
  target,
  id,
  active,
  label,
  children,
  className,
}: {
  target: Target;
  id: string;
  active: boolean;
  label: string;
  children?: ReactNode;
  className?: string;
}) {
  const { ref, isDropTarget } = useDroppable({
    id,
    type: "k-tree-target",
    accept: "k-tree-node",
    disabled: !active,
    data: target,
  });
  return (
    <div
      ref={ref}
      className={`k-sortable-tree__drop ${className ?? ""}`}
      data-available={active || undefined}
      data-over={(isDropTarget && active) || undefined}
    >
      {children}
      <span className="k-sortable-tree__drop-label" aria-hidden="true">
        {label}
      </span>
    </div>
  );
}

export function TreeRow<T>({
  entry,
  expanded,
  toggle,
  actions,
  children,
  disabled,
  labels,
  duration,
  onMeasure,
  fixed = false,
}: {
  entry: KSortableTreeEntry<T>;
  expanded: boolean;
  toggle: () => void;
  actions: readonly KMenuAction[];
  children: ReactNode;
  disabled: boolean;
  labels: KSortableTreeLabels;
  duration: number;
  onMeasure: (id: string, height: number | null) => void;
  fixed?: boolean;
}) {
  const contentRef = useRef<HTMLDivElement>(null);
  const pressedAt = useRef(0);
  useEffect(() => {
    if (!contentRef.current) return;
    const observer = new ResizeObserver(([entry]) => {
      if (entry) onMeasure(entryId, Math.ceil(entry.contentRect.height));
    });
    const entryId = entry.node.id;
    observer.observe(contentRef.current);
    return () => {
      observer.disconnect();
      onMeasure(entryId, null);
    };
  }, [entry.node.id, onMeasure]);
  const { ref, handleRef, isDragging } = useDraggable({
    id: entry.node.id,
    type: "k-tree-node",
    disabled: disabled || fixed,
    sensors: treeSensors,
    data: { id: entry.node.id },
  });
  const reduced = useReducedMotion();
  return (
    <motion.div
      layout={!reduced}
      transition={{ duration: reduced ? 0 : duration }}
      initial={{ opacity: reduced ? 1 : 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="k-sortable-tree__item"
      role="listitem"
      style={{ "--k-tree-depth": entry.depth } as CSSProperties}
      data-node-id={entry.node.id}
      data-depth={entry.depth}
    >
      <div
        ref={fixed ? undefined : ref}
        className="k-sortable-tree__row"
        data-dragging={isDragging || undefined}
        data-group={entry.node.children !== undefined || undefined}
        data-fixed={fixed || undefined}
        data-expanded={entry.node.children !== undefined ? expanded : undefined}
      >
        {entry.node.children !== undefined && (
          <KButton
            variant="ghost"
            className="k-sortable-tree__toggle"
            disabled={disabled}
            aria-label={`${expanded ? labels.collapse : labels.expand} ${entry.node.label}`}
            aria-expanded={expanded}
            onClick={toggle}
            children={null}
          />
        )}
        <div ref={contentRef} className="k-sortable-tree__row-layout">
          <KButton
            ref={fixed ? undefined : handleRef}
            variant="ghost"
            className="k-sortable-tree__handle k-icon-button"
            disabled={disabled}
            aria-label={`${fixed ? (expanded ? labels.collapse : labels.expand) : labels.drag} ${entry.node.label}`}
            title={`${fixed ? (expanded ? labels.collapse : labels.expand) : labels.drag} ${entry.node.label}`}
            aria-expanded={
              entry.node.children !== undefined ? expanded : undefined
            }
            onPointerDown={() => {
              pressedAt.current = performance.now();
            }}
            onClick={(event) => {
              const shortClick =
                event.detail === 0 ||
                performance.now() - pressedAt.current < 300;
              if (
                shortClick &&
                !event.defaultPrevented &&
                !isDragging &&
                entry.node.children !== undefined
              )
                toggle();
            }}
          >
            <KIcon name="grip-vertical" strokeWidth={1.5} />
          </KButton>
          {children}
          {!fixed && (
            <KMenuButton
              label={`${labels.move} ${entry.node.label}`}
              triggerContent={<KIcon name="ellipsis" strokeWidth={1.5} />}
              overflow
              align="end"
              disabled={disabled}
              actions={actions}
            />
          )}
        </div>
      </div>
    </motion.div>
  );
}
