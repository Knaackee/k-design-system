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
  KText,
} from "@k-design-system/ui";
import "./core-components-fixtures.css";

/** Same fixtures as Widgetbook core_components_fixture.dart. */

/** Reference settings screen: grouped sections, real content, no demo text. */
export function SettingsList() {
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
          <KPageHeader title={current.label} />
          {selected === "settings" ? (
            <SettingsList />
          ) : (
            <KText variant="body">
              {current.label} has no content in this reference.
            </KText>
          )}
        </KStack>
      </KAppShell>
    </div>
  );
}
