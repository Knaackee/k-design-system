import { useRef, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KRobotHead,
  KButton,
  KSelect,
  KSlider,
  KSwitch,
  KText,
  KInput,
  KField,
  KLink,
  kRobotHeadShapes,
  kRobotHeadStates,
  type KRobotHeadProps,
  type KRobotHeadHandle,
  type KRobotHeadState,
  type KRobotHeadShape,
  type KRobotHeadAudioSource,
} from "@k-design-system/ui";
import { RobotHeadAudioFixture } from "./robot-head-audio-fixture.js";
import "./robot-head-fixture.css";

const descriptions: Record<KRobotHeadState, string> = {
  idle: "Schaut sich um, blinzelt und hüpft gelegentlich.",
  thinking: "Denkt nach – mit wandernden Punkten und sanfter Neigung.",
  searching: "Sucht mit einer wandernden Scanlinie.",
  listening:
    "Hört zu. Die Frequenzbänder können einer echten Audioquelle folgen.",
  speaking:
    "Spricht. Optional bewegt sich der Mund zum tatsächlich abgespielten Audio.",
  working: "Arbeitet mit einer zyklischen Fortschrittsanimation.",
  happy: "Freut sich, lächelt und hüpft.",
  error: "Zeigt einen Fehler mit roten LEDs und Kopfschütteln.",
  sleeping: "Schläft mit geschlossenen Augen und aufsteigenden Z-Zeichen.",
};
const shells = [
  ["Kobalt", "#2b49a3"],
  ["Tomate", "#cf4b3e"],
  ["Mandarine", "#e08832"],
  ["Senf", "#c4a345"],
  ["Mint", "#6bbf9a"],
  ["Teal", "#287e85"],
  ["Traube", "#7951ad"],
  ["Rosa", "#df8aaa"],
  ["Graphit", "#454953"],
  ["Porzellan", "#dedbd2"],
];
function PlaygroundFixture(args: KRobotHeadProps) {
  const head = useRef<KRobotHeadHandle>(null);
  const [state, setState] = useState<KRobotHeadState>(args.state ?? "idle");
  const [shape, setShape] = useState<KRobotHeadShape>(
    args.shape ?? "rectangle",
  );
  const [color, setColor] = useState(args.color ?? "#2b49a3");
  const [trim, setTrim] = useState("#93a6c8");
  const [screen, setScreen] = useState("#e8f2ff");
  const [speed, setSpeed] = useState(1);
  const [size, setSize] = useState(240);
  const [paused, setPaused] = useState(false);
  const [antenna, setAntenna] = useState(true);
  const [shadow, setShadow] = useState(true);
  const [interactive, setInteractive] = useState(true);
  const [reduced, setReduced] = useState(false);
  const [source, setSource] = useState<KRobotHeadAudioSource>();
  const [playing, setPlaying] = useState(false);
  const [activations, setActivations] = useState(0);
  const [mode, setMode] = useState("pointer");
  const [x, setX] = useState(0);
  const [y, setY] = useState(0);
  const [reaction, setReaction] = useState(false);
  const options = (values: readonly string[]) =>
    values.map((value) => ({ value, label: value }));
  return (
    <div className="robot-demo">
      <header className="robot-demo__heading">
        <div>
          <KText as="h1" variant="heading3">
            KRobotHead
          </KText>
          <KText>Ein kleines Gesicht für große Ideen.</KText>
        </div>
        <KLink
          href="https://robot-heads.fayaz.workers.dev/"
          target="_blank"
          rel="noreferrer"
        >
          Original von Fayaz Ahmed ↗
        </KLink>
      </header>
      <div className="robot-demo__layout">
        <section className="robot-demo__preview" aria-label="Robotervorschau">
          <div className="robot-demo__stage">
            <KRobotHead
              {...args}
              ref={head}
              size={size}
              shape={shape}
              state={state}
              color={color}
              trimColor={trim}
              screenColor={screen}
              speed={speed}
              paused={paused}
              antenna={antenna}
              floorShadow={shadow}
              interactive={interactive}
              reducedMotion={reduced}
              seed={0.42}
              audio={source}
              target={
                mode === "external"
                  ? { x, y }
                  : mode === "off"
                    ? null
                    : undefined
              }
              aria-label="Roboter aktivieren"
              onActivate={() => setActivations((n) => n + 1)}
              onReactionStart={() => setReaction(true)}
              onReactionEnd={() => setReaction(false)}
            />
          </div>
          <KText as="h2" variant="heading3">
            {state}
          </KText>
          <KText>{descriptions[state]}</KText>
          <div className="robot-demo__row">
            <KButton variant="secondary" onClick={() => setPaused(!paused)}>
              {paused ? "Fortsetzen" : "Pause"}
            </KButton>
            <KButton variant="secondary" onClick={() => head.current?.react()}>
              Reaktion auslösen
            </KButton>
            <KButton
              variant="ghost"
              onClick={() => {
                head.current?.reset();
                setReaction(false);
              }}
            >
              Zurücksetzen
            </KButton>
          </div>
          <KText variant="label">
            {playing
              ? "Audio läuft"
              : source
                ? "Audio bereit / still"
                : "Synthetische Animation"}{" "}
            · {activations} Aktivierungen{reaction ? " · Reaktion aktiv" : ""}
          </KText>
          <RobotHeadAudioFixture
            onSource={(audio) => setSource(() => audio)}
            onPlaying={(value) => {
              setPlaying(value);
              if (value && state !== "listening") setState("speaking");
            }}
          />
          <div className="robot-demo__states" aria-label="Zustände">
            {kRobotHeadStates.map((value) => (
              <KButton
                key={value}
                aria-pressed={state === value}
                variant={state === value ? "primary" : "ghost"}
                onClick={() => setState(value)}
              >
                {value}
              </KButton>
            ))}
          </div>
        </section>
        <aside className="robot-demo__controls" aria-label="Einstellungen">
          <KSelect
            label="Form"
            options={options(kRobotHeadShapes)}
            value={shape}
            onValueChange={(v) => setShape(v as KRobotHeadShape)}
          />
          <KText variant="label">Gehäuse</KText>
          <div className="robot-demo__swatches">
            {shells.map(([label, value]) => (
              <KButton
                key={value}
                aria-label={label}
                aria-pressed={color === value}
                variant={color === value ? "primary" : "ghost"}
                onClick={() => setColor(value)}
              >
                <span
                  className="robot-demo__swatch"
                  style={{ background: value }}
                />
                {label}
              </KButton>
            ))}
          </div>
          <div className="robot-demo__colors">
            <KField label="Gehäusefarbe">
              <KInput
                type="color"
                value={color}
                onChange={(e) => setColor(e.target.value)}
              />
            </KField>
            <KField label="Metallfarbe">
              <KInput
                type="color"
                value={trim}
                onChange={(e) => setTrim(e.target.value)}
              />
            </KField>
            <KField label="LED-Farbe">
              <KInput
                type="color"
                value={screen}
                onChange={(e) => setScreen(e.target.value)}
              />
            </KField>
          </div>
          <KText variant="label">Geschwindigkeit · {speed.toFixed(1)}×</KText>
          <KSlider
            label="Geschwindigkeit"
            min={0}
            max={3}
            step={0.1}
            value={speed}
            onValueChange={setSpeed}
          />
          <KText variant="label">Größe · {size} px</KText>
          <KSlider
            label="Größe"
            min={64}
            max={280}
            step={8}
            value={size}
            onValueChange={setSize}
          />
          {(
            [
              ["Antenne", antenna, setAntenna],
              ["Bodenschatten", shadow, setShadow],
              ["Interaktion", interactive, setInteractive],
              ["Bewegung reduzieren", reduced, setReduced],
            ] as const
          ).map(([label, checked, change]) => (
            <KSwitch
              key={label}
              label={label}
              checked={checked}
              onCheckedChange={change}
            />
          ))}
          <KSelect
            label="Blicksteuerung"
            value={mode}
            onValueChange={setMode}
            options={[
              { value: "pointer", label: "Maus / Finger" },
              { value: "external", label: "Externer Zielpunkt" },
              { value: "off", label: "Keine Verfolgung" },
            ]}
          />
          {mode === "external" && (
            <>
              <KSlider
                label="Ziel X"
                min={-1}
                max={1}
                step={0.05}
                value={x}
                onValueChange={setX}
              />
              <KSlider
                label="Ziel Y"
                min={-1}
                max={1}
                step={0.05}
                value={y}
                onValueChange={setY}
              />
            </>
          )}
        </aside>
      </div>
    </div>
  );
}
const meta = {
  title: "Data Display/RobotHead",
  component: KRobotHead,
  parameters: { layout: "fullscreen" },
  args: { state: "idle", shape: "rectangle", size: 160, seed: 0.42 },
  argTypes: {
    state: { control: "select", options: kRobotHeadStates },
    shape: { control: "select", options: kRobotHeadShapes },
    color: { control: "color" },
    trimColor: { control: "color" },
    screenColor: { control: "color" },
    audio: { control: false },
    target: { control: "object" },
  },
} satisfies Meta<typeof KRobotHead>;
export default meta;
type Story = StoryObj<typeof meta>;
function AudioDemo() {
  const [source, setSource] = useState<KRobotHeadAudioSource>();
  const [playing, setPlaying] = useState(false);
  const [state, setState] = useState<KRobotHeadState>("speaking");
  return (
    <div className="robot-demo">
      <header className="robot-demo__heading">
        <div>
          <KText as="h1" variant="heading3">
            KRobotHead · Audio
          </KText>
          <KText>
            Deine Datei, dein Roboter. Abspielen und direkt vergleichen.
          </KText>
        </div>
      </header>
      <div className="robot-demo__layout robot-demo__layout--audio">
        <section className="robot-demo__preview" aria-label="Robotervorschau">
          <div className="robot-demo__stage">
            <KRobotHead
              size={240}
              state={state}
              audio={source}
              seed={0.42}
              aria-label="Roboter aktivieren"
            />
          </div>
          <div className="robot-demo__row">
            <KButton
              variant={state === "speaking" ? "primary" : "secondary"}
              aria-pressed={state === "speaking"}
              onClick={() => setState("speaking")}
            >
              Sprechen
            </KButton>
            <KButton
              variant={state === "listening" ? "primary" : "secondary"}
              aria-pressed={state === "listening"}
              onClick={() => setState("listening")}
            >
              Zuhören / Equalizer
            </KButton>
          </div>
          <KText role="status">
            {playing
              ? "Audio läuft"
              : source
                ? "Audio bereit / still"
                : "Synthetische Animation"}
          </KText>
        </section>
        <RobotHeadAudioFixture
          onSource={(audio) => setSource(() => audio)}
          onPlaying={setPlaying}
        />
      </div>
    </div>
  );
}
export const Playground: Story = {
  render: (args) => <PlaygroundFixture {...args} />,
  parameters: { controls: { disable: true } },
};
export const Controls: Story = {
  render: (args) => (
    <div className="robot-demo__single">
      <KRobotHead {...args} aria-label="Interaktiver Roboter" />
    </div>
  ),
};
export const States: Story = {
  render: (args) => (
    <div className="robot-demo__catalogue">
      {kRobotHeadStates.map((state) => (
        <section key={state}>
          <KRobotHead {...args} state={state} aria-label={state} />
          <KText>{state}</KText>
        </section>
      ))}
    </div>
  ),
};
export const Shapes: Story = {
  render: (args) => (
    <div className="robot-demo__catalogue">
      {kRobotHeadShapes.map((shape) => (
        <section key={shape}>
          <KRobotHead {...args} shape={shape} aria-label={shape} />
          <KText>{shape}</KText>
        </section>
      ))}
    </div>
  ),
};
export const Audio: Story = {
  args: { state: "speaking" },
  render: () => <AudioDemo />,
  parameters: { controls: { disable: true } },
};
