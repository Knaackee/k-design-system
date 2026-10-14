import { Accessibility, PointerActivationConstraints } from "@dnd-kit/dom";
import {
  DragDropProvider,
  PointerSensor,
  useDragDropManager,
} from "@dnd-kit/react";
import { isSortable, useSortable } from "@dnd-kit/react/sortable";
import {
  useEffect,
  useId,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { KAvatar } from "../basic-components.js";
import { KIcon } from "../primitives/icon.js";
import { useAgentSwitcherReorder } from "./use-agent-switcher-reorder.js";

export type KAgentConnection = "online" | "offline" | "unknown" | "sleeping";
export type KAgentActivityState = "idle" | "working" | "needs-input";

export interface KAgentSwitcherItem {
  id: string;
  name: string;
  avatar?: ReactNode;
  nameContent?: ReactNode;
  statusContent?: ReactNode;
  badgeContent?: ReactNode;
  semanticLabel?: string;
  connection?: KAgentConnection;
  activity?: KAgentActivityState;
  unread?: number;
  connectionColor?: string;
  statusColor?: string;
  badgeColor?: string;
  badgeForeground?: string;
  selectedColor?: string;
  showName?: boolean;
  /** Settings rows keep controls outside the selection/drag button. */
  controlContent?: ReactNode;
  reorderable?: boolean;
}

export interface KAgentSwitcherLabels {
  agents: string;
  connectionOnline: string;
  connectionOffline: string;
  connectionUnknown: string;
  connectionSleeping: string;
  activityIdle: string;
  activityWorking: string;
  activityNeedsInput: string;
  connectionPrefix: string;
  activityPrefix: string;
  unreadMessages: (count: number) => string;
  reorderInstruction: string;
  reorderInstructionVertical: string;
  reorderAnnouncement: (
    name: string,
    position: number,
    count: number,
  ) => string;
}

export interface KAgentSwitcherProps {
  items: readonly KAgentSwitcherItem[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onManage?: () => void;
  manageLabel?: string;
  labels?: Partial<KAgentSwitcherLabels>;
  onReorder?: (ids: string[]) => void;
  onLongPress?: (id: string) => void;
  /** Layout axis. Horizontal preserves the compact strip used by existing consumers. */
  orientation?: "horizontal" | "vertical";
  variant?: "switcher" | "settings";
}

const defaultLabels: KAgentSwitcherLabels = {
  agents: "Agents",
  connectionOnline: "Online",
  connectionOffline: "Offline",
  connectionUnknown: "Unknown",
  connectionSleeping: "Sleeping",
  activityIdle: "Idle",
  activityWorking: "Working",
  activityNeedsInput: "Needs input",
  connectionPrefix: "Connection",
  activityPrefix: "Activity",
  unreadMessages: (count) =>
    `${count} unread ${count === 1 ? "message" : "messages"}`,
  reorderInstruction:
    "Long-press and drag to reorder. With the keyboard, use Alt plus Left or Right arrow.",
  reorderInstructionVertical:
    "Long-press and drag to reorder. With the keyboard, use Alt plus Up or Down arrow.",
  reorderAnnouncement: (name, position, count) =>
    `${name} moved to position ${position} of ${count}.`,
};

type SwitcherItemStyle = CSSProperties & {
  "--k-agent-connection-color"?: string;
  "--k-agent-status-color"?: string;
  "--k-agent-badge-color"?: string;
  "--k-agent-badge-foreground"?: string;
  "--k-agent-selected-color"?: string;
};

const agentSwitcherSensors = [
  PointerSensor.configure({
    activationConstraints: [
      new PointerActivationConstraints.Delay({
        value: 450,
        tolerance: 8,
      }),
    ],
  }),
];

interface AgentDragData {
  id: string;
  name: string;
}

function AgentSwitcherSlot({
  item,
  index,
  reorderable,
  style,
  children,
}: {
  item: KAgentSwitcherItem;
  index: number;
  reorderable: boolean;
  style: SwitcherItemStyle;
  children: (handleRef: (element: Element | null) => void) => ReactNode;
}) {
  const { ref, handleRef, isDragging, isDropping } = useSortable<AgentDragData>(
    {
      id: item.id,
      index,
      group: "k-agent-switcher",
      type: "k-agent-switcher-item",
      disabled: !reorderable,
      data: { id: item.id, name: item.name },
    },
  );
  return (
    <li
      ref={ref}
      className="k-agent-switcher__item"
      data-agent-id={item.id}
      data-dragging={isDragging || undefined}
      data-dropping={isDropping || undefined}
      style={style}
    >
      {children(handleRef)}
    </li>
  );
}

function ExternalOrderGuard({
  sourceIds,
  ids,
}: {
  sourceIds: readonly string[] | undefined;
  ids: readonly string[];
}) {
  const manager = useDragDropManager();
  const sourceKey = sourceIds ? JSON.stringify(sourceIds) : undefined;
  const idsKey = JSON.stringify(ids);
  useEffect(() => {
    if (sourceKey && sourceKey !== idsKey) {
      manager?.actions.stop({ canceled: true });
    }
  }, [idsKey, manager, sourceKey]);
  return null;
}

/**
 * Controlled agent selection strip. Supplying `onReorder` opts into delayed
 * pointer drag and Alt+Arrow keyboard reordering; apply the emitted full ID
 * order to `items`. Custom visual slots should provide `semanticLabel`.
 */
export function KAgentSwitcher({
  items,
  selectedId,
  onSelect,
  onManage,
  manageLabel = "Agenten auswählen",
  labels: labelOverrides,
  onReorder,
  onLongPress,
  orientation = "horizontal",
  variant = "switcher",
}: KAgentSwitcherProps) {
  const labels = { ...defaultLabels, ...labelOverrides };
  const instructionsId = useId();
  const ids = items
    .filter((item) => variant !== "settings" || item.reorderable !== false)
    .map((item) => item.id);
  const dragSourceIds = useRef<readonly string[] | undefined>(undefined);
  const [guardSourceIds, setGuardSourceIds] = useState<
    readonly string[] | undefined
  >(undefined);
  const reorder = useAgentSwitcherReorder({
    ids,
    orientation,
    onReorder:
      onReorder && variant === "settings"
        ? (ordered) =>
            onReorder([
              ...ordered,
              ...items
                .filter((item) => item.reorderable === false)
                .map((item) => item.id),
            ])
        : onReorder,
    onLongPress,
    feedback: {
      announce: labels.reorderAnnouncement,
    },
  });
  const connectionLabels: Record<KAgentConnection, string> = {
    online: labels.connectionOnline,
    offline: labels.connectionOffline,
    unknown: labels.connectionUnknown,
    sleeping: labels.connectionSleeping,
  };
  const activityLabels: Record<KAgentActivityState, string> = {
    idle: labels.activityIdle,
    working: labels.activityWorking,
    "needs-input": labels.activityNeedsInput,
  };

  return (
    <DragDropProvider
      sensors={agentSwitcherSensors}
      plugins={(defaults) =>
        defaults.filter((plugin) => plugin !== Accessibility)
      }
      onDragStart={({ operation }) => {
        const source = operation.source?.data as AgentDragData | undefined;
        if (!source) return;
        const sourceIds = [...ids];
        dragSourceIds.current = sourceIds;
        setGuardSourceIds(sourceIds);
        reorder.startReorder(source.id, source.name);
      }}
      onDragEnd={({ operation, canceled }) => {
        const source = operation.source?.data as AgentDragData | undefined;
        const target = operation.target?.data as AgentDragData | undefined;
        const sourceIds = dragSourceIds.current;
        dragSourceIds.current = undefined;
        setGuardSourceIds(undefined);
        if (!source || !sourceIds) return;
        reorder.finishReorder(
          source.id,
          source.name,
          // Optimistic sorting can make the source its own drop target.
          isSortable(operation.source)
            ? sourceIds[
                Math.max(
                  0,
                  Math.min(sourceIds.length - 1, operation.source.index),
                )
              ]
            : target?.id,
          sourceIds,
          canceled,
        );
      }}
    >
      <ExternalOrderGuard sourceIds={guardSourceIds} ids={ids} />
      <nav
        ref={reorder.rootRef}
        className="k-agent-switcher"
        data-orientation={orientation}
        data-variant={variant}
        aria-label={labels.agents}
        onPointerMoveCapture={reorder.pointerMove}
      >
        <ul className="k-agent-switcher__list">
          {items.map((item, index) => {
            const selected = item.id === selectedId;
            const unread =
              item.unread === undefined ? undefined : Math.max(0, item.unread);
            const generatedLabel = [
              item.name,
              item.connection
                ? `${labels.connectionPrefix}: ${connectionLabels[item.connection]}`
                : undefined,
              item.activity
                ? `${labels.activityPrefix}: ${activityLabels[item.activity]}`
                : undefined,
              unread && unread > 0 ? labels.unreadMessages(unread) : undefined,
            ]
              .filter(Boolean)
              .join(", ");
            const itemStyle: SwitcherItemStyle = {
              "--k-agent-connection-color": item.connectionColor,
              "--k-agent-status-color": item.statusColor,
              "--k-agent-badge-color": item.badgeColor,
              "--k-agent-badge-foreground": item.badgeForeground,
              "--k-agent-selected-color": item.selectedColor,
            };

            return (
              <AgentSwitcherSlot
                key={item.id}
                item={item}
                index={index}
                reorderable={Boolean(onReorder) && item.reorderable !== false}
                style={itemStyle}
              >
                {(handleRef) =>
                  variant === "settings" ? (
                    <div className="k-agent-switcher__settings-row">
                      <span
                        className="k-agent-switcher__settings-avatar"
                        aria-hidden="true"
                      >
                        {item.avatar ?? (
                          <KAvatar alt={item.name} size="small" />
                        )}
                      </span>
                      <span className="k-agent-switcher__settings-name">
                        {item.nameContent ?? item.name}
                      </span>
                      {item.controlContent}
                      <button
                        ref={handleRef}
                        type="button"
                        className="k-agent-switcher__settings-handle"
                        aria-label={`${item.name}: ${labels.reorderInstructionVertical}`}
                        aria-describedby={instructionsId}
                        disabled={!onReorder || item.reorderable === false}
                        onPointerDown={(event) =>
                          reorder.pointerDown(event, item.id)
                        }
                        onPointerUp={reorder.pointerUp}
                        onPointerCancel={reorder.cancelPointer}
                        onPointerLeave={reorder.pointerLeave}
                        onContextMenu={(event) => event.preventDefault()}
                        onKeyDown={(event) => {
                          if (!onReorder || !event.altKey) return;
                          if (
                            event.key === "ArrowUp" ||
                            event.key === "ArrowDown"
                          ) {
                            event.preventDefault();
                            reorder.keyboardMove(
                              item.id,
                              item.name,
                              event.key === "ArrowUp" ? -1 : 1,
                            );
                          }
                        }}
                      >
                        <KIcon name="grip-vertical" />
                      </button>
                    </div>
                  ) : (
                    <button
                      ref={handleRef}
                      type="button"
                      className="k-agent-switcher__button"
                      aria-label={item.semanticLabel ?? generatedLabel}
                      aria-pressed={selected}
                      aria-describedby={onReorder ? instructionsId : undefined}
                      onClick={() => {
                        if (!reorder.consumeClick(item.id)) onSelect(item.id);
                      }}
                      onPointerDown={(event) =>
                        reorder.pointerDown(event, item.id)
                      }
                      onPointerUp={reorder.pointerUp}
                      onPointerCancel={reorder.cancelPointer}
                      onPointerLeave={reorder.pointerLeave}
                      onContextMenu={(event) => {
                        if (onReorder || onLongPress) event.preventDefault();
                      }}
                      onKeyDown={(event) => {
                        if (!onReorder || !event.altKey) return;
                        const previousKey =
                          orientation === "vertical" ? "ArrowUp" : "ArrowLeft";
                        const nextKey =
                          orientation === "vertical"
                            ? "ArrowDown"
                            : "ArrowRight";
                        if (
                          event.key === previousKey ||
                          event.key === nextKey
                        ) {
                          event.preventDefault();
                          reorder.keyboardMove(
                            item.id,
                            item.name,
                            event.key === previousKey ? -1 : 1,
                          );
                        }
                      }}
                    >
                      <span className="k-agent-switcher__avatar-shell">
                        {item.avatar == null ? (
                          <KAvatar
                            className="k-agent-switcher__avatar"
                            alt={item.name}
                            size="large"
                          />
                        ) : (
                          <span
                            className="k-agent-switcher__avatar k-agent-switcher__avatar-custom"
                            aria-hidden="true"
                          >
                            {item.avatar}
                          </span>
                        )}
                        {item.connection ? (
                          <span
                            className="k-agent-switcher__connection"
                            data-connection={item.connection}
                            aria-hidden="true"
                            title={connectionLabels[item.connection]}
                          ></span>
                        ) : null}
                        {item.badgeContent != null || (unread && unread > 0) ? (
                          <span
                            className="k-agent-switcher__unread"
                            aria-hidden="true"
                          >
                            {item.badgeContent ??
                              (unread! > 99 ? "99+" : unread)}
                          </span>
                        ) : null}
                      </span>
                      {item.showName === false ? null : (
                        <span
                          className="k-agent-switcher__name"
                          aria-hidden="true"
                        >
                          {item.nameContent ?? item.name}
                        </span>
                      )}
                      {item.statusContent != null || item.activity ? (
                        <span
                          className="k-agent-switcher__activity-label"
                          data-activity={item.activity}
                          aria-hidden="true"
                        >
                          {item.statusContent ?? activityLabels[item.activity!]}
                        </span>
                      ) : null}
                    </button>
                  )
                }
              </AgentSwitcherSlot>
            );
          })}
          {onManage ? (
            <li className="k-agent-switcher__item">
              <button
                type="button"
                className="k-agent-switcher__button k-agent-switcher__manage"
                aria-label={manageLabel}
                onClick={onManage}
              >
                <span
                  className="k-agent-switcher__manage-icon"
                  aria-hidden="true"
                >
                  <KIcon name="user-plus" />
                </span>
                <span className="k-agent-switcher__name">{manageLabel}</span>
              </button>
            </li>
          ) : null}
        </ul>
        {onReorder ? (
          <p id={instructionsId} className="k-agent-switcher__sr-only">
            {orientation === "vertical"
              ? labels.reorderInstructionVertical
              : labels.reorderInstruction}
          </p>
        ) : null}
        <p className="k-agent-switcher__sr-only" aria-live="polite">
          {reorder.announcement}
        </p>
      </nav>
    </DragDropProvider>
  );
}
