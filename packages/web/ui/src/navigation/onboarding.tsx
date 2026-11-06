import { useState, type ReactNode } from "react";
import { KProgressDots } from "../data-display/progress-dots.js";
import { useKLocalization } from "../localization/provider.js";
import { KButton } from "../primitives/button.js";

export interface KOnboardingProps {
  /** One element per step; each scrolls on its own when it is taller. */
  steps: readonly ReactNode[];
  onDone: () => void;
  onStepChange?: (step: number) => void;
  /** Whether the current step allows Next (a required answer is given). */
  canContinue?: boolean;
  initialStep?: number;
  /** Overrides the localized "Next" and "Done". */
  nextLabel?: string;
  doneLabel?: string;
}

/**
 * A step-by-step introduction or setup (Decision 0015). The footer is fixed
 * at the bottom on every step: Back at the start (hidden on the first step,
 * its space kept), the progress in the middle and Next — Done on the last
 * step — at the end. Only the step content changes. Mirrors `KOnboarding`
 * in Flutter.
 */
export function KOnboarding({
  steps,
  onDone,
  onStepChange,
  canContinue = true,
  initialStep = 0,
  nextLabel,
  doneLabel,
}: KOnboardingProps) {
  const { messages } = useKLocalization();
  const [step, setStep] = useState(initialStep);
  const [direction, setDirection] = useState<"forward" | "back">("forward");
  const last = step === steps.length - 1;
  const go = (next: number) => {
    setDirection(next > step ? "forward" : "back");
    setStep(next);
    onStepChange?.(next);
  };
  return (
    <div className="k-onboarding">
      <div
        key={step}
        className="k-onboarding__content"
        data-direction={direction}
      >
        {steps[step]}
      </div>
      <div className="k-onboarding__footer">
        <span
          className="k-onboarding__back"
          data-hidden={step === 0 || undefined}
        >
          <KButton
            variant="ghost"
            disabled={step === 0}
            tabIndex={step === 0 ? -1 : undefined}
            onClick={() => go(step - 1)}
          >
            {messages.onboardingBack}
          </KButton>
        </span>
        <KProgressDots
          count={steps.length}
          activeIndex={step}
          label={messages.onboardingStep
            .replace("{current}", String(step + 1))
            .replace("{total}", String(steps.length))}
        />
        <span className="k-onboarding__next">
          <KButton
            disabled={!canContinue}
            onClick={() => (last ? onDone() : go(step + 1))}
          >
            {last
              ? (doneLabel ?? messages.onboardingDone)
              : (nextLabel ?? messages.onboardingNext)}
          </KButton>
        </span>
      </div>
    </div>
  );
}
