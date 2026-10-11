import type { Meta, StoryObj } from "@storybook/react-vite";
import { useEffect, useState } from "react";
import {
  KAudioEdgeGlow,
  KButton,
  KSlider,
  type KAudioEdgeGlowState,
} from "@k-design-system/ui";

function AudioEdgeGlowFixture({
  state = "capturing",
  audioLevel = 0,
  reducedMotion = false,
}: {
  state?: KAudioEdgeGlowState;
  audioLevel?: number;
  reducedMotion?: boolean;
}) {
  const [mode, setMode] = useState(state);
  const [level, setLevel] = useState(audioLevel);
  const [color, setColor] = useState("#84cc16");
  useEffect(() => setMode(state), [state]);
  useEffect(() => setLevel(audioLevel), [audioLevel]);
  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        width: "100%",
        height: "100%",
        overflow: "hidden",
        background: "var(--k-color-surface-canvas)",
        display: "grid",
        placeItems: "center",
      }}
    >
      <div
        style={{
          textAlign: "center",
          width: "min(320px, 100%)",
          display: "grid",
          gap: "var(--k-space-control-gap)",
        }}
      >
        <p style={{ margin: 0 }}>
          {mode === "capturing"
            ? "Ich höre zu"
            : mode === "processing"
              ? "Wird verarbeitet"
              : "Bereit"}
        </p>
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            gap: "var(--k-space-control-gap)",
            flexWrap: "wrap",
          }}
        >
          <KButton onClick={() => setMode("capturing")}>Aufnahme</KButton>
          <KButton variant="secondary" onClick={() => setMode("processing")}>
            Verarbeitung
          </KButton>
          <KButton variant="ghost" onClick={() => setMode("inactive")}>
            Aus
          </KButton>
        </div>
        <label>Pegel · {Math.round(level * 100)} %</label>
        <KSlider
          label="Mikrofonpegel"
          value={level * 100}
          onValueChange={(value) => setLevel(value / 100)}
        />
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            gap: "var(--k-space-control-gap)",
            flexWrap: "wrap",
          }}
        >
          {[
            ["Limette", "#84cc16"],
            ["Violett", "#a78bfa"],
            ["Blau", "#38bdf8"],
          ].map(([label, value]) => (
            <KButton
              key={value}
              variant="ghost"
              onClick={() => setColor(value!)}
            >
              {label}
            </KButton>
          ))}
        </div>
        <p style={{ margin: 0 }}>
          {reducedMotion
            ? "Bewegung reduziert"
            : "Die Farbe und der Pegel gehören dem Consumer."}
        </p>
      </div>
      <KAudioEdgeGlow
        color={color}
        state={mode}
        audioLevel={level}
        reducedMotion={reducedMotion}
      />
    </div>
  );
}
const meta = {
  title: "Feedback/Audio edge glow",
  component: AudioEdgeGlowFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof AudioEdgeGlowFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Quiet: Story = {
  name: "audio-edge-glow-quiet",
  parameters: { fixtureId: "audio-edge-glow-quiet" },
  args: { audioLevel: 0 },
};
export const Speaking: Story = {
  name: "audio-edge-glow-speaking",
  parameters: { fixtureId: "audio-edge-glow-speaking" },
  args: { audioLevel: 0.35 },
};
export const Processing: Story = {
  name: "audio-edge-glow-processing",
  parameters: { fixtureId: "audio-edge-glow-processing" },
  args: { state: "processing" },
};
export const ReducedMotion: Story = {
  name: "audio-edge-glow-reduced-motion",
  parameters: { fixtureId: "audio-edge-glow-reduced-motion" },
  args: { audioLevel: 0.35, reducedMotion: true },
};
export const Inactive: Story = {
  name: "audio-edge-glow-inactive",
  parameters: { fixtureId: "audio-edge-glow-inactive" },
  args: { state: "inactive" },
};
