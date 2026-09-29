import { draftWindow } from "./data-table-draft-window.js";
import { TruncatedContent } from "../internal/truncated-content.js";
import { VirtualTableHeader } from "./data-table-virtual-header.js";
import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useId,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  defaultRangeExtractor,
  useVirtualizer,
  type Range,
} from "@tanstack/react-virtual";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { tableWidths } from "./table-layout.js";
import {
  flattenDataTable,
  validateWindow,
  type KDataTableEntry,
  type KDataTableWindow,
} from "./data-table-entries.js";
import type { KDataTableProps } from "./data-table.js";
import type { DataTableNode } from "./data-table-model.js";

const emptyEntries: readonly never[] = [];

type Props<T> = Omit<KDataTableProps<T>, "rows" | "toolbar"> & {
  viewport: NonNullable<KDataTableProps<T>["viewport"]>;
  displayMode?: "multiColumn" | "singleColumn";
  model: { count: number; nodes: DataTableNode<T>[] };
  localGroupDepth: number;
};

/** One shared viewport; all upstream types stay behind the K contract. */
export function KVirtualDataTable<T>(props: Props<T>) {
  const { viewport, columns, rowId, externalWindow, activeCell } = props;
  const tableId = useId();
  for (const value of [
    viewport.height,
    viewport.rowHeight,
    viewport.groupHeight,
    viewport.footerHeight,
  ])
    if (value !== undefined && (!Number.isFinite(value) || value <= 0))
      throw new RangeError(
        "KDataTable viewport extents must be positive and finite",
      );
  if (
    viewport.overscan !== undefined &&
    (!Number.isSafeInteger(viewport.overscan) || viewport.overscan < 0)
  )
    throw new RangeError("KDataTable overscan must be a nonnegative integer");
  if (externalWindow && (!props.queryRevision || !props.onRangeRequest))
    throw new Error(
      "KDataTable external windows require queryRevision and onRangeRequest",
    );
  if (externalWindow) validateWindow(externalWindow);
  const scroll = useRef<HTMLDivElement>(null);
  const probe = useRef<HTMLSpanElement>(null);
  const [geometry, setGeometry] = useState({ width: 0, row: 49, indent: 12 });
  useLayoutEffect(() => {
    const element = scroll.current,
      ruler = probe.current;
    if (!element || !ruler) return;
    const measure = () => {
      const style = getComputedStyle(element);
      const number = (name: string) =>
        parseFloat(style.getPropertyValue(name)) || 0;
      const width = element.clientWidth,
        row = ruler.getBoundingClientRect().height,
        indent = number("--k-space-control-inset-inline");
      setGeometry((previous) =>
        previous.width === width &&
        previous.row === row &&
        previous.indent === indent
          ? previous
          : { width, row, indent },
      );
    };
    measure();
    const resize = new ResizeObserver(measure);
    resize.observe(element);
    resize.observe(ruler);
    return () => resize.disconnect();
  }, []);
  const local = useMemo(
    () =>
      flattenDataTable(
        props.model.nodes,
        rowId,
        new Set(
          [...(props.collapsedGroups ?? new Set())].filter(
            (key) =>
              !props.draftRows?.some((d) =>
                d.originPath.some(
                  (_, i) =>
                    JSON.stringify(
                      d.originPath.slice(0, i + 1).map((g) => [g.id, g.value]),
                    ) === key,
                ),
              ),
          ),
        ),
        !!props.renderFooter,
      ),
    [props.model, rowId, props.collapsedGroups, props.renderFooter],
  );
  // A late response may not overwrite a window accepted for the current query.
  const accepted = useRef<KDataTableWindow<T> | undefined>(undefined);
  if (externalWindow?.queryRevision === props.queryRevision)
    accepted.current = externalWindow;
  const window =
    accepted.current?.queryRevision === props.queryRevision
      ? accepted.current
      : undefined;
  const projection = useMemo(
    () =>
      externalWindow
        ? draftWindow(window, props.draftRows ?? [], props.queryRevision, rowId)
        : undefined,
    [externalWindow, window, props.draftRows, props.queryRevision, rowId],
  );
  const indexed = useMemo(
    () =>
      projection?.indexed ?? local.map((entry, index) => ({ entry, index })),
    [projection, local],
  );
  const entries = useMemo(() => indexed.map((item) => item.entry), [indexed]);
  const count = projection?.count ?? local.length;
  const showHeader = props.showHeader && count > 0;
  const entryAt = projection?.entryAt ?? ((index: number) => local[index]);
  const pinnedIndex = activeCell
    ? (indexed.find(
        ({ entry }) =>
          entry.kind === "item" && rowId(entry.row) === activeCell.rowId,
      )?.index ?? -1)
    : -1;
  const rowExtent = viewport.rowHeight ?? geometry.row;
  const size = (index: number) =>
    entryAt(index)?.kind === "group"
      ? (viewport.groupHeight ?? rowExtent)
      : entryAt(index)?.kind === "footer"
        ? (viewport.footerHeight ?? rowExtent)
        : rowExtent;
  const virtual = useVirtualizer({
    count,
    getScrollElement: () => scroll.current,
    estimateSize: size,
    getItemKey: (index) =>
      entryAt(index)?.id ?? `unloaded:${props.queryRevision}:${index}`,
    overscan: viewport.overscan ?? 2,
    rangeExtractor: useCallback(
      (range: Range) => {
        const indices = defaultRangeExtractor(range);
        if (pinnedIndex >= 0 && !indices.includes(pinnedIndex))
          indices.push(pinnedIndex);
        return indices.sort((a, b) => a - b);
      },
      [pinnedIndex],
    ),
  });
  useLayoutEffect(
    () => virtual.measure(),
    [virtual, rowExtent, viewport.groupHeight, viewport.footerHeight, entries],
  );
  const requested = useRef("");
  const visible = virtual.getVirtualItems();
  const first = virtual.range?.startIndex ?? 0;
  const last =
    virtual.range?.endIndex ??
    Math.min(count - 1, Math.ceil(viewport.height / rowExtent));
  useEffect(() => {
    if (!externalWindow || !props.onRangeRequest || !props.queryRevision)
      return;
    // Do not request a replacement window until the active edit has committed.
    if (pinnedIndex >= 0 && (pinnedIndex < first || pinnedIndex > last)) return;
    const start = Math.max(0, first - (viewport.overscan ?? 2));
    const end = count
      ? Math.min(count, last + 1 + (viewport.overscan ?? 2))
      : Math.ceil(viewport.height / rowExtent) + (viewport.overscan ?? 2);
    const key = `${props.queryRevision}:${start}:${end}`;
    if (key === requested.current) return;
    requested.current = key;
    props.onRangeRequest({
      queryRevision: props.queryRevision,
      startIndex: projection?.toServer(start) ?? start,
      endIndex: projection?.toServer(end) ?? end,
    });
  }, [
    externalWindow,
    props.onRangeRequest,
    props.queryRevision,
    first,
    last,
    count,
    viewport.height,
    viewport.overscan,
    rowExtent,
    pinnedIndex,
  ]);
  const previousRevision = useRef(props.queryRevision);
  useLayoutEffect(() => {
    if (previousRevision.current !== props.queryRevision) {
      previousRevision.current = props.queryRevision;
      requested.current = "";
      virtual.scrollToOffset(0);
    }
  }, [props.queryRevision, virtual]);
  const exitAttempt = useRef("");
  useLayoutEffect(() => {
    if (pinnedIndex < 0 || (pinnedIndex >= first && pinnedIndex <= last)) {
      exitAttempt.current = "";
      return;
    }
    const key = `${activeCell?.rowId}:${first}:${last}`;
    if (exitAttempt.current === key) return;
    exitAttempt.current = key;
    if (!props.onBeforeActiveCellExit || !props.onBeforeActiveCellExit())
      virtual.scrollToIndex(pinnedIndex, { align: "auto" });
    else scroll.current?.focus({ preventScroll: true });
  }, [
    pinnedIndex,
    first,
    last,
    props.onBeforeActiveCellExit,
    activeCell?.rowId,
    virtual,
  ]);
  const indent = props.groupIndent ?? geometry.indent;
  const maxDepth =
    viewport.maxGroupDepth ?? (externalWindow ? 0 : props.localGroupDepth);
  if (
    !Number.isSafeInteger(maxDepth) ||
    maxDepth < 0 ||
    entries.some((entry) => entry.depth > maxDepth)
  )
    throw new RangeError(
      "KDataTable maxGroupDepth must cover all entry depths",
    );
  const minimum = tableWidths(columns, 0).reduce((a, b) => a + b, 0);
  const width = Math.max(geometry.width, minimum + maxDepth * indent);
  const [horizontal, setHorizontal] = useState(0);
  const [headerOffset, setHeaderOffset] = useState(0);
  useEffect(() => {
    const target = props.focusCell;
    if (!target || !scroll.current) return;
    const index = entries.findIndex(
      (entry) => entry.kind === "item" && rowId(entry.row) === target.rowId,
    );
    const column = columns.findIndex((column) => column.id === target.columnId);
    if (index < 0 || column < 0) return;
    virtual.scrollToIndex(indexed[index].index, { align: "auto" });
    const tracks = tableWidths(columns, width - maxDepth * indent);
    const x =
      maxDepth * indent +
      tracks.slice(0, column).reduce((sum, value) => sum + value, 0);
    if (
      x < scroll.current.scrollLeft ||
      x + tracks[column] > scroll.current.scrollLeft + geometry.width
    )
      scroll.current.scrollLeft = x;
    let frame = 0;
    frame = requestAnimationFrame(() => {
      frame = requestAnimationFrame(() => {
        const cell = [
          ...(scroll.current?.querySelectorAll<HTMLElement>(
            "[data-cell-column]",
          ) ?? []),
        ].find(
          (node) =>
            node.dataset.cellColumn === target.columnId &&
            node.dataset.cellRow === target.rowId,
        );
        const control = cell?.querySelector<HTMLElement>(
          'button:not(:disabled),input:not(:disabled),[tabindex="0"]',
        );
        (control ?? cell)?.focus();
      });
    });
    return () => cancelAnimationFrame(frame);
    // A new identity object is an explicit focus request, not a persistent lock.
  }, [props.focusCell]);
  const renderEntry = (entry: KDataTableEntry<T>) => {
    if (entry.kind === "footer")
      return props.renderFooter?.({ path: entry.path, rows: entry.rows });
    if (entry.kind === "group") {
      const collapsed =
        (props.collapsedGroups?.has(entry.groupKey) ?? false) &&
        !props.draftRows?.some((d) =>
          d.originPath.some(
            (_, i) =>
              JSON.stringify(
                d.originPath.slice(0, i + 1).map((g) => [g.id, g.value]),
              ) === entry.groupKey,
          ),
        );
      const title = `${entry.label} (${entry.count})`;
      if (!props.onCollapsedGroupsChange) return title;
      return (
        <KButton
          variant="ghost"
          aria-expanded={!collapsed}
          onClick={() => {
            const active = entries.find(
              (item) =>
                item.kind === "item" &&
                activeCell &&
                rowId(item.row) === activeCell.rowId,
            );
            const contains =
              active &&
              entry.path.every(
                (group, index) =>
                  active.path[index]?.id === group.id &&
                  active.path[index]?.value === group.value,
              );
            if (
              !collapsed &&
              contains &&
              (!props.onBeforeActiveCellExit || !props.onBeforeActiveCellExit())
            )
              return;
            if (
              !collapsed &&
              props.draftRows?.some((d) =>
                d.originPath.some(
                  (_, i) =>
                    JSON.stringify(
                      d.originPath.slice(0, i + 1).map((g) => [g.id, g.value]),
                    ) === entry.groupKey,
                ),
              )
            )
              return;
            const next = new Set(props.collapsedGroups);
            if (collapsed) next.delete(entry.groupKey);
            else next.add(entry.groupKey);
            props.onCollapsedGroupsChange?.(next);
          }}
        >
          <span className="k-virtual-group-label">
            <KIcon name={collapsed ? "chevron-right" : "chevron-down"} />
            <span>{title}</span>
          </span>
        </KButton>
      );
    }
    const widths = tableWidths(columns, width - maxDepth * indent);
    let left = maxDepth * indent;
    return columns.map((column, index) => {
      const x = left;
      left += widths[index];
      // Horizontal culling is computed against each depth's exact track layout.
      if (
        (x + widths[index] < horizontal || x > horizontal + geometry.width) &&
        !(
          activeCell?.rowId === rowId(entry.row) &&
          activeCell.columnId === column.id
        )
      )
        return null;
      return (
        <div
          role="cell"
          key={column.id}
          aria-colindex={index + 1}
          aria-describedby={`${tableId}-column-${index}`}
          data-cell-column={column.id}
          data-cell-row={rowId(entry.row)}
          tabIndex={-1}
          className="k-virtual-cell"
          data-overflow={column.overflow ?? "ellipsis"}
          style={{
            insetInlineStart: x,
            width: widths[index],
            textAlign: column.align ?? "start",
            paddingInline: column.paddingInline,
          }}
        >
          <div className="k-virtual-cell-content">
            {column.overflow === "visible" ? (
              column.cell(entry.row)
            ) : (
              <TruncatedContent>{column.cell(entry.row)}</TruncatedContent>
            )}
          </div>
        </div>
      );
    });
  };
  return (
    <div
      style={{ width: "100%", minWidth: 0 }}
      role="table"
      aria-label={props.label}
      aria-rowcount={count + (showHeader ? 1 : 0)}
      aria-colcount={columns.length}
      aria-busy={!!externalWindow && !window}
    >
      {props.error}
      {!externalWindow && props.model.count === 0 ? props.empty : null}
      {showHeader ? (
        <VirtualTableHeader
          table={{ ...props, rows: [] }}
          width={width}
          gutter={maxDepth * indent}
          offset={headerOffset}
          tableId={tableId}
        />
      ) : null}
      <div
        ref={scroll}
        className="k-virtual-table k-table"
        data-display-mode={props.displayMode}
        data-row-dividers={props.showRowDividers ?? false}
        style={{ height: viewport.height }}
        tabIndex={0}
        onScroll={(event) => {
          setHorizontal(Math.abs(event.currentTarget.scrollLeft));
          setHeaderOffset(event.currentTarget.scrollLeft);
        }}
      >
        {!showHeader ? (
          <span className="k-table-hidden-header">
            {columns.map((column, index) => (
              <span key={column.id} id={`${tableId}-column-${index}`}>
                {column.label}
              </span>
            ))}
          </span>
        ) : null}
        <span ref={probe} className="k-virtual-row-ruler" aria-hidden="true" />
        <div
          role="rowgroup"
          style={{
            height: virtual.getTotalSize(),
            width,
            position: "relative",
          }}
        >
          {visible.map((item) => {
            const entry = entryAt(item.index);
            return (
              <div
                key={item.key}
                role="row"
                aria-rowindex={item.index + (showHeader ? 2 : 1)}
                data-entry-id={entry?.id}
                data-entry-kind={entry?.kind ?? "placeholder"}
                className="k-virtual-row"
                style={{ top: item.start, height: item.size, width }}
              >
                {entry?.kind === "item" ? (
                  renderEntry(entry)
                ) : (
                  <div
                    role="cell"
                    aria-colspan={columns.length}
                    className="k-virtual-spanning-cell"
                    style={{ paddingInlineStart: (entry?.depth ?? 0) * indent }}
                  >
                    {entry ? (
                      renderEntry(entry)
                    ) : (
                      <span
                        className="k-virtual-placeholder"
                        aria-hidden="true"
                      />
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
        {externalWindow && !window
          ? props.loading
          : externalWindow && count === 0
            ? props.empty
            : null}
      </div>
    </div>
  );
}
