import { useId, useState, type CSSProperties } from "react";
import {
  KAvatar,
  KBreadcrumb,
  KButton,
  KIcon,
  KSettingsPage,
  KStack,
  KField,
  KInput,
  KSlider,
  KRadioGroup,
  type KIconName,
} from "@k-design-system/ui";
import { Row, Group } from "./settings-grouped-parts.js";
import {
  OverhaulAccess,
  OverhaulAssistant,
} from "./settings-overhaul-admin.js";
import { ExtraSettings } from "./settings-grouped-extra.js";
import { AvatarEditorFixture } from "./avatar-editor-fixture.js";
import { SettingsOverhaulDialog } from "./settings-overhaul-dialogs.js";
import { OverhaulPayments } from "./settings-overhaul-payments.js";
import { useReviewOverlayPreference } from "./review-overlay-preference.js";
import "./settings-grouped.css";
import "./settings-overhaul.css";

// Composition map: KSettingsPage shell → existing public K controls and gallery
// Row/Group compositions. New gallery scope only; no product data or requests.
export type SettingsOverhaulPage =
  | "overview"
  | "profile"
  | "appearance"
  | "language"
  | "payments"
  | "integrations"
  | "about"
  | "access"
  | "assistant"
  | "server";
const pages: { id: SettingsOverhaulPage; label: string; icon: KIconName }[] = [
  { id: "profile", label: "Profil & Konto", icon: "user" },
  { id: "payments", label: "Zahlungen", icon: "credit-card" },
  { id: "appearance", label: "Darstellung", icon: "sun" },
  { id: "language", label: "Sprache", icon: "languages" },
  { id: "about", label: "Über Onzeit", icon: "info" },
  { id: "integrations", label: "Integrationen", icon: "plug" },
  { id: "access", label: "Zugang & Einladungen", icon: "mail" },
  { id: "assistant", label: "KI-Assistent", icon: "sparkles" },
  { id: "server", label: "Server", icon: "server" },
];
const groups: [string, SettingsOverhaulPage[]][] = [
  ["Konto", ["profile"]],
  ["Business", ["payments"]],
  ["App", ["appearance", "language", "about"]],
  ["Erweitert", ["integrations"]],
  ["Plattform", ["access", "assistant", "server"]],
];

export function SettingsOverhaul({
  initialPage = "profile",
  initialDialog = null,
  empty = false,
  admin = true,
}: {
  initialPage?: SettingsOverhaulPage;
  initialDialog?: string | null;
  empty?: boolean;
  admin?: boolean;
}) {
  const presentationRootId = useId();
  const [presentation, setPresentation] = useReviewOverlayPreference();
  const [email, setEmail] = useState("denis@example.com");
  const [page, setPage] = useState(initialPage);
  const [dialog, setDialog] = useState<string | null>(initialDialog);
  const [avatar, setAvatar] = useState<string>();
  const [name, setName] = useState("Denis Knaack");
  const [draft, setDraft] = useState(
    initialDialog === "Name bearbeiten"
      ? "Denis Knaack"
      : initialDialog === "E-Mail ändern"
        ? "denis@example.com"
        : "",
  );
  const [scheme, setScheme] = useState("Automatisch");
  const [density, setDensity] = useState("Standard");
  const [fontSize, setFontSize] = useState(100);
  const [language, setLanguage] = useState("Deutsch");
  const [notice, setNotice] = useState("");
  const [updateAvailable, setUpdateAvailable] = useState(
    initialDialog === "Update verfügbar",
  );
  const title = pages.find((p) => p.id === page)?.label ?? "Einstellungen";
  const isAdmin = ["assistant", "server", "access"].includes(page);
  const open = (next: SettingsOverhaulPage) => {
    setPage(next);
    setNotice("");
  };
  const navigation = (
    <div className="sg-navigation so-navigation">
      <KButton variant="ghost" onClick={() => open("overview")}>
        <KIcon name="arrow-left" size={18} />
        Zurück zu Onzeit
      </KButton>
      <div className="so-person">
        <KAvatar alt={name} src={avatar} />
        <span>
          <strong>{name}</strong>
          <small>{email}</small>
        </span>
      </div>
      <KStack gap="action" align="stretch">
        {groups
          .filter(([g]) => admin || g !== "Plattform")
          .map(([g, ids]) => (
            <Group key={g} title={g}>
              {ids.map((id) => {
                const p = pages.find((p) => p.id === id)!;
                return (
                  <Row
                    key={id}
                    title={p.label}
                    icon={p.icon}
                    iconSize={17}
                    selected={page === id}
                    onClick={() => open(id)}
                    value={
                      id === "language"
                        ? language
                        : id === "appearance"
                          ? scheme
                          : undefined
                    }
                  />
                );
              })}
            </Group>
          ))}
      </KStack>
    </div>
  );
  return (
    <div
      id={presentationRootId}
      className="sg-review so-review"
      data-scheme={
        scheme === "Dunkel" ? "dark" : scheme === "Hell" ? "light" : undefined
      }
    >
      {page === "overview" ? (
        <section className="so-overview">
          <h1>Einstellungen</h1>
          <p>Dein Konto, deine App und dein Business.</p>
          {navigation}
        </section>
      ) : (
        <KSettingsPage
          style={{ background: "var(--k-color-surface-canvas)" }}
          navigation={navigation}
          detailVisible
          onBack={() => open("overview")}
          backLabel="Einstellungen"
          breadcrumb={
            <KBreadcrumb
              items={[
                {
                  id: "settings",
                  label: "Einstellungen",
                  onSelect: () => open("overview"),
                },
                { id: page, label: title },
              ]}
            />
          }
          title={
            page === "server" ? undefined : (
              <span className="so-title">
                {title}
                {isAdmin && (
                  <span className="sg-status sg-admin-badge">Admin</span>
                )}
              </span>
            )
          }
          description={
            ["appearance", "language"].includes(page)
              ? "Gilt nur für dieses Gerät."
              : undefined
          }
        >
          {page === "profile" && (
            <KStack gap="section" align="stretch">
              <div className="so-hero">
                <KButton
                  variant="ghost"
                  className="so-avatar-button"
                  aria-label="Foto ändern"
                  onClick={() => setDialog("Foto ändern")}
                >
                  <span className="so-avatar-wrap">
                    <KAvatar
                      alt={name}
                      src={avatar}
                      className="so-avatar"
                      size="large"
                    />
                    <span className="so-avatar-edit">
                      <KIcon name="pencil" size={15} />
                    </span>
                  </span>
                </KButton>
                <h2>{name}</h2>
                <p>{email}</p>
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
                  value={email}
                  onClick={() => {
                    setDraft(email);
                    setDialog("E-Mail ändern");
                  }}
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
              <Group title="">
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
                  className="so-appearance-preview"
                  style={
                    {
                      fontSize: `${fontSize}%`,
                      "--so-density":
                        density === "Kompakt"
                          ? 0.8
                          : density === "Groß"
                            ? 1.25
                            : 1,
                    } as CSSProperties
                  }
                >
                  <KAvatar alt="Elisa Ferrari" />
                  <span>
                    <b>Elisa Ferrari</b>
                    <small>Mobilitäts-Session · 6 Min Fahrt</small>
                  </span>
                  <span className="so-preview-time">
                    <strong>11:50</strong>
                    <small>in 25 Min</small>
                  </span>
                </div>
              </Group>
              <Group title="Farbschema">
                <div className="so-tiles">
                  {["Hell", "Dunkel", "Automatisch"].map((v, i) => (
                    <KButton
                      key={v}
                      variant="ghost"
                      className="so-tile"
                      aria-pressed={scheme === v}
                      onClick={() => setScheme(v)}
                    >
                      <span className="so-tile-content">
                        <span className={`so-swatch so-swatch-${i}`} />
                        <strong>{v}</strong>
                      </span>
                    </KButton>
                  ))}
                </div>
              </Group>
              <section>
                <h2 className="so-section-title">Dichte</h2>
                <div className="so-segments">
                  {["Kompakt", "Standard", "Groß"].map((v) => (
                    <KButton
                      fullWidth
                      variant={density === v ? "secondary" : "ghost"}
                      key={v}
                      aria-pressed={density === v}
                      onClick={() => setDensity(v)}
                    >
                      {v}
                    </KButton>
                  ))}
                </div>
              </section>
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
              <Group
                title="Dialogdarstellung · Testphase"
                footer="Temporäre Vorschau für Bearbeitungsdialoge. Die Anwendung bleibt unverändert."
              >
                <div className="sg-inset">
                  <KRadioGroup
                    label="Dialogdarstellung"
                    value={presentation}
                    onValueChange={(value) =>
                      setPresentation(value as "bottom-sheet" | "page-sheet")
                    }
                    items={[
                      {
                        value: "bottom-sheet",
                        label: "Bottom-Sheet (wie bisher)",
                      },
                      { value: "page-sheet", label: "Page-Sheet" },
                    ]}
                  />
                </div>
                <Row
                  title="Darstellung ausprobieren"
                  icon="panel-top"
                  onClick={() => {
                    setDraft(name);
                    setDialog("Name bearbeiten");
                  }}
                />
              </Group>
              <KButton
                variant="ghost"
                onClick={() => {
                  setScheme("Automatisch");
                  setDensity("Standard");
                  setFontSize(100);
                }}
              >
                Auf Standard zurücksetzen
              </KButton>
            </KStack>
          )}
          {page === "language" && (
            <Group title="">
              <div className="sg-inset">
                <KRadioGroup
                  label="App-Sprache"
                  value={language}
                  items={[
                    "Deutsch",
                    "English",
                    "Français",
                    "Español",
                    "Italiano",
                  ].map((value) => ({ value, label: value }))}
                  onValueChange={(value) => {
                    setLanguage(value);
                    setNotice(
                      "App-Sprache in der Vorschau ausgewählt; die Galerie bleibt deutsch.",
                    );
                  }}
                />
              </div>
            </Group>
          )}
          {page === "payments" && <OverhaulPayments empty={empty} />}
          {page === "access" && <OverhaulAccess empty={empty} />}
          {page === "assistant" && <OverhaulAssistant empty={empty} />}
          {["integrations", "server"].includes(page) && (
            <ExtraSettings key={page} page={page} />
          )}
          {page === "about" && (
            <KStack gap="section" align="stretch">
              <Group title="">
                <div className="so-version">
                  <KIcon name="clock" size={28} />
                  <span>
                    <b>Onzeit</b>
                    <small>Version 0.1.0+1 · Designvorschau</small>
                    <span className="sg-status sg-success">
                      <KIcon name="check" size={14} />
                      {updateAvailable
                        ? "Version 0.1.1 verfügbar"
                        : "Auf dem neuesten Stand"}
                    </span>
                  </span>
                </div>
                <Row
                  title={
                    updateAvailable ? "Update ansehen" : "Nach Updates suchen"
                  }
                  icon="refresh-cw"
                  onClick={() => {
                    setUpdateAvailable(true);
                    setDialog("Update verfügbar");
                  }}
                />
              </Group>
              {[
                ["Hilfe", ["Hilfe & Anleitungen", "Feedback senden"]],
                [
                  "Rechtliches",
                  ["Impressum", "Datenschutz", "AGB", "Open-Source-Lizenzen"],
                ],
              ].map(([g, items]) => (
                <Group key={g as string} title={g as string}>
                  {(items as string[]).map((v) => (
                    <Row key={v} title={v} onClick={() => setDialog(v)} />
                  ))}
                </Group>
              ))}
            </KStack>
          )}
          {notice && (
            <p role="status" className="so-notice">
              {notice}
            </p>
          )}
          <AvatarEditorFixture
            open={dialog === "Foto ändern"}
            onOpenChange={(v) => {
              if (!v) setDialog(null);
            }}
            onAvatarChange={setAvatar}
          />
          <SettingsOverhaulDialog
            presentationRootId={presentationRootId}
            title={dialog === "Foto ändern" ? null : dialog}
            onClose={() => setDialog(null)}
            onComplete={(message) => {
              setDialog(null);
              setNotice(message);
            }}
          >
            {["Name bearbeiten", "E-Mail ändern"].includes(dialog ?? "") && (
              <form
                className="so-edit-form"
                onSubmit={(event) => {
                  event.preventDefault();
                  if (
                    !draft.trim() ||
                    (dialog === "E-Mail ändern" &&
                      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(draft.trim()))
                  )
                    return;
                  if (dialog === "Name bearbeiten") setName(draft.trim());
                  else setEmail(draft.trim());
                  setDialog(null);
                  setNotice(
                    "Nur in dieser Vorschau geändert; keine E-Mail versendet.",
                  );
                }}
              >
                <KField
                  label={
                    dialog === "Name bearbeiten"
                      ? "Vollständiger Name"
                      : "Neue E-Mail-Adresse"
                  }
                  required
                >
                  <KInput
                    type={dialog === "Name bearbeiten" ? "text" : "email"}
                    autoComplete={
                      dialog === "Name bearbeiten" ? "name" : "email"
                    }
                    required
                    value={draft}
                    onChange={(event) => setDraft(event.target.value)}
                  />
                </KField>
                <p className="so-edit-help">
                  {dialog === "Name bearbeiten"
                    ? "So wird dein Name in deinem Konto angezeigt."
                    : "In der Anwendung bestätigst du die neue Adresse per E-Mail, bevor sie übernommen wird."}
                </p>
                <div className="so-edit-actions">
                  <KButton
                    fullWidth
                    style={{ justifyContent: "center" }}
                    variant="secondary"
                    type="button"
                    onClick={() => setDialog(null)}
                  >
                    Abbrechen
                  </KButton>
                  <KButton
                    fullWidth
                    style={{ justifyContent: "center" }}
                    type="submit"
                    disabled={
                      !draft.trim() ||
                      (dialog === "E-Mail ändern" &&
                        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(draft.trim()))
                    }
                  >
                    Änderung speichern
                  </KButton>
                </div>
                <p className="so-edit-preview">
                  Designvorschau · Änderungen gelten nur hier.
                </p>
              </form>
            )}
          </SettingsOverhaulDialog>
        </KSettingsPage>
      )}
    </div>
  );
}
