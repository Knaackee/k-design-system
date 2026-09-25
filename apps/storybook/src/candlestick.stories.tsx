import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KCandlestickChart,
  KSurface,
  KText,
  KButton,
  KDialog,
  KTable,
} from "@k-design-system/ui";
import fixture from "../../../fixtures/chart-candlestick.json";

function CandlestickFixture({
  showTableButton = true,
  tableButtonLabel = "Show data table",
  tableTitle = "Daily prices",
}: {
  showTableButton?: boolean;
  tableButtonLabel?: string;
  tableTitle?: string;
}) {
  const [selected, setSelected] = useState<string | null>(null);
  const [table, setTable] = useState(false);
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
          Demo market data
        </KText>
        <KText variant="heading3">{fixture.title}</KText>
        <KText
          variant="bodySmall"
          style={{ color: "var(--k-color-text-muted)" }}
        >
          {fixture.description}
        </KText>
      </div>
      <KCandlestickChart
        data={fixture.candles}
        label={fixture.title}
        description={fixture.description}
        xAxis={{
          min: -0.5,
          max: 7.5,
          ticks: [0, 2, 4, 6],
          format: (x) => fixture.categories[x] ?? "",
        }}
        yAxis={{
          min: 90,
          max: 120,
          ticks: [90, 100, 110, 120],
          format: (y) => y.toFixed(0),
        }}
        selectedId={selected}
        onSelectionChange={setSelected}
      />
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
          columns={[
            { id: "date", header: "Date" },
            { id: "open", header: "Open" },
            { id: "high", header: "High" },
            { id: "low", header: "Low" },
            { id: "close", header: "Close" },
            { id: "volume", header: "Volume" },
          ]}
          rows={fixture.candles.map((c) => ({
            id: c.id,
            cells: [
              fixture.categories[c.x],
              String(c.open),
              String(c.high),
              String(c.low),
              String(c.close),
              String(c.volume),
            ],
          }))}
        />
      </KDialog>
    </KSurface>
  );
}
const meta = {
  title: "Data display/Candlestick",
  component: CandlestickFixture,
  parameters: { layout: "fullscreen", fixtureId: "chart-candlestick" },
  args: {
    showTableButton: true,
    tableButtonLabel: "Show data table",
    tableTitle: "Daily prices",
  },
} satisfies Meta<typeof CandlestickFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Reference: Story = { name: "chart-candlestick" };
