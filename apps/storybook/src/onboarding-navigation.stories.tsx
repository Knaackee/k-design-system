import { useState, type CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KButton, KIcon, KProgressDots } from "@k-design-system/ui";

function Navigation({ controlSize = 56, iconSize = 24 }) {
  const [step, setStep] = useState(1);
  return (
    <div
      style={
        {
          "--k-size-control": `${controlSize}px`,
          "--k-size-hit-target": `${controlSize}px`,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          width: "100%",
          maxWidth: 600,
          marginInline: "auto",
        } as CSSProperties
      }
    >
      <KButton
        variant="ghost"
        aria-label="Back"
        disabled={step === 0}
        style={{ minWidth: controlSize }}
        onClick={() => setStep(step - 1)}
      >
        <KIcon name="arrow-left" size={iconSize} />
      </KButton>
      <KProgressDots count={3} activeIndex={step} label="Setup" />
      <KButton
        aria-label="Next"
        disabled={step === 2}
        style={{ minWidth: controlSize }}
        onClick={() => setStep(step + 1)}
      >
        <KIcon name="arrow-right" size={iconSize} />
      </KButton>
    </div>
  );
}
const meta = {
  title: "Patterns/OnboardingNavigation",
  component: Navigation,
  parameters: { fixtureId: "onboarding-navigation-touch" },
  args: { controlSize: 56, iconSize: 24 },
} satisfies Meta<typeof Navigation>;
export default meta;
export const Touch: StoryObj<typeof meta> = {};
