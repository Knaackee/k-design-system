import { useState } from "react";
import {
  KAlertDialog,
  KButton,
  KDialog,
  KField,
  KIcon,
  KIconButton,
  KInline,
  KInput,
  KSelect,
  KSortableTree,
  KStack,
  KText,
  KToast,
  KToastViewport,
  moveKSortableTree,
  type KSortableTreeNode,
  type KSortableTreeMove,
} from "@k-design-system/ui";
import "./sortable-tree-fixture.css";

type Offer = { kind: "service" | "product"; detail: string };
type Node = KSortableTreeNode<Offer>;
type Structure = "category" | "kind" | "flat";
const offers: Node[] = [
  {
    id: "cut",
    label: "Haarschnitt",
    data: { kind: "service", detail: "45 Min. · 48 €" },
  },
  {
    id: "styling",
    label: "Styling",
    data: { kind: "service", detail: "30 Min. · 32 €" },
  },
  {
    id: "color",
    label: "Farbe & Pflege",
    data: { kind: "service", detail: "90 Min. · ab 85 €" },
  },
  {
    id: "shampoo",
    label: "Pflegeshampoo",
    data: { kind: "product", detail: "250 ml · 18 €" },
  },
  {
    id: "conditioner",
    label: "Conditioner",
    data: { kind: "product", detail: "200 ml · 22 €" },
  },
];
function leaves(nodes: readonly Node[]): Node[] {
  return nodes.flatMap((node) =>
    node.children ? leaves(node.children) : [node],
  );
}
function structure(items: Node[], mode: Structure): Node[] {
  if (mode === "flat") return items;
  if (mode === "kind")
    return [
      {
        id: "services",
        label: "Dienstleistungen",
        children: items.filter((n) => n.data?.kind !== "product"),
      },
      {
        id: "products",
        label: "Produkte",
        children: items.filter((n) => n.data?.kind === "product"),
      },
    ];
  return [
    {
      id: "hair",
      label: "Schnitt & Styling",
      children: items.filter((n) => n.id === "cut" || n.id === "styling"),
    },
    {
      id: "care",
      label: "Farbe & Pflege",
      children: items.filter((n) => n.id !== "cut" && n.id !== "styling"),
    },
    { id: "new", label: "Neue Kategorie", children: [] },
  ];
}
function replace(nodes: readonly Node[], item: Node): Node[] {
  return nodes.map((node) =>
    node.id === item.id
      ? item
      : node.children
        ? { ...node, children: replace(node.children, item) }
        : node,
  );
}
function find(nodes: readonly Node[], id: string): Node | undefined {
  for (const node of nodes) {
    if (node.id === id) return node;
    const child = node.children && find(node.children, id);
    if (child) return child;
  }
}
const labels = {
  drag: "Verschieben",
  expand: "Aufklappen",
  collapse: "Zuklappen",
  move: "Reihenfolge ändern",
  up: "Nach oben",
  down: "Nach unten",
  indent: "Einrücken",
  outdent: "Ausrücken",
  moveTo: "Verschieben",
  root: "Ohne Kategorie",
  drop: "Hier ablegen",
  empty: "Noch keine Einträge",
  moved: (label: string) => `${label} verschoben`,
};

export function SortableTreeFixture({
  initial = "category",
  deep = false,
  mobile = false,
  empty = false,
  ungrouped = false,
}: {
  initial?: Structure;
  deep?: boolean;
  mobile?: boolean;
  empty?: boolean;
  ungrouped?: boolean;
}) {
  const [nodes, setNodes] = useState<Node[]>(() =>
    empty
      ? []
      : deep
        ? [
            {
              id: "catalog",
              label: "Mein Angebot",
              children: [
                {
                  id: "beauty",
                  label: "Beauty & Pflege",
                  children: structure(offers, "category"),
                },
              ],
            },
          ]
        : ungrouped
          ? [
              ...structure(
                offers.filter((node) => node.data?.kind !== "product"),
                initial,
              ),
              ...offers.filter((node) => node.data?.kind === "product"),
            ]
          : structure(offers, initial),
  );
  const [mode, setMode] = useState<Structure>(initial);
  const [previous, setPrevious] = useState<{
    nodes: Node[];
    mode: Structure;
    expanded: readonly string[];
  }>();
  const [expanded, setExpanded] = useState<readonly string[]>([
    "hair",
    "care",
    "new",
    "services",
    "products",
    "catalog",
    "beauty",
  ]);
  const [editor, setEditor] = useState<{
    node: Node;
    parentId?: string;
    fresh?: boolean;
  }>();
  const [removing, setRemoving] = useState<Node>();
  const [toast, setToast] = useState<{ message: string; key: number }>();
  const [name, setName] = useState("");
  const [event, setEvent] = useState("Bereit zum Sortieren");
  function change(next: Node[], message: string, nextMode = mode) {
    setPrevious({ nodes, mode, expanded });
    setNodes(next);
    setMode(nextMode);
    setEvent(message);
    setToast({ message, key: Date.now() });
  }
  function onMove(move: KSortableTreeMove) {
    const next = moveKSortableTree(nodes, move, {
      maxDepth: deep ? undefined : 1,
    });
    if (next !== nodes)
      change(
        [...next],
        `„${find(nodes, move.id)?.label}“ ${move.parentId ? `in „${find(nodes, move.parentId)?.label}“ einsortiert` : "umsortiert"}`,
      );
  }
  function edit(node: Node, fresh = false, parentId?: string) {
    setName(node.label);
    setEditor({ node, fresh, parentId });
  }
  function save() {
    if (!editor || !name.trim()) return;
    const item = { ...editor.node, label: name.trim() };
    let next = replace(nodes, item);
    if (editor.fresh) {
      next = [...nodes, item];
      if (editor.parentId)
        next = [
          ...moveKSortableTree(next, {
            id: item.id,
            parentId: editor.parentId,
            index: find(nodes, editor.parentId)?.children?.length ?? 0,
          }),
        ];
    }
    change(
      next,
      `${item.children ? "Kategorie" : item.data?.kind === "product" ? "Produkt" : "Leistung"} „${item.label}“ ${editor.fresh ? "hinzugefügt" : "umbenannt"}`,
    );
    setEditor(undefined);
  }
  function undo() {
    if (!previous) return;
    setNodes(previous.nodes);
    setMode(previous.mode);
    setExpanded(previous.expanded);
    setPrevious(undefined);
    setToast(undefined);
    setEvent("Änderung rückgängig gemacht");
  }
  function removeNode(items: readonly Node[], id: string): Node[] {
    return items
      .filter((node) => node.id !== id)
      .map((node) =>
        node.children
          ? { ...node, children: removeNode(node.children, id) }
          : node,
      );
  }
  const fresh = (group: boolean, parentId?: string) =>
    edit(
      {
        id: crypto.randomUUID(),
        label: "",
        ...(group
          ? { children: [] }
          : { data: { kind: "service" as const, detail: "Dienstleistung" } }),
      },
      true,
      parentId,
    );
  return (
    <section
      className={`sortable-tree-fixture${mobile ? " sortable-tree-fixture--mobile" : ""}`}
    >
      <KStack gap="control" align="stretch">
        <KStack gap="control" align="stretch">
          <KText variant="heading3">Angebote ordnen</KText>
          <KText variant="bodySmall">
            Ziehe am Griff, um deine Angebote zu ordnen.
          </KText>
        </KStack>
        <KInline gap="control" wrap align="center">
          {!deep && (
            <div className="sortable-tree-fixture__select">
              <KSelect
                label="Anordnung"
                value={mode}
                onValueChange={(value) => {
                  const nextMode = value as Structure;
                  change(
                    structure(leaves(nodes), nextMode),
                    "Anordnung geändert",
                    nextMode,
                  );
                  setExpanded(["hair", "care", "new", "services", "products"]);
                }}
                options={[
                  { value: "category", label: "Nach Themen", icon: "folders" },
                  {
                    value: "kind",
                    label: "Leistungen & Produkte",
                    icon: "list-tree",
                  },
                  { value: "flat", label: "Ohne Kategorien", icon: "list" },
                ]}
              />
            </div>
          )}
          <KIconButton
            icon="undo-2"
            strokeWidth={1.5}
            label="Rückgängig"
            disabled={!previous}
            onClick={undo}
          />
        </KInline>
        <KSortableTree
          nodes={nodes}
          minRowHeight={96}
          ungroupedLabel={mode === "flat" ? undefined : "Ohne Kategorie"}
          defaultUngroupedExpanded={!ungrouped}
          onMove={onMove}
          expandedIds={expanded}
          onExpandedChange={setExpanded}
          maxDepth={deep ? undefined : 1}
          canMove={(move) =>
            deep || !find(nodes, move.id)?.children || move.parentId === null
          }
          ariaLabel="Kategorien und Angebote"
          labels={labels}
          renderContent={({ node, expanded }) => (
            <div
              className="sortable-tree-fixture__content"
              data-group={node.children !== undefined || undefined}
            >
              <div className="sortable-tree-fixture__name">
                <KText as="span" variant="bodySmall">
                  {node.label}
                </KText>
                {(!node.children || !expanded) && (
                  <KText as="span" variant="caption">
                    {node.children
                      ? `${node.children.length} Einträge`
                      : node.data?.detail.split(" · ")[0]}
                  </KText>
                )}
              </div>
              {!node.children && node.data?.detail.includes(" · ") && (
                <KText
                  as="span"
                  variant="bodySmall"
                  className="sortable-tree-fixture__price"
                >
                  {node.data.detail.split(" · ").slice(1).join(" · ")}
                </KText>
              )}
            </div>
          )}
          getActions={({ node }) => [
            {
              id: "edit",
              label: "Bearbeiten",
              iconContent: <KIcon name="pencil" strokeWidth={1.5} />,
              onSelect: () => edit(node),
            },
            {
              id: "remove",
              label: "Entfernen",
              destructive: true,
              iconContent: <KIcon name="trash" strokeWidth={1.5} />,
              onSelect: () => setRemoving(node),
            },
          ]}
        />
        <KInline gap="action" wrap>
          <KButton variant="secondary" onClick={() => fresh(true)}>
            <KIcon name="folder-plus" strokeWidth={1.5} />
            Kategorie
          </KButton>
          <KButton variant="ghost" onClick={() => fresh(false)}>
            <KIcon name="plus" strokeWidth={1.5} />
            Angebot
          </KButton>
        </KInline>
        <KText
          variant="caption"
          role="status"
          className="sortable-tree-fixture__status"
        >
          {event}
        </KText>
      </KStack>
      <KToastViewport position="bottom-center">
        {toast && (
          <KToast
            key={toast.key}
            title={toast.message}
            tone="success"
            duration={8000}
            onDismiss={() => setToast(undefined)}
            action={
              <KButton variant="ghost" onClick={undo}>
                Rückgängig
              </KButton>
            }
          />
        )}
      </KToastViewport>
      <KAlertDialog
        open={!!removing}
        onOpenChange={(open) => {
          if (!open) setRemoving(undefined);
        }}
        title={
          removing?.children ? "Kategorie entfernen?" : "Eintrag entfernen?"
        }
        description={`„${removing?.label ?? ""}“ wird entfernt.${removing?.children?.length ? " Alle enthaltenen Kategorien und Angebote werden ebenfalls entfernt." : ""}`}
        destructive
        cancelLabel="Abbrechen"
        actionLabel="Entfernen"
        onAction={() => {
          if (!removing) return;
          change(
            removeNode(nodes, removing.id),
            `${removing.children ? "Kategorie" : removing.data?.kind === "product" ? "Produkt" : "Leistung"} „${removing.label}“ entfernt`,
          );
        }}
      />
      <KDialog
        open={!!editor}
        onOpenChange={(open) => {
          if (!open) setEditor(undefined);
        }}
        title={editor?.fresh ? "Eintrag hinzufügen" : "Eintrag bearbeiten"}
        actions={
          <>
            <KButton variant="ghost" onClick={() => setEditor(undefined)}>
              Abbrechen
            </KButton>
            <KButton disabled={!name.trim()} onClick={save}>
              Übernehmen
            </KButton>
          </>
        }
      >
        <KField label="Name">
          <KInput
            value={name}
            onChange={(e) => setName(e.target.value)}
            maxLength={160}
          />
        </KField>
      </KDialog>
    </section>
  );
}
