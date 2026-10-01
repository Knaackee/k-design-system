import { DataTableHeader } from "./data-table-header.js";
import { tableWidths } from "./table-layout.js";
import type { KDataTableProps } from "./data-table.js";

export function VirtualTableHeader<T>({
  table,
  width,
  gutter,
  offset,
  tableId,
}: {
  table: KDataTableProps<T>;
  width: number;
  gutter: number;
  offset: number;
  tableId: string;
}) {
  const widths = tableWidths(table.columns, width - gutter);
  return (
    <div className="k-data-table-header-viewport" role="rowgroup">
      <div
        className="k-data-table-header-row"
        role="row"
        aria-rowindex={1}
        style={{
          width,
          paddingInlineStart: gutter,
          transform: `translateX(${-offset}px)`,
        }}
      >
        {table.columns.map((column, index) => (
          <div
            key={column.id}
            role="columnheader"
            aria-colindex={index + 1}
            id={`${tableId}-column-${index}`}
            aria-sort={
              column.compare
                ? table.sort?.columnId === column.id
                  ? table.sort.direction
                  : "none"
                : undefined
            }
            style={{
              width: widths[index],
              textAlign: column.align ?? "start",
              paddingInline: column.paddingInline,
            }}
          >
            <DataTableHeader
              column={column}
              sort={table.sort}
              onSortChange={table.onSortChange}
              beforeSort={
                table.activeCell
                  ? () => table.onBeforeActiveCellExit?.() ?? false
                  : undefined
              }
            />
          </div>
        ))}
      </div>
    </div>
  );
}
