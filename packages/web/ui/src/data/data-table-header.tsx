import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import type { KDataTableColumn } from "./data-table.js";
import type { KDataTableSort } from "./data-table-model.js";
import { nextDataTableSort } from "./data-table-model.js";
import { TruncatedContent } from "../internal/truncated-content.js";

/** Shared by ordinary and virtual column headers; the consumer owns sort state. */
export function DataTableHeader<T>({
  column,
  sort,
  onSortChange,
  beforeSort,
}: {
  column: KDataTableColumn<T>;
  sort?: KDataTableSort | null;
  onSortChange?: (sort: KDataTableSort | null) => void;
  beforeSort?: () => boolean;
}) {
  const direction = sort?.columnId === column.id ? sort.direction : undefined;
  const icon = (
    <KIcon
      name={
        direction === "ascending"
          ? "arrow-up"
          : direction === "descending"
            ? "arrow-down"
            : "arrow-up-down"
      }
    />
  );
  if (!column.compare || !onSortChange)
    return (
      <span
        className="k-data-table-header-label"
        style={{ paddingInline: column.headerContentInset }}
      >
        {direction && column.align === "end" ? icon : null}
        <TruncatedContent>{column.label}</TruncatedContent>
        {direction && column.align !== "end" ? icon : null}
      </span>
    );
  return (
    <span
      className="k-data-table-header-label"
      style={{ paddingInline: column.headerContentInset }}
    >
      <KButton
        variant="ghost"
        className="k-data-table-sort"
        onClick={() => {
          if (beforeSort && !beforeSort()) return;
          onSortChange(nextDataTableSort(sort, column.id));
        }}
      >
        {column.align === "end" ? icon : null}
        {column.label}
        {column.align !== "end" ? icon : null}
      </KButton>
    </span>
  );
}
