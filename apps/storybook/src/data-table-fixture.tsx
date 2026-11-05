import { useEffect, useRef, useState } from "react";
import { TitleCell } from "./data-table-title-cell.js";
import { BudgetCell } from "./data-table-budget-cell.js";
import {
  KDataTableDraftController,
  KDataTableDraftInteraction,
  KCheckbox,
  KInline,
  KContainer,
  KStack,
  KText,
  KIconButton,
  KButton,
  KIcon,
  KDataTable,
  KSelect,
  KSearchField,
  KFilterBar,
  KMenuButton,
  type KDataTableColumn,
  type KDataTableSort,
  type KDataTableSection,
} from "@k-design-system/ui";

import {
  projects,
  statuses,
  statusLabel,
  type Project,
} from "./data-table-project-data.js";

export function DataTableFixture({
  grouped = false,
  showHeader = false,
  singleColumn = false,
  addLabel = "Add project",
  createProject,
  initialEditColumn = "project",
  allowCreate = true,
  saveDelay = 0,
  failSave = false,
  saveLabel = "Save",
  cancelLabel = "Cancel",
}: {
  grouped?: boolean;
  showHeader?: boolean;
  singleColumn?: boolean;
  addLabel?: string;
  createProject?: (section: KDataTableSection<Project>) => Omit<Project, "id">;
  initialEditColumn?: string;
  allowCreate?: boolean;
  saveDelay?: number;
  failSave?: boolean;
  saveLabel?: string;
  cancelLabel?: string;
}) {
  const [rows, setRows] = useState(projects);
  const nextId = useRef(1);
  const addTrigger = useRef<HTMLButtonElement | null>(null);
  const [initialCell, setInitialCell] = useState<{
    rowId: string;
    columnId: string;
  } | null>(null);
  const [result, setResult] = useState("No action selected");
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("all");
  const [sort, setSort] = useState<KDataTableSort | null>(null);
  const [collapsed, setCollapsed] = useState<ReadonlySet<string>>(new Set());
  const [delayed, setDelayed] = useState(false);
  const [failing, setFailing] = useState(false);
  const policy = useRef({ saveDelay, failSave });
  policy.current = {
    saveDelay: delayed ? 1000 : saveDelay,
    failSave: failing || failSave,
  };
  const [controller] = useState(
    () =>
      new KDataTableDraftController<Project>({
        rowId: (r) => r.id,
        cloneRow: (r) => ({ ...r }),
        isEqual: (a, b) =>
          (Object.keys(a) as (keyof Project)[]).every((k) => a[k] === b[k]),
        onCommit: async (row) => {
          if (policy.current.saveDelay)
            await new Promise((r) => setTimeout(r, policy.current.saveDelay));
          if (policy.current.failSave) throw new Error("Demo save failed");
          return row;
        },
        onEvent: (event) => {
          setResult(`${event.type}: ${event.snapshot.id} (${event.reason})`);
          if (event.type === "committed")
            setRows((previous) => [...previous, event.acceptedRow!]);
          if (event.type === "cancelled" && event.reason === "escape")
            requestAnimationFrame(() => addTrigger.current?.focus());
          if (event.type === "committed" || event.type === "cancelled")
            setInitialCell(null);
        },
      }),
  );
  const [, refresh] = useState(0);
  useEffect(
    () => controller.subscribe(() => refresh((n) => n + 1)),
    [controller],
  );
  const update = (row: Project) => {
    if (controller.get(row.id)) controller.update(row.id, row);
    else
      setRows((previous) =>
        previous.map((item) => (item.id === row.id ? row : item)),
      );
  };
  const columns: KDataTableColumn<Project>[] = [
    {
      id: "icon",
      label: "Type",
      width: 48,
      paddingInline: 0,
      align: "center",
      cell: (row: Project) => (
        <KIconButton
          label={`Open ${row.id}`}
          icon="folder"
          onClick={() => setResult(`Open: ${row.title}`)}
        />
      ),
    },
    {
      id: "project",
      label: "Project",
      headerContentInset: 4,
      minWidth: 240,
      flex: 2,
      paddingInline: 0,
      cell: (row: Project) => (
        <TitleCell
          id={row.id}
          title={row.title}
          initiallyEditing={
            initialCell?.rowId === row.id && initialCell.columnId === "project"
          }
          provisional={!!controller.get(row.id)}
          disabled={controller.get(row.id)?.status === "saving"}
          onChange={(title) => {
            if (controller.get(row.id)) update({ ...row, title });
          }}
          onCancel={() => controller.cancel(row.id, "escape")}
          onCommit={(title, explicit) => {
            update({ ...row, title });
            setInitialCell(null);
            if (explicit && controller.get(row.id))
              void controller.commit(row.id, "enter");
          }}
        />
      ),
      compare: (a, b) => (a.title < b.title ? -1 : a.title > b.title ? 1 : 0),
    },
    {
      id: "status",
      label: "Status",
      headerContentInset:
        "calc(var(--k-space-control-inset-inline) + var(--k-border-width-default))",
      minWidth: 180,
      cell: (row: Project) => (
        <KSelect
          presentation="inline"
          label={`Status for ${row.title}`}
          options={statuses}
          value={row.status}
          disabled={controller.get(row.id)?.status === "saving"}
          onValueChange={(value) => update({ ...row, status: value })}
        />
      ),
    },
    {
      id: "budget",
      label: "Budget",
      headerContentInset: 4,
      width: 168,
      align: "end",
      cell: (row) => (
        <BudgetCell
          id={row.id}
          value={row.budget}
          disabled={controller.get(row.id)?.status === "saving"}
          onCommit={(budget) => update({ ...row, budget })}
        />
      ),
      compare: (a, b) => a.budget - b.budget,
    },
  ];
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Project workspace</KText>
          <KDataTable
            label="Project workspace"
            displayMode={singleColumn ? "singleColumn" : "multiColumn"}
            singleColumn={{
              columnLabel: "Project",
              title: (row) => row.title,
              leading: () => <KIcon name="folder" />,
              trailing: (row) => (
                <>
                  <KIcon
                    name={
                      statuses.find((s) => s.value === row.status)?.icon ??
                      "minus"
                    }
                  />
                  <span>{statusLabel(row.status)}</span>
                </>
              ),
              ariaLabel: (row) => `Open ${row.title}`,
              onActivate: (row) => setResult(`Open: ${row.title}`),
            }}
            focusCell={initialCell}
            columns={columns.map((column) => ({
              ...column,
              cell: (row: Project) => (
                <KDataTableDraftInteraction
                  controller={controller}
                  rowId={row.id}
                >
                  {column.cell(row)}
                </KDataTableDraftInteraction>
              ),
            }))}
            rows={rows}
            draftRows={controller.drafts.map((d) => ({
              row: d.current,
              originPath: d.originPath,
            }))}
            rowId={(row) => row.id}
            empty={<KText role="status">No matching projects</KText>}
            sort={sort}
            showHeader={showHeader}
            onSortChange={setSort}
            renderFooter={
              !allowCreate
                ? undefined
                : (section) => {
                    const { path } = section;
                    const centeredFirstColumn =
                      !singleColumn &&
                      columns[0]?.align === "center" &&
                      columns[0].width !== undefined;
                    return (
                      <div style={{ width: "100%" }}>
                        <KButton
                          variant="ghost"
                          fullWidth
                          style={
                            centeredFirstColumn
                              ? { paddingInline: 0 }
                              : undefined
                          }
                          aria-label={
                            path.length
                              ? `${addLabel} to ${path.map((group) => group.label).join(" / ")}`
                              : addLabel
                          }
                          onClick={(event) => {
                            if (singleColumn) {
                              setResult(
                                `Add project requested in ${section.path.map((group) => group.label).join(" / ")}`,
                              );
                              return;
                            }
                            addTrigger.current = event.currentTarget;
                            const n = nextId.current++;
                            const row: Project = {
                              id: `new-${n}`,
                              title: "",
                              owner: "You",
                              budget: 0,
                              status:
                                path.find((group) => group.id === "status")
                                  ?.value ??
                                (status === "all" ? "planned" : status),
                              platform:
                                path.find((group) => group.id === "platform")
                                  ?.value ?? "Web",
                            };
                            // These defaults and the initial cell are consumer policy.
                            Object.assign(row, createProject?.(section), {
                              id: `new-${n}`,
                            });
                            controller.begin(row, {
                              originPath: path,
                              initialColumnId: initialEditColumn,
                            });
                            setInitialCell({
                              rowId: row.id,
                              columnId: initialEditColumn,
                            });
                            setResult("New project draft");
                          }}
                        >
                          <span
                            style={{
                              display: centeredFirstColumn
                                ? "inline-grid"
                                : "inline-flex",
                              gridTemplateColumns: centeredFirstColumn
                                ? `${columns[0].width}px auto`
                                : undefined,
                              alignItems: "center",
                              gap: centeredFirstColumn
                                ? undefined
                                : "var(--k-space-control-gap)",
                            }}
                          >
                            <span
                              style={
                                centeredFirstColumn
                                  ? { justifySelf: "center" }
                                  : undefined
                              }
                            >
                              <KIcon name="plus" />
                            </span>
                            <span
                              style={
                                centeredFirstColumn
                                  ? { paddingInlineStart: 4 }
                                  : undefined
                              }
                            >
                              {addLabel}
                            </span>
                          </span>
                        </KButton>
                      </div>
                    );
                  }
            }

            filter={(row) =>
              (status === "all" || row.status === status) &&
              `${row.title} ${row.owner}`
                .toLowerCase()
                .includes(query.toLowerCase())
            }
            groups={
              grouped
                ? [
                    {
                      id: "status",
                      value: (row) => row.status,
                      label: statusLabel,
                    },
                    { id: "platform", value: (row) => row.platform },
                  ]
                : []
            }
            collapsedGroups={collapsed}
            onCollapsedGroupsChange={setCollapsed}
            toolbar={
              <KFilterBar
                label="Project filters"
                resetLabel="Reset all"
                resetEnabled={Boolean(query || status !== "all")}
                onReset={() => {
                  setQuery("");
                  setStatus("all");
                }}
              >
                <div style={{ width: 240, maxWidth: "100%" }}>
                  <KSearchField
                    aria-label="Search projects"
                    placeholder="Search projects"
                    value={query}
                    onChange={(event) => setQuery(event.target.value)}
                    clearable
                    clearLabel="Clear search"
                    onClear={() => setQuery("")}
                  />
                </div>
                <div style={{ width: 180, maxWidth: "100%" }}>
                  <KSelect
                    label="Status filter"
                    value={status}
                    onValueChange={setStatus}
                    options={[
                      { value: "all", label: "All statuses" },
                      ...statuses,
                    ]}
                  />
                </div>
                <KMenuButton
                  label="Sort"
                  actions={[
                    {
                      id: "original",
                      label: "Original order",
                      onSelect: () => setSort(null),
                    },
                    {
                      id: "project-asc",
                      label: "Project ascending",
                      onSelect: () =>
                        setSort({
                          columnId: "project",
                          direction: "ascending",
                        }),
                    },
                    {
                      id: "project-desc",
                      label: "Project descending",
                      onSelect: () =>
                        setSort({
                          columnId: "project",
                          direction: "descending",
                        }),
                    },
                    {
                      id: "budget-asc",
                      label: "Budget ascending",
                      onSelect: () =>
                        setSort({ columnId: "budget", direction: "ascending" }),
                    },
                    {
                      id: "budget-desc",
                      label: "Budget descending",
                      onSelect: () =>
                        setSort({
                          columnId: "budget",
                          direction: "descending",
                        }),
                    },
                  ]}
                />
              </KFilterBar>
            }
          />
          <KInline wrap>
            <KCheckbox
              label="Delay save"
              value={delayed}
              onValueChange={setDelayed}
            />
            <KCheckbox
              label="Fail save"
              value={failing}
              onValueChange={setFailing}
            />
          </KInline>
          {controller.drafts.map((d) => (
            <KDataTableDraftInteraction
              key={d.id}
              controller={controller}
              rowId={d.id}
            >
              <KStack>
                <KText>
                  {d.id}: {d.status}
                </KText>
                <KButton
                  disabled={d.status === "saving"}
                  onClick={() => void controller.commit(d.id, "action")}
                >
                  {saveLabel} {d.id}
                </KButton>
                <KButton
                  disabled={d.status === "saving"}
                  onClick={() => controller.cancel(d.id, "action")}
                >
                  {cancelLabel} {d.id}
                </KButton>
                {d.status === "error" && (
                  <KText role="alert">
                    Save failed. Your changes are retained.
                  </KText>
                )}
              </KStack>
            </KDataTableDraftInteraction>
          ))}
          <KText role="status">{result}</KText>
        </KStack>
      </KContainer>
    </div>
  );
}
