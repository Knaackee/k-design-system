import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAdaptiveDialog,
  KButton,
  KDisclosure,
  KSwitch,
  KWorkflow,
  type KWorkflowPhase,
} from "@k-design-system/ui";
import "./workflow-session.css";

function SessionReview() {
  const [open, setOpen] = useState(true);
  const [details, setDetails] = useState(false);
  const [approved, setApproved] = useState(false);
  const phases: KWorkflowPhase[] = [
    {
      id: "prepare",
      title: "Start & Vorbereitung",
      status: "succeeded",
      durationLabel: "12 Sek.",
      events: [
        {
          id: "ready",
          kind: "status",
          title: "Bereit",
          description:
            "Arbeitsumgebung und zugewiesene Ressourcen wurden geladen.",
          timestamp: "17:43",
        },
      ],
    },
    {
      id: "inspect",
      title: "Dateien prüfen",
      status: "succeeded",
      durationLabel: "1 Min.",
      defaultOpen: true,
      events: [
        {
          id: "step",
          kind: "custom",
          title: "Beispieldatei lesen",
          content: (
            <KDisclosure title="Beispieldatei lesen" defaultOpen>
              <p>
                Die Datei wurde geprüft. Zwei Abschnitte können verständlicher
                formuliert werden.
              </p>
              {details && (
                <div className="k-workflow__transcript">
                  <div>
                    <strong>Du</strong>
                    <p>
                      Prüfe die Release Notes und schlage eine kurze,
                      verständliche Zusammenfassung vor.
                    </p>
                  </div>
                  <div>
                    <strong>Agent</strong>
                    <p>
                      Ich lese zuerst die vorhandene Datei und prüfe
                      anschließend die Änderungen.
                    </p>
                  </div>
                  <KDisclosure title="read · release-notes.md">
                    <pre>
                      {
                        'Argumente\n{ "path": "docs/release-notes.md" }\n\nErgebnis · Demo\n# Release Notes\nVerbesserte Session-Ansicht und nachvollziehbare Tool-Aufrufe.'
                      }
                    </pre>
                  </KDisclosure>
                  <div>
                    <strong>Agent</strong>
                    <p>
                      Die relevanten Änderungen sind erfasst. Ich fasse sie
                      zusammen und lasse die Formulierung vor dem Abschluss
                      bestätigen.
                    </p>
                  </div>
                </div>
              )}
            </KDisclosure>
          ),
        },
      ],
    },
    {
      id: "question",
      title: "Rückfrage",
      status: "succeeded",
      durationLabel: "18 Sek.",
      events: [
        {
          id: "question-event",
          kind: "question",
          title: "Rückfrage",
          description:
            "Soll die Zusammenfassung auch technische Details enthalten?",
          timestamp: "17:44",
        },
        {
          id: "answer",
          kind: "answer",
          title: "Deine Antwort",
          description:
            "Ja, bitte die wichtigsten technischen Änderungen ergänzen.",
          timestamp: "17:44",
        },
      ],
    },
    {
      id: "result",
      title: "Ergebnis & Freigabe",
      status: approved ? "succeeded" : "waiting",
      durationLabel: "30 Sek.",
      defaultOpen: true,
      events: [
        {
          id: "artifact",
          kind: "artifact",
          title: "Zusammenfassung.md",
          description: "Vorschau · Beispieldatei",
          content: (
            <KDisclosure title="Datei ansehen">
              <p>
                Die Session-Ansicht zeigt Arbeitsschritte, Rückfragen und
                Ergebnisse. Optionale Session-Details machen Nachrichten und
                Tool-Aufrufe nachvollziehbar.
              </p>
            </KDisclosure>
          ),
        },
        {
          id: "approval",
          kind: "approval",
          title: approved ? "Freigegeben" : "Deine Freigabe",
          description: approved
            ? "Das Demo-Ergebnis wurde bestätigt."
            : "Die Zusammenfassung ist fertig und wartet auf deine Prüfung.",
          content: (
            <KButton disabled={approved} onClick={() => setApproved(true)}>
              {approved ? "Bestätigt" : "Ergebnis bestätigen"}
            </KButton>
          ),
        },
      ],
    },
  ];
  return (
    <>
      <KButton onClick={() => setOpen(true)}>Session öffnen</KButton>
      <KAdaptiveDialog
        open={open}
        onOpenChange={setOpen}
        title="Session prüfen"
        headerless
        className="workflow-session-dialog"
        contentInset={false}
      >
        <KWorkflow
          title="Lokaler Pi – Persönlich"
          status={approved ? "succeeded" : "waiting"}
          statusLabel={approved ? "Abgeschlossen" : "Prüfung nötig"}
          phases={phases}
          stepCountLabel="2 / 2"
          durationLabel="2 Min."
          startedAt="2026-10-09T17:43:00"
          endedAt="2026-10-09T17:45:00"
          formatDateTime={(value) =>
            new Intl.DateTimeFormat("de-DE", {
              dateStyle: "short",
              timeStyle: "short",
            }).format(new Date(value))
          }
          labels={{
            timeline: "Ablauf",
            steps: "Schritte",
            duration: "Dauer",
            start: "Start",
            end: "Ende",
          }}
          toolbarActions={
            <>
              <span>Session-Details</span>
              <KSwitch
                showLabel={false}
                label="Session-Details"
                checked={details}
                onCheckedChange={setDetails}
              />
            </>
          }
          renderEvent={(event) =>
            event.kind === "custom" ? event.content : undefined
          }
        />
      </KAdaptiveDialog>
    </>
  );
}

const meta = {
  title: "Patterns/Workflow Session",
  component: SessionReview,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof SessionReview>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Review: Story = {
  parameters: { fixtureId: "workflow-session-review" },
};
