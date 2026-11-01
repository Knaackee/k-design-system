import { useState, type CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KPlanPicker,
  KStack,
  KText,
  KIcon,
  type KPlan,
  type KPlanPickerLayout,
} from "@k-design-system/ui";

const plans: KPlan[] = [
  {
    id: "essential",
    name: "Essential",
    description: "Alles für deinen Start.",
    features: [
      "Deine eigene Buchungsseite",
      "Online-Termine",
      "Kundenverwaltung",
    ],
    prices: {
      monthly: {
        amount: "19 €",
        period: "/ Monat",
        billingNote: "Monatliche Abrechnung",
      },
      yearly: {
        amount: "190 €",
        period: "/ Jahr",
        billingNote: "Jährliche Abrechnung",
      },
    },
  },
  {
    id: "plus",
    name: "Plus",
    description: "Mehr Freiraum für deinen Alltag.",
    badge: "Mehr Möglichkeiten",
    features: [
      "Alles aus Essential",
      "Automatische Erinnerungen",
      "Tages- und Routenplanung",
      "Individuelle Buchungsseite",
    ],
    prices: {
      monthly: {
        amount: "29 €",
        period: "/ Monat",
        billingNote: "Monatliche Abrechnung",
      },
      yearly: {
        amount: "290 €",
        period: "/ Jahr",
        billingNote: "Jährliche Abrechnung",
      },
    },
  },
  {
    id: "studio",
    name: "Studio",
    description: "Gemeinsam weiter wachsen.",
    features: [
      "Alles aus Plus",
      "Mehrere Teammitglieder",
      "Gemeinsamer Kalender",
      "Erweiterte Auswertungen",
    ],
    prices: {
      monthly: {
        amount: "49 €",
        period: "/ Monat",
        billingNote: "Monatliche Abrechnung",
      },
      yearly: {
        amount: "490 €",
        period: "/ Jahr",
        billingNote: "Jährliche Abrechnung",
      },
    },
  },
];
type FixtureProps = {
  planCount: number;
  catalog: "tiers" | "durations";
  annual: boolean;
  mobile: boolean;
  stacked: boolean;
  loading: boolean;
  unavailable: boolean;
  accent: string;
  layout: KPlanPickerLayout;
  stickyAction: boolean;
  artwork: boolean;
  noPreselection: boolean;
};
function Fixture({
  planCount,
  catalog,
  annual,
  mobile,
  stacked,
  loading,
  unavailable,
  accent,
  layout,
  stickyAction,
  artwork,
  noPreselection,
}: FixtureProps) {
  const [selection, setSelection] = useState<string | null>(
    noPreselection ? null : "essential",
  );
  const [interval, setInterval] = useState("monthly");
  const [event, setEvent] = useState("");
  const durationPlans: KPlan[] = [
    {
      id: "essential",
      name: "Monatlich",
      features: ["Alle Funktionen", "Monatliche Abrechnung"],
      prices: {
        monthly: {
          amount: "9 €",
          period: "/ Monat",
          billingNote: "9 € werden jeden Monat abgerechnet.",
        },
      },
    },
    {
      id: "plus",
      name: "Jährlich",
      features: ["Alle Funktionen", "Eine Rechnung pro Jahr"],
      prices: {
        monthly: {
          amount: "90 €",
          period: "/ Jahr",
          billingNote: "90 € werden jährlich abgerechnet.",
          equivalent: "Entspricht 7,50 € pro Monat",
        },
      },
    },
    {
      id: "studio",
      name: "Lifetime",
      features: ["Alle Funktionen", "Keine wiederkehrende Zahlung"],
      prices: {
        monthly: {
          amount: "249 €",
          period: "einmalig",
          billingNote: "Einmalige Zahlung von 249 €.",
        },
      },
    },
  ];
  const items = (catalog === "durations" ? durationPlans : plans)
    .slice(0, planCount)
    .map((plan, index) =>
      unavailable && index === planCount - 1 ? { ...plan, prices: {} } : plan,
    );
  const current =
    noPreselection && selection === null
      ? null
      : items.some((plan) => plan.id === selection)
        ? selection
        : (items[0]?.id ?? null);
  return (
    <div
      style={{
        width: "100%",
        boxSizing: "border-box",
        maxWidth: mobile ? 390 : 1040,
        margin: "auto",
        padding: "var(--k-space-card-padding)",
      }}
    >
      <KStack gap="section" align="stretch">
        <KStack gap="control" align="center">
          <KText variant="heading2" textWrap="balance">
            Mach mehr aus deinem Alltag.
          </KText>
          <KText className="k-plan-picker__muted">
            Ein Plan, der zu dir passt.
          </KText>
        </KStack>
        <KPlanPicker
          plans={items}
          layout={layout}
          stickyAction={stickyAction}
          intro={
            artwork ? (
              <KStack gap="action" align="center">
                <KIcon name="sparkles" size={48} strokeWidth={1} />
                <KText variant="heading3">
                  Mehr Zeit für das, was du liebst.
                </KText>
                <KText>Weniger organisieren. Mehr Möglichkeiten.</KText>
              </KStack>
            ) : undefined
          }
          comparison={{
            label: "Leistungen vergleichen",
            rows: [
              {
                id: "page",
                label: "Buchungsseite",
                values: {
                  essential: "Enthalten",
                  plus: "Individuell",
                  studio: "Individuell",
                },
              },
              {
                id: "team",
                label: "Teammitglieder",
                values: { essential: "1", plus: "1", studio: "5" },
              },
              {
                id: "reminders",
                label: "Erinnerungen",
                values: {
                  essential: "Nicht enthalten",
                  plus: "Automatisch",
                  studio: "Automatisch",
                },
              },
              {
                id: "planning",
                label: "Routenplanung",
                values: {
                  essential: "Nicht enthalten",
                  plus: "Enthalten",
                  studio: "Für das Team",
                },
              },
            ],
          }}
          value={current}
          onValueChange={(value) => {
            setSelection(value);
            setEvent(`onValueChange: ${value}`);
          }}
          intervals={
            annual && catalog !== "durations"
              ? [
                  { id: "monthly", label: "Monatlich" },
                  { id: "yearly", label: "Jährlich" },
                ]
              : [{ id: "monthly", label: "Monatlich" }]
          }
          interval={annual && catalog !== "durations" ? interval : "monthly"}
          onIntervalChange={(value) => {
            setInterval(value);
            setEvent(`onIntervalChange: ${value}`);
          }}
          label="Plan wählen"
          intervalLabel="Zahlungsweise"
          unavailableLabel="Bald verfügbar"
          actionLabel="Weiter mit deinem Plan"
          onContinue={(value) =>
            setEvent(`onContinue: ${JSON.stringify(value)}`)
          }
          loading={loading}
          mobileLayout={stacked ? "stacked" : "focused"}
          note="Beispielpreise für die Designprüfung. Es wird kein Kauf ausgelöst."
          style={{ "--k-plan-accent": accent } as CSSProperties}
        />
        <KText variant="caption" role="status" aria-live="polite">
          {event || "Wähle einen Plan, um die Events zu prüfen."}
        </KText>
      </KStack>
    </div>
  );
}
export default {
  title: "Patterns/PlanPicker",
  component: Fixture,
  parameters: { layout: "fullscreen", fixtureId: "plan-picker-playground" },
  args: {
    planCount: 3,
    catalog: "tiers",
    layout: "cards",
    stickyAction: false,
    artwork: false,
    noPreselection: false,
    annual: true,
    mobile: false,
    stacked: false,
    loading: false,
    unavailable: false,
    accent: "var(--k-color-action-primary-background)",
  },
  argTypes: {
    catalog: { control: "select", options: ["tiers", "durations"] },
    layout: {
      control: "select",
      options: ["cards", "stacked", "compact", "focused", "comparison"],
    },
    planCount: { control: { type: "range", min: 1, max: 3, step: 1 } },
    accent: { control: "color" },
  },
} satisfies Meta<typeof Fixture>;
type Story = StoryObj<typeof Fixture>;
export const Playground: Story = {};
export const SingleMonthly: Story = {
  args: { planCount: 1, annual: false },
  parameters: { fixtureId: "plan-picker-single-monthly" },
};
export const SingleAnnual: Story = {
  args: { planCount: 1 },
  parameters: { fixtureId: "plan-picker-single-annual" },
};
export const TwoPlans: Story = {
  args: { planCount: 2 },
  parameters: { fixtureId: "plan-picker-two" },
};
export const Mobile: Story = {
  args: { mobile: true },
  parameters: { fixtureId: "plan-picker-mobile" },
};
export const Stacked: Story = {
  args: { layout: "stacked", stacked: true },
  parameters: { fixtureId: "plan-picker-stacked" },
};
export const Unavailable: Story = {
  args: { unavailable: true },
  parameters: { fixtureId: "plan-picker-unavailable" },
};
export const Loading: Story = {
  args: { loading: true },
  parameters: { fixtureId: "plan-picker-loading" },
};

export const CompactRows: Story = {
  args: { layout: "compact", mobile: true, stacked: true },
  parameters: { fixtureId: "plan-picker-compact-rows" },
};
export const FocusedDetails: Story = {
  args: { layout: "focused" },
  parameters: { fixtureId: "plan-picker-focused" },
};
export const FeatureComparison: Story = {
  args: { layout: "comparison", stacked: true },
  parameters: { fixtureId: "plan-picker-comparison" },
};
export const MobileComparison: Story = {
  args: { layout: "comparison", mobile: true, stacked: true },
  parameters: { fixtureId: "plan-picker-mobile-comparison" },
};
export const BenefitLed: Story = {
  args: { layout: "compact", artwork: true, mobile: true },
  parameters: { fixtureId: "plan-picker-benefit-led" },
};
export const StickyAction: Story = {
  args: { layout: "stacked", mobile: true, stacked: true, stickyAction: true },
  parameters: { fixtureId: "plan-picker-sticky-action" },
};
export const ExplicitChoice: Story = {
  args: { noPreselection: true },
  parameters: { fixtureId: "plan-picker-explicit-choice" },
};
export const LargeText: Story = {
  args: { layout: "compact", mobile: true },
  globals: { textScale: 1.5, density: "spacious" },
  parameters: { fixtureId: "plan-picker-large-text" },
};
export const Dark: Story = {
  globals: { theme: "dark" },
  parameters: { fixtureId: "plan-picker-dark" },
};

export const DurationOffers: Story = {
  args: {
    catalog: "durations",
    layout: "compact",
    mobile: true,
    annual: false,
  },
  parameters: { fixtureId: "plan-picker-duration-offers" },
};
