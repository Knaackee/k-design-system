import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KBarChart,
  KAreaChart,
  KDonutChart,
  KSurface,
  KText,
  KButton,
  KDialog,
  KTable,
  type KChartSelection,
} from "@k-design-system/ui";
import fixture from "../../../fixtures/chart-families.json";

type Variant =
  | "bar"
  | "bar-compact"
  | "bar-horizontal"
  | "bar-stacked"
  | "area"
  | "area-stacked"
  | "donut"
  | "pie";
function ChartFamilyFixture({
  variant = "bar",
  showTableButton = true,
  tableButtonLabel = "Show data table",
  tableTitle = "Data table",
}: {
  variant?: Variant;
  showTableButton?: boolean;
  tableButtonLabel?: string;
  tableTitle?: string;
}) {
  const [selection, setSelection] = useState<KChartSelection | null>(null);
  const [segment, setSegment] = useState<string | null>(null);
  const [visible, setVisible] = useState(fixture.series.map((s) => s.id));
  const [visibleSegments, setVisibleSegments] = useState(
    fixture.segments.map((s) => s.id),
  );
  const [table, setTable] = useState(false);
  const circular = variant === "donut" || variant === "pie";
  const stacked = variant.endsWith("stacked");
  const title = circular ? "Task distribution" : "Workspace activity";
  const formatCategory = (x: number) => fixture.categories[x] ?? "";
  const props = {
    series:
      variant === "bar-compact" ? fixture.series.slice(0, 1) : fixture.series,
    xAxis: {
      min: variant.startsWith("bar") ? -0.5 : 0,
      max: variant.startsWith("bar") ? 5.5 : 5,
      ticks: [0, 1, 2, 3, 4, 5],
      format: formatCategory,
    },
    yAxis: {
      min: 0,
      max: stacked ? 160 : 100,
      ticks: stacked ? [0, 40, 80, 120, 160] : [0, 25, 50, 75, 100],
      format: String,
    },
    label: title,
    selectedPoint: selection,
    onSelectionChange: setSelection,
    visibleSeriesIds: visible,
    onVisibleSeriesChange: variant === "bar-compact" ? undefined : setVisible,
    stacked,
  };
  return (
    <KSurface
      radius="card"
      style={{
        padding: "var(--k-space-card-padding)",
        width: "100%",
        boxSizing: "border-box",
      }}
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
        <KText variant="heading3">{title}</KText>
        <KText
          variant="bodySmall"
          style={{ color: "var(--k-color-text-muted)" }}
        >
          {circular
            ? "Tasks by status"
            : "Completed and planned tasks · This week"}
        </KText>
      </div>
      {circular ? (
        <KDonutChart
          segments={fixture.segments}
          label={title}
          selectedId={segment}
          onSelectionChange={setSegment}
          visibleSegmentIds={visibleSegments}
          onVisibleSegmentsChange={setVisibleSegments}
          formatValue={String}
          innerRadiusRatio={variant === "pie" ? 0 : 0.65}
          centerContent={
            variant === "donut" ? (
              <KText variant="heading3">100</KText>
            ) : undefined
          }
        />
      ) : variant.startsWith("area") ? (
        <KAreaChart {...props} />
      ) : (
        <KBarChart
          {...props}
          compact={variant === "bar-compact"}
          orientation={variant === "bar-horizontal" ? "horizontal" : "vertical"}
        />
      )}
      {showTableButton && (
        <KButton
          variant="ghost"
          aria-haspopup="dialog"
          style={{ marginTop: "var(--k-space-content-action-gap)" }}
          onClick={() => setTable(true)}
        >
          {tableButtonLabel}
        </KButton>
      )}
      <KDialog open={table} onOpenChange={setTable} title={tableTitle}>
        <KTable
          label={tableTitle}
          columns={
            circular
              ? [
                  { id: "status", header: "Status" },
                  { id: "value", header: "Tasks" },
                ]
              : [
                  { id: "day", header: "Day" },
                  ...fixture.series.map((s) => ({ id: s.id, header: s.label })),
                ]
          }
          rows={
            circular
              ? fixture.segments.map((s) => ({
                  id: s.id,
                  cells: [s.label, String(s.value)],
                }))
              : fixture.categories.map((day, x) => ({
                  id: day,
                  cells: [
                    day,
                    ...fixture.series.map((s) => String(s.points[x].y)),
                  ],
                }))
          }
        />
      </KDialog>
    </KSurface>
  );
}
const meta = {
  title: "Data display/ChartVariants",
  component: ChartFamilyFixture,
  parameters: { layout: "fullscreen", fixtureId: "chart-bar" },
  args: {
    variant: "bar",
    showTableButton: true,
    tableButtonLabel: "Show data table",
    tableTitle: "Data table",
  },
} satisfies Meta<typeof ChartFamilyFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Bar: Story = { name: "chart-bar" };
export const CompactBar: Story = {
  name: "chart-bar-compact",
  args: { variant: "bar-compact", showTableButton: false },
  parameters: { fixtureId: "chart-bar-compact" },
};
export const HorizontalBar: Story = {
  name: "chart-bar-horizontal",
  args: { variant: "bar-horizontal" },
  parameters: { fixtureId: "chart-bar-horizontal" },
};
export const StackedBar: Story = {
  name: "chart-bar-stacked",
  args: { variant: "bar-stacked" },
  parameters: { fixtureId: "chart-bar-stacked" },
};
export const Area: Story = {
  name: "chart-area",
  args: { variant: "area" },
  parameters: { fixtureId: "chart-area" },
};
export const StackedArea: Story = {
  name: "chart-area-stacked",
  args: { variant: "area-stacked" },
  parameters: { fixtureId: "chart-area-stacked" },
};
export const Donut: Story = {
  name: "chart-donut",
  args: { variant: "donut" },
  parameters: { fixtureId: "chart-donut" },
};
export const Pie: Story = {
  name: "chart-pie",
  args: { variant: "pie" },
  parameters: { fixtureId: "chart-pie" },
};
