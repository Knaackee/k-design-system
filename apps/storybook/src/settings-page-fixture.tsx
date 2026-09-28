import { useState, type ReactNode } from "react";
import {
  KButton,
  KCheckbox,
  KField,
  KIcon,
  KInput,
  KSearchField,
  KSidebar,
  KSidebarBody,
  KSidebarGroup,
  KSidebarHeader,
  KSidebarItem,
  type KIconName,
} from "@k-design-system/ui";
import "./settings-page-fixture.css";

interface SettingsSection {
  id: string;
  label: string;
  description: string;
  icon: KIconName;
  group: "Personal" | "Workspace" | "System";
}

const sections: SettingsSection[] = [
  {
    id: "preferences",
    label: "Preferences",
    description: "Language, appearance, and regional defaults.",
    icon: "sliders-horizontal",
    group: "Personal",
  },
  {
    id: "profile",
    label: "Profile",
    description: "Your public name and account details.",
    icon: "user",
    group: "Personal",
  },
  {
    id: "notifications",
    label: "Notifications",
    description: "Choose when and where you are notified.",
    icon: "bell",
    group: "Personal",
  },
  {
    id: "security",
    label: "Security & access",
    description: "Password, sessions, and sign-in methods.",
    icon: "lock",
    group: "Personal",
  },
  {
    id: "workspace",
    label: "Workspace",
    description: "Identity and defaults for this workspace.",
    icon: "users",
    group: "Workspace",
  },
  {
    id: "issues",
    label: "Issues & editor",
    description: "Defaults for creating and editing work.",
    icon: "check-check",
    group: "Workspace",
  },
  {
    id: "integrations",
    label: "Agents & integrations",
    description: "Connected tools and automated workflows.",
    icon: "settings",
    group: "Workspace",
  },
  {
    id: "data",
    label: "Data & advanced",
    description: "Exports, retention, and advanced options.",
    icon: "settings",
    group: "System",
  },
];

function SettingsNavigation({
  selected,
  onSelect,
  onBackToApp,
}: {
  selected: string;
  onSelect: (id: string) => void;
  onBackToApp?: () => void;
}) {
  const [search, setSearch] = useState("");
  return (
    <KSidebar label="Settings navigation" className="settings-page__sidebar">
      <KSidebarHeader>
        <KSidebarItem
          label="Back to app"
          leading={<KIcon name="arrow-left" />}
          onSelect={onBackToApp}
        />
        <KSearchField
          aria-label="Search settings"
          placeholder="Search settings…"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </KSidebarHeader>
      <KSidebarBody>
        {(["Personal", "Workspace", "System"] as const).map((group) => (
          <KSidebarGroup key={group} label={group}>
            {sections
              .filter(
                (section) =>
                  section.group === group &&
                  section.label.toLowerCase().includes(search.toLowerCase()),
              )
              .map((section) => (
                <KSidebarItem
                  key={section.id}
                  label={section.label}
                  leading={<KIcon name={section.icon} />}
                  trailing={
                    <span className="settings-page__mobile-chevron">
                      <KIcon name="chevron-right" size={14} />
                    </span>
                  }
                  active={selected === section.id}
                  onSelect={() => onSelect(section.id)}
                />
              ))}
          </KSidebarGroup>
        ))}
      </KSidebarBody>
    </KSidebar>
  );
}

function SettingRow({
  title,
  description,
  control,
}: {
  title: string;
  description: string;
  control: ReactNode;
}) {
  return (
    <div className="settings-page__row">
      <div>
        <strong>{title}</strong>
        <p>{description}</p>
      </div>
      {control}
    </div>
  );
}

function SettingsContent({
  section,
  onBack,
}: {
  section: SettingsSection;
  onBack: () => void;
}) {
  const [updates, setUpdates] = useState(true);
  const [saved, setSaved] = useState(false);
  return (
    <section className="settings-page__content" aria-label="Settings content">
      <button className="settings-page__back" type="button" onClick={onBack}>
        <KIcon name="arrow-left" size={16} />
        Settings
      </button>
      <header>
        <span>{section.group}</span>
        <h1>{section.label}</h1>
        <p>{section.description}</p>
      </header>
      <section
        className="settings-page__section"
        aria-label={`${section.label} settings`}
      >
        <KField label="Display name">
          <KInput defaultValue="Dennis Knaack" clearable />
        </KField>
        <KField
          label="Contact email"
          helperText="Used for account and security messages."
        >
          <KInput type="email" defaultValue="dennis@example.com" />
        </KField>
        <SettingRow
          title="Product updates"
          description="Receive a concise monthly summary of important changes."
          control={
            <KCheckbox
              label="Product updates"
              aria-label="Product updates"
              value={updates}
              onValueChange={setUpdates}
            />
          }
        />
        <div className="settings-page__actions">
          <KButton onClick={() => setSaved(true)}>Save changes</KButton>
        </div>
        {saved && <p role="status">Demo: Changes saved locally.</p>}
      </section>
    </section>
  );
}

export function SettingsPageFixture({
  onBackToApp,
}: { onBackToApp?: () => void } = {}) {
  const [selected, setSelected] = useState("profile");
  const [mobileDetail, setMobileDetail] = useState(false);
  const section = sections.find((entry) => entry.id === selected)!;
  return (
    <div className="settings-page">
      <div
        className="settings-page__navigation"
        data-mobile-hidden={mobileDetail || undefined}
      >
        <SettingsNavigation
          selected={selected}
          onBackToApp={onBackToApp}
          onSelect={(id) => {
            setSelected(id);
            setMobileDetail(true);
          }}
        />
      </div>
      <div
        className="settings-page__detail"
        data-mobile-hidden={!mobileDetail || undefined}
      >
        <SettingsContent
          section={section}
          onBack={() => setMobileDetail(false)}
        />
      </div>
    </div>
  );
}
