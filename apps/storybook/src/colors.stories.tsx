import type { Meta, StoryObj } from "@storybook/react-vite";
import { KInline, KStack, KText } from "@k-design-system/ui";

const ColorGallery = () => (
  <KInline wrap className="k-color-grid">
    {[
      ["primary", "Primary", "Brand and principal actions"],
      ["secondary", "Secondary", "Supporting brand emphasis"],
      ["info", "Info", "Neutral system information"],
      ["success", "Success", "Completed or healthy state"],
      ["warning", "Warning", "Attention without failure"],
      ["error", "Error", "Failure or destructive state"],
    ].map(([role, name, description]) => (
      <KInline
        align="center"
        className={`k-color-card k-color-card--${role}`}
        key={role}
      >
        <span className="k-color-card__accent" aria-hidden="true" />
        <KStack className="k-color-card__copy">
          <KText variant="label">{name}</KText>
          <KText variant="bodySmall">{description}</KText>
        </KStack>
      </KInline>
    ))}
  </KInline>
);

const meta = {
  title: "Primitives/Colors",
  component: ColorGallery,
  tags: ["autodocs"],
  parameters: {
    fixtureId: "colors-semantic-roles",
  },
} satisfies Meta<typeof ColorGallery>;

export default meta;
type Story = StoryObj<typeof meta>;

export const SemanticRoles: Story = {};
