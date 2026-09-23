import { useState, type CSSProperties, type ReactNode } from "react";
import {
  KBadge,
  KButton,
  KIcon,
  KIconButton,
  KMenuButton,
  KOverflowMenu,
  KResponsiveDrawer,
  KSearchField,
  KSidebar,
  KSidebarBody,
  KSidebarExpandedContent,
  KSidebarFooter,
  KSidebarGroup,
  KSidebarHeader,
  KSidebarItem,
  KSidebarRailContent,
  KSidebarSeparator,
  KSidebarSubgroup,
  KSidebarToggle,
  type KIconName,
  type KSidebarMode,
} from "@k-design-system/ui";

const shellStyle: CSSProperties = {
  display: "grid",
  gridTemplateColumns: "auto minmax(0, 1fr)",
  width: "min(100%, 960px)",
  height: 660,
  overflow: "hidden",
  border: "1px solid var(--k-color-border-default)",
  borderRadius: "var(--k-radius-card)",
  background: "var(--k-color-surface-canvas)",
};

const workspaceStyle: CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 8,
  minWidth: 0,
};

const avatarStyle: CSSProperties = {
  display: "inline-flex",
  alignItems: "center",
  justifyContent: "center",
  width: 28,
  height: 28,
  flex: "0 0 auto",
  borderRadius: "var(--k-radius-control)",
  background: "var(--k-color-action-primary-background)",
  color: "var(--k-color-action-primary-foreground)",
  font: "600 12px/1 var(--k-font-family)",
};

interface DemoSidebarProps {
  initialMode?: KSidebarMode;
  onNavigate?: (label: string) => void;
  fullWidth?: boolean;
}

function DemoSidebar({
  initialMode = "expanded",
  onNavigate,
  fullWidth = false,
}: DemoSidebarProps) {
  const [mode, setMode] = useState<KSidebarMode>(initialMode);
  const [active, setActive] = useState("All issues");
  const navigate = (label: string) => {
    setActive(label);
    onNavigate?.(label);
  };
  const actionMenu = (label: string) => (
    <KOverflowMenu
      label={`${label} actions`}
      actions={[
        { id: "open", label: "Open in new tab", icon: "external-link" },
        { id: "copy", label: "Copy link", icon: "copy" },
        {
          id: "unpin",
          label: "Unpin",
          icon: "x",
          separatorBefore: true,
        },
      ]}
    />
  );
  const item = (
    label: string,
    icon: KIconName,
    options: {
      badge?: ReactNode;
      depth?: number;
      action?: boolean;
      trailing?: string;
    } = {},
  ) => (
    <KSidebarItem
      key={label}
      label={label}
      leading={<KIcon name={icon} />}
      badge={options.badge}
      trailing={options.trailing}
      action={options.action ? actionMenu(label) : undefined}
      depth={options.depth}
      active={active === label}
      onSelect={() => navigate(label)}
    />
  );
  return (
    <KSidebar
      mode={mode}
      onModeChange={setMode}
      label="Workspace navigation"
      style={
        fullWidth
          ? ({ "--k-sidebar-width": "100%" } as CSSProperties)
          : undefined
      }
    >
      <KSidebarHeader>
        <div style={{ ...workspaceStyle, justifyContent: "space-between" }}>
          <KMenuButton
            label="Orbit workspace"
            actions={[
              { id: "profile", label: "Account and profile", icon: "user" },
              {
                id: "workspace",
                label: "Workspace settings",
                icon: "settings",
              },
              {
                id: "sign-out",
                label: "Sign out",
                icon: "x",
                separatorBefore: true,
              },
            ]}
            triggerVariant="ghost"
            triggerClassName="k-sidebar-workspace-switcher"
            fullWidth
            triggerContent={
              <span className="k-sidebar-workspace-switcher__content">
                <span style={avatarStyle}>O</span>
                <span className="k-sidebar__expanded-only k-sidebar-workspace-switcher__label">
                  <strong>Orbit</strong>
                  <small>Design workspace</small>
                </span>
                <span className="k-sidebar__expanded-only">
                  <KIcon name="chevron-down" size={14} />
                </span>
              </span>
            }
          />
          <KSidebarExpandedContent>
            <KSidebarToggle />
          </KSidebarExpandedContent>
        </div>
        <KSidebarRailContent>
          <KSidebarToggle />
        </KSidebarRailContent>
      </KSidebarHeader>
      <KSidebarBody>
        <KSidebarGroup>
          {item("Inbox", "mail", {
            badge: <KBadge variant="primary">9</KBadge>,
            action: true,
          })}
          {item("My issues", "user")}
          {item("Calendar", "calendar")}
          {item("All issues", "check-check")}
        </KSidebarGroup>
        <KSidebarGroup
          label="Workspace"
          action={
            <KIconButton
              label="Add workspace item"
              icon="plus"
              onClick={() => undefined}
            />
          }
        >
          {item("Projects", "folder", {
            badge: <KBadge variant="secondary">99+</KBadge>,
            action: true,
          })}
          {item("Views", "sliders-horizontal")}
        </KSidebarGroup>
        <KSidebarGroup
          label="Teams"
          action={
            <KIconButton
              label="Add team"
              icon="plus"
              onClick={() => undefined}
            />
          }
        >
          <KSidebarSubgroup
            label="Knaack"
            leading={<KIcon name="users" />}
            action={actionMenu("Knaack")}
          >
            {item("Issues", "check-check", { depth: 1 })}
            {item("Cycles", "refresh-cw", { depth: 1 })}
            {item("Projects", "folder", { depth: 1 })}
            {item("Members", "users", {
              depth: 1,
              badge: <KBadge variant="secondary">99</KBadge>,
              action: true,
            })}
          </KSidebarSubgroup>
          <KSidebarSubgroup
            label="Product lab"
            leading={<KIcon name="users" />}
            action={actionMenu("Product lab")}
            defaultExpanded={false}
          >
            {item("Roadmap", "calendar", { depth: 1 })}
            {item("Research notes", "file-text", { depth: 1 })}
          </KSidebarSubgroup>
        </KSidebarGroup>
        <KSidebarGroup label="Pinned" collapsible>
          {item("KNAACK.IT", "folder", { action: true })}
          {item("PB-Hero", "folder", { action: true })}
          {item("Design system", "star", { action: true })}
          {item("Research", "search", { action: true })}
        </KSidebarGroup>
      </KSidebarBody>
      <KSidebarFooter>
        {item("Search", "search", { trailing: "/" })}
        <KSidebarSeparator />
        {item("Settings", "settings")}
      </KSidebarFooter>
    </KSidebar>
  );
}

function Content({ selection }: { selection: string }) {
  return (
    <main style={{ minWidth: 0, padding: 32 }}>
      <span style={{ color: "var(--k-color-text-muted)", fontSize: 12 }}>
        Workspace / Navigation
      </span>
      <h2
        style={{ margin: "12px 0", font: "600 22px/1.2 var(--k-font-family)" }}
      >
        {selection}
      </h2>
      <p style={{ color: "var(--k-color-text-muted)", maxWidth: 500 }}>
        Hover pinned rows to reveal their contextual actions. Collapse the
        sidebar to keep the same destinations in a compact icon rail.
      </p>
    </main>
  );
}

export function SidebarFixture({ initialMode = "expanded" }: DemoSidebarProps) {
  const [selection, setSelection] = useState("All issues");
  return (
    <div style={shellStyle}>
      <DemoSidebar initialMode={initialMode} onNavigate={setSelection} />
      <Content selection={selection} />
    </div>
  );
}

export function SidebarDrawerFixture() {
  const [open, setOpen] = useState(false);
  return (
    <div style={{ padding: 24 }}>
      <KButton onClick={() => setOpen(true)}>Open navigation</KButton>
      <KResponsiveDrawer
        open={open}
        onOpenChange={setOpen}
        side="left"
        title="Workspace navigation"
        description="The same sidebar content composed inside the existing drawer."
        contentInset={false}
      >
        <div
          style={{
            height: "100%",
            overflow: "hidden",
          }}
        >
          <DemoSidebar fullWidth />
        </div>
      </KResponsiveDrawer>
    </div>
  );
}

export function SettingsSidebarFixture() {
  const [active, setActive] = useState("Profile");
  const settingsItem = (label: string, icon: KIconName) => (
    <KSidebarItem
      key={label}
      label={label}
      leading={<KIcon name={icon} />}
      active={active === label}
      onSelect={() => setActive(label)}
    />
  );
  return (
    <div style={shellStyle}>
      <KSidebar label="Settings navigation">
        <KSidebarHeader>
          <KSidebarItem
            label="Back to app"
            leading={<KIcon name="arrow-left" />}
            onSelect={() => undefined}
          />
          <KSearchField
            aria-label="Search settings"
            placeholder="Search settings…"
          />
        </KSidebarHeader>
        <KSidebarBody>
          <KSidebarGroup label="Personal">
            {settingsItem("Preferences", "sliders-horizontal")}
            {settingsItem("Profile", "user")}
            {settingsItem("Notifications", "bell")}
            {settingsItem("Security & access", "lock")}
          </KSidebarGroup>
          <KSidebarGroup label="Workspace">
            {settingsItem("Workspace", "users")}
            {settingsItem("Issues & editor", "check-check")}
            {settingsItem("Agents & integrations", "settings")}
          </KSidebarGroup>
          <KSidebarGroup label="System">
            {settingsItem("Data & advanced", "database")}
            {settingsItem("Administration", "settings")}
          </KSidebarGroup>
        </KSidebarBody>
      </KSidebar>
      <Content selection={active} />
    </div>
  );
}
