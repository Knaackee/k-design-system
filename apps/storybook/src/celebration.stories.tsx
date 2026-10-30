import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAvatar,
  KButton,
  KCelebration,
  KStack,
  KText,
} from "@k-design-system/ui";

const meta = {
  title: "Patterns/Celebration",
  component: KCelebration,
  args: { children: null, active: true, particleCount: 24, durationMs: 1100 },
} satisfies Meta<typeof KCelebration>;
export default meta;
export const ProfileReveal: StoryObj<typeof meta> = {
  render: (args) => {
    const [revision, replay] = useState(0);
    return (
      <KStack
        gap="section"
        align="center"
        style={{ minHeight: "70vh", justifyContent: "center" }}
      >
        <KCelebration {...args} key={revision}>
          <KAvatar alt="Alex" fallback="A" size="large" />
        </KCelebration>
        <KText variant="heading2">Das sieht schon nach dir aus.</KText>
        <KButton onClick={() => replay((value) => value + 1)}>
          Erneut ansehen
        </KButton>
      </KStack>
    );
  },
};
