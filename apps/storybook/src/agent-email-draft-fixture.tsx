import { useEffect, useRef, useState } from "react";
import {
  KAgentEmailDraft,
  KContainer,
  KDictationState,
  KIcon,
  KInline,
  KSpinner,
  KText,
  KStack,
  type KAgentEmailDraftValue,
  type KAgentEmailDraftAttachment,
  type KAgentEmailDraftStatus,
  type KCardBorder,
} from "@k-design-system/ui";

export type EmailDraftScenario =
  "pending" | "validation" | "submitting" | "sent" | "discarded";

export function AgentEmailDraftFixture({
  scenario = "pending",
  border = "aurora",
  toolbar = false,
}: {
  scenario?: EmailDraftScenario;
  border?: KCardBorder;
  toolbar?: boolean;
}) {
  return (
    <EmailDraftSession
      key={scenario}
      scenario={scenario}
      border={border}
      toolbar={toolbar}
    />
  );
}

function EmailDraftSession({
  scenario,
  border,
  toolbar,
}: {
  scenario: EmailDraftScenario;
  border: KCardBorder;
  toolbar: boolean;
}) {
  const subjectInput = useRef<HTMLInputElement>(null);
  const subjectRange = useRef({ start: 0, end: 0 });
  const [subjectState, setSubjectState] = useState(KDictationState.ready);
  const [bodyState, setBodyState] = useState(KDictationState.ready);
  const bodyInsert = useRef<((text: string) => void) | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => () => clearTimeout(timer.current), []);
  const pending = useRef(true);
  const subjectPressed = () => {
    if (subjectState === KDictationState.recording) {
      setSubjectState(KDictationState.processing);
      timer.current = setTimeout(() => {
        if (!pending.current) return;
        const input = subjectInput.current;
        if (input) {
          input.focus();
          input.setSelectionRange(
            subjectRange.current.start,
            subjectRange.current.end,
          );
          // Browser editing command preserves the native input undo transaction.
          document.execCommand("insertText", false, " – aktualisiert");
          setValue((current) => ({ ...current, subject: input.value }));
        }
        setSubjectState(KDictationState.ready);
      }, 800);
    } else {
      const input = subjectInput.current;
      subjectRange.current = {
        start: input?.selectionStart ?? 0,
        end: input?.selectionEnd ?? 0,
      };
      setSubjectState(KDictationState.recording);
    }
  };
  const [value, setValue] = useState<KAgentEmailDraftValue>({
    to:
      scenario === "validation"
        ? ""
        : "Mara Hoffmann <mara.hoffmann@example.com>",
    subject: "Unterlagen für unseren Termin am Donnerstag",
    markdown:
      "Hallo Mara,\n\nanbei die besprochene Übersicht für unseren Termin am Donnerstag. Passt es für dich weiterhin um 10 Uhr?\n\nViele Grüße\nDennis",
  });
  const [attachments, setAttachments] = useState<KAgentEmailDraftAttachment[]>([
    { id: "agenda", name: "Projektübersicht.pdf", description: "PDF · 248 KB" },
  ]);
  const [status, setStatus] = useState<KAgentEmailDraftStatus>(
    scenario === "validation" ? "pending" : scenario,
  );
  pending.current = status === "pending";
  const [validation, setValidation] = useState(scenario === "validation");
  const statusLabel = {
    pending: undefined,
    submitting: "Wird gesendet …",
    sent: "Versendet",
    discarded: "Verworfen",
  }[status];
  return (
    <KContainer className="k-primitive-fixture">
      <KStack gap="section" align="stretch">
        <KText variant="caption">
          Diktat-Demo: simuliert, ohne Mikrofonaufnahme. Starten, stoppen, Text
          prüfen.
        </KText>
        <KStack gap="control" align="stretch">
          <KAgentEmailDraft
            draftId="demo-project-mail"
            title="Mail"
            from="Dennis Knaack <dennis@example.com>"
            value={value}
            subjectInputRef={subjectInput}
            subjectDictation={{
              state: subjectState,
              label:
                subjectState === KDictationState.recording
                  ? "Betreff-Diktat stoppen"
                  : "Betreff diktieren (Demo)",
              offset: subjectRange.current.start,
              onPressed:
                bodyState === KDictationState.ready
                  ? subjectPressed
                  : undefined,
            }}
            onChange={(next) => {
              if (
                subjectState !== KDictationState.ready &&
                next.subject !== value.subject
              ) {
                let prefix = 0;
                while (
                  prefix < value.subject.length &&
                  prefix < next.subject.length &&
                  value.subject[prefix] === next.subject[prefix]
                )
                  prefix++;
                let oldEnd = value.subject.length,
                  newEnd = next.subject.length;
                while (
                  oldEnd > prefix &&
                  newEnd > prefix &&
                  value.subject[oldEnd - 1] === next.subject[newEnd - 1]
                ) {
                  oldEnd--;
                  newEnd--;
                }
                const map = (offset: number) =>
                  offset <= prefix
                    ? offset
                    : offset >= oldEnd
                      ? offset + newEnd - oldEnd
                      : newEnd;
                subjectRange.current = {
                  start: map(subjectRange.current.start),
                  end: map(subjectRange.current.end),
                };
              }
              setValue(next);
              setValidation((current) => current && !next.to.trim());
            }}
            attachments={attachments}
            onAddAttachment={() =>
              setAttachments((current) =>
                current.some((file) => file.id === "notes")
                  ? current
                  : [
                      ...current,
                      {
                        id: "notes",
                        name: "Gesprächsnotizen.txt",
                        description: "Text · 2 KB",
                      },
                    ],
              )
            }
            onRemoveAttachment={(id) =>
              setAttachments((current) =>
                current.filter((file) => file.id !== id),
              )
            }
            status={status}
            errors={
              validation
                ? { to: "Bitte gib mindestens einen Empfänger an." }
                : undefined
            }
            border={border}
            editor={{
              dictation: {
                state: bodyState,
                label:
                  bodyState === KDictationState.recording
                    ? "Nachricht-Diktat stoppen"
                    : "Nachricht diktieren (Demo)",
                onStart: (insert) => {
                  if (subjectState !== KDictationState.ready) return;
                  bodyInsert.current = insert;
                  setBodyState(KDictationState.recording);
                },
                onStop: () => {
                  setBodyState(KDictationState.processing);
                  timer.current = setTimeout(() => {
                    if (!pending.current) return;
                    bodyInsert.current?.(" Ergänzung aus dem Demo-Diktat.");
                    setBodyState(KDictationState.ready);
                  }, 800);
                },
              },
              showExpandButton: true,
              expandLabel: "Nachricht vergrößern",
              collapseLabel: "Zurück zum Entwurf",
              showFixedToolbar: toolbar,
              labels: { source: "Markdown", read: "Vorschau" },
            }}
            labels={{
              from: "Von",
              to: "An",
              subject: "Betreff",
              message: "Nachricht",
              showBcc: "Bcc hinzufügen",
              attachments: "Anhänge",
              addAttachment: "Anhang hinzufügen",
              removeAttachment: (name) => `${name} entfernen`,
              send: "Senden",
              discard: "Verwerfen",
            }}
            onSend={() => {
              if (!value.to.trim()) {
                setValidation(true);
                return;
              }
              setStatus("sent");
            }}
            onDiscard={() => {
              setStatus("discarded");
            }}
          />
          {statusLabel ? (
            <KInline gap="control" align="start" role="status">
              {status === "submitting" ? (
                <KSpinner aria-hidden="true" role="presentation" />
              ) : status === "sent" ? (
                <KIcon name="check" className="k-leading" />
              ) : null}
              <KText variant="caption">{statusLabel}</KText>
            </KInline>
          ) : null}
        </KStack>
      </KStack>
    </KContainer>
  );
}
