import { useState } from "react";
import {
  KButton,
  KField,
  KIcon,
  KInput,
  KSearchField,
  KSettingsPage,
  KSettingsRow,
  KSettingsSection,
  KSlider,
  KSidebar,
  KSidebarBody,
  KSidebarGroup,
  KSidebarHeader,
  KSidebarItem,
  KStack,
  KSwitch,
  type KIconName,
} from "@k-design-system/ui";

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
    description:
      "Manage your personal information and communication preferences.",
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
    <KSidebar label="Settings navigation" role="navigation">
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
                    <span className="k-settings-page__compact-only">
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

function SettingsContent() {
  const [updates, setUpdates] = useState(true);
  const [volume, setVolume] = useState(60);
  const [saved, setSaved] = useState(false);
  return (
    <>
      <KSettingsSection
        title="Profile information"
        description="Details shown across your workspace."
      >
        <KSettingsRow
          title="Display name"
          description="Used in comments, assignments, and mentions."
          layout="fullWidth"
          control={
            <KInput
              aria-label="Display name"
              defaultValue="Dennis Knaack"
              clearable
            />
          }
        />
        <KSettingsRow
          title="Contact email"
          description="Used for account and security messages."
          layout="fullWidth"
          control={
            <KInput
              aria-label="Contact email"
              type="email"
              defaultValue="dennis@example.com"
            />
          }
        />
      </KSettingsSection>
      <KSettingsSection
        title="Communication"
        description="Choose which product messages you receive."
      >
        <KSettingsRow
          title="Notification volume"
          description="Adjust the volume used for preview sounds."
          layout="fullWidth"
          control={
            <KSlider
              label="Notification volume"
              min={0}
              max={100}
              value={volume}
              valueLabel={(value) => `${value}%`}
              onValueChange={setVolume}
            />
          }
        />
        <KSettingsRow
          title="Product updates"
          description="Receive a concise monthly summary of important changes."
          layout="compact"
          control={
            <KSwitch
              showLabel={false}
              label="Product updates"
              checked={updates}
              onCheckedChange={setUpdates}
            />
          }
        />
      </KSettingsSection>
      <KStack gap="action">
        <KButton onClick={() => setSaved(true)}>Save changes</KButton>
        {saved && <p role="status">Changes saved locally.</p>}
      </KStack>
    </>
  );
}

export function SettingsPageFixture({
  onBackToApp,
}: { onBackToApp?: () => void } = {}) {
  const [selected, setSelected] = useState("profile");
  const [mobileDetail, setMobileDetail] = useState(false);
  const section = sections.find((entry) => entry.id === selected)!;
  return (
    <KSettingsPage
      navigation={
        <SettingsNavigation
          selected={selected}
          onBackToApp={onBackToApp}
          onSelect={(id) => {
            setSelected(id);
            setMobileDetail(true);
          }}
        />
      }
      detailVisible={mobileDetail}
      onBack={() => setMobileDetail(false)}
      title={section.label}
      description={section.description}
    >
      <SettingsContent />
    </KSettingsPage>
  );
}
