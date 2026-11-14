import { useState } from "react";
import {
  KAppShell,
  KBadge,
  KButton,
  KIcon,
  KIconButton,
  KList,
  KListItem,
  KMenuButton,
  KOnboarding,
  KPage,
  KPageHeader,
  KSegmentedControl,
  KSidebarItem,
  KStack,
  KText,
} from "@k-design-system/ui";
import "./core-components-fixtures.css";

/** Same fixtures as Widgetbook core_components_fixture.dart. */

/** Reference settings screen: grouped sections, real content, no demo text. */
export function SettingsList() {
  const [sounds, setSounds] = useState(true);
  return (
    <KStack gap="section" align="stretch">
      <KList title="Account">
        <KListItem
          title="Profile"
          description="Dana Weber · dana@example.com"
          leadingIcon="user"
          onClick={() => {}}
        />
        <KListItem
          title="Password and security"
          leadingIcon="lock"
          onClick={() => {}}
        />
      </KList>
      <KList title="Notifications">
        <KListItem
          title="Push notifications"
          leadingIcon="bell"
          trailing={<KBadge variant="secondary">3 new</KBadge>}
          onClick={() => {}}
        />
        <KListItem
          title="Email summary"
          leadingIcon="mail"
          value="Weekly"
          menu={[
            { id: "daily", label: "Daily", onSelect: () => {} },
            {
              id: "weekly",
              label: "Weekly",
              checked: true,
              onSelect: () => {},
            },
            { id: "never", label: "Never", onSelect: () => {} },
          ]}
        />
        <KListItem
          title="Sounds"
          leadingIcon="volume-2"
          switchValue={sounds}
          onSwitchChange={setSounds}
        />
      </KList>
      <KList title="Assistant" footer="Speech input runs on this device.">
        <KListItem
          title="On-device speech input"
          leadingIcon="mic"
          value="Not set up"
          onClick={() => {}}
        />
      </KList>
      <KList
        title="Storage"
        footer="Offline files are removed after 30 days without use."
      >
        <KListItem
          title="Used"
          leadingIcon="hard-drive"
          value="12.4 of 50 GB"
        />
        <KListItem
          title="Downloads"
          leadingIcon="download"
          value="Wi-Fi only"
          onClick={() => {}}
        />
      </KList>
      <KList title="About" footer="Version 4.2.0 (318)">
        <KListItem
          title="Help and support"
          leadingIcon="circle-question-mark"
          onClick={() => {}}
        />
        <KListItem
          title="Terms of use"
          leadingIcon="file-text"
          onClick={() => {}}
        />
      </KList>
    </KStack>
  );
}

export function ListFixture() {
  return (
    <div className="cc-fixture">
      <SettingsList />
    </div>
  );
}

export function SegmentedControlFixture() {
  const [period, setPeriod] = useState("week");
  const [view, setView] = useState("list");
  return (
    <KStack gap="section" align="stretch" className="cc-fixture">
      <KSegmentedControl
        label="Period"
        value={period}
        onValueChange={setPeriod}
        segments={[
          { value: "day", label: "Day" },
          { value: "week", label: "Week" },
          { value: "month", label: "Month" },
          { value: "year", label: "Year" },
        ]}
      />
      <KSegmentedControl
        label="View"
        value={view}
        onValueChange={setView}
        segments={[
          { value: "list", label: "List", icon: "list" },
          { value: "grid", label: "Grid", icon: "layout-grid" },
        ]}
      />
      <KText role="status" variant="bodySmall">
        {period} · {view}
      </KText>
    </KStack>
  );
}

export function PageHeaderFixture() {
  return (
    <KStack gap="section" align="stretch" className="cc-fixture">
      <KPageHeader
        title="Riverside"
        subtitle="3 buildings · updated today"
        backLabel="Back to Portfolios"
        onBack={() => {}}
        actions={
          <>
            <KIconButton icon="share" label="Share" onClick={() => {}} />
            <KButton variant="primary" onClick={() => {}}>
              Add building
            </KButton>
          </>
        }
      />
      <KPageHeader title="Portfolios" subtitle="Top level: no back control" />
    </KStack>
  );
}

const destinations = [
  { id: "home", label: "Home", icon: "house" },
  { id: "portfolios", label: "Portfolios", icon: "building" },
  { id: "inbox", label: "Inbox", icon: "inbox", badge: "2" },
  { id: "settings", label: "Settings", icon: "settings" },
] as const;

/** Objects with media tiles, a status badge and a shared-with summary. */
export function PortfolioList() {
  return (
    <KStack gap="section" align="stretch">
      <KList title="Own portfolios">
        <KListItem
          title="Riverside Holdings"
          description="Dana Weber · Updated 22.09.2026"
          mediaIcon="folder"
          trailing={<KBadge variant="secondary">Draft</KBadge>}
          onClick={() => {}}
        />
        <KListItem
          title="North Estates"
          description="Updated 03.10.2026"
          mediaIcon="building"
          value="12 units"
          onClick={() => {}}
        />
      </KList>
      <KList title="Sharing">
        <KListItem
          title="Sabrina, Patricia, Kristin"
          leadingIcon="users"
          value="3 people"
          onClick={() => {}}
        />
      </KList>
    </KStack>
  );
}

function ShellPage({ id, label }: { id: string; label: string }) {
  if (id === "home")
    return (
      <>
        <KPageHeader
          title="Assistant"
          leading={
            <KIconButton label="Chat history" icon="menu" onClick={() => {}} />
          }
        />
        <KList title="What can I help with?">
          <KListItem
            title="Create a portfolio"
            description="With a name and a goal"
            leadingIcon="folder"
            onClick={() => {}}
          />
          <KListItem
            title="Add a building"
            description="From an exposé or photos"
            leadingIcon="building"
            onClick={() => {}}
          />
        </KList>
      </>
    );
  return (
    <>
      <KPageHeader
        title={label}
        actions={
          id === "portfolios" ? (
            <>
              <KButton onClick={() => {}}>
                <KIcon name="plus" size={16} />
                Portfolio
              </KButton>
              <KMenuButton
                label="Options"
                overflow
                actions={[
                  { id: "export", label: "Export", onSelect: () => {} },
                ]}
              />
            </>
          ) : undefined
        }
      />
      {id === "settings" ? (
        <SettingsList />
      ) : id === "portfolios" ? (
        <PortfolioList />
      ) : (
        <KText variant="body">{label} has no content in this reference.</KText>
      )}
    </>
  );
}

export function AppShellFixture({
  initial = "settings",
  customSidebar = false,
  iconOnlyTabs = false,
  brandNavigation = false,
}: {
  initial?: string;
  customSidebar?: boolean;
  iconOnlyTabs?: boolean;
  brandNavigation?: boolean;
}) {
  const [selected, setSelected] = useState(initial);
  return (
    <div className="cc-shell">
      <KAppShell
        destinations={destinations.map((destination) => ({
          ...destination,
          renderMobileIcon:
            brandNavigation && destination.id === "inbox"
              ? () => (
                  <svg viewBox="0 0 100 100">
                    <path d="M50 0 100 50 50 100 0 50Z" fill="currentColor" />
                  </svg>
                )
              : undefined,
        }))}
        selectedId={selected}
        onSelectedChange={setSelected}
        tabBarLabelVisibility={
          iconOnlyTabs || brandNavigation ? "never" : "always"
        }
        sidebarContent={
          customSidebar ? (
            <>
              <KSidebarItem
                label="Home"
                active={selected === "home"}
                onSelect={() => setSelected("home")}
              />
              <KSidebarItem
                label="Assistant"
                onSelect={() => setSelected("home")}
              />
            </>
          ) : undefined
        }
        sidebarFooter={
          customSidebar ? (
            <>
              {destinations
                .filter((item) => item.id !== "home")
                .map((item) => (
                  <KSidebarItem
                    key={item.id}
                    label={item.label}
                    active={selected === item.id}
                    onSelect={() => setSelected(item.id)}
                  />
                ))}
            </>
          ) : undefined
        }
        sidebarHeader={
          <KText as="span" variant="label">
            Assetry
          </KText>
        }
      >
        {/* Tabs stay mounted, as in most apps; only the shown page fills the
            top bar (Decision 0015). */}
        {destinations.map((destination) => (
          <KStack
            key={destination.id}
            gap="section"
            align="stretch"
            className="cc-fixture"
            hidden={destination.id !== selected}
          >
            <ShellPage id={destination.id} label={destination.label} />
          </KStack>
        ))}
      </KAppShell>
    </div>
  );
}

/** Reference onboarding: footer with Back, progress and Next on every step. */
export function OnboardingFixture() {
  const steps = [
    ["Welcome to Assetry", "Your properties, from portfolio to building."],
    ["Add your first portfolio", "Group buildings by owner or region."],
    ["Invite your team", "Share a portfolio with read or edit access."],
  ].map(([title, body]) => (
    <KPage key={title}>
      <KStack gap="control" align="stretch">
        <KText as="h1" variant="heading1">
          {title}
        </KText>
        <KText>{body}</KText>
      </KStack>
    </KPage>
  ));
  return (
    <div style={{ height: "100dvh" }}>
      <KOnboarding steps={steps} onDone={() => {}} />
    </div>
  );
}
