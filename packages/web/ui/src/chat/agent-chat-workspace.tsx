import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { KAnimatedIcon } from "../primitives/animated-icon.js";
import { KButton } from "../primitives/button.js";
import { KBottomSheet, KDesktopDialog } from "../overlays/overlay.js";
import { AgentAvatarInfo } from "./agent-avatar-info.js";

export interface KAgentChatWorkspaceLabels {
  agents: string;
  closeAgents: string;
}

export interface KAgentChatWorkspaceProps {
  sidebar:
    ReactNode | ((controls: KAgentChatWorkspaceSidebarControls) => ReactNode);
  avatar: ReactNode;
  avatarLabel?: ReactNode;
  avatarPopover?: ReactNode;
  avatarPopoverLabel?: string;
  contentMaxWidth?: number | "full";
  rightSidebar?: ReactNode;
  rightSidebarOpen?: boolean;
  rightSidebarWidth?: number;
  rightSidebarTitle?: string;
  onRightSidebarOpenChange?: (open: boolean) => void;
  title: ReactNode;
  status?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
  composer: ReactNode;
  labels?: Partial<KAgentChatWorkspaceLabels>;
  className?: string;
  avatarSizeMobile?: number;
  avatarSizeDesktop?: number;
  avatarSizeCompact?: number;
  avatarBackdropBlur?: number;
  avatarTransitionDuration?: number;
  showTitle?: boolean;
  conversationEmpty?: boolean;
  avatarSizeEmpty?: number;
  debugAvatarBounds?: boolean;
  sidebarCollapsed?: boolean;
  defaultSidebarCollapsed?: boolean;
  onSidebarCollapsedChange?: (collapsed: boolean) => void;
  sidebarToggle?: (controls: {
    collapsed: boolean;
    toggle: () => void;
  }) => ReactNode;
}

export interface KAgentChatWorkspaceSidebarControls {
  close: () => void;
}

const defaultLabels: KAgentChatWorkspaceLabels = {
  agents: "Agents",
  closeAgents: "Close agents",
};

/**
 * Full-view agent conversation composition. Consumers own all agent, session,
 * message, composer, label, and action state supplied through its slots.
 */
export function KAgentChatWorkspace({
  sidebar,
  avatar,
  avatarLabel,
  avatarPopover,
  avatarPopoverLabel = "Account and usage",
  contentMaxWidth = 920,
  rightSidebar,
  rightSidebarOpen = false,
  rightSidebarWidth,
  rightSidebarTitle = "Details",
  onRightSidebarOpenChange,
  title,
  status,
  actions,
  children,
  composer,
  labels: labelOverrides,
  className,
  sidebarCollapsed,
  defaultSidebarCollapsed = false,
  onSidebarCollapsedChange,
  sidebarToggle,
  avatarSizeMobile = 80,
  avatarSizeDesktop = 104,
  avatarSizeCompact = 52,
  avatarBackdropBlur = 12,
  avatarTransitionDuration = 180,
  showTitle = false,
  conversationEmpty = false,
  avatarSizeEmpty = 240,
  debugAvatarBounds = false,
}: KAgentChatWorkspaceProps) {
  const labels = { ...defaultLabels, ...labelOverrides };
  const [compact, setCompact] = useState(false);
  const [dockRight, setDockRight] = useState(false);
  useEffect(() => {
    const viewport = window.visualViewport;
    const update = () => {
      setDockRight(window.innerWidth >= 1024);
      setCompact(
        (viewport?.height ?? window.innerHeight) < 620 ||
          window.innerHeight - (viewport?.height ?? window.innerHeight) > 150,
      );
    };
    update();
    viewport?.addEventListener("resize", update);
    window.addEventListener("resize", update);
    return () => {
      viewport?.removeEventListener("resize", update);
      window.removeEventListener("resize", update);
    };
  }, []);
  const [agentsOpen, setAgentsOpen] = useState(false);
  const [internalCollapsed, setInternalCollapsed] = useState(
    defaultSidebarCollapsed,
  );
  const collapsed = sidebarCollapsed ?? internalCollapsed;
  const toggleSidebar = () => {
    setInternalCollapsed(!collapsed);
    onSidebarCollapsedChange?.(!collapsed);
  };
  const agentsTriggerRef = useRef<HTMLButtonElement>(null);
  const [desktop, setDesktop] = useState(
    () =>
      typeof window !== "undefined" &&
      typeof window.matchMedia === "function" &&
      window.matchMedia("(min-width: 768px)").matches,
  );
  useEffect(() => {
    if (
      typeof window === "undefined" ||
      typeof window.matchMedia !== "function"
    )
      return;
    const media = window.matchMedia("(min-width: 768px)");
    const update = () => {
      setDesktop(media.matches);
      if (media.matches) setAgentsOpen(false);
    };
    update();
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  const changeAgentsOpen = (open: boolean) => {
    setAgentsOpen(open);
    if (!open) requestAnimationFrame(() => agentsTriggerRef.current?.focus());
  };
  const sidebarContent = () =>
    typeof sidebar === "function"
      ? sidebar({ close: () => changeAgentsOpen(false) })
      : sidebar;

  return (
    <main
      data-sidebar-collapsed={collapsed}
      data-right-sidebar-open={Boolean(
        rightSidebar && rightSidebarOpen && dockRight,
      )}
      data-show-title={showTitle}
      data-compact={compact}
      data-conversation-empty={conversationEmpty}
      data-debug-avatar-bounds={debugAvatarBounds}
      style={
        {
          "--k-agent-chat-workspace-avatar-mobile-size": `${avatarSizeMobile}px`,
          "--k-agent-chat-workspace-avatar-desktop-size": `${avatarSizeDesktop}px`,
          "--k-agent-chat-workspace-avatar-compact-size": `${avatarSizeCompact}px`,
          "--k-agent-chat-workspace-avatar-blur": `${avatarBackdropBlur}px`,
          "--k-agent-chat-workspace-avatar-transition": `${avatarTransitionDuration}ms`,
          "--k-agent-chat-workspace-avatar-empty-size": `${avatarSizeEmpty}px`,
          "--k-agent-chat-workspace-content-max-width":
            contentMaxWidth === "full" ? "100%" : `${contentMaxWidth}px`,
          ...(rightSidebarWidth !== undefined
            ? {
                "--k-agent-chat-workspace-right-sidebar-width": `${rightSidebarWidth}px`,
              }
            : {}),
        } as CSSProperties
      }
      className={["k-agent-chat-workspace", className]
        .filter(Boolean)
        .join(" ")}
    >
      {desktop ? (
        <aside
          className="k-agent-chat-workspace__sidebar"
          aria-label={labels.agents}
          inert={collapsed}
          aria-hidden={collapsed}
        >
          <div className="k-agent-chat-workspace__toolbar" aria-hidden="true" />
          {sidebarContent()}
        </aside>
      ) : null}

      <section className="k-agent-chat-workspace__chat">
        <div className="k-agent-chat-workspace__toolbar">
          {sidebarToggle && desktop ? (
            sidebarToggle({ collapsed, toggle: toggleSidebar })
          ) : (
            <KButton
              ref={agentsTriggerRef}
              className="k-agent-chat-workspace__agents-trigger"
              variant="ghost"
              onClick={() => (desktop ? toggleSidebar() : setAgentsOpen(true))}
              aria-haspopup={desktop ? undefined : "dialog"}
              aria-label={
                desktop && !collapsed ? labels.closeAgents : labels.agents
              }
              aria-expanded={desktop ? !collapsed : agentsOpen}
            >
              <KAnimatedIcon
                name={desktop && !collapsed ? "arrow-left" : "arrow-right"}
                aria-hidden="true"
              />
            </KButton>
          )}
          {actions ? (
            <div className="k-agent-chat-workspace__actions">{actions}</div>
          ) : null}
        </div>

        <div className="k-agent-chat-workspace__stage">
          <div className="k-agent-chat-workspace__conversation">{children}</div>
          <header className="k-agent-chat-workspace__identity">
            <AgentAvatarInfo
              avatar={avatar}
              label={avatarLabel}
              content={avatarPopover}
              accessibleLabel={avatarPopoverLabel}
            />
            <h1
              className={
                showTitle
                  ? "k-agent-chat-workspace__title"
                  : "k-visually-hidden"
              }
            >
              {title}
            </h1>
            {status ? (
              <div className="k-agent-chat-workspace__status">{status}</div>
            ) : null}
          </header>
        </div>
        <footer className="k-agent-chat-workspace__composer">{composer}</footer>
      </section>

      {dockRight && rightSidebar ? (
        <aside
          className="k-agent-chat-workspace__right-sidebar"
          aria-label={rightSidebarTitle}
          inert={!rightSidebarOpen}
          aria-hidden={!rightSidebarOpen}
        >
          <div>{rightSidebar}</div>
        </aside>
      ) : null}
      {!dockRight && rightSidebar ? (
        <KBottomSheet
          open={rightSidebarOpen}
          onOpenChange={(open) => onRightSidebarOpenChange?.(open)}
          title={rightSidebarTitle}
        >
          {rightSidebar}
        </KBottomSheet>
      ) : null}

      {!desktop ? (
        <KDesktopDialog
          open={agentsOpen}
          onOpenChange={changeAgentsOpen}
          title={desktop ? null : labels.agents}
          closeLabel={labels.closeAgents}
          className="k-responsive-drawer k-responsive-drawer--left k-agent-chat-workspace__drawer"
          contentInset={false}
        >
          {sidebarContent()}
        </KDesktopDialog>
      ) : null}
    </main>
  );
}
