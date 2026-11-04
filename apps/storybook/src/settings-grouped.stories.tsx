import { Access as AccessEmptyContent } from "./settings-grouped-admin.js";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState, type ReactNode } from "react";
import {
  KAvatar,
  KBreadcrumb,
  KButton,
  KIcon,
  KSettingsPage,
  KStack,
  KField,
  KInput,
  KAdaptiveDialog,
  KSlider,
  type KIconName,
} from "@k-design-system/ui";
import "./settings-grouped.css";
import { Row, Group } from "./settings-grouped-parts.js";
import { ProfileDialog } from "./settings-profile-dialog.js";
import { ExtraSettings } from "./settings-grouped-extra.js";
import { AvatarEditorFixture } from "./avatar-editor-fixture.js";

// Review composition only: no account mutations or production routing.
// KSettingsPage owns responsive navigation; KButton owns keyboard/touch behavior.
type Page =
  | "profile"
  | "appearance"
  | "language"
  | "payments"
  | "integrations"
  | "about"
  | "access"
  | "assistant"
  | "server";
const pages: { id: Page; title: string; icon: KIconName }[] = [
  { id: "profile", title: "Profil & Konto", icon: "user" },
  { id: "appearance", title: "Darstellung", icon: "sun" },
  { id: "language", title: "Sprache", icon: "languages" },
  { id: "payments", title: "Zahlungen", icon: "credit-card" },
  { id: "integrations", title: "Integrationen", icon: "plug" },
  { id: "about", title: "Über Onzeit", icon: "info" },
  { id: "access", title: "Zugang & Einladungen", icon: "mail" },
  { id: "assistant", title: "KI-Assistent", icon: "sparkles" },
  { id: "server", title: "Server", icon: "server" },
];

function GroupedSettings({
  initialPage = "profile",
  overview = false,
  admin = true,
  emptyAccess = false,
}: {
  initialPage?: Page;
  overview?: boolean;
  admin?: boolean;
  emptyAccess?: boolean;
}) {
  const [page, setPage] = useState<Page>(initialPage);
  const [detail, setDetail] = useState(!overview);
  const [avatar, setAvatar] = useState<string | undefined>();
  const [name, setName] = useState("Denis Knaack");
  const [draft, setDraft] = useState(name);
  const [dialog, setDialog] = useState<string | null>(null);
  const [scheme, setScheme] = useState("Automatisch");
  const [density, setDensity] = useState("Standard");
  const [fontSize, setFontSize] = useState(100);
  const [language, setLanguage] = useState("Deutsch");
  const [notice, setNotice] = useState("");
  const open = (id: Page) => {
    setPage(id);
    setDetail(true);
  };
  const navigation = (
    <div className="sg-navigation">
      <KButton
        className="sg-back-home"
        variant="ghost"
        onClick={() => setDetail(false)}
      >
        <KIcon name="arrow-left" size={20} />
        Zurück zu Onzeit
      </KButton>
      <div className="sg-profile-link">
        <KAvatar alt={name} size="large" />
        <div>
          <strong>{name}</strong>
          <small>denis@example.com</small>
        </div>
      </div>
      <Group title="Konto">
        <Row
          title="Profil & Konto"
          icon="user"
          iconSize={15}
          onClick={() => open("profile")}
          selected={detail && page === "profile"}
        />
      </Group>
      {(
        [
          ["Business", ["payments"]],
          ["App", ["appearance", "language", "about"]],
          ["Erweitert", ["integrations"]],
          ...(admin ? [["Plattform", ["access", "assistant", "server"]]] : []),
        ] as [string, Page[]][]
      ).map(([title, ids]) => (
        <Group key={title} title={title}>
          {ids.map((id) => {
            const item = pages.find((p) => p.id === id)!;
            return (
              <Row
                key={id}
                title={item.title}
                icon={item.icon}
                iconSize={15}
                value={
                  id === "language"
                    ? language
                    : id === "appearance"
                      ? scheme
                      : undefined
                }
                onClick={() => open(id)}
                selected={detail && page === id}
              />
            );
          })}
        </Group>
      ))}
    </div>
  );
  return (
    <div className="sg-review">
      <KSettingsPage
        className="sg-shell"
        navigation={navigation}
        breadcrumb={
          <div className="sg-breadcrumb">
            <KBreadcrumb
              label="Brotkrümelnavigation"
              items={[
                {
                  id: "settings",
                  label: "Einstellungen",
                  onSelect: () => setDetail(false),
                },
                {
                  id: page,
                  label: pages.find((item) => item.id === page)!.title,
                },
              ]}
            />
          </div>
        }
        title={
          ["assistant", "server"].includes(page)
            ? undefined
            : pages.find((item) => item.id === page)?.title
        }
        description={
          page === "appearance" || page === "language"
            ? "Gilt nur für dieses Gerät."
            : undefined
        }
        detailVisible={detail}
        backLabel="Einstellungen"
      >
        {page === "profile" && (
          <KStack gap="section" align="stretch">
            <div className="sg-hero">
              <KButton
                variant="ghost"
                onClick={() => setDialog("Foto ändern")}
                aria-label="Foto ändern"
                className="sg-hero-avatar-button"
              >
                <span className="sg-avatar-wrap">
                  <KAvatar
                    alt={name}
                    src={avatar}
                    size="large"
                    className="sg-avatar"
                  />
                  <span className="sg-edit">
                    <KIcon name="pencil" size={16} />
                  </span>
                </span>
              </KButton>
              <h2>{name}</h2>
              <p>denis@example.com</p>
              {admin && <span className="sg-badge">Plattform-Admin</span>}
            </div>
            <Group title="Persönliche Daten">
              <Row
                title="Name"
                value={name}
                onClick={() => {
                  setDraft(name);
                  setDialog("Name bearbeiten");
                }}
              />
              <Row
                title="E-Mail"
                value="denis@example.com"
                onClick={() => setDialog("E-Mail ändern")}
              />
            </Group>
            <Group
              title="Sicherheit"
              footer="Abmelden betrifft nur dieses Gerät."
            >
              <Row
                title="Passwort ändern"
                description="Sichere deinen Zugang mit einem Passwort."
                onClick={() => setDialog("Passwort ändern")}
              />
              <Row
                title="Abmelden"
                icon="log-out"
                danger
                onClick={() => setDialog("Abmelden?")}
              />
            </Group>
            <Group title="Konto verwalten">
              <Row
                title="Konto löschen"
                danger
                onClick={() => setDialog("Konto löschen?")}
              />
            </Group>
          </KStack>
        )}
        {page === "appearance" && (
          <KStack gap="section" align="stretch">
            <Group title="Vorschau">
              <div
                className="sg-preview"
                style={{
                  fontSize: `${fontSize}%`,
                  gap:
                    density === "Kompakt"
                      ? "var(--k-space-control-gap)"
                      : "var(--k-space-content-action-gap)",
                }}
              >
                <KAvatar alt="Elisa Ferrari" />
                <div>
                  <strong>Elisa Ferrari</strong>
                  <small>Einzeltraining · 16 Min Fahrt</small>
                </div>
                <strong>11:50</strong>
              </div>
            </Group>
            <Group title="Farbschema">
              <div className="sg-options">
                {["Hell", "Dunkel", "Automatisch"].map((label, index) => (
                  <KButton
                    key={label}
                    variant="ghost"
                    className="sg-option"
                    aria-pressed={scheme === label}
                    onClick={() => setScheme(label)}
                  >
                    <span className="sg-option-body">
                      <span className={`sg-swatch sg-swatch-${index}`}>
                        <span />
                        <span />
                      </span>
                      <strong>{label}</strong>
                    </span>
                  </KButton>
                ))}
              </div>
            </Group>
            <Group title="Dichte">
              <div className="sg-options">
                {["Kompakt", "Standard", "Groß"].map((label) => (
                  <KButton
                    key={label}
                    variant={density === label ? "secondary" : "ghost"}
                    onClick={() => setDensity(label)}
                    aria-pressed={density === label}
                  >
                    {label}
                  </KButton>
                ))}
              </div>
            </Group>
            <Group
              title={`Schriftgröße · ${fontSize}%`}
              footer="Die Systemschrift deines Geräts wird zusätzlich berücksichtigt."
            >
              <div className="sg-inset">
                <KSlider
                  label="Schriftgröße"
                  value={fontSize}
                  onValueChange={setFontSize}
                  min={85}
                  max={130}
                  step={5}
                />
              </div>
            </Group>
            <KButton
              variant="ghost"
              onClick={() => {
                setFontSize(100);
                setDensity("Standard");
                setScheme("Automatisch");
              }}
            >
              Auf Standard zurücksetzen
            </KButton>
          </KStack>
        )}
        {page === "language" && (
          <Group title="App-Sprache">
            {["Deutsch", "English", "Français", "Español", "Italiano"].map(
              (label) => (
                <Row
                  key={label}
                  title={label}
                  selected={language === label}
                  onClick={() => setLanguage(label)}
                />
              ),
            )}
          </Group>
        )}
        {!["profile", "appearance", "language"].includes(page) &&
          (page === "access" && emptyAccess ? (
            <AccessEmptyContent empty />
          ) : (
            <ExtraSettings key={page} page={page} />
          ))}
        <AvatarEditorFixture
          open={dialog === "Foto ändern"}
          onOpenChange={(value) => {
            if (!value) setDialog(null);
          }}
          onAvatarChange={setAvatar}
        />
        {notice && <p role="status">{notice}</p>}
        <KAdaptiveDialog
          open={dialog !== null && dialog !== "Foto ändern"}
          onOpenChange={(value) => {
            if (!value) setDialog(null);
          }}
          title={dialog ?? ""}
          description={
            dialog === "Name bearbeiten"
              ? "Änderungen gelten nur für diese Vorschau."
              : "Designvorschau – es werden keine Kontodaten geändert."
          }
          actions={
            <KButton variant="secondary" onClick={() => setDialog(null)}>
              Schließen
            </KButton>
          }
        >
          {dialog === "Name bearbeiten" ? (
            <KStack gap="control">
              <KField label="Name">
                <KInput
                  value={draft}
                  onChange={(event) => setDraft(event.target.value)}
                />
              </KField>
              <KButton
                disabled={!draft.trim()}
                onClick={() => {
                  setName(draft.trim());
                  setDialog(null);
                  setNotice("Name in der Vorschau gespeichert.");
                }}
              >
                Speichern
              </KButton>
            </KStack>
          ) : (
            <p>
              Dieser erste Entwurf zeigt die Navigation und die Gestaltung. Die
              Fachdialoge folgen nach deiner Prüfung.
            </p>
          )}
        </KAdaptiveDialog>
      </KSettingsPage>
    </div>
  );
}
const meta = {
  title: "Patterns/SettingsGrouped",
  component: GroupedSettings,
  parameters: { layout: "fullscreen" },
  args: { admin: true },
} satisfies Meta<typeof GroupedSettings>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Profile: Story = {};
export const Overview: Story = { args: { overview: true } };
export const Appearance: Story = { args: { initialPage: "appearance" } };
export const Language: Story = { args: { initialPage: "language" } };

export const Payments: Story = { args: { initialPage: "payments" } };
export const Integrations: Story = { args: { initialPage: "integrations" } };
export const About: Story = { args: { initialPage: "about" } };
export const Access: Story = { args: { initialPage: "access" } };
export const Assistant: Story = { args: { initialPage: "assistant" } };
export const Server: Story = { args: { initialPage: "server" } };

export const AccessEmpty: Story = {
  args: { initialPage: "access", emptyAccess: true },
};
