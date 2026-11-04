import { useId, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAdaptiveDialog,
  KResponsiveDrawer,
  KPageSheet,
  KButton,
  KCard,
  KText,
  KIcon,
  KStack,
  KInline,
  KField,
  KSelect,
  KAlert,
} from "@k-design-system/ui";
import "./page-sheet-review.css";

import {
  AppOverhaulDayForm,
  defaultDayFormValue,
  isDayFormValid,
  type DayFormValue,
} from "./app-overhaul-day-form";
const defaults = defaultDayFormValue;
type Day = DayFormValue;
type Presentation = "adaptive" | "drawer" | "page";

/** Gallery experiment only: same form, draft and actions for all three public overlays. */
function PageSheetReview({
  initialPresentation = "page",
}: {
  initialPresentation?: Presentation;
}) {
  const rootId = useId();
  const [presentation, setPresentation] =
    useState<Presentation>(initialPresentation);
  const [open, setOpen] = useState(false);
  const [saved, setSaved] = useState<Day>(defaults);
  const [draft, setDraft] = useState<Day>(defaults);
  const [date, setDate] = useState("2026-11-03");
  const [savedDate, setSavedDate] = useState(date);
  const [message, setMessage] = useState("");
  const [discard, setDiscard] = useState(false);
  const dirty =
    JSON.stringify(saved) !== JSON.stringify(draft) || date !== savedDate;
  const invalid = !isDayFormValid(draft, date);
  const requestClose = (next: boolean) => {
    if (!next && dirty) setDiscard(true);
    else setOpen(next);
  };
  const form = (
    <KStack gap="section" align="stretch" className="psr-fields">
      <AppOverhaulDayForm
        value={draft}
        onChange={setDraft}
        date={date}
        onDateChange={setDate}
        onSave={() => {}}
        onReset={() => setDraft(defaults)}
        hideActions
      />
      {discard && (
        <KAlert
          title="Änderungen verwerfen?"
          description="Dein Entwurf wurde noch nicht übernommen."
          tone="warning"
          action={
            <KInline gap="control" wrap>
              <KButton variant="secondary" onClick={() => setDiscard(false)}>
                Weiter bearbeiten
              </KButton>
              <KButton
                onClick={() => {
                  setDraft(saved);
                  setDate(savedDate);
                  setDiscard(false);
                  setOpen(false);
                }}
              >
                Verwerfen
              </KButton>
            </KInline>
          }
        />
      )}
    </KStack>
  );
  const props = {
    open,
    onOpenChange: requestClose,
    title: "Tag anpassen",
    closeLabel: "Schließen",
    children: form,
    className: "psr-overlay",
    actions: (
      <KInline gap="control" className="psr-actions">
        <KButton variant="secondary" onClick={() => setDraft(defaults)}>
          Zurücksetzen
        </KButton>
        <KButton
          disabled={invalid}
          onClick={() => {
            setSaved(draft);
            setSavedDate(date);
            setDiscard(false);
            setOpen(false);
            setMessage("In dieser Vorschau übernommen.");
          }}
        >
          Übernehmen
        </KButton>
      </KInline>
    ),
  };
  return (
    <div className="psr-shell">
      <div className="psr-surface" id={rootId}>
        <KStack gap="section" align="stretch" className="psr-content">
          <header>
            <KText variant="caption">OVERLAY-VERGLEICH · STORYBOOK</KText>
            <h1>Ein Tag. Drei Darstellungen.</h1>
            <p>
              Gleicher Inhalt und gleiche Aktionen – du entscheidest, welche
              Präsentation sich richtig anfühlt.
            </p>
          </header>
          <KField label="Darstellung">
            <KSelect
              value={presentation}
              onValueChange={(value) => setPresentation(value as Presentation)}
              options={[
                { value: "adaptive", label: "Dialog / Bottom Sheet" },
                { value: "drawer", label: "Seitenleiste / Bottom Sheet" },
                { value: "page", label: "Page Sheet" },
              ]}
            />
          </KField>
          <KCard className="psr-card">
            <KStack gap="action" align="stretch">
              <KText variant="caption">
                {new Date(`${savedDate}T12:00:00`).toLocaleDateString("de-DE", {
                  weekday: "long",
                  day: "numeric",
                  month: "long",
                })}
              </KText>
              <h2>Mein Tag</h2>
              <KText>
                {saved.off
                  ? "Freier Tag"
                  : `${saved.start}–${saved.end} · Leipzig`}
              </KText>
              <KButton
                fullWidth
                onClick={() => {
                  setDraft(saved);
                  setDate(savedDate);
                  setDiscard(false);
                  setOpen(true);
                }}
              >
                <KIcon name="sliders-horizontal" size={20} />
                Tag anpassen
              </KButton>
            </KStack>
          </KCard>
          {message && <KText role="status">{message}</KText>}
          <KText variant="caption">
            Zum Vergleichen öffnen, innen scrollen und nach unten ziehen. Bei
            Änderungen fragt die Vorschau vor dem Verwerfen nach.
          </KText>
        </KStack>
      </div>
      {presentation === "page" ? (
        <KPageSheet {...props} presentationRootId={rootId} />
      ) : presentation === "drawer" ? (
        <KResponsiveDrawer {...props} />
      ) : (
        <KAdaptiveDialog {...props} />
      )}
    </div>
  );
}

export default {
  title: "Review/PageSheetComparison",
  component: PageSheetReview,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof PageSheetReview>;
type Story = StoryObj<typeof PageSheetReview>;
export const PageSheet: Story = { args: { initialPresentation: "page" } };
export const AdaptiveDialog: Story = {
  args: { initialPresentation: "adaptive" },
};
export const SidePanel: Story = { args: { initialPresentation: "drawer" } };
export const Dark: Story = { globals: { theme: "dark" } };
