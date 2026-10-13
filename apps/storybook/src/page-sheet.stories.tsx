import { useId, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton, KCard, KInput, KPageSheet, KText } from "@k-design-system/ui";
import "./page-sheet-demo.css";

function PageSheetDemo() {
  const rootId = useId();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("Orbit");
  const [saved, setSaved] = useState(false);
  return (
    <div className="page-sheet-demo">
      <div id={rootId} className="page-sheet-demo__app">
        <header className="page-sheet-demo__header">
          <KText variant="heading3">Workspace</KText>
          <KButton onClick={() => setOpen(true)}>Projekt öffnen</KButton>
        </header>
        <KText variant="heading4">Guten Morgen, Alex</KText>
        <KText>Deine Projekte und die nächsten Schritte im Überblick.</KText>
        {[
          "Orbit · Designsystem",
          "Website · Veröffentlichung",
          "Mobile · Neue Ideen",
        ].map((title, i) => (
          <KCard key={title} className="page-sheet-demo__card">
            <KText variant="heading4">{title}</KText>
            <KText>
              {i + 3} offene Aufgaben · Dein Team ist auf dem aktuellen Stand.
            </KText>
            <KButton onClick={() => setOpen(true)}>Details ansehen</KButton>
          </KCard>
        ))}
        <KText role="status">
          {saved
            ? "Änderungen gespeichert."
            : "Wähle ein Projekt für weitere Details."}
        </KText>
      </div>
      <KPageSheet
        presentationRootId={rootId}
        open={open}
        onOpenChange={setOpen}
        title="Projekt bearbeiten"
        description="Details und nächste Schritte"
        closeLabel="Schließen"
        actions={
          <>
            <KButton onClick={() => setOpen(false)}>Abbrechen</KButton>
            <KButton
              onClick={() => {
                setSaved(true);
                setOpen(false);
              }}
            >
              Speichern
            </KButton>
          </>
        }
      >
        <div className="page-sheet-demo__fields">
          <label>
            Projektname
            <KInput
              value={name}
              onChange={(event) => setName(event.target.value)}
            />
          </label>
          <KText>
            Ziehe den Griff nach unten, um zur Übersicht zurückzukehren.
          </KText>
          {Array.from({ length: 12 }, (_, index) => (
            <KCard key={index} className="page-sheet-demo__card">
              <KText variant="heading4">Meilenstein {index + 1}</KText>
              <KText>
                Gemeinsam planen, Fortschritte besprechen und die nächsten
                Aufgaben vorbereiten.
              </KText>
            </KCard>
          ))}
        </div>
      </KPageSheet>
    </div>
  );
}

export default {
  title: "Overlays/PageSheet",
  component: PageSheetDemo,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof PageSheetDemo>;
export const App: StoryObj<typeof PageSheetDemo> = {
  parameters: { fixtureId: "page-sheet-app" },
};
