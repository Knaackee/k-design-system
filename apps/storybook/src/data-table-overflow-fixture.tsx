import { useState } from "react";
import { KTable, KButton, KIcon, KStack } from "@k-design-system/ui";

export function DataTableOverflowFixture() {
  const [ascending, setAscending] = useState(true);
  return (
    <KStack gap="control" align="stretch">
      <div style={{ maxWidth: 620 }}>
        <KTable
          label="Text overflow"
          columns={[
            {
              id: "name",
              width: 180,
              header: (
                <KButton
                  variant="ghost"
                  className="k-data-table-sort"
                  onClick={() => setAscending(!ascending)}
                >
                  Wirtschaftseinheit
                  <KIcon name={ascending ? "arrow-up" : "arrow-down"} />
                </KButton>
              ),
              sortDirection: ascending ? "ascending" : "descending",
            },
            { id: "owner", width: 140, header: "Verantwortliche Person" },
            {
              id: "budget",
              width: 140,
              header: "Budget",
              align: "end",
              overflow: "visible",
            },
            {
              id: "actions",
              width: 160,
              header: "Aktionen",
              overflow: "visible",
            },
          ]}
          rows={[
            {
              id: "one",
              cells: [
                "Wohnquartier Am Sonnenhang mit langem Namen",
                "Alexandra Musterfrau",
                "1.234.567,89 €",
                <KButton key="open" variant="ghost" onClick={() => {}}>
                  Wirtschaftseinheit öffnen
                </KButton>,
              ],
            },
          ]}
        />
      </div>
      <div style={{ maxWidth: 320 }}>
        <KTable
          label="Multiline description"
          columns={[
            { id: "description", header: "Beschreibung", overflow: "wrap" },
          ]}
          rows={[
            {
              id: "one",
              cells: [
                "Diese Beschreibung darf ausdrücklich mehrere Zeilen verwenden. Alle anderen Textspalten bleiben einzeilig.",
              ],
            },
          ]}
        />
      </div>
    </KStack>
  );
}
