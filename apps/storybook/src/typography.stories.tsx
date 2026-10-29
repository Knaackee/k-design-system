import type { Meta, StoryObj } from "@storybook/react-vite";
import { KText, KStack } from "@k-design-system/ui";

const meta = {
  title: "Primitives/Typography",
  component: KText,
  tags: ["autodocs"],
  args: {
    children: "Designing software with clarity",
    variant: "body",
  },
  argTypes: {
    variant: {
      control: "select",
      options: [
        "heading1",
        "heading2",
        "heading3",
        "heading4",
        "heading5",
        "heading6",
        "body",
        "bodySmall",
        "label",
        "caption",
      ],
    },
  },
  parameters: {
    fixtureId: "typography-primary",
  },
} satisfies Meta<typeof KText>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {};

const balancedExamples = [
  "Bereit für einen entspannteren Arbeitsalltag und mehr Umsatz?",
  "Ready for a calmer working day and more revenue?",
  "Prêt pour des journées plus sereines et un meilleur chiffre d’affaires ?",
];

export const BalancedMobile: Story = {
  parameters: { fixtureId: "typography-balanced-mobile" },
  render: () => (
    <KStack
      gap="section"
      style={{ width: 340, maxWidth: "100%", textAlign: "center" }}
    >
      {balancedExamples.map((text) => (
        <KText key={text} variant="heading1" textWrap="balance">
          {text}
        </KText>
      ))}
    </KStack>
  ),
};

export const BalancedTablet: Story = {
  parameters: { fixtureId: "typography-balanced-tablet" },
  render: () => (
    <KStack
      gap="section"
      style={{ width: 680, maxWidth: "100%", textAlign: "center" }}
    >
      {balancedExamples.map((text) => (
        <KText key={text} variant="heading1" textWrap="balance">
          {text}
        </KText>
      ))}
    </KStack>
  ),
};

export const BalancedLargeText: Story = {
  ...BalancedMobile,
  globals: { textScale: 1.5 },
  parameters: { fixtureId: "typography-balanced-large-text" },
};

export const Scale: Story = {
  parameters: {
    fixtureId: "typography-scale",
  },
  render: () => (
    <KStack gap="section" className="k-type-specimen">
      <KText variant="heading1">H1 · Product direction</KText>
      <KText variant="heading2">H2 · Planning and strategy</KText>
      <KText variant="heading3">H3 · Project overview</KText>
      <KText variant="heading4">H4 · Current milestone</KText>
      <KText variant="heading5">H5 · Work in progress</KText>
      <KText variant="heading6">H6 · Supporting section</KText>
      <KText>
        Body · Clear interface copy supports fast reading across product and
        editorial contexts.
      </KText>
      <KText variant="bodySmall">
        Body small · Secondary information remains legible without competing
        with the main content.
      </KText>
      <KText variant="label">Label · ASSIGNEE</KText>
      <KText variant="caption">Caption · Updated moments ago</KText>
    </KStack>
  ),
};
