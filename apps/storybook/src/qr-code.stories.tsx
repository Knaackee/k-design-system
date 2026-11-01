import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import {
  KQrCode,
  KButton,
  KStack,
  KInline,
  KText,
  type KQrCodeProps,
  type KQrCodeVariant,
  type KQrCodeModuleShape,
  type KQrCodeEyeShape,
} from "@k-design-system/ui";
const variants: [KQrCodeVariant, string][] = [
  ["classic", "Klassisch"],
  ["soft", "Soft"],
  ["portrait", "Persönlich"],
  ["card", "Visitenkarte"],
];
function Playground(props: KQrCodeProps) {
  const [variant, setVariant] = useState<KQrCodeVariant>("portrait");
  const [shape, setShape] = useState<KQrCodeModuleShape>("fluid");
  const [eyes, setEyes] = useState<KQrCodeEyeShape>("rounded");
  const [color, setColor] = useState("#2563eb");
  return (
    <KStack
      align="center"
      gap="section"
      style={{ maxWidth: 680, margin: "auto" }}
    >
      <KStack align="center">
        <KText variant="heading2">Dein QR-Code</KText>
        <KText>Ein Scan. Direkt zu deiner Buchungsseite.</KText>
      </KStack>
      <KInline gap="control" wrap>
        {variants.map(([key, name]) => (
          <KButton
            key={key}
            variant={variant === key ? "primary" : "secondary"}
            onClick={() => setVariant(key)}
          >
            {name}
          </KButton>
        ))}
      </KInline>
      <KInline gap="control" wrap>
        {(
          [
            ["square", "Eckig"],
            ["rounded", "Abgerundet"],
            ["dots", "Punkte"],
            ["fluid", "Fließend"],
          ] as const
        ).map(([key, label]) => (
          <KButton
            key={key}
            variant={shape === key ? "primary" : "secondary"}
            onClick={() => setShape(key)}
          >
            {label}
          </KButton>
        ))}
      </KInline>
      <KInline gap="control" wrap>
        {(
          [
            ["square", "Eckige Ecken"],
            ["rounded", "Weiche Ecken"],
            ["circle", "Runde Ecken"],
          ] as const
        ).map(([key, label]) => (
          <KButton
            key={key}
            variant={eyes === key ? "primary" : "secondary"}
            onClick={() => setEyes(key)}
          >
            {label}
          </KButton>
        ))}
      </KInline>
      <KQrCode
        eyeShape={eyes}
        {...props}
        variant={variant}
        color={color}
        moduleShape={shape}
      />
      <KInline gap="control" wrap>
        {[
          ["#2563eb", "Blau"],
          ["#7c3aed", "Violett"],
          ["#059669", "Grün"],
          ["#18181b", "Graphit"],
        ].map(([value, name]) => (
          <KButton
            key={value}
            variant={color === value ? "primary" : "secondary"}
            onClick={() => setColor(value)}
          >
            {name}
          </KButton>
        ))}
      </KInline>
    </KStack>
  );
}
const meta = {
  title: "Data display/QrCode",
  component: KQrCode,
  args: {
    data: "https://example.com/book/alex",
    label: "Buchungsseite öffnen",
    size: 240,
    color: "#2563eb",
    imageUrl: "/image-cropper/jordan.png",
    title: "Alex Morgan",
    caption: "Termin buchen",
  },
  argTypes: {
    eyeShape: { control: "select", options: ["square", "rounded", "circle"] },
    moduleShape: {
      control: "select",
      options: ["square", "rounded", "dots", "fluid"],
    },
    variant: { control: "select", options: variants.map(([key]) => key) },
    color: { control: "color" },
    size: { control: { type: "range", min: 160, max: 400, step: 8 } },
  },
} satisfies Meta<typeof KQrCode>;
export default meta;
type Story = StoryObj<typeof meta>;
export const PlaygroundStory: Story = {
  name: "qr-code-playground",
  render: (props) => <Playground {...props} />,
};
export const Classic: Story = { args: { variant: "classic" } };
export const Soft: Story = { args: { variant: "soft" } };
export const Portrait: Story = { args: { variant: "portrait" } };
export const Card: Story = { args: { variant: "card" } };

export const Dots: Story = {
  args: { moduleShape: "dots", variant: "portrait" },
};
export const Fluid: Story = {
  args: { moduleShape: "fluid", variant: "portrait" },
};
