import type { Meta, StoryObj } from "@storybook/react-vite";
import { useEffect, useRef, type ReactNode } from "react";
import { applyKAccent, KMetricCard } from "@k-design-system/ui";
import "./metric-card.css";

const meta = {
  title: "Data Display/Metric Card",
  component: KMetricCard,
  args: { label: "Umsatz", value: "0 €", description: "noch keine Termine" },
  parameters: { fixtureId: "metric-card", layout: "fullscreen" },
  globals: { style: "apple", language: "de" },
} satisfies Meta<typeof KMetricCard>;
export default meta;
type Story = StoryObj<typeof meta>;

function Review({ children }: { children: ReactNode }) {
  const root = useRef<HTMLDivElement>(null);
  useEffect(
    () => (root.current ? applyKAccent(root.current, "#0C679F") : undefined),
    [],
  );
  return (
    <div ref={root} className="metric-card-review">
      {children}
    </div>
  );
}
const revenue = [12, 16, 13, 18, 22, 19, 26, 24, 28, 25, 29, 33];
const bookings = [2, 3, 3, 5, 4, 6, 5, 7, 6, 7, 8, 9];
const customers = [1, 1, 2, 2, 3, 2, 3, 4, 4, 4, 5, 5];
function Metrics({ filled }: { filled: boolean }) {
  return (
    <Review>
      <div className="metric-card-review__grid">
        <KMetricCard
          label="Umsatz"
          value={filled ? "146,76 €" : "0 €"}
          description={filled ? "bestätigte Termine" : "noch keine Termine"}
          comparison={
            filled
              ? {
                  label: "+12%",
                  description: "gegenüber der Vorperiode",
                  sentiment: "positive",
                }
              : undefined
          }
          trend={
            filled
              ? { values: revenue, label: "Umsatz im ausgewählten Zeitraum" }
              : undefined
          }
        />
        <KMetricCard
          label="Buchungen"
          value={filled ? "8" : "0"}
          description={filled ? "heute 3" : "noch keine Termine"}
          comparison={
            filled
              ? {
                  label: "+3",
                  description: "gegenüber der Vorperiode",
                  sentiment: "positive",
                }
              : undefined
          }
          trend={
            filled
              ? {
                  values: bookings,
                  label: "Buchungen im ausgewählten Zeitraum",
                }
              : undefined
          }
        />
        <KMetricCard
          label="Neue Kund:innen"
          value={filled ? "5" : "0"}
          description={filled ? "erstmals gebucht" : "–"}
          comparison={
            filled
              ? {
                  label: "+2",
                  description: "gegenüber der Vorperiode",
                  sentiment: "positive",
                }
              : undefined
          }
          trend={
            filled
              ? {
                  values: customers,
                  label: "Erstbuchungen im ausgewählten Zeitraum",
                }
              : undefined
          }
        />
        <KMetricCard
          label="Auslastung"
          value={filled ? "25 %" : "0 %"}
          description={
            filled ? "4 von 16 h diese Woche" : "0 von 16 h diese Woche"
          }
          progress={{
            value: filled ? 25 : 0,
            label: "Auslastung der verfügbaren Arbeitszeit",
          }}
        />
      </div>
    </Review>
  );
}
export const FilledDark: Story = {
  globals: { theme: "dark" },
  render: () => <Metrics filled />,
};
export const EmptyLight: Story = {
  globals: { theme: "light" },
  render: () => <Metrics filled={false} />,
};
export const FilledLight: Story = {
  globals: { theme: "light" },
  render: () => <Metrics filled />,
};
export const EmptyDark: Story = {
  globals: { theme: "dark" },
  render: () => <Metrics filled={false} />,
};
export const EdgeCases: Story = {
  render: () => (
    <Review>
      <div className="metric-card-review__grid">
        <KMetricCard
          label="Umsatz im ausgewählten Zeitraum"
          value="12.450 €"
          description="Noch keine belastbare Vorperiode"
          trend={{ values: [4, 4, 4, 4], label: "Konstanter Umsatz" }}
        />
        <KMetricCard
          label="Buchungen"
          value="3"
          description="Rückgang gegenüber der Vorperiode"
          comparison={{
            label: "−2",
            description: "gegenüber der Vorperiode",
            sentiment: "negative",
          }}
          trend={{
            values: [8, 6, null, 4, 3],
            label: "Verlauf mit einer Datenlücke",
          }}
        />
        <KMetricCard
          label="Neue Kund:innen"
          value="–"
          description="Daten noch nicht verfügbar"
        />
        <KMetricCard
          label="Auslastung"
          value="100 %"
          description="16 von 16 h diese Woche"
          progress={{ value: 100, label: "Auslastung" }}
        />
      </div>
    </Review>
  ),
};
