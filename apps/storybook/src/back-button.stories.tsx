import type { Meta, StoryObj } from "@storybook/react-vite";
import { KBackButton, KInline, KStack, KText } from "@k-design-system/ui";

/** Same fixture as Widgetbook Navigation/BackButton/back-button. */
function BackButtonFixture() {
  return (
    <KStack gap="section" style={{ padding: "var(--k-space-layout-gutter)" }}>
      <KInline gap="control" align="center">
        <KBackButton label="Back to Portfolios" onClick={() => {}} />
        <KText variant="heading4" as="h1">
          Riverside
        </KText>
      </KInline>
      <KText variant="bodySmall">
        The chevron alone; screen readers hear “Back to Portfolios”. In
        right-to-left layouts it points the other way.
      </KText>
      <div dir="rtl">
        <KInline gap="control" align="center">
          <KBackButton label="العودة" onClick={() => {}} />
          <KText variant="heading4">ريفرسايد</KText>
        </KInline>
      </div>
    </KStack>
  );
}

export default {
  title: "Navigation/BackButton",
  parameters: { fixtureId: "back-button" },
} satisfies Meta;

export const BackButton: StoryObj = {
  name: "back-button",
  render: () => <BackButtonFixture />,
};
