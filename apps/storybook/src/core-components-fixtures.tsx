import { useState } from "react";
import {
  KAppShell,
  KBadge,
  KButton,
  KIconButton,
  KList,
  KListItem,
  KPageHeader,
  KSegmentedControl,
  KStack,
  KSurface,
  KText,
} from "@k-design-system/ui";
import "./core-components-fixtures.css";

/** Same fixtures as Widgetbook core_components_fixture.dart. */

export function SettingsList() {
  const [last, setLast] = useState("–");
  return (
    <KStack gap="action" align="stretch">
      <KSurface radius="card" style={{ overflow: "hidden" }}>
        <KList>
          <KListItem
            title="Account"
            description="dana@example.com"
            leadingIcon="user"
            onClick={() => setLast("Account")}
          />
          <KListItem
            title="Notifications"
            leadingIcon="bell"
            trailing={<KBadge variant="secondary">3 new</KBadge>}
            onClick={() => setLast("Notifications")}
          />
          <KListItem
            title="Storage"
            leadingIcon="hard-drive"
            trailing={
              <KText as="span" variant="bodySmall">
                12.4 GB of 50 GB
              </KText>
            }
          />
          <KListItem
            title="A very long title for a row that wraps onto a second line at large text"
            description="Titles wrap; set titleMaxLines to truncate with …"
            leadingIcon="file-text"
            onClick={() => setLast("Long row")}
          />
          <KListItem
            title="Truncated title for a row that would otherwise take several lines"
            titleMaxLines={1}
            leadingIcon="scissors"
          />
          <KListItem
            title="Export data"
            leadingIcon="download"
            disabled
            onClick={() => {}}
          />
        </KList>
      </KSurface>
      <KText role="status" variant="bodySmall">
        Last opened: {last}
      </KText>
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

export function AppShellFixture() {
  const [selected, setSelected] = useState("settings");
  const current = destinations.find((item) => item.id === selected)!;
  return (
    <div className="cc-shell">
      <KAppShell
        destinations={destinations}
        selectedId={selected}
        onSelectedChange={setSelected}
        sidebarHeader={
          <KText as="span" variant="label">
            Assetry
          </KText>
        }
      >
        <KStack gap="section" align="stretch" className="cc-fixture">
          <KPageHeader title={current.label} subtitle="Adaptive shell demo" />
          {selected === "settings" ? (
            <SettingsList />
          ) : (
            <KText variant="body">
              Below 600 px the destinations are a tab bar, from 600 px a sidebar
              rail and from 840 px the full sidebar.
            </KText>
          )}
        </KStack>
      </KAppShell>
    </div>
  );
}
