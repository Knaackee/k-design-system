import { useCallback, useMemo, useRef, useState } from "react";
import {
  KButton,
  KDataTable,
  KEditableCell,
  KInput,
  KInline,
  KStack,
  KText,
  type KDataTableColumn,
  type KDataTableSort,
  type KDataTableWindow,
  type KDataTableRange,
  type KDataTableCellIdentity,
} from "@k-design-system/ui";
interface Item {
  id: string;
  title: string;
  team: string;
}
const seed = Array.from({ length: 240 }, (_, index) => ({
  id: `row-${index}`,
  title: `Project ${index + 1}`,
  team: index < 120 ? "Web" : "Mobile",
}));
const rowId = (row: Item) => row.id;
const groups = [{ id: "team", value: (row: Item) => row.team }];
export function DataTableVirtualFixture({
  external = false,
  showHeader = false,
}: {
  external?: boolean;
  showHeader?: boolean;
}) {
  const [rows, setRows] = useState(seed);
  const [sort, setSort] = useState<KDataTableSort | null>(null);
  const [active, setActive] = useState<KDataTableCellIdentity | null>(null);
  const [draft, setDraft] = useState("");
  const editSession = useRef<{ rowId: string; draft: string } | null>(null);
  const [focusCell, setFocusCell] = useState<KDataTableCellIdentity | null>(
    null,
  );
  const [collapsed, setCollapsed] = useState(new Set<string>());
  const [message, setMessage] = useState("");
  const [revision, setRevision] = useState("query-1");
  const [window, setWindow] = useState<KDataTableWindow<Item>>({
    queryRevision: "query-1",
    totalCount: 240,
    startIndex: 0,
    entries: [],
  });
  const [error, setError] = useState(false);
  const [hold, setHold] = useState(false);
  const pending = useRef<KDataTableRange | null>(null);
  const load = useCallback((range: KDataTableRange) => {
    setWindow({
      queryRevision: range.queryRevision,
      totalCount: 240,
      startIndex: range.startIndex,
      entries: seed.slice(range.startIndex, range.endIndex).map((row) => ({
        kind: "item",
        id: `item:${row.id}`,
        row,
        depth: 0,
        path: [],
      })),
    });
  }, []);
  const request = useCallback(
    (range: KDataTableRange) => {
      pending.current = range;
      if (!hold) load(range);
    },
    [hold, load],
  );
  const commit = () => {
    const session = editSession.current;
    if (!session) return true;
    if (!session.draft.trim()) {
      setMessage("Title is required");
      return false;
    }
    // Enter, focus transfer and scrolling can all end the same edit. Claim it
    // synchronously before React updates so a later blur cannot commit again.
    editSession.current = null;
    setRows((previous) =>
      previous.map((row) =>
        row.id === session.rowId ? { ...row, title: session.draft } : row,
      ),
    );
    setMessage(`Saved ${session.draft}`);
    setActive(null);
    return true;
  };
  const columns: KDataTableColumn<Item>[] = [
    {
      id: "title",
      label: "Project",
      headerContentInset: "var(--k-space-control-inset-inline)",
      compare: (a, b) =>
        a.title.localeCompare(b.title, "en", { numeric: true }),
      minWidth: 240,
      cell: (row) => (
        <KEditableCell
          label={`Edit ${row.id}`}
          display={row.title}
          editing={active?.rowId === row.id}
          onEdit={() => {
            editSession.current = { rowId: row.id, draft: row.title };
            setActive({ rowId: row.id, columnId: "title" });
            setDraft(row.title);
          }}
          editor={
            <KInput
              aria-label={`Title ${row.id}`}
              aria-invalid={!draft.trim()}
              autoFocus
              value={draft}
              onChange={(event) => {
                if (editSession.current)
                  editSession.current.draft = event.target.value;
                setDraft(event.target.value);
              }}
              onBlur={commit}
              onKeyDown={(event) => {
                if (event.nativeEvent.isComposing) return;
                if (event.key === "Enter" || event.key === "Escape")
                  event.preventDefault();
                if (event.key === "Enter") commit();
                if (event.key === "Escape") {
                  editSession.current = null;
                  setActive(null);
                  setMessage("Cancelled");
                }
              }}
            />
          }
        />
      ),
    },
    { id: "team", label: "Team", width: 160, cell: (row) => row.team },
    ...Array.from({ length: 8 }, (_, index) => ({
      id: `detail-${index}`,
      label: `Detail ${index + 1}`,
      width: 120,
      cell: (row: Item) => `${row.id} / ${index + 1}`,
    })),
  ];
  // Draft and active identity live outside the recycled cells.
  const externalColumns = useMemo<KDataTableColumn<Item>[]>(
    () => [
      {
        id: "title",
        label: "Project",
        minWidth: 240,
        cell: (row) => row.title,
      },
      { id: "team", label: "Team", width: 160, cell: (row) => row.team },
    ],
    [],
  );
  return (
    <KStack
      align="stretch"
      gap="section"
      style={{ width: "100%", minWidth: 0 }}
    >
      <KInline gap="control" wrap>
        {!external && (
          <KButton
            onClick={() =>
              setFocusCell({ rowId: "row-200", columnId: "title" })
            }
          >
            Focus project 201
          </KButton>
        )}
        {external && (
          <>
            <KButton
              onClick={() => {
                setHold(true);
                setRevision((previous) =>
                  previous === "query-1" ? "query-2" : "query-1",
                );
              }}
            >
              Change query
            </KButton>
            <KButton
              onClick={() => {
                if (pending.current) load(pending.current);
                setHold(false);
                setError(false);
              }}
            >
              Load requested range
            </KButton>
            <KButton
              onClick={() =>
                setWindow({
                  queryRevision: "obsolete",
                  totalCount: 1,
                  startIndex: 0,
                  entries: [
                    {
                      kind: "item",
                      id: "stale",
                      depth: 0,
                      path: [],
                      row: { id: "stale", title: "STALE RESULT", team: "Old" },
                    },
                  ],
                })
              }
            >
              Deliver stale response
            </KButton>
            <KButton onClick={() => setError(true)}>Simulate error</KButton>
          </>
        )}
      </KInline>
      <KDataTable
        showHeader={showHeader}
        sort={sort}
        onSortChange={external ? undefined : setSort}
        label={external ? "External projects" : "Virtual projects"}
        rows={external ? [] : rows}
        rowId={rowId}
        columns={external ? externalColumns : columns}
        empty={<span>No projects</span>}
        viewport={{ height: 320, overscan: 2 }}
        groups={external ? undefined : groups}
        collapsedGroups={collapsed}
        onCollapsedGroupsChange={setCollapsed}
        renderFooter={
          external
            ? undefined
            : (section) => (
                <KButton
                  variant="ghost"
                  onClick={() =>
                    setMessage(`Add to ${section.path.at(-1)?.label ?? "root"}`)
                  }
                >
                  Add project to {section.path.at(-1)?.label}
                </KButton>
              )
        }
        activeCell={active}
        onBeforeActiveCellExit={commit}
        focusCell={focusCell}
        externalWindow={external ? window : undefined}
        queryRevision={external ? revision : undefined}
        onRangeRequest={external ? request : undefined}
        loading={<span>Loading projects</span>}
        error={
          error ? <span role="alert">Could not load projects</span> : undefined
        }
      />
      <KText as="span" role="status">
        {message ||
          (external
            ? `Query ${revision}`
            : "240 projects; drafts stay outside cells")}
      </KText>
    </KStack>
  );
}
