import { useState } from "react";
import {
  KButton,
  KInline,
  KSlider,
  KSoundProvider,
  KSoundToggle,
  KStack,
  KSurface,
  KText,
  useKSound,
  type KSoundCue,
} from "@k-design-system/ui";

export function SoundOnboardingFixture() {
  const [enabled, setEnabled] = useState(false);
  const [volume, setVolume] = useState(0.25);
  return (
    <KSoundProvider enabled={enabled} volume={volume}>
      <KSurface style={{ padding: "var(--k-space-layout-section-gap)" }}>
        <KStack gap="section" align="stretch">
          <KInline gap="control" align="center">
            <KText as="h1" variant="heading2">
              Onboarding · Sounds
            </KText>
            <KSoundToggle
              enabled={enabled}
              onEnabledChange={setEnabled}
              labelEnable="Sounds aktivieren"
              labelDisable="Sounds ausschalten"
            />
          </KInline>
          <KText variant="body">
            Dezentes Feedback für bewusste Aktionen. Alle Aktionen funktionieren
            auch ohne Ton.
          </KText>
          <KSlider
            label="Lautstärke"
            value={volume * 100}
            min={0}
            max={100}
            onValueChange={(value) => setVolume(value / 100)}
          />
          <SoundEvents />
        </KStack>
      </KSurface>
    </KSoundProvider>
  );
}
function SoundEvents() {
  const sound = useKSound();
  const [status, setStatus] = useState("Bereit.");
  const events: [KSoundCue, string][] = [
    ["tap", "Auswahl"],
    ["tick", "Schrittwechsel"],
    ["complete", "Website übernommen"],
    ["pop", "Angebot hinzugefügt"],
    ["drop", "Neu eingeordnet"],
    ["release", "Rückgängig"],
  ];
  return (
    <KStack gap="action" align="stretch">
      <KInline gap="control" wrap>
        {events.map(([cue, label]) => (
          <KButton
            key={cue}
            variant="secondary"
            onClick={() => {
              setStatus(label);
              void sound.play(cue);
            }}
          >
            {label}
          </KButton>
        ))}
      </KInline>
      <KText role="status" variant="bodySmall">
        {status}
      </KText>
    </KStack>
  );
}
