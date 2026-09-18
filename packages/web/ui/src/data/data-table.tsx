import { insertDataTableDrafts } from "./data-table-draft-placement.js";
import type { KDataTableDraftRow } from "./data-table-draft.js";
import { useEffect, useRef, useMemo, type ReactNode } from "react";
import { KTable, type KTableColumn, type KTableAlign } from "./table.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { tableWidths } from "./table-layout.js";
import { KStack } from "../primitives/layout.js";
import {
  dataTableModel,
  type DataTableNode,
  type KDataTableSort,
  type KDataTableGroup,
} from "./data-table-model.js";
export type {
  KDataTableSort,
  KDataTableSortDirection,
  KDataTableGroup,
} from "./data-table-model.js";
export interface KDataTableColumn<T> {
  id: string;
  label: string;
  cell: (row: T) => ReactNode;
  compare?: (a: T, b: T) => number;
  width?: number;
  minWidth?: number;
  flex?: number;
  align?: KTableAlign;
  paddingInline?: number;
}
export type {
  KDataTableGroupValue,
  KDataTableSection,
  KDataTableViewport,
  KDataTableEntry,
  KDataTableWindow,
  KDataTableRange,
  KDataTableCellIdentity,
} from "./data-table-entries.js";
import type {
  KDataTableGroupValue,
  KDataTableSection,
  KDataTableViewport,
  KDataTableWindow,
  KDataTableRange,
  KDataTableCellIdentity,
} from "./data-table-entries.js";
import { KVirtualDataTable } from "./data-table-virtual.js";
export type KDataTableDisplayMode = "multiColumn" | "singleColumn";

/** A read-only row projection; consumers own its action and displayed content. */
export interface KDataTableSingleColumn<T> {
  title: (row: T) => ReactNode;
  leading?: (row: T) => ReactNode;
  trailing?: (row: T) => ReactNode;
  onActivate: (row: T) => void;
  ariaLabel: (row: T) => string;
  columnLabel: string;
}

export interface KDataTableProps<T> {
  displayMode?: KDataTableDisplayMode;
  singleColumn?: KDataTableSingleColumn<T>;
  draftRows?: readonly KDataTableDraftRow<T>[];
  viewport?: KDataTableViewport;
  externalWindow?: KDataTableWindow<T>;
  queryRevision?: string;
  onRangeRequest?: (range: KDataTableRange) => void;
  loading?: ReactNode;
  error?: ReactNode;
  activeCell?: KDataTableCellIdentity | null;
  /** Return false to veto scrolling or collapsing away from an invalid editor. */
  onBeforeActiveCellExit?: () => boolean;
  /** Changing this object requests focus; the cell must exist in loaded entries. */
  focusCell?: KDataTableCellIdentity | null;
  label: string;
  columns: readonly KDataTableColumn<T>[];
  rows: readonly T[];
  rowId: (row: T) => string;
  empty: ReactNode;
  toolbar?: ReactNode;
  renderFooter?: (section: KDataTableSection<T>) => ReactNode;
  showRowDividers?: boolean;
  sort?: KDataTableSort | null;
  filter?: (row: T) => boolean;
  groups?: readonly KDataTableGroup<T>[];
  /** Logical pixels per group level; defaults to the control inline inset token. */
  groupIndent?: number;
  collapsedGroups?: ReadonlySet<string>;
  onCollapsedGroupsChange?: (keys: Set<string>) => void;
}
/** Controlled composition: consumer owns query controls, data and state. */
export function KDataTable<T>({
  displayMode = "multiColumn",
  singleColumn,
  draftRows = [],
  viewport,
  externalWindow,
  queryRevision,
  onRangeRequest,
  loading,
  error,
  activeCell,
  onBeforeActiveCellExit,
  focusCell,
  label,
  columns,
  rows,
  rowId,
  empty,
  toolbar,
  renderFooter,
  showRowDividers = false,
  sort,
  filter,
  groups,
  groupIndent,
  collapsedGroups = new Set(),
  onCollapsedGroupsChange,
}: KDataTableProps<T>) {
  const contentRoot = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (viewport || displayMode === "singleColumn" || !focusCell) return;
    const frame = requestAnimationFrame(() => {
      const row = [
        ...(contentRoot.current?.querySelectorAll<HTMLElement>(
          "[data-row-id]",
        ) ?? []),
      ].find((node) => node.dataset.rowId === focusCell.rowId);
      const index = columns.findIndex((c) => c.id === focusCell.columnId);
      const cell = row?.children.item(index);
      cell
        ?.querySelector<HTMLElement>(
          'input:not(:disabled),button:not(:disabled),[tabindex="0"]',
        )
        ?.focus();
    });
    return () => cancelAnimationFrame(frame);
  }, [focusCell, viewport, displayMode]);
  if (
    displayMode === "singleColumn" &&
    (!singleColumn || !singleColumn.columnLabel.trim())
  )
    throw new Error(
      "KDataTable singleColumn requires content and a column label",
    );
  const displayColumns: readonly KDataTableColumn<T>[] =
    displayMode === "singleColumn" && singleColumn
      ? [
          {
            id: "__singleColumn",
            label: singleColumn.columnLabel,
            minWidth: 160,
            paddingInline: 0,
            cell: (row) => {
              const content = (
                <>
                  {singleColumn.leading && (
                    <span className="k-data-single-leading">
                      {singleColumn.leading(row)}
                    </span>
                  )}
                  <span className="k-data-single-title">
                    {singleColumn.title(row)}
                  </span>
                  {singleColumn.trailing && (
                    <span className="k-data-single-trailing">
                      {singleColumn.trailing(row)}
                    </span>
                  )}
                </>
              );
              return (
                <button
                  type="button"
                  className="k-data-single-row"
                  aria-label={singleColumn.ariaLabel(row)}
                  onClick={() => singleColumn.onActivate(row)}
                >
                  {content}
                </button>
              );
            },
          },
        ]
      : columns;
  if (!label.trim() || columns.some((c) => !c.label.trim()))
    throw new Error("KDataTable requires nonempty table and column labels");
  if (
    columns.some((column) => !column.id.trim()) ||
    new Set(columns.map((column) => column.id)).size !== columns.length
  )
    throw new Error("KDataTable column IDs must be nonempty and unique");
  if (
    groupIndent !== undefined &&
    (!Number.isFinite(groupIndent) || groupIndent < 0)
  )
    throw new RangeError(
      "KDataTable groupIndent must be finite and nonnegative",
    );
  const indent = (depth: number) =>
    groupIndent === undefined
      ? `calc(${depth} * var(--k-space-control-inset-inline))`
      : depth * groupIndent;
  if (
    columns.some(
      (c) =>
        c.paddingInline !== undefined &&
        (!Number.isFinite(c.paddingInline) || c.paddingInline < 0),
    )
  )
    throw new RangeError(
      "KDataTable paddingInline must be finite and nonnegative",
    );
  tableWidths(columns, 0);
  const model = useMemo(
    () =>
      externalWindow
        ? { count: 0, nodes: [] }
        : (() => {
            const ids = new Set(draftRows.map((d) => rowId(d.row)));
            if (
              ids.size !== draftRows.length ||
              [...ids].some((id) => !id.trim())
            )
              throw new Error("Draft row IDs must be unique and nonempty");
            const base = dataTableModel({
              rows: rows.filter((r) => !ids.has(rowId(r))),
              columns,
              rowId,
              filter,
              groups,
              sort,
            });
            return {
              count: base.count + draftRows.length,
              nodes: insertDataTableDrafts(base.nodes, draftRows),
            };
          })(),
    [rows, columns, rowId, filter, groups, sort, externalWindow, draftRows],
  );
  if (externalWindow && !viewport)
    throw new Error("KDataTable externalWindow requires viewport");
  if (viewport)
    return (
      <KStack align="stretch" gap="section">
        {toolbar}
        <KVirtualDataTable
          draftRows={draftRows}
          label={label}
          columns={displayColumns}
          displayMode={displayMode}
          rowId={rowId}
          model={model}
          localGroupDepth={groups?.length ?? 0}
          viewport={viewport}
          externalWindow={externalWindow}
          queryRevision={queryRevision}
          onRangeRequest={onRangeRequest}
          loading={loading}
          error={error}
          empty={empty}
          renderFooter={renderFooter}
          collapsedGroups={collapsedGroups}
          onCollapsedGroupsChange={onCollapsedGroupsChange}
          groupIndent={groupIndent}
          showRowDividers={showRowDividers}
          activeCell={displayMode === "singleColumn" ? null : activeCell}
          onBeforeActiveCellExit={onBeforeActiveCellExit}
          focusCell={displayMode === "singleColumn" ? null : focusCell}
        />
      </KStack>
    );
  const tableColumns: KTableColumn[] = displayColumns.map((column) => ({
    id: column.id,
    width: column.width,
    minWidth: column.minWidth,
    flex: column.flex,
    align: column.align,
    paddingInline: column.paddingInline,
    header: column.label,
    headerLabel: column.label,
  }));
  const render = (
    nodes: DataTableNode<T>[],
    depth: number,
    path: KDataTableGroupValue[],
  ): ReactNode =>
    nodes.map((node) => {
      if (node.kind === "rows")
        return (
          <div
            key="rows"
            style={{ paddingInlineStart: indent(depth), minWidth: 0 }}
          >
            <KStack align="stretch" gap="control">
              <KTable
                label={[label, ...path.map((group) => group.label)].join(" / ")}
                columns={tableColumns}
                showHeader={false}
                data-display-mode={displayMode}
                showRowDividers={showRowDividers}
                rows={node.rows.map((row) => ({
                  id: rowId(row),
                  cells: displayColumns.map((column) => column.cell(row)),
                }))}
              />
              {renderFooter?.({ path, rows: node.rows })}
            </KStack>
          </div>
        );
      const collapsed =
        collapsedGroups.has(node.key) &&
        !draftRows.some(
          (d) =>
            JSON.stringify(
              d.originPath.slice(0, depth + 1).map((g) => [g.id, g.value]),
            ) === node.key,
        );
      const title = `${node.label} (${node.count})`;
      return (
        <KStack key={node.key} align="stretch" gap="control">
          <div
            style={{
              paddingInlineStart: indent(depth),
            }}
          >
            {onCollapsedGroupsChange ? (
              <KButton
                variant="ghost"
                aria-expanded={!collapsed}
                onClick={() => {
                  if (
                    !collapsed &&
                    draftRows.some(
                      (d) =>
                        JSON.stringify(
                          d.originPath
                            .slice(0, depth + 1)
                            .map((g) => [g.id, g.value]),
                        ) === node.key,
                    )
                  )
                    return;
                  const next = new Set(collapsedGroups);
                  if (collapsed) next.delete(node.key);
                  else next.add(node.key);
                  onCollapsedGroupsChange(next);
                }}
              >
                <span
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "var(--k-space-control-gap)",
                  }}
                >
                  <KIcon name={collapsed ? "chevron-right" : "chevron-down"} />
                  <span>{title}</span>
                </span>
              </KButton>
            ) : (
              <span>{title}</span>
            )}
          </div>
          {!collapsed && (
            <KStack align="stretch" gap="section">
              {render(node.children, depth + 1, [
                ...path,
                { id: node.groupId, value: node.value, label: node.label },
              ])}
            </KStack>
          )}
        </KStack>
      );
    });
  return (
    <div ref={contentRoot} style={{ display: "contents" }}>
      <KStack align="stretch" gap="section">
        {toolbar}
        {model.count ? (
          render(model.nodes, 0, [])
        ) : (
          <KStack align="stretch" gap="control">
            {empty}
            {renderFooter?.({ path: [], rows: [] })}
          </KStack>
        )}
      </KStack>
    </div>
  );
}
