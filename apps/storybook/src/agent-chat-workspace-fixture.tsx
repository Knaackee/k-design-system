import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
} from "react";
import {
  KAgentChatWorkspace,
  KCallBar,
  KButton,
  KUsageDetails,
  KAgentSwitcher,
  KSelect,
  KMenuButton,
  KIcon,
  KChatComposer,
  KChatConversation,
  KIconButton,
  type KAgentActivityState,
  type KAgentConnection,
  type KAgentSwitcherItem,
  type KChatMessageValue,
  type KChatAttachmentPart,
  type KChatRunState,
} from "@k-design-system/ui";
import { AgentWorkspaceAvatar } from "./agent-workspace-avatar.js";
import "./agent-chat-workspace-fixture.css";

type FixtureVariant =
  "fullscreen" | "needs-input" | "offline" | "mobile" | "empty";
type AvatarShape = "circle" | "squircle" | "star" | "capsule";
type AvatarStatus = "idle" | "working" | "waiting" | "blocked";

interface FixtureAgent extends KAgentSwitcherItem {
  color: string;
  shape: AvatarShape;
  heroStatus: AvatarStatus;
  statusLabel: string;
  runState: KChatRunState;
}

const initialAgents: readonly FixtureAgent[] = [
  {
    id: "ada",
    name: "Ada",
    color: "#35a66f",
    shape: "circle",
    heroStatus: "idle",
    connection: "online",
    activity: "idle",
    statusLabel: "Bereit",
    runState: "idle",
  },
  {
    id: "linus",
    name: "Linus",
    color: "#397bd9",
    shape: "squircle",
    heroStatus: "working",
    connection: "online",
    activity: "working",
    statusLabel: "Arbeitet",
    runState: "streaming",
  },
  {
    id: "mira",
    name: "Mira",
    color: "#8b5fd3",
    shape: "star",
    heroStatus: "waiting",
    connection: "online",
    activity: "needs-input",
    unread: 1,
    statusLabel: "Benötigt Eingabe",
    runState: "awaiting-input",
  },
  {
    id: "nova",
    name: "Nova",
    color: "#df8736",
    shape: "capsule",
    heroStatus: "idle",
    connection: "sleeping",
    activity: "idle",
    statusLabel: "In Ruhe",
    runState: "idle",
  },
  {
    id: "pi",
    name: "Lokaler Pi",
    color: "#249c98",
    shape: "circle",
    heroStatus: "blocked",
    connection: "offline",
    activity: "idle",
    statusLabel: "Offline",
    runState: "failed",
  },
];

const germanLabels = {
  agents: "Agenten",
  connectionOnline: "Online",
  connectionOffline: "Offline",
  connectionUnknown: "Unbekannt",
  connectionSleeping: "In Ruhe",
  activityIdle: "Bereit",
  activityWorking: "Arbeitet",
  activityNeedsInput: "Benötigt Eingabe",
  connectionPrefix: "Verbindung",
  activityPrefix: "Status",
  unreadMessages: (count: number) =>
    `${count} ${count === 1 ? "ungelesene Nachricht" : "ungelesene Nachrichten"}`,
  reorderInstruction:
    "Gedrückt halten und ziehen. Mit Alt und Pfeil links oder rechts sortieren.",
  reorderInstructionVertical:
    "Gedrückt halten und ziehen. Mit Alt und Pfeil hoch oder runter sortieren.",
  reorderAnnouncement: (name: string, position: number, count: number) =>
    `${name} ist an Position ${position} von ${count}.`,
};

const sessions = ["Aktuelles Gespräch", "Release vorbereiten"] as const;

const fixtureConversation: { role: "user" | "assistant"; text: string }[] = [
  {
    role: "user",
    text: "Was müssen wir vor der Freitagsvorschau prüfen?",
  },
  {
    role: "assistant",
    text: "Wir sollten die Vorschau an drei konkreten Aufgaben prüfen: ein Gespräch beginnen, zwischen zwei Agenten wechseln und eine laufende Antwort stoppen. Für jede Aufgabe halten wir fest, was die Person sehen und tun können muss.\n\n1. Öffne die Agentenliste und wähle eine andere Person aus. Der Entwurf des bisherigen Gesprächs bleibt erhalten.\n2. Schreibe eine kurze Nachricht und danach einen längeren Absatz. Die Eingabe darf die Antwortgeschichte nicht verdecken.\n3. Öffne die Tastatur, scrolle zu einer früheren Antwort und kehre zur neuesten Nachricht zurück.\n4. Trenne die Verbindung. Die Oberfläche erklärt den Zustand, ohne einen erfolgreichen Versand vorzutäuschen.\n\nFür die Abnahme brauchen wir zusätzlich ein schmales Telefon und ein Tablet. Ein einzelnes Bildschirmfoto zeigt die Abstände, aber erst das Scrollen macht sichtbar, ob Avatar, Text und Eingabe dauerhaft zusammenpassen.",
  },
  {
    role: "user",
    text: "Beginne am Telefon. Der Avatar darf nichts verdecken.",
  },
  {
    role: "assistant",
    text: "Ja. Der Avatar liegt als kleine Ebene über dem Gespräch. Am Anfang gibt es etwas Abstand innerhalb des scrollbaren Verlaufs. Dieser Abstand verschwindet beim Scrollen mit den Nachrichten; er verkleinert den verfügbaren Bereich nicht dauerhaft.\n\nWenn die Tastatur erscheint, wird der Avatar kleiner. Die Gesprächsauswahl, die Schaltfläche für ein neues Gespräch und das Schließen bleiben erreichbar. Lange Namen kürzen wir sichtbar ab, während die vollständige Bezeichnung für assistive Technologien erhalten bleibt.",
  },
  {
    role: "user",
    text: "Wie prüfe ich die getrennten Entwürfe?",
  },
  {
    role: "assistant",
    text: "Ein kurzer Test reicht:\n\n- Schreibe bei Ada „Termin am Donnerstag“ und sende noch nicht.\n- Wechsle zu Linus und schreibe „Build prüfen“.\n- Kehre zu Ada zurück. Dort muss wieder „Termin am Donnerstag“ stehen.\n- Öffne bei Ada ein neues Gespräch. Dieses beginnt mit einer leeren Eingabe.\n- Wähle das erste Gespräch erneut. Sein bisheriger Entwurf erscheint wieder.\n\nDie Vorschau verwendet ausschließlich lokale Beispieldaten. Es werden keine echten Agenten angeschrieben und keine Änderungen an einer produktiven Unterhaltung gespeichert.",
  },
  {
    role: "user",
    text: "Ergänze einen kurzen Rückblick für Freitag.",
  },
  {
    role: "assistant",
    text: "**Rückblick für die Vorschau**\n\nDie wichtigsten Wege sind jetzt beschrieben: Auswahl, getrennte Entwürfe, Senden, Stoppen und die Rückkehr zu früheren Nachrichten. Offen bleibt die visuelle Prüfung auf beiden Geräten mit eingeblendeter Tastatur, langen Antworten und wechselnder Verbindung.\n\nFür den nächsten Durchgang nehmen wir genau diesen längeren Beispielverlauf. Wir lesen eine ältere Liste, scrollen wieder nach unten und schreiben eine neue Nachricht. So prüfen wir die Oberfläche im tatsächlichen Gebrauch statt nur im leeren Zustand.\n\nDie Reihenfolge für Freitag lautet: erst die Geräteprüfung abschließen, dann die gefundenen Abstandsprobleme korrigieren und zuletzt die gemeinsam geprüfte Vorschau freigeben.",
  },
];

const baseMessages: Record<string, KChatMessageValue[]> = Object.fromEntries(
  initialAgents.map((agent) => [
    agent.id,
    [
      {
        id: `${agent.id}-user`,
        role: "user",
        authorLabel: "Du",
        parts: [
          {
            id: `${agent.id}-request`,
            type: "text",
            text: `Hilf mir bitte beim nächsten Schritt, ${agent.name}.`,
          },
        ],
      },
      {
        id: `${agent.id}-assistant`,
        role: "assistant",
        authorLabel: agent.name,
        parts: [
          {
            id: `${agent.id}-answer`,
            type: "text",
            text:
              agent.id === "mira"
                ? "Soll ich zuerst die mobile Ansicht oder die Tastaturbedienung prüfen?"
                : agent.id === "pi"
                  ? "Die lokale Verbindung ist unterbrochen. Entwürfe bleiben auf diesem Gerät erhalten."
                  : "Ich habe den Kontext und bereite einen klaren nächsten Schritt vor.",
          },
        ],
      },
      ...fixtureConversation.map((turn, index): KChatMessageValue => ({
        id: agent.id + "-continued-" + index,
        role: turn.role,
        authorLabel: turn.role === "assistant" ? agent.name : "Du",
        parts: [
          {
            id: agent.id + "-continued-text-" + index,
            type: "text",
            text: turn.text,
          },
        ],
      })),
    ],
  ]),
);

function RosterAvatar({ agent }: { agent: FixtureAgent }) {
  return (
    <span
      className="agent-chat-workspace-fixture__roster-avatar"
      data-shape={agent.shape}
      style={{ "--agent-avatar-color": agent.color } as CSSProperties}
    >
      {agent.shape === "star" ? "★" : agent.name.slice(0, 1)}
    </span>
  );
}

export function AgentChatWorkspaceFixture({
  variant = "fullscreen",
}: {
  variant?: FixtureVariant;
}) {
  const resetExpiries = ["21. Oktober 2026", "28. Oktober 2026"];
  const initialSelected =
    variant === "needs-input" ? "mira" : variant === "offline" ? "pi" : "ada";
  const [agents, setAgents] = useState(initialAgents);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [chatOpen, setChatOpen] = useState(true);
  const [callOpen, setCallOpen] = useState(false);
  const [callExpanded, setCallExpanded] = useState(true);
  const [callMuted, setCallMuted] = useState(false);
  const [callSeconds, setCallSeconds] = useState(0);
  const callOrigin = useRef<DOMRect | null>(null);
  const pattern = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!callOpen) return;
    const timer = setInterval(
      () => setCallSeconds((seconds) => seconds + 1),
      1000,
    );
    return () => clearInterval(timer);
  }, [callOpen]);
  const [selectedId, setSelectedId] = useState(initialSelected);
  const [selectedSessions, setSelectedSessions] = useState<
    Record<string, string>
  >({});
  const [sessionLists, setSessionLists] = useState<Record<string, string[]>>(
    {},
  );
  const [attachments, setAttachments] = useState<
    Record<string, KChatAttachmentPart[]>
  >({});
  const [voiceKey, setVoiceKey] = useState<string | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string>>(
    variant === "empty"
      ? {}
      : {
          "ada/Aktuelles Gespräch": "Prüfe auch den kleinen Bildschirm.",
          linus: "",
          "mira/Aktuelles Gespräch": "Beginne mit der mobilen Ansicht.",
          nova: "",
          "pi/Aktuelles Gespräch": "Dieser Entwurf bleibt lokal.",
        },
  );
  const [messages, setMessages] = useState<Record<string, KChatMessageValue[]>>(
    variant === "empty"
      ? {}
      : Object.fromEntries(
          Object.entries(baseMessages).map(([id, value]) => [
            `${id}/${sessions[0]}`,
            value,
          ]),
        ),
  );
  const selected = useMemo(
    () => agents.find((agent) => agent.id === selectedId) ?? agents[0],
    [agents, selectedId],
  );

  const selectedSession = selectedSessions[selected.id] ?? sessions[0];
  const recentSessions = sessionLists[selected.id] ?? [...sessions];
  const conversationKey = `${selected.id}/${selectedSession}`;

  const reorder = (ids: string[]) =>
    setAgents((current) =>
      ids.flatMap((id) => {
        const item = current.find((agent) => agent.id === id);
        return item ? [item] : [];
      }),
    );

  const rosterItems = agents.map((agent) => ({
    ...agent,
    avatar: <RosterAvatar agent={agent} />,
    statusContent: agent.statusLabel,
    semanticLabel: `${agent.name}, ${agent.statusLabel}`,
  }));

  const renderSidebar = (close: () => void) => (
    <div className="agent-chat-workspace-fixture__sidebar">
      <KAgentSwitcher
        orientation="vertical"
        items={rosterItems}
        selectedId={selected.id}
        onSelect={(id) => {
          setSelectedId(id);

          close();
        }}
        onReorder={reorder}
        labels={germanLabels}
      />
    </div>
  );

  const addAttachment = (title: string, mediaType: string) =>
    setAttachments((current) => ({
      ...current,
      [conversationKey]: [
        ...(current[conversationKey] ?? []),
        {
          id: `file-${Date.now()}`,
          type: "attachment",
          title,
          description: "Demo-Anhang · nur Vorschau",
          mediaType,
          state: "ready",
        },
      ],
    }));

  const submit = (text: string) => {
    if (callOpen) setCallExpanded(false);
    setMessages((current) => ({
      ...current,
      [conversationKey]: [
        ...(current[conversationKey] ?? []),
        {
          id: `${selected.id}-user-${(current[conversationKey] ?? []).length}`,
          role: "user",
          authorLabel: "Du",
          parts: [
            {
              id: `${selected.id}-text-${(current[conversationKey] ?? []).length}`,
              type: "text",
              text,
            },
          ],
        },
      ],
    }));
    setDrafts((current) => ({ ...current, [conversationKey]: "" }));
  };

  if (!chatOpen)
    return <KButton onClick={() => setChatOpen(true)}>Chat öffnen</KButton>;

  return (
    <div ref={pattern} className="agent-chat-workspace-fixture__pattern">
      <KAgentChatWorkspace
        defaultSidebarCollapsed
        className={
          callOpen ? "agent-chat-workspace-fixture--calling" : undefined
        }
        avatarPopoverActivation="tap"
        avatarSizeCompact={52}
        conversationEmpty={(messages[conversationKey] ?? []).length === 0}
        avatarTransitionDuration={900}
        avatarSizeEmpty={420}
        contentMaxWidth={920}
        rightSidebarOpen={detailsOpen}
        onRightSidebarOpenChange={setDetailsOpen}
        rightSidebarTitle="Kontext"
        rightSidebar={
          <div className="agent-chat-workspace-fixture__context">
            <h2>Kontext</h2>
            <p>
              Platzhalter für Dateien, Ergebnisse und Informationen zum
              aktuellen Gespräch.
            </p>
            <h3>Dateien</h3>
            <p>Projektbrief.pdf</p>
            <h3>Ergebnisse</h3>
            <p>Hier erscheinen später geteilte Inhalte des Agenten.</p>
          </div>
        }
        sidebar={({ close }) => renderSidebar(close)}
        avatar={
          <AgentWorkspaceAvatar
            shape={selected.shape}
            color={selected.color}
            status={selected.heroStatus}
            size={420}
            label={`${selected.name}, ${selected.statusLabel}`}
          />
        }
        title={selected.name}
        avatarLabel={selected.name}
        avatarPopoverLabel={`${selected.name}: Zugang und Kontingente`}
        avatarPopover={
          <div className="agent-chat-workspace-fixture__usage-preview">
            <KUsageDetails
              extraResetsLabel="Zusatzresets"
              extraResets={resetExpiries.map((expiry) => ({
                id: expiry,
                label: `Verfällt am ${expiry}`,
                valueLabel: "1 Reset",
              }))}
              title="Codex"
              sourceLabel="demo@example.com"
              statusLabel="Beispieldaten · Verbunden"
              observedLabel="Gerade eben · Demo"
              windows={[
                {
                  id: "week",
                  label: "7 Tage",
                  valueLabel: "68 % Rest",
                  progress: 68,
                  extraResetCount: resetExpiries.length,
                  renewalLabel: "Reset in 3 Tagen 13 Std.",
                },
              ]}
            />
          </div>
        }
        status={
          selected.statusLabel === "Bereit" ||
          selected.statusLabel === "In Ruhe" ? null : (
            <span
              className="agent-chat-workspace-fixture__status"
              style={
                { "--agent-status-color": selected.color } as CSSProperties
              }
              role="status"
              aria-live={
                selected.activity === "needs-input" ||
                selected.connection === "offline"
                  ? "polite"
                  : "off"
              }
            >
              {selected.statusLabel} · {selectedSession}
            </span>
          )
        }
        actions={
          <>
            <KSelect
              presentation="inline"
              label="Letzte Sessions"
              optionsLabel="Letzte Sessions"
              value={selectedSession}
              options={recentSessions.map((session) => ({
                value: session,
                label: session,
              }))}
              onValueChange={(session) => {
                setVoiceKey(null);
                setSelectedSessions((current) => ({
                  ...current,
                  [selected.id]: session,
                }));
              }}
            />
            <KIconButton
              icon="plus"
              label="Neue Session"
              onClick={() => {
                const session = `Neue Session ${recentSessions.length - 1}`;
                setSessionLists((current) => ({
                  ...current,
                  [selected.id]: [session, ...recentSessions],
                }));
                setSelectedSessions((current) => ({
                  ...current,
                  [selected.id]: session,
                }));
                setVoiceKey(null);
              }}
            />
            {callOpen && (
              <KIconButton
                className="agent-chat-workspace-fixture__call-start"
                icon="phone"
                variant="ghost"
                label={callOpen ? "Zum Anruf zurückkehren" : "Anrufen"}
                onClick={() => {
                  if (!callOpen) {
                    callOrigin.current =
                      pattern.current
                        ?.querySelector(".k-agent-chat-workspace__avatar")
                        ?.getBoundingClientRect() ?? null;
                    setCallSeconds(0);
                    setCallMuted(false);
                  }
                  setCallOpen(true);
                  setCallExpanded(true);
                }}
              />
            )}
            <KIconButton
              icon="x"
              label="Chat schließen"
              onClick={() => {
                setCallOpen(false);
                setChatOpen(false);
              }}
            />
          </>
        }
        labels={{ agents: "Agenten", closeAgents: "Agenten schließen" }}
        composer={
          <KChatComposer
            value={drafts[conversationKey] ?? ""}
            onValueChange={(value) =>
              setDrafts((current) => ({ ...current, [conversationKey]: value }))
            }
            onSubmit={submit}
            onStop={() => undefined}
            runState={selected.runState}
            disabled={selected.connection === "offline"}
            attachments={attachments[conversationKey] ?? []}
            leadingTools={
              <KMenuButton
                label="Anhängen"
                triggerVariant="ghost"
                overflow
                triggerContent={<KIcon name="plus" />}
                actions={[
                  {
                    id: "image",
                    label: "Bild auswählen",
                    iconContent: <KIcon name="image" strokeWidth={1.5} />,
                    onSelect: () => addAttachment("Bild.jpg", "image/jpeg"),
                  },
                  {
                    id: "camera",
                    label: "Neues Bild aufnehmen",
                    iconContent: <KIcon name="camera" strokeWidth={1.5} />,
                    onSelect: () => addAttachment("Aufnahme.jpg", "image/jpeg"),
                  },
                  {
                    id: "document",
                    label: "Dokument auswählen",
                    iconContent: <KIcon name="file" strokeWidth={1.5} />,
                    onSelect: () =>
                      addAttachment("Projektbrief.pdf", "application/pdf"),
                  },
                ]}
              />
            }
            onAttachmentRemove={(file) =>
              setAttachments((current) => ({
                ...current,
                [conversationKey]: (current[conversationKey] ?? []).filter(
                  (item) => item.id !== file.id,
                ),
              }))
            }
            voiceActive={voiceKey === conversationKey}
            voiceCapture={{
              samples: [0.001, 0.008, 0.03, 0.12, 0.008, 0.004, 0.06, 0.02],
              onCancel: () => setVoiceKey(null),
              onSend: () => {
                setVoiceKey(null);
                submit(
                  [drafts[conversationKey], "Dies ist ein Demo-Diktat."]
                    .filter(Boolean)
                    .join(" "),
                );
              },
            }}
            onStartCall={() => {
              callOrigin.current =
                pattern.current
                  ?.querySelector(".k-agent-chat-workspace__avatar")
                  ?.getBoundingClientRect() ?? null;
              setCallSeconds(0);
              setCallMuted(false);
              setCallOpen(true);
              setCallExpanded(true);
            }}
            onVoiceInput={() => {
              if (voiceKey === conversationKey) {
                setVoiceKey(null);
                setDrafts((current) => ({
                  ...current,
                  [conversationKey]: [
                    current[conversationKey],
                    "Dies ist ein Demo-Diktat.",
                  ]
                    .filter(Boolean)
                    .join(" "),
                }));
              } else setVoiceKey(conversationKey);
            }}
            labels={{
              input: `Nachricht an ${selected.name}`,
              placeholder:
                selected.connection === "offline"
                  ? "Offline – Entwurf bleibt erhalten"
                  : "Nachricht …",
              send: "Nachricht senden",
              attach: "Datei anhängen (Demo)",
              removeAttachment: "Anhang entfernen",
              voice: "Audio starten (Demo)",
              stopVoice: "Audio stoppen (Demo)",
              cancelVoice: "Aufnahme verwerfen",
              sendVoice: "Diktat direkt senden",
              call: "Telefonat starten",
            }}
          />
        }
      >
        {callOpen && (
          <KCallBar
            className="agent-chat-workspace-fixture__call"
            name={selected.name}
            status={callMuted ? "Mikrofon stumm" : "Hört zu"}
            duration={`${Math.floor(callSeconds / 60)
              .toString()
              .padStart(
                2,
                "0",
              )}:${(callSeconds % 60).toString().padStart(2, "0")}`}
            muted={callMuted}
            microphoneLevel={0}
            onMutedChange={setCallMuted}
            expanded={callExpanded}
            avatarOrigin={callOrigin.current}
            onExpandedChange={setCallExpanded}
            onEndCall={() => setCallOpen(false)}
            avatar={
              <AgentWorkspaceAvatar
                shape={selected.shape}
                color={selected.color}
                status="idle"
                size={420}
                label={selected.name}
              />
            }
            labels={{
              region: "Anruf",
              duration: "Anrufdauer",
              mute: "Mikrofon stummschalten",
              unmute: "Mikrofon einschalten",
              minimize: "Zum Chat",
              expand: "Anruf öffnen",
              end: "Auflegen",
            }}
          />
        )}
        <div
          className="agent-chat-workspace-fixture__chat-content"
          inert={callOpen && callExpanded}
          aria-hidden={callOpen && callExpanded ? true : undefined}
        >
          {(messages[conversationKey] ?? []).length > 0 && (
            <KChatConversation
              className="agent-chat-workspace-fixture__conversation"
              messages={messages[conversationKey] ?? []}
              runState={selected.runState}
              metadataMode="hidden"
              labels={{
                assistant: selected.name,
                user: "Du",
                emptyTitle: "Noch keine Demo-Nachrichten",
                emptyDescription: "Schreibe eine lokale Vorschau-Nachricht.",
              }}
            />
          )}
        </div>
      </KAgentChatWorkspace>
    </div>
  );
}
