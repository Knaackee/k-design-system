import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import {
  KButton,
  KHapticsProvider,
  KInline,
  KStack,
  KSurface,
  KSwitch,
  KText,
  useKHaptics,
  type KHapticCue,
} from "@k-design-system/ui";

export default {
  title: "Patterns/Haptics",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

const cues: [KHapticCue, string][] = [
  ["selection", "Auswahl"],
  ["light", "Leicht"],
  ["medium", "Mittel"],
  ["heavy", "Kräftig"],
  ["success", "Erfolg"],
  ["warning", "Warnung"],
  ["error", "Fehler"],
];

function HapticsFixture() {
  const [enabled, setEnabled] = useState(false);
  return (
    <KHapticsProvider enabled={enabled}>
      <KSurface style={{ padding: "var(--k-space-layout-section-gap)" }}>
        <KStack gap="section" align="stretch">
          <KText as="h1" variant="heading2">
            Haptisches Feedback
          </KText>
          <KText variant="body">
            Aus, bis die Person es einschaltet. Jede Rückmeldung ist auch
            sichtbar; Haptik ergänzt nur.
          </KText>
          <KSwitch
            label="Haptik"
            checked={enabled}
            onCheckedChange={setEnabled}
          />
          <HapticEvents />
        </KStack>
      </KSurface>
    </KHapticsProvider>
  );
}

function HapticEvents() {
  const haptics = useKHaptics();
  const [status, setStatus] = useState("Bereit.");
  return (
    <KStack gap="action" align="stretch">
      <KInline gap="control" wrap>
        {cues.map(([cue, label]) => (
          <KButton
            key={cue}
            variant="secondary"
            onClick={() => {
              setStatus(label);
              haptics.perform(cue);
            }}
          >
            {label}
          </KButton>
        ))}
      </KInline>
      <KText role="status" variant="bodySmall">
        {status}
      </KText>
      <KText variant="bodySmall">
        {haptics.isSupported
          ? "Dieser Browser unterstützt Vibration."
          : "Dieser Browser hat keine Vibration (zum Beispiel Safari auf iOS); die Cues bleiben still."}
      </KText>
    </KStack>
  );
}

export const Review: StoryObj = {
  name: "haptics-review",
  parameters: { fixtureId: "haptics-review" },
  render: () => <HapticsFixture />,
};
