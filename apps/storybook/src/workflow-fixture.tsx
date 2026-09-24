import { useMemo, useState } from "react";
import {
  KWorkflow,
  KLink,
  type KWorkflowEvent,
  type KWorkflowPhase,
  type KWorkflowPresentation,
} from "@k-design-system/ui";

export function WorkflowFixture({
  presentation = "auto",
  showTechnicalEventsInCompact = false,
}: {
  presentation?: KWorkflowPresentation;
  showTechnicalEventsInCompact?: boolean;
}) {
  const [activated, setActivated] = useState<string>();
  const { start, phases } = useMemo(() => createFixture(), []);
  return (
    <section className="k-workflow-fixture">
      <KWorkflow
        title="Knaackee"
        status="running"
        statusLabel="Läuft"
        phases={phases}
        startedAt={start}
        stepCountLabel="4"
        presentation={presentation}
        labels={{
          timeline: "Ablauf",
          steps: "Schritte",
          duration: "Dauer",
          start: "Start",
          end: "Ende",
          notEnded: "Noch nicht beendet",
          running: "Läuft",
          pending: "Ausstehend",
          paused: "Pausiert",
          waiting: "Wartet",
          succeeded: "Abgeschlossen",
          failed: "Fehlgeschlagen",
          cancelled: "Abgebrochen",
        }}
        formatDateTime={formatDemoDateTime}
        showTechnicalEventsInCompact={showTechnicalEventsInCompact}
        onEventActivate={(event) => setActivated(event.id)}
        aria-describedby={activated ? "workflow-selection" : undefined}
      />
      {activated ? (
        <output
          id="workflow-selection"
          className="k-workflow-fixture__selection"
        >
          Event aktiviert: {activated}
        </output>
      ) : null}
    </section>
  );
}

const formatDemoDateTime = (value: string | number | Date) => {
  const date = new Date(value);
  const part = (number: number) => number.toString().padStart(2, "0");
  return `${part(date.getDate())}.${part(date.getMonth() + 1)}.${date.getFullYear()}, ${part(date.getHours())}:${part(date.getMinutes())}`;
};

function createFixture(): {
  start: Date;
  phases: KWorkflowPhase[];
} {
  const now = new Date();
  const start = new Date(now.getTime() - 3 * 60_000 - 18_000);
  const minute = (offset: number) =>
    new Date(start.getTime() + offset * 60_000);
  const event = (
    id: string,
    kind: KWorkflowEvent["kind"],
    title: string,
    description: string,
    timestamp: string,
    extra: Partial<KWorkflowEvent> = {},
  ): KWorkflowEvent => ({
    id,
    kind,
    title,
    description,
    timestamp,
    ...extra,
  });

  return {
    start,
    phases: [
      {
        id: "prepare",
        title: "Start & Vorbereitung",
        status: "succeeded",
        startedAt: start,
        endedAt: minute(0.7),
        events: [
          event(
            "started",
            "status",
            "Status: Läuft",
            "Agent work started",
            "13:11",
            {
              status: "running",
            },
          ),
          event(
            "issue-log",
            "log",
            "Log",
            "Pi tool issues_get started.\nPi tool issues_get finished.",
            "13:12",
            {
              importance: "technical",
            },
          ),
        ],
      },
      {
        id: "gate",
        title: "Rückfrage · Human Gate",
        status: "succeeded",
        startedAt: minute(0.7),
        endedAt: minute(1.8),
        events: [
          event(
            "location-question",
            "question",
            "Rückfrage",
            "Für welchen Ort soll ich das aktuelle Wetter ermitteln?",
            "13:12",
            {
              sequence: 4,
              content: (
                <p>
                  Ort (Stadt oder Postleitzahl, gegebenenfalls Land): Zürich
                </p>
              ),
              interactive: true,
            },
          ),
          event(
            "paused",
            "status",
            "Statusänderung",
            "Agent work paused",
            "13:12",
            {
              sequence: 5,
              status: "paused",
            },
          ),
        ],
      },
      {
        id: "result",
        title: "Ergebnis & Artefakte",
        status: "succeeded",
        startedAt: minute(1.8),
        endedAt: minute(2.8),
        events: [
          event(
            "web-log",
            "log",
            "Log",
            "Pi tool web_search finished.\nPi tool fetch_content finished.",
            "13:14",
            {
              importance: "technical",
            },
          ),
          event("weather", "result", "Ergebnis", "Wetter für Zürich", "13:15", {
            sequence: 15,
            interactive: true,
            content: (
              <div>
                <p>
                  Laut <KLink href="https://wttr.in/Zurich">wttr.in</KLink>,
                  Gebiet Zürichhorn:
                </p>
                <ul>
                  <li>
                    <strong>16 °C, bedeckt</strong>
                  </li>
                  <li>
                    Gefühlt <strong>14 °C</strong>
                  </li>
                  <li>
                    Wind <strong>4 km/h</strong>
                  </li>
                </ul>
                <p>
                  Die Ortsrückfrage wurde beantwortet und erst danach
                  recherchiert.
                </p>
              </div>
            ),
          }),
          event(
            "approved",
            "approval",
            "Ergebnis freigegeben",
            "Vom Nutzer freigegeben",
            "13:15",
          ),
        ],
      },
      {
        id: "continue",
        title: "Weiterarbeit",
        status: "running",
        startedAt: minute(2.8),
        events: [
          event(
            "resumed",
            "progress",
            "Fortschritt",
            "Die abschließende Dokumentation wird erstellt.",
            "jetzt",
            {
              status: "running",
            },
          ),
        ],
      },
    ],
  };
}
