import { useMemo, useState, type CSSProperties } from "react";
import {
  KAgentSwitcher,
  KChatComposer,
  KChatConversation,
  KIcon,
  KText,
  type KAgentSwitcherItem,
  type KChatMessageValue,
} from "@k-design-system/ui";

const agents: readonly KAgentSwitcherItem[] = [
  {
    id: "ada",
    name: "Ada",
    avatar: "🧭",
    connection: "online",
    activity: "working",
    unread: 2,
  },
  {
    id: "linus",
    name: "Linus",
    avatar: "🌙",
    connection: "sleeping",
    activity: "idle",
  },
  {
    id: "mira",
    name: "Mira",
    avatar: "✨",
    connection: "online",
    activity: "needs-input",
    unread: 1,
  },
];

const initialMessages: Record<string, KChatMessageValue[]> = {
  ada: [
    {
      id: "ada-user",
      role: "user",
      authorLabel: "Du",
      parts: [
        {
          id: "ada-user-text",
          type: "text",
          text: "Prüfe bitte den aktuellen Web-Build.",
        },
      ],
    },
    {
      id: "ada-agent",
      role: "assistant",
      authorLabel: "Ada",
      parts: [
        {
          id: "ada-agent-text",
          type: "text",
          text: "Ich prüfe gerade Komponenten und Tastaturbedienung.",
        },
      ],
    },
  ],
  linus: [
    {
      id: "linus-agent",
      role: "assistant",
      authorLabel: "Linus",
      parts: [
        {
          id: "linus-agent-text",
          type: "text",
          text: "Die letzte Analyse ist abgeschlossen. Ich bin im Ruhemodus.",
        },
      ],
    },
  ],
  mira: [
    {
      id: "mira-agent",
      role: "assistant",
      authorLabel: "Mira",
      parts: [
        {
          id: "mira-agent-text",
          type: "text",
          text: "Soll ich die kurze oder die ausführliche Zusammenfassung vorbereiten?",
        },
      ],
    },
  ],
};

const shellStyle: CSSProperties = {
  width: "100%",
  height: "100dvh",
  minHeight: 0,
  display: "grid",
  gridTemplateRows: "auto auto minmax(0, 1fr) auto",
  overflow: "hidden",
  background: "var(--k-color-surface-canvas)",
};

const demoLabelStyle: CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  gap: "var(--k-space-control-gap)",
  padding: "var(--k-space-control-gap) var(--k-space-layout-gutter)",
  borderBottom:
    "var(--k-border-width-default) solid var(--k-color-border-default)",
};

const conversationStyle: CSSProperties = {
  width: "min(820px, 100%)",
  minHeight: 0,
  justifySelf: "center",
};

const germanLabels = {
  agents: "Persönliche Agenten",
  connectionOnline: "Online",
  connectionOffline: "Offline",
  connectionUnknown: "Unbekannt",
  connectionSleeping: "Schläft",
  activityIdle: "In Ruhe",
  activityWorking: "Arbeitet",
  activityNeedsInput: "Benötigt Eingabe",
  connectionPrefix: "Verbindung",
  activityPrefix: "Aktivität",
  unreadMessages: (count: number) =>
    `${count} ${count === 1 ? "ungelesene Nachricht" : "ungelesene Nachrichten"}`,
  reorderInstruction:
    "Gedrückt halten und ziehen. Mit der Tastatur Alt plus Pfeil links oder rechts verwenden.",
  reorderAnnouncement: (name: string, position: number, count: number) =>
    `${name} ist an Position ${position} von ${count}.`,
};

export function AgentSwitcherFixture() {
  const [agentItems, setAgentItems] =
    useState<readonly KAgentSwitcherItem[]>(agents);
  const [selectedId, setSelectedId] = useState<string | null>("ada");
  const [drafts, setDrafts] = useState<Record<string, string>>({
    ada: "Ergänze danach bitte die mobilen Zustände.",
    linus: "",
    mira: "Nimm die kurze Zusammenfassung.",
  });
  const [messagesByAgent, setMessagesByAgent] =
    useState<Record<string, KChatMessageValue[]>>(initialMessages);
  const [manageNote, setManageNote] = useState("");
  const selected = useMemo(
    () => agentItems.find((agent) => agent.id === selectedId) ?? agentItems[0],
    [agentItems, selectedId],
  );
  const runState =
    selected.activity === "working"
      ? "streaming"
      : selected.activity === "needs-input"
        ? "awaiting-input"
        : "idle";

  const submit = (text: string) => {
    setMessagesByAgent((current) => ({
      ...current,
      [selected.id]: [
        ...current[selected.id],
        {
          id: `${selected.id}-user-${current[selected.id].length}`,
          role: "user",
          authorLabel: "Du",
          parts: [
            {
              id: `${selected.id}-text-${current[selected.id].length}`,
              type: "text",
              text,
            },
          ],
        },
      ],
    }));
    setDrafts((current) => ({ ...current, [selected.id]: "" }));
  };

  return (
    <main
      className="k-agent-ui-fixture"
      style={shellStyle}
      aria-label="Agenten-Chat Demo"
    >
      <KAgentSwitcher
        items={agentItems}
        selectedId={selected.id}
        onSelect={(id) => {
          setSelectedId(id);
          setManageNote("");
        }}
        onManage={() => setManageNote("Agentenauswahl geöffnet (Demo)")}
        labels={germanLabels}
      />
      <div style={demoLabelStyle}>
        <KText variant="bodySmall">
          Demodaten · keine echten Agenten oder Arbeitsläufe
        </KText>
        <KText variant="caption" aria-live="polite">
          {manageNote || `Chat mit ${selected.name}`}
        </KText>
      </div>
      <KChatConversation
        style={conversationStyle}
        messages={messagesByAgent[selected.id]}
        runState={runState}
        metadataMode="grouped"
        labels={{ assistant: selected.name, user: "Du" }}
      />
      <KChatComposer
        value={drafts[selected.id] ?? ""}
        onValueChange={(value) =>
          setDrafts((current) => ({ ...current, [selected.id]: value }))
        }
        onSubmit={submit}
        onStop={() =>
          setAgentItems((current) =>
            current.map((agent) =>
              agent.id === selected.id ? { ...agent, activity: "idle" } : agent,
            ),
          )
        }
        runState={runState}
        labels={{ placeholder: `Nachricht an ${selected.name}…` }}
      />
    </main>
  );
}

const showcaseAgents: readonly KAgentSwitcherItem[] = [
  {
    id: "nova",
    name: "Nova",
    avatar: <KIcon name="sparkles" />,
    nameContent: <strong>Nova</strong>,
    statusContent: <span>Plant</span>,
    badgeContent: "VIP",
    semanticLabel: "Nova, plant, VIP",
    connection: "online",
    activity: "working",
    unread: 3,
    connectionColor: "var(--k-color-brand-secondary-accent)",
    statusColor: "var(--k-color-brand-secondary-foreground)",
    badgeColor: "var(--k-color-brand-secondary-background)",
    badgeForeground: "var(--k-color-brand-secondary-foreground)",
    selectedColor: "var(--k-color-brand-secondary-accent)",
  },
  {
    id: "atlas",
    name: "Atlas",
    avatar: <KIcon name="bot" />,
    connection: "offline",
    activity: "idle",
  },
  {
    id: "echo",
    name: "Echo",
    avatar: <KIcon name="audio-waveform" />,
    semanticLabel: "Echo, kompakte Darstellung",
    showName: false,
  },
  {
    id: "sage",
    name: "Sage",
    connection: "unknown",
    activity: "needs-input",
    unread: 1,
  },
  {
    id: "pixel",
    name: "Pixel",
    connection: "online",
    activity: "idle",
  },
  {
    id: "lumen",
    name: "Lumen",
    connection: "sleeping",
    activity: "idle",
  },
  {
    id: "orbit",
    name: "Orbit",
    connection: "offline",
    activity: "idle",
  },
  {
    id: "quill",
    name: "Quill",
    connection: "online",
    activity: "working",
  },
  {
    id: "wren",
    name: "Wren",
    connection: "online",
    activity: "idle",
  },
  {
    id: "iris",
    name: "Iris",
    connection: "online",
    activity: "needs-input",
  },
  {
    id: "sol",
    name: "Sol",
    connection: "sleeping",
    activity: "idle",
  },
  {
    id: "moss",
    name: "Moss",
    connection: "offline",
    activity: "idle",
  },
  {
    id: "coda",
    name: "Coda",
    connection: "online",
    activity: "working",
  },
  {
    id: "finn",
    name: "Finn",
    connection: "unknown",
    activity: "idle",
  },
];

export interface AgentSwitcherShowcaseProps {
  showConnections?: boolean;
  showActivity?: boolean;
  showUnread?: boolean;
  customColors?: boolean;
  reorderable?: boolean;
}

export function AgentSwitcherShowcaseFixture({
  showConnections = true,
  showActivity = true,
  showUnread = true,
  customColors = true,
  reorderable = false,
}: AgentSwitcherShowcaseProps) {
  const [items, setItems] =
    useState<readonly KAgentSwitcherItem[]>(showcaseAgents);
  const [selectedId, setSelectedId] = useState<string | null>("nova");
  const [note, setNote] = useState("Bereit");
  const visibleItems = items.map((item) => ({
    ...item,
    connection: showConnections ? item.connection : undefined,
    activity: showActivity ? item.activity : undefined,
    statusContent: showActivity ? item.statusContent : undefined,
    unread: showUnread ? item.unread : undefined,
    badgeContent: showUnread ? item.badgeContent : undefined,
    connectionColor: customColors ? item.connectionColor : undefined,
    statusColor: customColors ? item.statusColor : undefined,
    badgeColor: customColors ? item.badgeColor : undefined,
    badgeForeground: customColors ? item.badgeForeground : undefined,
    selectedColor: customColors ? item.selectedColor : undefined,
  }));

  const applyOrder = (ids: string[]) => {
    setItems((current) =>
      ids.flatMap((id) => {
        const item = current.find((candidate) => candidate.id === id);
        return item ? [item] : [];
      }),
    );
    setNote(`Reihenfolge: ${ids.join(", ")}`);
  };

  return (
    <section
      style={{
        width: "min(680px, 100%)",
        display: "grid",
        gap: "var(--k-space-layout-gutter)",
      }}
      aria-label="Konfigurierbarer Agentenumschalter"
    >
      <KAgentSwitcher
        items={visibleItems}
        selectedId={selectedId}
        onSelect={(id) => {
          setSelectedId(id);
          setNote(`Auswahl: ${id}`);
        }}
        onReorder={reorderable ? applyOrder : undefined}
        onLongPress={(id) => setNote(`Langdruck: ${id}`)}
        labels={germanLabels}
      />
      <KText variant="bodySmall">
        {reorderable
          ? "Sortieren: gedrückt halten und ziehen oder Alt + Pfeiltasten verwenden."
          : "Benutzerdefinierte Inhalte bleiben innerhalb der standardisierten Avatarfläche."}
      </KText>
      <KText variant="caption" aria-live="polite">
        {note}
      </KText>
    </section>
  );
}
