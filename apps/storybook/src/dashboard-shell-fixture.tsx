import { useEffect, useLayoutEffect, useRef, useState } from "react";
import {
  KBadge,
  KBottomSheet,
  KBreadcrumb,
  KButton,
  KCard,
  KField,
  KIcon,
  KIconButton,
  KInput,
  KResponsiveDrawer,
  KSidebar,
  KSidebarBody,
  KSidebarFooter,
  KSidebarGroup,
  KSidebarHeader,
  KSidebarItem,
  KSidebarToggle,
  KStack,
  KText,
  KThemeSwitcher,
  type KThemeMode,
  type KSidebarMode,
} from "@k-design-system/ui";
import { SettingsPageFixture } from "./settings-page-fixture.js";
import "./dashboard-shell.css";

const projects = [
  { name: "Website refresh", status: "In progress" },
  { name: "Customer portal", status: "In review" },
  { name: "Mobile app", status: "Planned" },
];

export function DashboardShellFixture({
  initialInspector = false,
  initialMode = "rail",
}: { initialInspector?: boolean; initialMode?: KSidebarMode } = {}) {
  const root = useRef<HTMLDivElement>(null);
  const detailsButton = useRef<HTMLButtonElement>(null);
  const navigationButton = useRef<HTMLButtonElement>(null);
  const [width, setWidth] = useState(() => window.innerWidth);
  const [mode, setMode] = useState<KSidebarMode>(initialMode);
  const [page, setPage] = useState<"Overview" | "Projects" | "Detail">(
    "Overview",
  );
  const [selected, setSelected] = useState(projects[0]!);
  const [settings, setSettings] = useState(false);
  const [navigationOpen, setNavigationOpen] = useState(false);
  const [inspector, setInspector] = useState(initialInspector);
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [themeMode, setThemeMode] = useState<KThemeMode>("system");
  const [systemDark, setSystemDark] = useState(
    () => matchMedia("(prefers-color-scheme: dark)").matches,
  );
  const theme =
    themeMode === "system" ? (systemDark ? "dark" : "light") : themeMode;
  useEffect(() => {
    const media = matchMedia("(prefers-color-scheme: dark)");
    const update = () => setSystemDark(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  useEffect(() => {
    // Portalled overlays inherit the preview document's theme.
    const previous = document.documentElement.dataset.theme;
    document.documentElement.dataset.theme = theme;
    return () => {
      if (previous === undefined) delete document.documentElement.dataset.theme;
      else document.documentElement.dataset.theme = previous;
    };
  }, [theme]);
  const mobile = width < 600;
  useLayoutEffect(() => {
    if (!root.current) return;
    const observer = new ResizeObserver(([entry]) => {
      if (entry) setWidth(entry.contentRect.width);
    });
    observer.observe(root.current);
    return () => observer.disconnect();
  }, []);
  useEffect(() => {
    if (!mobile) setNavigationOpen(false);
  }, [mobile]);
  const closeInspector = (open: boolean) => {
    setInspector(open);
    if (!open) requestAnimationFrame(() => detailsButton.current?.focus());
  };
  const navigate = (next: typeof page) => {
    setPage(next);
    setSettings(false);
    if (mobile) setNavigationOpen(false);
  };
  const title = page === "Detail" ? selected.name : page;
  const breadcrumbs = [
    { id: "orbit", label: "Orbit", onSelect: () => navigate("Overview") },
    ...(page === "Detail"
      ? [
          {
            id: "projects",
            label: "Projects",
            onSelect: () => navigate("Projects"),
          },
        ]
      : []),
    { id: "current", label: title },
  ];
  const navigation = (drawer = false) => (
    <KSidebar
      mode={drawer ? "expanded" : mode}
      onModeChange={setMode}
      label="Workspace navigation"
      className="dashboard-shell__sidebar"
    >
      {!drawer && (
        <KSidebarHeader>
          <div className="dashboard-shell__brand">
            <span className="k-sidebar__expanded-only dashboard-shell__identity">
              <KIcon name="orbit" size={24} />
              <KText variant="heading5" as="span">
                Orbit
              </KText>
            </span>
            {!drawer && (
              <KSidebarToggle railContent={<KIcon name="orbit" size={24} />} />
            )}
          </div>
        </KSidebarHeader>
      )}
      <KSidebarBody>
        <KSidebarGroup label="Workspace">
          <KSidebarItem
            label="Overview"
            leading={<KIcon name="house" />}
            active={page === "Overview"}
            onSelect={() => navigate("Overview")}
          />
          <KSidebarItem
            label="Projects"
            leading={<KIcon name="folder" />}
            active={page !== "Overview"}
            onSelect={() => navigate("Projects")}
          />
        </KSidebarGroup>
      </KSidebarBody>
      <KSidebarFooter>
        <KSidebarItem
          data-shell-settings
          label="Settings"
          leading={<KIcon name="settings" />}
          onSelect={() => {
            setSettings(true);
            if (mobile) setNavigationOpen(false);
          }}
        />
      </KSidebarFooter>
    </KSidebar>
  );
  const inspectorContent = (
    <KStack gap="action" align="stretch">
      <KText variant="heading5" as="h3">
        {selected.name}
      </KText>
      <KBadge variant="secondary" className="dashboard-shell__status">
        {selected.status}
      </KBadge>
      <KField label="Notes" helperText="Demo data stays in this showcase.">
        <KInput
          value={notes[selected.name] ?? ""}
          onChange={(event) =>
            setNotes({ ...notes, [selected.name]: event.target.value })
          }
        />
      </KField>
    </KStack>
  );
  const InspectorOverlay = mobile ? KBottomSheet : KResponsiveDrawer;
  return (
    <div
      ref={root}
      className="dashboard-shell"
      data-mobile={mobile || undefined}
      data-theme={theme}
    >
      {settings ? (
        <SettingsPageFixture
          onBackToApp={() => {
            setSettings(false);
            requestAnimationFrame(() =>
              (
                root.current?.querySelector<HTMLButtonElement>(
                  "[data-shell-settings] button",
                ) ?? navigationButton.current
              )?.focus(),
            );
          }}
        />
      ) : (
        <>
          {!mobile && navigation()}
          <div className="dashboard-shell__workspace">
            <header className="dashboard-shell__header">
              {mobile && (
                <KIconButton
                  ref={navigationButton}
                  icon="menu"
                  label="Open navigation"
                  onClick={() => setNavigationOpen(true)}
                />
              )}
              <KBreadcrumb items={breadcrumbs} />
              <KThemeSwitcher value={themeMode} onValueChange={setThemeMode} />
              <KIconButton
                ref={detailsButton}
                icon="panel-right"
                label="Project details"
                aria-expanded={inspector}
                onClick={() => setInspector(!inspector)}
              />
            </header>
            <div className="dashboard-shell__body">
              <section
                className="dashboard-shell__main"
                aria-label="Workspace content"
              >
                <KStack gap="action" align="stretch">
                  <div>
                    <KText variant="heading2" as="h1">
                      {title}
                    </KText>
                    <KText className="dashboard-shell__muted">
                      {page === "Overview"
                        ? "A clear view of your workspace."
                        : page === "Projects"
                          ? "Your current projects and their progress."
                          : "Track progress and keep project notes together."}
                    </KText>
                  </div>
                  {page === "Overview" && (
                    <div className="dashboard-shell__metrics">
                      {[
                        ["Active projects", "12"],
                        ["Tasks completed", "84"],
                        ["Needs attention", "3"],
                      ].map(([label, value]) => (
                        <KCard key={label}>
                          <KStack gap="control">
                            <KText variant="bodySmall">{label}</KText>
                            <KText variant="heading2" as="p">
                              {value}
                            </KText>
                          </KStack>
                        </KCard>
                      ))}
                    </div>
                  )}
                  {page !== "Detail" ? (
                    <KCard>
                      <KStack gap="action" align="stretch">
                        <KText variant="heading4" as="h2">
                          Projects
                        </KText>
                        {projects.map((project) => (
                          <div
                            className="dashboard-shell__project"
                            key={project.name}
                          >
                            <KButton
                              variant="ghost"
                              onClick={() => {
                                setSelected(project);
                                navigate("Detail");
                              }}
                            >
                              {project.name}
                            </KButton>
                            <KBadge variant="secondary">
                              {project.status}
                            </KBadge>
                          </div>
                        ))}
                      </KStack>
                    </KCard>
                  ) : (
                    <KCard>
                      <KStack gap="action" align="stretch">
                        <KBadge variant="secondary">{selected.status}</KBadge>
                        <KText>
                          Review the project details and add a note to
                          coordinate the next steps.
                        </KText>
                        <KButton
                          variant="secondary"
                          onClick={() => navigate("Projects")}
                        >
                          Back to projects
                        </KButton>
                      </KStack>
                    </KCard>
                  )}
                  <KText variant="caption" className="dashboard-shell__muted">
                    Demo workspace · No live data
                  </KText>
                </KStack>
              </section>
            </div>
          </div>
          <InspectorOverlay
            open={inspector}
            onOpenChange={closeInspector}
            title="Project details"
            closeLabel="Close details"
          >
            {inspectorContent}
          </InspectorOverlay>
        </>
      )}
      <KResponsiveDrawer
        className="dashboard-shell__navigation-drawer"
        breakpoint={0}
        side="left"
        open={mobile && navigationOpen}
        onOpenChange={(open) => {
          setNavigationOpen(open);
          if (!open)
            requestAnimationFrame(() =>
              (
                navigationButton.current ??
                root.current?.querySelector<HTMLButtonElement>("button")
              )?.focus(),
            );
        }}
        title={
          <span className="dashboard-shell__identity">
            <KIcon name="orbit" size={24} />
            Orbit
          </span>
        }
        closeLabel="Close navigation"
        contentInset={false}
      >
        {navigation(true)}
      </KResponsiveDrawer>
    </div>
  );
}
