import {
  useEffect,
  useRef,
  useState,
  type ReactNode,
  type HTMLAttributes,
} from "react";
import { tableWidths, type TableTrack } from "./table-layout.js";

export type KTableAlign = "start" | "center" | "end";
export interface KTableColumn extends TableTrack {
  id: string;
  header: ReactNode;
  align?: KTableAlign;
  headerLabel?: string;
  /** Optional cell inset in logical pixels; defaults to the theme control inset. */
  paddingInline?: number;
}
export interface KTableRow {
  id: string;
  cells: readonly ReactNode[];
}
export interface KTableProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "children"
> {
  label: string;
  showHeader?: boolean;
  showRowDividers?: boolean;
  columns: readonly KTableColumn[];
  rows: readonly KTableRow[];
}

/** Semantic table with shared fixed/flexible tracks and horizontal overflow. */
export function KTable({
  label,
  showHeader = true,
  showRowDividers = true,
  columns,
  rows,
  className = "",
  ...props
}: KTableProps) {
  const viewport = useRef<HTMLDivElement>(null);
  const [available, setAvailable] = useState(0);
  useEffect(() => {
    const element = viewport.current;
    if (!element) return;
    const measure = () => setAvailable(element.clientWidth);
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  if (!showHeader && columns.some((c) => !c.headerLabel?.trim()))
    throw new Error("KTable hidden headers require column headerLabel");
  if (!label.trim()) throw new Error("KTable requires a nonempty label");
  for (const [name, items] of [
    ["column", columns],
    ["row", rows],
  ] as const) {
    const ids = new Set<string>();
    for (const item of items) {
      if (!item.id.trim() || ids.has(item.id))
        throw new Error(`KTable ${name} IDs must be nonempty and unique`);
      ids.add(item.id);
    }
  }
  if (rows.some((row) => row.cells.length !== columns.length))
    throw new Error("KTable rows must contain one cell per column");
  if (
    columns.some(
      (c) =>
        c.paddingInline !== undefined &&
        (!Number.isFinite(c.paddingInline) || c.paddingInline < 0),
    )
  )
    throw new RangeError("KTable paddingInline must be finite and nonnegative");
  const widths = tableWidths(columns, available);
  const width = widths.reduce((a, b) => a + b, 0);
  return (
    <div
      {...props}
      ref={viewport}
      className={`k-table-viewport ${className}`}
      role="region"
      aria-label={label}
      tabIndex={width > available ? 0 : undefined}
    >
      <table
        data-row-dividers={showRowDividers}
        className="k-table"
        aria-label={label}
        style={{ width }}
      >
        <colgroup>
          {columns.map((column, index) => (
            <col key={column.id} style={{ width: widths[index] }} />
          ))}
        </colgroup>
        <thead className={showHeader ? undefined : "k-table-hidden-header"}>
          <tr>
            {columns.map((column) => (
              <th
                key={column.id}
                scope="col"
                style={{
                  textAlign: column.align ?? "start",
                  paddingInline: column.paddingInline,
                }}
              >
                {showHeader ? column.header : column.headerLabel}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id} data-row-id={row.id}>
              {row.cells.map((cell, index) => (
                <td
                  key={columns[index].id}
                  style={{
                    textAlign: columns[index].align ?? "start",
                    paddingInline: columns[index].paddingInline,
                  }}
                >
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
