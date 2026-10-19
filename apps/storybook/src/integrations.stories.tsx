import { useState, type ReactNode } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KBadge, KButton, KText } from "@k-design-system/ui";
import {
  KIntegrationAdminCatalog,
  KIntegrationEditor,
  type KIntegrationDraft,
  KIntegrationConnectionCard,
  KIntegrationMarketplace,
  type KIntegrationCatalogItem,
  type KIntegrationConnectionState,
  type KIntegrationItem,
} from "@k-design-system/ui/patterns/integrations";
import { BrandMark } from "./integrations-brand-marks.js";
import tasksIcon from "./assets/tasks-icon.png";

const baseIntegrations: readonly KIntegrationItem[] = [
  {
    id: "tasks",
    name: "Tasks",
    category: "planning",
    description:
      "Aufgaben und Projekte finden, planen und mit deinem Assistenten bearbeiten.",
    icon: <img src={tasksIcon} alt="" width={28} height={28} />,
    availabilityLabel: "MCP-Server",
  },
  {
    id: "gmail",
    name: "Gmail",
    category: "communication",
    description:
      "E-Mails finden, lesen und als Kontext für Aufgaben verwenden.",
    icon: <BrandMark brand="gmail" />,
    state: "connected",
    availabilityLabel: "Developer Preview",
    accountLabel: "arbeit@beispiel.de",
  },
  {
    id: "outlook",
    name: "Outlook",
    category: "communication",
    description: "Postfach und Kalender für Termin- und Nachrichtenaufgaben.",
    icon: <BrandMark brand="outlook" />,
  },
  {
    id: "github",
    name: "GitHub",
    category: "development",
    description: "Issues, Pull Requests und Repositories als Arbeitskontext.",
    icon: <BrandMark brand="github" />,
    state: "error",
  },
  {
    id: "sentry",
    name: "Sentry",
    category: "development",
    description: "Fehler, Releases und betroffene Dienste untersuchen.",
    icon: <BrandMark brand="sentry" />,
  },
  {
    id: "notion",
    name: "Notion",
    category: "knowledge",
    description:
      "Seiten und Datenbanken nach freigegebenem Wissen durchsuchen.",
    icon: <BrandMark brand="notion" />,
  },
  {
    id: "linear",
    name: "Linear",
    category: "planning",
    description: "Projekte, Issues und Zyklen für Planung und Status nutzen.",
    icon: <BrandMark brand="linear" />,
  },
  {
    id: "slack",
    name: "Slack",
    category: "communication",
    description: "Freigegebene Channels und Threads als Teamkontext verwenden.",
    icon: <BrandMark brand="slack" />,
    state: "unavailable",
    availabilityLabel: "Workspace-Freigabe nötig",
  },
];

const categories = [
  { id: "all", label: "Alle" },
  { id: "communication", label: "Kommunikation" },
  { id: "development", label: "Entwicklung" },
  { id: "planning", label: "Planung" },
  { id: "knowledge", label: "Wissen" },
] as const;

function PreviewFrame({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        minHeight: "100vh",
        paddingBlock: "var(--k-space-card-padding)",
      }}
    >
      <div
        style={{
          width: "min(100% - 32px, 1120px)",
          margin: "0 auto var(--k-space-control-gap)",
        }}
      >
        <KBadge
          variant="warning"
          style={{ whiteSpace: "normal", maxWidth: "100%" }}
        >
          Interaktive Vorschau · keine echte Anmeldung
        </KBadge>
      </div>
      {children}
    </div>
  );
}

function MarketplaceFixture() {
  const [items, setItems] = useState(baseIntegrations);
  const [category, setCategory] = useState("all");
  const [query, setQuery] = useState("");
  const [activeId, setActiveId] = useState<string>();

  const updateState = (
    id: string,
    state: KIntegrationConnectionState,
    accountLabel?: ReactNode,
  ) =>
    setItems((current) =>
      current.map((item) =>
        item.id === id
          ? {
              ...item,
              state,
              accountLabel: state === "connected" ? accountLabel : undefined,
            }
          : item,
      ),
    );

  return (
    <PreviewFrame>
      <KIntegrationMarketplace
        integrations={items}
        categories={categories}
        activeCategory={category}
        searchValue={query}
        activeIntegrationId={activeId}
        onCategoryChange={setCategory}
        onSearchChange={setQuery}
        onConnect={(item) => {
          setActiveId(item.id);
        }}
        onDisconnect={(item) => updateState(item.id, "disconnected")}
        renderPanel={(item) => (
          <KIntegrationConnectionCard
            name={item.name}
            icon={item.icon}
            description="Anmeldung und Kontoauswahl erfolgen beim jeweiligen Dienst. Hier simulieren wir nur die erfolgreiche Rückkehr."
            permissions={[
              "Freigegebene Inhalte lesen",
              "Verbindung jederzeit trennen",
            ]}
            state="disconnected"
            stateLabel="Nicht verbunden"
            connectLabel="OAuth-Rückkehr simulieren"
            onConnect={() => {
              updateState(item.id, "connected", "demo@beispiel.de");
              setActiveId(undefined);
            }}
          />
        )}
      />
    </PreviewFrame>
  );
}

function ChatConnectionFixture() {
  const [state, setState] =
    useState<KIntegrationConnectionState>("disconnected");
  const stateLabels: Record<KIntegrationConnectionState, string> = {
    disconnected: "Nicht verbunden",
    pending: "Simulierter Verbindungstest läuft",
    connected: "Arbeit · dennis@unternehmen.de",
    error: "Simulation fehlgeschlagen",
    unavailable: "Voraussetzungen fehlen",
  };
  const simulate = () => setState("pending");
  return (
    <PreviewFrame>
      <div style={{ width: "min(100% - 32px, 620px)", margin: "48px auto" }}>
        <KIntegrationConnectionCard
          name="Gmail"
          icon={<BrandMark brand="gmail" />}
          availability="Developer Preview"
          description="Lass Assist E-Mails finden und relevante Inhalte in deiner Unterhaltung zusammenfassen."
          permissions={[
            "Betreff und Inhalt freigegebener E-Mails lesen",
            "Anhänge nur nach Auswahl öffnen",
            "Keine E-Mail ohne Bestätigung senden",
          ]}
          state={state}
          stateLabel={stateLabels[state]}
          connectLabel="Verbindung simulieren"
          onConnect={simulate}
          onRetry={simulate}
          onDisconnect={() => setState("disconnected")}
        />
        {state === "pending" ? (
          <div
            style={{
              marginTop: "var(--k-space-control-gap)",
              display: "flex",
              flexWrap: "wrap",
              gap: "var(--k-space-control-gap)",
            }}
          >
            <KButton onClick={() => setState("connected")}>
              Erfolg simulieren
            </KButton>
            <KButton variant="secondary" onClick={() => setState("error")}>
              Fehler simulieren
            </KButton>
            <KButton variant="ghost" onClick={() => setState("disconnected")}>
              Abbrechen
            </KButton>
          </div>
        ) : null}
      </div>
    </PreviewFrame>
  );
}

function ConnectionStatesFixture() {
  const states: readonly KIntegrationConnectionState[] = [
    "disconnected",
    "pending",
    "connected",
    "error",
    "unavailable",
  ];
  const labels = [
    "Nicht verbunden",
    "Verbindung wird simuliert",
    "Arbeit · verbunden",
    "Test fehlgeschlagen",
    "Workspace-Freigabe nötig",
  ];
  return (
    <PreviewFrame>
      <div
        style={{
          width: "min(100% - 32px, 1120px)",
          margin: "32px auto",
          display: "grid",
          gridTemplateColumns:
            "repeat(auto-fit, minmax(min(100%, 320px), 1fr))",
          gap: "var(--k-space-control-inset-inline)",
          alignItems: "start",
        }}
      >
        {states.map((state, index) => (
          <KIntegrationConnectionCard
            key={state}
            name={`Linear · ${state}`}
            icon={<BrandMark brand="linear" />}
            description="Fest definierter Zustand für Review und Barrierefreiheitsprüfung."
            permissions={[
              "Ausgewählte Projekte lesen",
              "Issues als Kontext verwenden",
            ]}
            state={state}
            stateLabel={labels[index]}
            onConnect={() => undefined}
            onRetry={() => undefined}
            onDisconnect={() => undefined}
          />
        ))}
      </div>
    </PreviewFrame>
  );
}

const catalogSeed: readonly KIntegrationCatalogItem[] = baseIntegrations.map(
  (item, index) => ({
    ...item,
    category:
      categories.find((category) => category.id === item.category)?.label ??
      item.category,
    endpoint: `https://mcp.example.test/${item.id}`,
    catalogState: index < 2 ? "published" : index < 5 ? "tested" : "draft",
  }),
);

function AdminCatalogFixture() {
  const [items, setItems] = useState(catalogSeed);

  const [message, setMessage] = useState(
    "Änderungen bleiben bis zum Neuladen in dieser Vorschau.",
  );
  const [editor, setEditor] = useState<{
    id?: string;
    value?: KIntegrationDraft;
    icon?: ReactNode;
    state?: KIntegrationCatalogItem["catalogState"];
  }>();
  const [settings, setSettings] = useState<Record<string, KIntegrationDraft>>(
    {},
  );
  const [testError, setTestError] = useState(false);
  const save = (
    value: KIntegrationDraft,
    state: KIntegrationCatalogItem["catalogState"],
  ) => {
    const id = editor?.id ?? crypto.randomUUID();
    const previous = items.find((item) => item.id === id);
    const item: KIntegrationCatalogItem = {
      id,
      name: value.name,
      description: value.description,
      category: value.category,
      endpoint: value.endpoint,
      catalogState: state,
      icon: value.iconDataUrl ? (
        <img src={value.iconDataUrl} alt="" width={28} height={28} />
      ) : (
        (previous?.icon ?? value.name.slice(0, 1))
      ),
    };
    setItems((current) =>
      previous
        ? current.map((entry) => (entry.id === id ? item : entry))
        : [...current, item],
    );
    setSettings((current) => ({ ...current, [id]: value }));

    setEditor(undefined);
    setMessage(
      `${value.name} gespeichert. Änderungen gelten nur in dieser Vorschau.`,
    );
  };
  return (
    <PreviewFrame>
      <KIntegrationAdminCatalog
        integrations={items}

        onCreate={() => setEditor({})}
        onEdit={(item) =>
          setEditor({
            id: item.id,
            state: item.catalogState,
            icon: item.icon,
            value: settings[item.id] ?? {
              name: item.name,
              description: String(item.description),
              category: item.category,
              endpoint: String(item.endpoint),
              authType: "oauth",
              clientId: "",
              scopes: "",
              iconDataUrl: "",
            },
          })
        }
      />
      {editor ? (
        <KIntegrationEditor
          key={editor.id ?? "new"}
          open
          onOpenChange={(open) => !open && setEditor(undefined)}
          value={editor.value}
          icon={editor.icon}
          catalogState={editor.state}
          onSave={save}
          onPublish={(value) => save(value, "published")}
          onTest={() => !testError}
          testControls={
            <KButton
              type="button"
              variant="ghost"
              onClick={() => setTestError(!testError)}
            >
              {testError
                ? "Testausgang: Fehler (ändern)"
                : "Testausgang: Erfolg (ändern)"}
            </KButton>
          }
        />
      ) : null}
      <KText
        as="p"
        variant="caption"
        role="status"
        aria-live="polite"
        style={{ width: "min(100% - 32px, 980px)", margin: "0 auto" }}
      >
        {message}
      </KText>
    </PreviewFrame>
  );
}

const meta = {
  title: "Patterns/Integrations",
  component: MarketplaceFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof MarketplaceFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Marketplace: Story = {
  parameters: { fixtureId: "integrations-marketplace" },
  render: () => <MarketplaceFixture />,
};
export const ChatConnection: Story = {
  parameters: { fixtureId: "integrations-chat-connection" },
  render: () => <ChatConnectionFixture />,
};
export const ConnectionStates: Story = {
  parameters: { fixtureId: "integrations-connection-states" },
  render: () => <ConnectionStatesFixture />,
};
export const AdminCatalog: Story = {
  parameters: { fixtureId: "integrations-admin-catalog" },
  render: () => <AdminCatalogFixture />,
};
