import { useState } from "react";
import {
  KIcon,
  KIconButton,
  KKanban,
  type KKanbanColumn,
  type KKanbanMove,
} from "@k-design-system/ui";

type DemoCard = {
  id: string;
  title: string;
  priority: string;
  project: string;
  tag?: string;
};

const initialColumns: KKanbanColumn<DemoCard>[] = [
  {
    id: "backlog",
    title: "Backlog",
    leading: <KIcon name="circle-alert" size={16} />,
    addLabel: "+ Add issue",
    items: [
      {
        id: "ISS-311",
        title: "Unify navigation patterns",
        priority: "Medium",
        project: "Orbit",
      },
      {
        id: "ISS-326",
        title: "Improve sign-in feedback",
        priority: "Low",
        project: "Orbit",
      },
      {
        id: "ISS-343",
        title: "Plan browser extension",
        priority: "Medium",
        project: "Workspace",
        tag: "Research",
      },
    ],
  },
  {
    id: "todo",
    title: "To do",
    leading: <KIcon name="circle-check" size={16} />,
    addLabel: "+ Add issue",
    items: [
      {
        id: "ISS-389",
        title: "Refresh repository list",
        priority: "High",
        project: "Orbit",
      },
      {
        id: "ISS-390",
        title: "Add nested context menus",
        priority: "Medium",
        project: "Web",
      },
    ],
  },
  {
    id: "progress",
    title: "In progress",
    leading: <KIcon name="clock" size={16} />,
    addLabel: "+ Add issue",
    items: [
      {
        id: "ISS-354",
        title: "Refine project dialog",
        priority: "Medium",
        project: "Orbit",
        tag: "Question",
      },
      {
        id: "ISS-360",
        title: "Polish Markdown rendering",
        priority: "Medium",
        project: "Editor",
        tag: "Review",
      },
    ],
  },
  {
    id: "blocked",
    title: "Blocked",
    leading: <KIcon name="triangle-alert" size={16} />,
    addLabel: "+ Add issue",
    items: [
      {
        id: "ISS-334",
        title: "Align mobile bottom sheet",
        priority: "Urgent",
        project: "Mobile",
      },
    ],
  },
];

function applyMove(
  columns: readonly KKanbanColumn<DemoCard>[],
  move: KKanbanMove<DemoCard>,
) {
  const next = columns.map((column) => ({
    ...column,
    items: [...column.items],
  }));
  const source = next.find((column) => column.id === move.sourceColumnId)!;
  const target = next.find((column) => column.id === move.targetColumnId)!;
  source.items.splice(move.sourceIndex, 1);
  target.items.splice(move.targetIndex, 0, move.item);
  return next;
}

export function KanbanFixture({ selection = false }: { selection?: boolean }) {
  const [columns, setColumns] = useState(initialColumns);
  const [selected, setSelected] = useState<string[]>(
    selection ? ["ISS-326"] : [],
  );
  const [message, setMessage] = useState("Drag a card or open it");

  return (
    <div className="k-kanban-fixture" style={{ minHeight: 620 }}>
      <KKanban
        columns={columns}
        getItemId={(item) => item.id}
        getItemLabel={(item) => item.title}
        selectedItemIds={selected}
        onSelectionChange={setSelected}
        onCardOpen={(item) => setMessage(`Opened ${item.id}`)}
        onAddCard={(columnId) => setMessage(`Add requested for ${columnId}`)}
        onCardMove={(move) => {
          setColumns((current) => applyMove(current, move));
          setMessage(`${move.itemId} moved to ${move.targetColumnId}`);
        }}
        renderCard={({ item, selected: isSelected, toggleSelected }) => (
          <div style={{ display: "grid", gap: 10 }}>
            <div style={{ display: "flex", alignItems: "flex-start", gap: 8 }}>
              <input
                type="checkbox"
                checked={isSelected}
                aria-label={`Select ${item.title}`}
                onChange={toggleSelected}
              />
              <strong style={{ flex: 1, lineHeight: 1.35 }}>
                {item.title}
              </strong>
              <KIconButton
                icon="ellipsis"
                label={`Actions for ${item.title}`}
                onClick={() => setMessage(`Actions requested for ${item.id}`)}
              />
            </div>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                flexWrap: "wrap",
                gap: 8,
                color: "var(--k-color-text-muted)",
                fontSize: "var(--k-font-body-small-size)",
              }}
            >
              <span>{item.id}</span>
              <span>{item.priority}</span>
              {item.tag && <span>{item.tag}</span>}
              <span
                style={{ display: "inline-flex", alignItems: "center", gap: 4 }}
              >
                <KIcon name="folder" size={14} /> {item.project}
              </span>
            </div>
          </div>
        )}
      />
      <p
        role="status"
        style={{ paddingInline: "var(--k-space-layout-gutter)" }}
      >
        {message}
      </p>
    </div>
  );
}
