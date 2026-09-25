import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KLineChart,
  KSurface,
  KText,
  KButton,
  KDialog,
  KTable,
  type KChartSelection,
} from "@k-design-system/ui";
import fixture from "../../../fixtures/chart-line-reference.json";

function ChartFixture({
  scenario = "reference",
  showTableButton = true,
  tableButtonLabel = "Show data table",
  tableTitle = "Data table",
}: {
  scenario?: "reference" | "empty" | "gaps" | "large";
  showTableButton?: boolean;
  tableButtonLabel?: string;
  tableTitle?: string;
}) {
  const [selection, setSelection] = useState<KChartSelection | null>(null);
  const [visible, setVisible] = useState(fixture.series.map((s) => s.id));
  const [table, setTable] = useState(false);
  const series =
    scenario === "empty"
      ? []
      : fixture.series.map((s) => ({
          ...s,
          points:
            scenario === "large"
              ? Array.from({ length: 1000 }, (_, i) => ({
                  id: `sample-${i}`,
                  x:
                    fixture.xAxis.min +
                    ((fixture.xAxis.max - fixture.xAxis.min) * i) / 999,
                  y: 50 + 30 * Math.sin(i / 25 + s.colorIndex),
                }))
              : s.points.map((p, i) => ({
                  ...p,
                  y:
                    scenario === "gaps" && i === 5
                      ? null
                      : scenario === "gaps" && i === 8
                        ? -10
                        : p.y,
                })),
        }));
  const formatDate = (x: number) => `${new Date(x).getUTCDate()} Sep`;
  const dates = [
    ...new Set(series.flatMap((s) => s.points.map((p) => p.x))),
  ].sort((a, b) => a - b);
  const values = series.map((s) => new Map(s.points.map((p) => [p.x, p.y])));
  return (
    <div
      style={{
        width: "100%",
        boxSizing: "border-box",
      }}
    >
      <KSurface
        radius="card"
        style={{ padding: "var(--k-space-card-padding)" }}
      >
        <div
          style={{
            display: "grid",
            gap: "var(--k-space-control-gap)",
            marginBottom: "var(--k-space-content-action-gap)",
          }}
        >
          <KText
            variant="bodySmall"
            style={{ color: "var(--k-color-text-muted)" }}
          >
            Activity
          </KText>
          <KText variant="heading3">Workspace activity</KText>
          <KText
            variant="bodySmall"
            style={{ color: "var(--k-color-text-muted)" }}
          >
            Completed and planned tasks · September 2026
          </KText>
        </div>
        <KLineChart
          series={series}
          xAxis={{
            ...fixture.xAxis,
            format: formatDate,
          }}
          yAxis={{
            ...fixture.yAxis,
            ...(scenario === "gaps"
              ? { min: -25, ticks: [-25, 0, 25, 50, 75, 100] }
              : {}),
            format: String,
          }}
          label="Workspace activity"
          description="Use left and right arrow keys to explore values. Escape clears the selection."
          selectedPoint={selection}
          onSelectionChange={setSelection}
          visibleSeriesIds={visible}
          onVisibleSeriesChange={setVisible}
        />
        {showTableButton && (
          <KButton
            style={{ marginTop: "var(--k-space-content-action-gap)" }}
            variant="ghost"
            aria-haspopup="dialog"
            onClick={() => setTable(true)}
          >
            {tableButtonLabel}
          </KButton>
        )}
        <KDialog open={table} onOpenChange={setTable} title={tableTitle}>
          <KTable
            label={tableTitle}
            columns={[
              { id: "date", header: "Date" },
              ...series.map((s) => ({ id: s.id, header: s.label })),
            ]}
            rows={dates.map((x) => ({
              id: String(x),
              cells: [
                formatDate(x),
                ...values.map((points) =>
                  points.get(x) == null ? "�" : String(points.get(x)),
                ),
              ],
            }))}
          />
        </KDialog>
      </KSurface>
    </div>
  );
}
const meta = {
  title: "Data display/Charts",
  component: ChartFixture,
  parameters: { layout: "fullscreen", fixtureId: "chart-line-reference" },
  args: {
    scenario: "reference",
    showTableButton: true,
    tableButtonLabel: "Show data table",
    tableTitle: "Data table",
  },
} satisfies Meta<typeof ChartFixture>;
export default meta;
export const LineReference: StoryObj<typeof meta> = {
  name: "chart-line-reference",
};
export const Empty: StoryObj<typeof meta> = {
  name: "chart-line-empty",
  args: { scenario: "empty" },
  parameters: { fixtureId: "chart-line-empty" },
};
export const Gaps: StoryObj<typeof meta> = {
  name: "chart-line-gaps",
  args: { scenario: "gaps" },
  parameters: { fixtureId: "chart-line-gaps" },
};
export const Large: StoryObj<typeof meta> = {
  name: "chart-line-large",
  args: { scenario: "large" },
  parameters: { fixtureId: "chart-line-large" },
};
