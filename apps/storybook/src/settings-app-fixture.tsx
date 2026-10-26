import "./settings-app-fixture.css";
import { DashboardShellFixture } from "./dashboard-shell-fixture.js";
import { useState } from "react";
import {
  KAlert,
  KButton,
  KCheckbox,
  KField,
  KIcon,
  KInline,
  KInput,
  KRadioGroup,
  KSearchField,
  KSelect,
  KSettingsPage,
  KSettingsRow,
  KSettingsSection,
  KSidebar,
  KSidebarBody,
  KSidebarGroup,
  KSidebarHeader,
  KSidebarItem,
  KStack,
  KSwitch,
  KText,
  KSpinner,
  type KIconName,
} from "@k-design-system/ui";

const pages: {
  id: string;
  title: string;
  description: string;
  icon: KIconName;
}[] = [
  {
    id: "profile",
    title: "Profil",
    description: "Deine Identität und Kontaktdaten im Workspace.",
    icon: "user",
  },
  {
    id: "preferences",
    title: "Darstellung & Sprache",
    description: "Richte deinen persönlichen Arbeitsbereich ein.",
    icon: "sliders-horizontal",
  },
  {
    id: "notifications",
    title: "Benachrichtigungen",
    description: "Entscheide, was dich erreicht und wie oft.",
    icon: "bell",
  },
  {
    id: "workspace",
    title: "Workspace",
    description: "Gemeinsame Standards für dein Team.",
    icon: "users",
  },
  {
    id: "connections",
    title: "Verbindungen",
    description:
      "Verwalte die Dienste, die mit deinem Workspace verbunden sind.",
    icon: "plug",
  },
];
const initial = {
  name: "Alex Morgan",
  email: "alex@example.com",
  language: "de",
  appearance: "system",
  density: "standard",
  mentions: true,
  digest: true,
  frequency: "daily",
  workspace: "Orbit Studio",
  visibility: "private",
};
type Values = typeof initial;
export type SettingsAppState = "ready" | "loading" | "error";

/** Demo-only consumer composition. No backend, routing or persistence in the library. */
export function SettingsAppFixture({
  initialPage = "Overview",
  initialState = "ready",
  emptyWorkspace = false,
  workspaceName = "Orbit",
}: {
  initialPage?: "Overview" | "Projects" | "New project";
  initialState?: SettingsAppState;
  emptyWorkspace?: boolean;
  workspaceName?: string;
}) {
  return (
    <DashboardShellFixture
      initialMode="expanded"
      initialPage={initialPage}
      emptyWorkspace={emptyWorkspace}
      workspaceName={workspaceName}
      initialSettings={initialState !== "ready"}
      formPage
      renderSettings={(onBackToApp) => (
        <SettingsAppContent
          initialState={initialState}
          onBackToApp={onBackToApp}
        />
      )}
    />
  );
}

function SettingsAppContent({
  initialState = "ready",
  onBackToApp,
}: {
  initialState?: SettingsAppState;
  onBackToApp: () => void;
}) {
  const [page, setPage] = useState("profile");
  const [detail, setDetail] = useState(false);
  const [search, setSearch] = useState("");
  const [values, setValues] = useState(initial);
  const [saved, setSaved] = useState(initial);
  const [status, setStatus] = useState("");
  const [attempted, setAttempted] = useState(false);
  const [state, setState] = useState(initialState);
  const [connected, setConnected] = useState(false);
  const selected = pages.find((p) => p.id === page)!;
  const matches = pages.filter((p) =>
    p.title.toLocaleLowerCase().includes(search.trim().toLocaleLowerCase()),
  );
  const dirty = JSON.stringify(values) !== JSON.stringify(saved);
  const nameError = !values.name.trim()
    ? "Bitte gib einen Namen ein."
    : undefined;
  const emailError = !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email)
    ? "Bitte gib eine gültige E-Mail-Adresse ein."
    : undefined;
  const workspaceError = !values.workspace.trim()
    ? "Bitte gib einen Workspace-Namen ein."
    : undefined;
  function update<K extends keyof Values>(key: K, value: Values[K]) {
    setValues((v) => ({ ...v, [key]: value }));
    setStatus("");
  }
  function save() {
    setAttempted(true);
    if (nameError || emailError) {
      setPage("profile");
      setDetail(true);
      return;
    }
    if (workspaceError) {
      setPage("workspace");
      setDetail(true);
      return;
    }
    setSaved({ ...values });
    setAttempted(false);
    setStatus("Änderungen für diese Demo gespeichert.");
  }
  return (
    <div className="settings-app-demo">
      <KSettingsPage
        eyebrow="ORBIT STUDIO · EINSTELLUNGEN"
        title={selected.title}
        description={selected.description}
        detailVisible={detail}
        onBack={() => setDetail(false)}
        backLabel="Alle Einstellungen"
        navigation={
          <KSidebar label="Einstellungen" role="navigation">
            <KSidebarHeader>
              <KSidebarItem
                label={"Zur\u00fcck zur App"}
                leading={<KIcon name="arrow-left" />}
                onSelect={onBackToApp}
              />
              <KSearchField
                aria-label="Einstellungen durchsuchen"
                placeholder="Einstellungen suchen…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </KSidebarHeader>
            <KSidebarBody>
              <KSidebarGroup label="Dein Arbeitsbereich">
                {matches.map((p) => (
                  <KSidebarItem
                    key={p.id}
                    label={p.title}
                    leading={<KIcon name={p.icon} />}
                    active={page === p.id}
                    onSelect={() => {
                      setPage(p.id);
                      setDetail(true);
                    }}
                  />
                ))}
                {!matches.length && (
                  <KText role="status">Keine passenden Einstellungen.</KText>
                )}
              </KSidebarGroup>
            </KSidebarBody>
          </KSidebar>
        }
      >
        {state !== "ready" ? (
          <KStack gap="section" align="stretch">
            {state === "loading" ? (
              <KSpinner label="Einstellungen werden geladen" />
            ) : (
              <KAlert
                tone="error"
                title="Einstellungen nicht verfügbar"
                description="Die Verbindung konnte nicht hergestellt werden. Deine Eingaben bleiben erhalten."
              />
            )}
            <KButton onClick={() => setState("ready")}>
              {state === "loading"
                ? "Demo-Laden abschließen"
                : "Erneut versuchen"}
            </KButton>
          </KStack>
        ) : (
          <KStack gap="section" align="stretch">
            {page === "profile" && (
              <>
                <KSettingsSection
                  title="Persönliche Angaben"
                  description="So sehen dich andere Mitglieder deines Teams."
                >
                  <KField
                    label="Anzeigename"
                    required
                    errorText={attempted ? nameError : undefined}
                    helperText="Wird in Kommentaren und Zuweisungen angezeigt."
                  >
                    <KInput
                      value={values.name}
                      onChange={(e) => update("name", e.target.value)}
                      autoComplete="name"
                    />
                  </KField>
                  <KField
                    label="E-Mail-Adresse"
                    required
                    errorText={attempted ? emailError : undefined}
                    helperText="Für wichtige Konto- und Sicherheitsnachrichten."
                  >
                    <KInput
                      type="email"
                      value={values.email}
                      onChange={(e) => update("email", e.target.value)}
                      autoComplete="email"
                    />
                  </KField>
                </KSettingsSection>
                <KAlert
                  title="Deine Daten bleiben privat"
                  description="Diese Referenz speichert nur im lokalen React-Zustand. Es werden keine Daten übertragen."
                  icon="lock"
                />
              </>
            )}
            {page === "preferences" && (
              <KSettingsSection
                title="Persönliche Standards"
                description="Die Auswahl demonstriert Consumer-State. Die Galerie-Vorschau steuerst du weiterhin über die Storybook-Toolbar."
              >
                <KSelect
                  label="Sprache"
                  value={values.language}
                  onValueChange={(v) => update("language", v)}
                  options={[
                    { value: "de", label: "Deutsch" },
                    { value: "en", label: "English" },
                  ]}
                />
                <KRadioGroup
                  label="Farbschema"
                  value={values.appearance}
                  onValueChange={(v) => update("appearance", v)}
                  items={[
                    { value: "system", label: "Systemeinstellung" },
                    { value: "light", label: "Hell" },
                    { value: "dark", label: "Dunkel" },
                  ]}
                />
                <KSelect
                  label="Informationsdichte"
                  value={values.density}
                  onValueChange={(v) => update("density", v)}
                  options={[
                    { value: "dense", label: "Kompakt" },
                    { value: "standard", label: "Standard" },
                    { value: "spacious", label: "Großzügig" },
                  ]}
                />
              </KSettingsSection>
            )}
            {page === "notifications" && (
              <>
                <KSettingsSection
                  title="Direkte Benachrichtigungen"
                  description="Wichtige Ereignisse, ohne unnötige Unterbrechungen."
                >
                  <KSettingsRow
                    title="Erwähnungen"
                    description="Wenn jemand dich direkt in einem Kommentar anspricht."
                    layout="compact"
                    control={
                      <KSwitch
                        label="Erwähnungen"
                        showLabel={false}
                        checked={values.mentions}
                        onCheckedChange={(v) => update("mentions", v)}
                      />
                    }
                  />
                </KSettingsSection>
                <KSettingsSection
                  title="Zusammenfassung"
                  description="Ein Überblick über die Aktivitäten deines Teams."
                >
                  <KCheckbox
                    label="Zusammenfassung per E-Mail erhalten"
                    value={values.digest}
                    onValueChange={(v) => update("digest", v)}
                  />
                  <KRadioGroup
                    label="Häufigkeit"
                    disabled={!values.digest}
                    value={values.frequency}
                    onValueChange={(v) => update("frequency", v)}
                    items={[
                      { value: "daily", label: "Täglich" },
                      { value: "weekly", label: "Wöchentlich" },
                    ]}
                  />
                </KSettingsSection>
              </>
            )}
            {page === "workspace" && (
              <KSettingsSection
                title="Team-Einstellungen"
                description="Diese Standards gelten für neue Inhalte im Workspace."
              >
                <KField
                  label="Workspace-Name"
                  required
                  errorText={attempted ? workspaceError : undefined}
                >
                  <KInput
                    value={values.workspace}
                    onChange={(e) => update("workspace", e.target.value)}
                  />
                </KField>
                <KSelect
                  label="Standardsichtbarkeit"
                  value={values.visibility}
                  onValueChange={(v) => update("visibility", v)}
                  options={[
                    { value: "private", label: "Nur eingeladene Mitglieder" },
                    { value: "team", label: "Alle im Workspace" },
                  ]}
                />
              </KSettingsSection>
            )}
            {page === "connections" && (
              <KSettingsSection
                title="Verbundene Dienste"
                description="Du entscheidest, welche Dienste Zugriff erhalten."
              >
                <KAlert
                  title={
                    connected ? "Kalender verbunden" : "Noch keine Verbindungen"
                  }
                  description={
                    connected
                      ? "Demo-Verbindung aktiv. Es wurde kein externer Dienst autorisiert."
                      : "Verbinde einen Dienst, um ihn hier zu verwalten."
                  }
                  icon="calendar"
                  tone={connected ? "success" : "neutral"}
                />
                <KButton
                  variant="secondary"
                  onClick={() => setConnected((v) => !v)}
                >
                  {connected
                    ? "Demo-Verbindung trennen"
                    : "Demo-Kalender verbinden"}
                </KButton>
              </KSettingsSection>
            )}
            {dirty && (
              <KAlert
                tone="warning"
                title="Ungespeicherte Änderungen"
                description="Deine Eingaben bleiben beim Wechsel der Kategorie erhalten. Speichern übernimmt alle Kategorien."
              />
            )}
            <KInline gap="action" wrap>
              <KButton disabled={!dirty} onClick={save}>
                Änderungen speichern
              </KButton>
              <KButton
                variant="secondary"
                disabled={!dirty}
                onClick={() => {
                  setValues({ ...saved });
                  setAttempted(false);
                  setStatus("Änderungen verworfen.");
                }}
              >
                Verwerfen
              </KButton>
            </KInline>
            {status && (
              <KText role="status" variant="bodySmall">
                {status}
              </KText>
            )}
          </KStack>
        )}
      </KSettingsPage>
    </div>
  );
}
