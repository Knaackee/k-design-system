import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KInline,
  KShowcaseGrid,
  KStack,
  KSurface,
  KText,
  type KShowcaseGridProps,
} from "@k-design-system/ui";
import "./showcase-grid-fixture.css";

// Illustrative gallery content only: consumers supply their own screenshots or components.
const previews = [
  ["Studio Flora", "Zeit für dich.", "Haare & Styling", "rose"],
  ["Grünraum", "Mehr Leben im Garten.", "Gartenpflege", "green"],
  ["Balance", "Ankommen. Durchatmen.", "Massage & Bewegung", "blue"],
  ["Pfotenfreund", "Für deinen Lieblingsgast.", "Fellpflege", "amber"],
  ["Lichtblick", "Dein Zuhause. Dein Stil.", "Beratung & Einrichtung", "blue"],
  ["Atelier Mia", "Schön in deinem Alltag.", "Kosmetik", "rose"],
  ["Klar & Gut", "Raum zum Wohlfühlen.", "Reinigung", "green"],
  ["Technik daheim", "Einfach wieder verbunden.", "IT-Hilfe", "amber"],
  ["Gartenzeit", "Draußen wird es schön.", "Pflanzen & Pflege", "green"],
  ["Salon Zuhause", "Dein Moment. Dein Look.", "Mobile Haarpflege", "rose"],
  ["Freiraum", "Bewegung, die gut tut.", "Physiotherapie", "blue"],
  ["Werk & Wert", "Gut gemacht hält länger.", "Handwerk", "amber"],
] as const;

function PreviewCard({ index }: { index: number }) {
  const [name, headline, service, tone] = previews[index]!;
  return (
    <KSurface
      radius="card"
      elevation="low"
      className={`showcase-preview showcase-preview--${tone}`}
    >
      <KStack gap="control" align="stretch">
        <KInline gap="control" className="showcase-preview__brand">
          <span className="showcase-preview__mark">{name[0]}</span>
          <KText variant="label">{name}</KText>
        </KInline>
        <div className="showcase-preview__art">
          <span className="showcase-preview__orb" />
          <span className="showcase-preview__arch" />
          <span className="showcase-preview__leaf" />
        </div>
        <KText variant="heading4" textWrap="balance">
          {headline}
        </KText>
        <KText variant="bodySmall">{service}</KText>
        <div className="showcase-preview__line" />
        <div className="showcase-preview__line showcase-preview__line--short" />
        <span className="showcase-preview__cta">
          <KText variant="label">Termin auswählen</KText>
        </span>
      </KStack>
    </KSurface>
  );
}

const items = previews.map((_, index) => ({
  id: `preview-${index}`,
  content: <PreviewCard index={index} />,
}));

function Gallery({
  hero = true,
  width,
  ...props
}: Partial<KShowcaseGridProps> & { hero?: boolean; width?: number }) {
  const [revision, setRevision] = useState(0);
  const [paused, setPaused] = useState(false);
  return (
    <KStack
      gap="action"
      align="stretch"
      style={{ width: width ?? "100%", maxWidth: "100%" }}
    >
      <KShowcaseGrid
        key={revision}
        items={items}
        {...props}
        animate={props.animate !== false && !paused}
        className="showcase-fixture"
        style={{ minHeight: width ? "42rem" : "40rem", ...props.style }}
      >
        {hero && (
          <div className="showcase-fixture__quiet-area">
            <KStack
              gap="section"
              align="center"
              className="showcase-fixture__copy"
            >
              <KText variant="caption">DEINE SEITE. DEIN STIL.</KText>
              <KText variant="heading1" textWrap="balance">
                So vielfältig wie dein Arbeitsalltag.
              </KText>
              <KText variant="body" textWrap="balance">
                Eine Buchungsseite, die zu dir passt. Und mehr Zeit für das, was
                du liebst.
              </KText>
              <KButton
                onClick={() =>
                  props.loop
                    ? setPaused((value) => !value)
                    : setRevision((value) => value + 1)
                }
              >
                {props.loop
                  ? paused
                    ? "Animation fortsetzen"
                    : "Animation pausieren"
                  : "Animation erneut ansehen"}
              </KButton>
            </KStack>
          </div>
        )}
      </KShowcaseGrid>
      {!hero && (
        <KButton
          variant="ghost"
          onClick={() => setRevision((value) => value + 1)}
        >
          Animation erneut ansehen
        </KButton>
      )}
    </KStack>
  );
}

const meta = {
  title: "Patterns/ShowcaseGrid",
  component: KShowcaseGrid,
  parameters: { layout: "fullscreen" },
  args: {
    items,
    columns: 4,
    compactColumns: 2,
    tilt: -8,
    durationMs: 900,
    staggerMs: 90,
    animate: true,
    edgeFade: true,
    loop: true,
    loopDurationMs: 45000,
  },
  argTypes: {
    items: { control: false },
    children: { control: false },
    tilt: { control: { type: "range", min: -15, max: 15, step: 1 } },
  },
} satisfies Meta<typeof KShowcaseGrid>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Hero: Story = { render: (args) => <Gallery {...args} /> };
export const Mobile: Story = {
  render: (args) => <Gallery {...args} width={390} />,
};
export const GridOnly: Story = {
  render: (args) => <Gallery {...args} hero={false} />,
};
export const ReducedMotion: Story = {
  args: { animate: false },
  render: (args) => <Gallery {...args} />,
};
export const Dark: Story = {
  globals: { theme: "dark" },
  render: (args) => <Gallery {...args} />,
};
