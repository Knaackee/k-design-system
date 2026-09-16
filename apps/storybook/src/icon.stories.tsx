import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KContainer,
  KIcon,
  KGrid,
  KInline,
  KStack,
  KText,
  kIconNames,
  type KIconName,
} from "@k-design-system/ui";
const meta = {
  title: "Primitives/Icon",
  parameters: { fixtureId: "icon-lucide" },
  args: { size: 16 },
  argTypes: { size: { control: "select", options: [12, 16, 20, 24] } },
} satisfies Meta<{ size: number }>;
export default meta;
type Story = StoryObj<{ size: number }>;
export const Lucide: Story = {
  render: ({ size }) => (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Shared Lucide icons</KText>
          <KInline wrap gap="section" align="center">
            {(
              [
                ["check", "Check"],
                ["x", "Close"],
                ["arrow-right", "Next"],
                ["info", "Information"],
              ] as [KIconName, string][]
            ).map(([name, label]) => (
              <KIcon key={name} name={name} label={label} size={size} />
            ))}
          </KInline>
          <KInline gap="section" align="center">
            {[12, 16, 20].map((size) => (
              <KIcon
                key={size}
                name="check"
                size={size}
                label={`Check ${size}`}
              />
            ))}
          </KInline>
          <KText variant="bodySmall">{kIconNames.length} Lucide icons</KText>
          <KGrid minColumnWidth={48} gap="control">
            {kIconNames.map((name) => (
              <div key={name} className="k-icon-cell" title={name}>
                <KIcon name={name} size={size} label={name} />
              </div>
            ))}
          </KGrid>
        </KStack>
      </KContainer>
    </div>
  ),
};
