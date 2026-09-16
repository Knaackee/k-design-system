import type { Meta, StoryObj } from "@storybook/react-vite";
import { KContainer, KGrid, KCard, KStack, KText } from "@k-design-system/ui";
const meta = {
  title: "Primitives/Grid",
  component: KGrid,
  parameters: { fixtureId: "grid-responsive" },
  args: { minColumnWidth: 240, gap: "section" },
  argTypes: {
    columns: {
      control: "select",
      options: ["Auto", 1, 2, 3, 4, 6],
      mapping: { Auto: undefined },
    },
    minColumnWidth: { control: { type: "range", min: 80, max: 400, step: 20 } },
    gap: { control: "select", options: ["control", "action", "section"] },
  },
} satisfies Meta<typeof KGrid>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Responsive: Story = {
  render: (args) => (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Responsive grid</KText>
          <KGrid {...args}>
            {[1, 2, 3, 4].map((n) => (
              <KCard key={n}>
                <KText>Item {n}</KText>
              </KCard>
            ))}
          </KGrid>
        </KStack>
      </KContainer>
    </div>
  ),
};
