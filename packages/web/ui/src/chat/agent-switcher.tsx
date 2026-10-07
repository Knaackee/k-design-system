import { useId, type CSSProperties, type ReactNode } from "react";
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
}: KAgentSwitcherProps) {
  const labels = { ...defaultLabels, ...labelOverrides };
  const instructionsId = useId();
  const ids = items.map((item) => item.id);
  const reorder = useAgentSwitcherReorder({
    ids,
    onReorder,
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
    <nav
      ref={reorder.rootRef}
      className="k-agent-switcher"
      aria-label={labels.agents}
    >
      <ul className="k-agent-switcher__list">
        {items.map((item) => {
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
            <li
              key={item.id}
              className="k-agent-switcher__item"
              data-agent-id={item.id}
              data-dragging={reorder.draggingId === item.id || undefined}
              data-drag-over={reorder.overId === item.id || undefined}
              style={itemStyle}
            >
              <button
                type="button"
                className="k-agent-switcher__button"
                aria-label={item.semanticLabel ?? generatedLabel}
                aria-pressed={selected}
                aria-describedby={onReorder ? instructionsId : undefined}
                onClick={() => {
                  if (!reorder.consumeClick(item.id)) onSelect(item.id);
                }}
                onPointerDown={(event) =>
                  reorder.pointerDown(event, item.id, item.name)
                }
                onPointerMove={reorder.pointerMove}
                onPointerUp={reorder.pointerUp}
                onPointerCancel={reorder.cancel}
                onPointerLeave={reorder.pointerLeave}
                onContextMenu={(event) => {
                  if (onReorder || onLongPress) event.preventDefault();
                }}
                onKeyDown={(event) => {
                  if (event.key === "Escape" && reorder.draggingId) {
                    event.preventDefault();
                    reorder.cancel();
                    return;
                  }
                  if (!onReorder || !event.altKey) return;
                  if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
                    event.preventDefault();
                    reorder.keyboardMove(
                      item.id,
                      item.name,
                      event.key === "ArrowLeft" ? -1 : 1,
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
                      {item.badgeContent ?? (unread! > 99 ? "99+" : unread)}
                    </span>
                  ) : null}
                </span>
                {item.showName === false ? null : (
                  <span className="k-agent-switcher__name" aria-hidden="true">
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
            </li>
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
          {labels.reorderInstruction}
        </p>
      ) : null}
      <p className="k-agent-switcher__sr-only" aria-live="polite">
        {reorder.announcement}
      </p>
    </nav>
  );
}
