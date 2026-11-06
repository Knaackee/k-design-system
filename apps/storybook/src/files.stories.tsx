import { useEffect, useRef, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KFilesHome,
  kFilesHomeCategory,
  type KFilesHomeCategory,
  KFileTree,
  KFileInfo,
  KFileShare,
  KTransferList,
  KStorageBreakdown,
  KFilesWorkspace,
  KFileTransferPanel,
  type KFileTransfer,
  type KFileNode,
} from "@k-design-system/ui/patterns/files";
import {
  KMenuButton,
  type KMenuAction,
} from "@k-design-system/ui/actions/menu-button";
import { KTabStrip } from "@k-design-system/ui/patterns/tab-strip";
import { KButton } from "@k-design-system/ui/primitives/button";
import { KIconButton } from "@k-design-system/ui/actions/icon-button";
import { KIcon } from "@k-design-system/ui/primitives/icon";
import { KFileIcon } from "@k-design-system/ui/primitives/file-icon";
import {
  KCodeEditor,
  KMarkdownEditor,
  type KCodeEditorHandle,
} from "@k-design-system/ui/editors";
import { KSearchField, KAdaptiveDialog, KInput } from "@k-design-system/ui";
import { KSidebarItem } from "@k-design-system/ui/navigation/sidebar";
import { KDictationState } from "@k-design-system/ui/forms/dictation-action";
import "./files-review.css";

const nodes: KFileNode[] = [
  {
    id: "notes",
    name: "Notizen",
    kind: "folder",
    children: [
      { id: "welcome", name: "Willkommen.md", kind: "file", detail: "2 KB" },
      { id: "project", name: "Projektplan.md", kind: "file", detail: "8 KB" },
      { id: "code", name: "example.ts", kind: "file" },
      {
        id: "archive",
        name: "Archiv",
        kind: "folder",
        children: [{ id: "archived", name: "Notiz.md", kind: "file" }],
      },
    ],
  },
  {
    id: "media",
    name: "Medien",
    kind: "folder",
    children: [
      { id: "photo", name: "Entwurf.svg", kind: "file", detail: "1,8 KB" },
      { id: "video", name: "Präsentation.mp4", kind: "file", detail: "24 MB" },
    ],
  },
];
function ReviewMarkdown({
  value,
  onChange,
  editorRef,
  name,
}: {
  value: string;
  onChange: (value: string) => void;
  editorRef: (editor: KCodeEditorHandle | null) => void;
  name: string;
}) {
  const [state, setState] = useState(KDictationState.ready);
  const insert = useRef<((text: string) => boolean) | null>(null);
  return (
    <KMarkdownEditor
      markdown={value}
      onChange={onChange}
      sourceEditorRef={editorRef}
      showModeSwitcher={false}
      showSearchButton={false}
      showFloatingToolbar={false}
      ariaLabel={`${name} bearbeiten`}
      className="k-files-review__editor"
      dictation={{
        state,
        label:
          state === KDictationState.recording
            ? "Demo-Aufnahme beenden"
            : "Spracheingabe ausprobieren (Demo)",
        onStart: (commit) => {
          insert.current = commit;
          setState(KDictationState.recording);
        },
        onStop: () => {
          insert.current?.("Hier steht der diktierte Beispieltext.");
          insert.current = null;
          setState(KDictationState.ready);
        },
      }}
    />
  );
}
function FilesReview({
  initialMode = "files",
  showShared = true,
  appLabel = "App",
}: {
  initialMode?: string;
  showShared?: boolean;
  appLabel?: string;
}) {
  const workspace = initialMode === "home";
  const [tree, setTree] = useState(nodes);
  const picker = useRef<HTMLInputElement>(null);
  const editors = useRef<Record<string, KCodeEditorHandle | null>>({});
  const uploadFolder = useRef("notes");
  const [uploads, setUploads] = useState<Record<string, File>>({});
  const [transfers, setTransfers] = useState<KFileTransfer[]>(
    workspace
      ? []
      : [
          {
            id: "demo-done",
            name: "Willkommen.md",
            progress: 1,
            status: "Abgeschlossen",
          },
        ],
  );
  const [transferVisible, setTransferVisible] = useState(!workspace);
  const [transferCollapsed, setTransferCollapsed] = useState(false);
  const running = transfers.some((item) => item.progress < 1);
  useEffect(() => {
    if (!running) return;
    const timer = setInterval(
      () =>
        setTransfers((items) =>
          items.map((item) => ({
            ...item,
            progress: Math.min(1, item.progress + 0.08),
            status:
              item.progress + 0.08 >= 1
                ? "Abgeschlossen · Demo"
                : "Wird hochgeladen · Demo",
          })),
        ),
      400,
    );
    return () => clearInterval(timer);
  }, [running]);
  const [dialog, setDialog] = useState<{
    kind: "info" | "rename" | "share" | "transfers" | "reference";
    node: KFileNode;
  } | null>(null);
  const [name, setName] = useState("");
  const [recipients, setRecipients] = useState([
    {
      id: "alex",
      name: "Alex · alex@example.com",
      permission: "Kann bearbeiten",
      expires: "Bis 31. Oktober 2026",
    },
  ]);
  const [copied, setCopied] = useState(false);
  const allNodes = (items: readonly KFileNode[]): KFileNode[] =>
    items.flatMap((node) => [node, ...allNodes(node.children ?? [])]);
  const [search, setSearch] = useState("");
  const query = search.trim().toLocaleLowerCase();
  const filterNodes = (items: readonly KFileNode[]): KFileNode[] =>
    items.flatMap((node) => {
      if (node.name.toLocaleLowerCase().includes(query)) return [node];
      const children = filterNodes(node.children ?? []);
      return children.length ? [{ ...node, children }] : [];
    });
  const visibleNodes = query ? filterNodes(tree) : tree;
  const [selected, setSelected] = useState(
    initialMode === "home" ? "home" : "welcome",
  );
  const [homeFilter, setHomeFilter] = useState<KFilesHomeCategory>("all");
  const [openTabs, setOpenTabs] = useState<string[]>(
    workspace ? [] : ["welcome", "project", "code"],
  );
  const [mobile, setMobile] = useState(
    () =>
      typeof matchMedia === "function" &&
      matchMedia("(max-width: 599px)").matches,
  );
  useEffect(() => {
    if (typeof matchMedia !== "function") return;
    const media = matchMedia("(max-width: 599px)");
    const update = () => setMobile(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  function select(id: string) {
    setSelected(id);
    if (mobile) setSidebarOpen(false);
    if (allNodes(tree).find((node) => node.id === id)?.kind === "file")
      setOpenTabs((ids) => (ids.includes(id) ? ids : [...ids, id]));
  }
  function closeTabs(ids: string[]) {
    const remaining = openTabs.filter((id) => !ids.includes(id));
    setOpenTabs(remaining);
    if (ids.includes(selected))
      setSelected(
        remaining[Math.min(openTabs.indexOf(selected), remaining.length - 1)] ??
          "home",
      );
  }
  const [expanded, expand] = useState(["notes", "media"]);
  const [mode, setMode] = useState(initialMode);
  const [sidebarOpen, setSidebarOpen] = useState(
    () =>
      typeof matchMedia !== "function" ||
      !matchMedia("(max-width: 599px)").matches,
  );
  const [notice, setNotice] = useState("");
  const [documents, setDocuments] = useState<Record<string, string>>({
    code: "// Beispiel mit Syntax-Highlighting\nexport const greet = (name: string): string => {\n  return `Hallo ${name}`;\n};\n",
    welcome:
      "# Willkommen\n\nEin gemeinsamer Platz für Notizen, Dokumente und Medien.\n\nDiese Datei kannst du hier direkt bearbeiten.",
    project:
      "# Projektplan\n\n## Nächste Schritte\n\n- Entwürfe abstimmen\n- Gemeinsam Inhalte bearbeiten\n- Ergebnisse freigeben",
  });
  const current =
    allNodes(tree).find((node) => node.id === selected) ?? tree[0];
  const uploadedFile = uploads[current.id];
  const isUploadedText =
    !!uploadedFile &&
    (uploadedFile.type.startsWith("text/") ||
      /\.(txt|md|markdown|js|jsx|ts|tsx|json|html|css|xml|csv|yaml|yml|py|rs|go|java|sh|sql)$/i.test(
        current.name,
      ));
  const [readError, setReadError] = useState<string | null>(null);
  useEffect(() => {
    setReadError(null);
    if (!isUploadedText || documents[current.id] !== undefined) return;
    let active = true;
    void uploadedFile
      .text()
      .then((text) => {
        if (active)
          setDocuments((previous) => ({ ...previous, [current.id]: text }));
      })
      .catch(() => {
        if (active) setReadError("Die Textdatei konnte nicht gelesen werden.");
      });
    return () => {
      active = false;
    };
  }, [current.id, uploadedFile, isUploadedText, documents]);
  const writable = (node: KFileNode) =>
    node.kind === "folder" && !["shared", "trash"].includes(node.id);
  const parentOf = (id: string) =>
    allNodes(tree).find((node) =>
      node.children?.some((child) => child.id === id),
    );
  function chooseUpload(
    folder = current.kind === "folder" ? current : parentOf(current.id),
  ) {
    if (!folder || !writable(folder)) return;
    uploadFolder.current = folder.id;
    picker.current?.click();
  }
  function receiveFiles(files: File[], folder: KFileNode) {
    if (!files.length || !writable(folder)) return;
    const additions = files.map((file) => ({
      id: crypto.randomUUID(),
      name: file.name,
      kind: "file" as const,
      detail: `${file.size} Bytes`,
    }));
    setTransfers((previous) => [
      ...previous,
      ...additions.map((node) => ({
        id: node.id,
        name: node.name,
        progress: 0,
        status: "Wird hochgeladen · Demo",
      })),
    ]);
    setTransferVisible(true);
    setTransferCollapsed(false);
    setUploads((previous) => ({
      ...previous,
      ...Object.fromEntries(
        additions.map((node, index) => [node.id, files[index]]),
      ),
    }));
    const insert = (items: KFileNode[]): KFileNode[] =>
      items.map((node) =>
        node.id === folder.id
          ? { ...node, children: [...(node.children ?? []), ...additions] }
          : {
              ...node,
              children: node.children ? insert([...node.children]) : undefined,
            },
      );
    setTree((previous) => insert(previous));
    expand((previous) => [...new Set([...previous, folder.id])]);
    setNotice("");
  }
  function createEntry(kind: "file" | "folder") {
    const id = `created-${kind}-${allNodes(tree).length}`;
    const entry: KFileNode = {
      id,
      name: kind === "file" ? "Neue Datei.md" : "Neuer Ordner",
      kind,
      ...(kind === "folder" ? { children: [] } : {}),
    };
    setTree((previous) => [...previous, entry]);
    if (kind === "file") {
      setDocuments((previous) => ({ ...previous, [id]: "# Neue Datei\n\n" }));
      setOpenTabs((previous) => [...previous, id]);
    }
    setSelected(id);
    if (mobile) setSidebarOpen(false);
  }
  function download(node = current) {
    const blob =
      documents[node.id] !== undefined
        ? new Blob([documents[node.id]], { type: "text/plain;charset=utf-8" })
        : (uploads[node.id] ?? null);
    if (!blob) {
      setNotice("Für diese Beispieldatei ist kein Download-Inhalt hinterlegt.");
      return;
    }
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = node.name;
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  function openDialog(
    kind: "info" | "rename" | "share" | "transfers" | "reference",
    node = current,
  ) {
    setName(node.name);
    setSidebarOpen(false);
    setDialog({ kind, node });
  }
  function rename() {
    if (!dialog || !name.trim()) return;
    const update = (items: readonly KFileNode[]): KFileNode[] =>
      items.map((node) => ({
        ...node,
        name: node.id === dialog.node.id ? name.trim() : node.name,
        children: node.children ? update(node.children) : undefined,
      }));
    setTree(update(tree));
    setDialog(null);
  }
  function fileActions(node: KFileNode): KMenuAction[] {
    return [
      ...(node.kind === "file"
        ? [
            {
              id: "download",
              label: "Herunterladen",
              icon: "download" as const,
              onSelect: () => download(node),
            },
          ]
        : []),
      {
        id: "info",
        label: "Datei-Info",
        icon: "info",
        onSelect: () => openDialog("info", node),
      },
      {
        id: "rename",
        label: "Umbenennen",
        icon: "pencil",
        onSelect: () => openDialog("rename", node),
      },
      {
        id: "share",
        label: "Freigeben",
        icon: "share-2",
        onSelect: () => openDialog("share", node),
      },
    ];
  }
  return (
    <div className="k-files-review">
      <input
        ref={picker}
        type="file"
        multiple
        hidden
        onChange={(event) => {
          const folder = allNodes(tree).find(
            (node) => node.id === uploadFolder.current,
          );
          if (folder)
            receiveFiles(Array.from(event.target.files ?? []), folder);
          event.target.value = "";
        }}
      />
      <KFilesWorkspace
        header={
          (!workspace || mobile) && (
            <header
              style={{ textAlign: "center", padding: 16, fontWeight: 500 }}
            >
              Dateien
            </header>
          )
        }
        constrainContentWidth={false}
        sidebarOpen={sidebarOpen}
        onSidebarOpenChange={setSidebarOpen}
        title={mode === "storage" ? "Speicherverbrauch" : "Dateien"}
        tabs={
          mode !== "storage" && (
            <KTabStrip
              items={[
                {
                  id: "home",
                  label: "Übersicht",
                  icon: <KIcon name="house" />,
                  closable: false,
                },
                ...openTabs
                  .map((id) => allNodes(tree).find((node) => node.id === id)!)
                  .filter(Boolean)
                  .map((node) => ({
                    id: node.id,
                    label: node.name,
                    icon: <KFileIcon name={node.name} />,
                  })),
              ]}
              selectedId={selected}
              onSelect={select}
              onClose={(id) => closeTabs([id])}
              onReorder={(ids) =>
                setOpenTabs(ids.filter((id) => id !== "home"))
              }
              menuActions={(item, presentation) =>
                item.id === "home"
                  ? []
                  : [
                      ...fileActions(
                        allNodes(tree).find((node) => node.id === item.id)!,
                      ),
                      {
                        id: "close",
                        label: "Schließen",
                        separatorBefore: true,
                        onSelect: () => closeTabs([item.id]),
                      },
                      {
                        id: "others",
                        label: "Andere schließen",
                        onSelect: () =>
                          closeTabs(openTabs.filter((id) => id !== item.id)),
                      },
                      ...(presentation === "tabs"
                        ? [
                            {
                              id: "right",
                              label: "Rechts schließen",
                              onSelect: () =>
                                closeTabs(
                                  openTabs.slice(openTabs.indexOf(item.id) + 1),
                                ),
                            },
                          ]
                        : []),
                      {
                        id: "all",
                        label: "Alle schließen",
                        onSelect: () => closeTabs(openTabs),
                      },
                    ]
              }
            />
          )
        }
        sidebarHeader={
          <KSidebarItem
            label={
              appLabel === "App" ? "Zurück zur App" : `Zurück zu ${appLabel}`
            }
            leading={<KIcon name="arrow-left" />}
            onSelect={() => setNotice("Demo: zurück zur App")}
          />
        }
        sidebarFooter={
          <div className="k-files-review__sidebar-footer">
            {workspace ? (
              <KMenuButton
                label="Datei hinzufügen"
                fullWidth
                triggerVariant="ghost"
                triggerClassName="k-files-review__add"
                triggerContent={
                  <span className="k-files-review__add-content">
                    <KIcon name="file-plus" />
                    <span>Datei hinzufügen</span>
                    <KIcon name="chevron-up" />
                  </span>
                }
                actions={[
                  {
                    id: "new-file",
                    label: "Neue Datei",
                    icon: "file-plus",
                    onSelect: () => createEntry("file"),
                  },
                  {
                    id: "new-folder",
                    label: "Neuer Ordner",
                    icon: "folder-plus",
                    onSelect: () => createEntry("folder"),
                  },
                  {
                    id: "upload",
                    label: "Hochladen",
                    icon: "upload",
                    onSelect: () => chooseUpload(tree[0]),
                  },
                ]}
              />
            ) : (
              <KSidebarItem
                label="Dateien hochladen"
                leading={<KIcon name="upload" />}
                onSelect={() => chooseUpload()}
                disabled={
                  !writable(
                    current.kind === "folder"
                      ? current
                      : (parentOf(current.id) ?? current),
                  )
                }
              />
            )}
            {showShared && (
              <KSidebarItem
                label="Mit mir geteilt"
                leading={<KIcon name="users" />}
                onSelect={() => setNotice("Demo: Mit mir geteilt")}
              />
            )}
            <KSidebarItem
              label="Papierkorb"
              leading={<KIcon name="trash" />}
              onSelect={() => setNotice("Demo: Papierkorb")}
            />
          </div>
        }
        actions={
          mode === "storage" || selected === "home" ? undefined : (
            <>
              {!mobile && (
                <>
                  <KIconButton
                    icon="search"
                    label="In Datei suchen"
                    disabled={!selected || documents[selected] === undefined}
                    onClick={() => editors.current[selected]?.openSearch()}
                  />
                  <KIconButton
                    icon="share-2"
                    label="Freigeben"
                    disabled={!selected}
                    onClick={() => openDialog("share")}
                  />
                  <KIconButton
                    icon="message-circle"
                    label="Im Chat referenzieren"
                    disabled={!selected}
                    onClick={() => openDialog("reference")}
                  />
                </>
              )}
              <KMenuButton
                overflow
                align="end"
                label="Weitere Dateiaktionen"
                actions={[
                  ...(mobile
                    ? [
                        {
                          id: "search-file",
                          label: "In Datei suchen",
                          icon: "search" as const,
                          disabled:
                            !selected || documents[selected] === undefined,
                          onSelect: () =>
                            editors.current[selected]?.openSearch(),
                        },
                        {
                          id: "reference-file",
                          label: "Im Chat referenzieren",
                          icon: "message-circle" as const,
                          disabled: !selected,
                          onSelect: () => openDialog("reference"),
                        },
                      ]
                    : []),
                  ...(selected ? fileActions(current) : []),
                  {
                    id: "transfers",
                    label: "Übertragungen",
                    icon: "arrow-down-up",
                    onSelect: () => {
                      setTransferVisible(true);
                      setTransferCollapsed(false);
                    },
                  },
                ]}
              />
            </>
          )
        }
        search={
          <KSearchField
            aria-label="Dateien durchsuchen"
            placeholder="Dateien durchsuchen…"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        }
        navigation={
          <>
            <KSidebarItem
              label="Übersicht"
              leading={<KIcon name="house" />}
              onSelect={() => select("home")}
            />
            <KFileTree
              nodes={visibleNodes}
              selectedId={selected}
              expandedIds={query ? [...expanded, "notes", "media"] : expanded}
              emptyContent="Keine Dateien gefunden"
              onFilesDrop={receiveFiles}
              canDropFiles={writable}
              menuActions={(node) => [
                ...(writable(node)
                  ? [
                      {
                        id: "upload",
                        label: "Dateien hochladen",
                        icon: "upload" as const,
                        onSelect: () => chooseUpload(node),
                      },
                    ]
                  : []),
                ...(node.kind === "file"
                  ? [
                      {
                        id: "download",
                        label: "Herunterladen",
                        icon: "download" as const,
                        onSelect: () => download(node),
                      },
                    ]
                  : []),
                {
                  id: "info",
                  label: "Datei-Info",
                  icon: "info",
                  onSelect: () => openDialog("info", node),
                },
                {
                  id: "rename",
                  label: "Umbenennen",
                  icon: "pencil",
                  onSelect: () => openDialog("rename", node),
                },
                {
                  id: "share",
                  label: "Freigeben",
                  icon: "share-2",
                  onSelect: () => openDialog("share", node),
                },
                {
                  id: "trash",
                  label: "In Papierkorb",
                  icon: "trash",
                  destructive: true,
                  separatorBefore: true,
                  onSelect: () =>
                    setNotice(
                      `Demo: ${node.name} in den Papierkorb verschieben`,
                    ),
                },
              ]}
              onExpandedChange={expand}
              onSelect={(id) => {
                select(id);
                setMode("files");
              }}
            />
          </>
        }
      >
        <div className="k-files-review__body">
          {notice && <p role="status">{notice}</p>}
          {mode === "storage" ? (
            <KStorageBreakdown
              formatBytes={(bytes) => `${(bytes / 1048576).toFixed(1)} MB`}
              checkedAt="Demo · zuletzt geprüft: gerade eben"
              entries={[
                { id: "issues", label: "Issue-Anhänge", bytes: 12582912 },
                { id: "files", label: "Dateien", bytes: 27053260 },
                { id: "artifacts", label: "Chat-Artefakte", bytes: 1048576 },
                { id: "trash", label: "Papierkorb", bytes: 2097152 },
                { id: "versions", label: "Alte Versionen", bytes: 524288 },
                {
                  id: "parts",
                  label: "Unvollständige Uploads",
                  bytes: 8388608,
                },
              ]}
            />
          ) : (
            <>
              {selected === "home" && (
                <div className="k-files-review__home">
                  <KFilesHome
                    files={allNodes(tree)
                      .filter((node) => node.kind === "file")
                      .map((node) => ({
                        id: node.id,
                        name: node.name,
                        parentLabel: parentOf(node.id)?.name ?? "Dateien",
                        updatedLabel: "10. Okt., 14:00",
                        updatedAt: "2026-10-10T14:00:00Z",
                        category: kFilesHomeCategory(node.name) as Exclude<
                          KFilesHomeCategory,
                          "all"
                        >,
                      }))}
                    filter={homeFilter}
                    onFilterChange={setHomeFilter}
                    onOpen={select}
                    onCreateFile={() => createEntry("file")}
                    onCreateFolder={() => createEntry("folder")}
                    onUpload={() => chooseUpload(tree[0])}
                    onRetry={() => setNotice("Demo: Erneut geladen")}
                  />
                </div>
              )}
              {!selected && (
                <div className="k-files-empty">
                  Öffne eine Datei in der Sidebar.
                </div>
              )}
              {[
                ...openTabs,
                ...(current.kind === "folder" && selected ? [current.id] : []),
              ].map((id) => {
                const current = allNodes(tree).find((node) => node.id === id)!;
                const uploadedFile = uploads[id];
                const isUploadedText =
                  !!uploadedFile &&
                  (uploadedFile.type.startsWith("text/") ||
                    /\.(txt|md|markdown|js|jsx|ts|tsx|json|html|css|xml|csv|yaml|yml|py|rs|go|java|sh|sql)$/i.test(
                      current.name,
                    ));
                return (
                  <div
                    key={id}
                    className="k-files-review__tab-panel"
                    hidden={id !== selected}
                  >
                    {current.kind === "folder" ? (
                      <div className="k-files-review__folder">
                        {current.children?.length ? (
                          current.children.map((node) => (
                            <KButton
                              key={node.id}
                              variant="ghost"
                              onClick={() => select(node.id)}
                            >
                              <KFileIcon name={node.name} kind={node.kind} />
                              {node.name}
                            </KButton>
                          ))
                        ) : (
                          <p className="k-files-muted">
                            Dieser Ordner ist leer.
                          </p>
                        )}
                      </div>
                    ) : current.id === "photo" ? (
                      <div className="k-files-review__viewer">
                        <img
                          alt="Entwurf: geometrische Formen auf dunkler Fläche"
                          src={`data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800"><rect width="1200" height="800" fill="#252830"/><circle cx="420" cy="400" r="230" fill="#aeb8c9"/><rect x="560" y="170" width="350" height="460" rx="32" fill="#64748b"/></svg>')}`}
                        />
                      </div>
                    ) : current.id === "video" ? (
                      <div className="k-files-review__viewer k-files-review__media-empty">
                        <KIcon name="file-video-camera" size={48} />
                        <p>Video-Vorschau</p>
                        <span className="k-files-muted">
                          In diesem Beispiel ist keine Videodatei hinterlegt.
                        </span>
                      </div>
                    ) : isUploadedText &&
                      documents[current.id] === undefined ? (
                      <div className="k-files-review__viewer" role="status">
                        {readError ?? "Textdatei wird geladen…"}
                      </div>
                    ) : uploadedFile && !isUploadedText ? (
                      <div className="k-files-review__viewer k-files-review__media-empty">
                        <KFileIcon name={current.name} size={48} />
                        <p>{current.name}</p>
                        <span className="k-files-muted">
                          Lokal hinzugefügt · {uploadedFile.size} Bytes
                        </span>
                        <KButton variant="secondary" onClick={() => download()}>
                          Herunterladen
                        </KButton>
                      </div>
                    ) : /\.(md|markdown)$/i.test(current.name) ? (
                      <ReviewMarkdown
                        key={current.id}
                        name={current.name}
                        value={documents[current.id] ?? ""}
                        onChange={(value) =>
                          setDocuments((previous) => ({
                            ...previous,
                            [current.id]: value,
                          }))
                        }
                        editorRef={(editor) => {
                          editors.current[current.id] = editor;
                        }}
                      />
                    ) : (
                      <KCodeEditor
                        ref={(editor) => {
                          editors.current[current.id] = editor;
                        }}
                        key={current.id}
                        value={documents[current.id] ?? ""}
                        onChange={(value) =>
                          setDocuments((previous) => ({
                            ...previous,
                            [current.id]: value,
                          }))
                        }
                        language={
                          current.name.endsWith(".ts")
                            ? "typescript"
                            : current.name.endsWith(".js")
                              ? "javascript"
                              : current.name.endsWith(".json")
                                ? "json"
                                : current.name.endsWith(".md")
                                  ? "markdown"
                                  : "plain"
                        }
                        minHeight={0}
                        showToolbar={false}
                        showSearchButton={false}
                        lineWrapping={
                          current.name.endsWith(".md") ||
                          current.name.endsWith(".txt")
                        }
                        ariaLabel={`${current.name} bearbeiten`}
                        className="k-files-review__editor"
                      />
                    )}
                  </div>
                );
              })}
            </>
          )}
        </div>
      </KFilesWorkspace>
      {transferVisible && (
        <KFileTransferPanel
          items={transfers}
          collapsed={transferCollapsed}
          onCollapsedChange={setTransferCollapsed}
          onClose={() => setTransferVisible(false)}
          label="Übertragungen"
        />
      )}
      <KAdaptiveDialog
        open={dialog !== null}
        onOpenChange={(open) => {
          if (!open) setDialog(null);
        }}
        title={
          dialog?.kind === "rename"
            ? "Umbenennen"
            : dialog?.kind === "share"
              ? "Freigeben"
              : dialog?.kind === "transfers"
                ? "Übertragungen"
                : dialog?.kind === "reference"
                  ? "Im Chat referenzieren"
                  : "Datei-Info"
        }
        className="k-files-review-dialog"
        description={dialog?.kind === "info" ? undefined : dialog?.node.name}
        closeLabel="Schließen"
        actions={
          dialog?.kind === "rename" ? (
            <>
              <KButton variant="ghost" onClick={() => setDialog(null)}>
                Abbrechen
              </KButton>
              <KButton disabled={!name.trim()} onClick={rename}>
                Umbenennen
              </KButton>
            </>
          ) : undefined
        }
      >
        {dialog?.kind === "rename" ? (
          <form
            className="k-files-rename-form"
            onSubmit={(event) => {
              event.preventDefault();
              rename();
            }}
          >
            <label htmlFor="files-rename">Name</label>
            <KInput
              id="files-rename"
              autoFocus
              value={name}
              onChange={(event) => setName(event.target.value)}
              onFocus={(event) =>
                event.target.setSelectionRange(
                  0,
                  dialog.node.kind === "file" && name.lastIndexOf(".") > 0
                    ? name.lastIndexOf(".")
                    : name.length,
                )
              }
            />
          </form>
        ) : dialog?.kind === "info" ? (
          <KFileInfo
            name={dialog.node.name}
            properties={[
              {
                label: "Typ",
                value:
                  dialog.node.kind === "folder"
                    ? "Ordner"
                    : (dialog.node.name.split(".").pop()?.toUpperCase() ??
                      "Datei"),
              },
              { label: "Größe", value: dialog.node.detail ?? "—" },
              {
                label: "Speicherort",
                value:
                  dialog.node.id === "photo" || dialog.node.id === "video"
                    ? "Dateien / Medien"
                    : "Dateien / Notizen",
              },
              { label: "Geändert", value: "10. Oktober 2026, 14:00" },
            ]}
          />
        ) : dialog?.kind === "share" ? (
          <KFileShare
            recipients={recipients}
            onInvite={(email, permission) =>
              setRecipients((current) => [
                ...current,
                {
                  id: email,
                  name: email,
                  permission:
                    permission === "edit" ? "Kann bearbeiten" : "Kann ansehen",
                  expires: "",
                },
              ])
            }
            onRevoke={(id) =>
              setRecipients((current) =>
                current.filter((person) => person.id !== id),
              )
            }
            link="https://example.com/shared/demo"
            onCopyLink={() => {
              void navigator.clipboard
                .writeText("https://example.com/shared/demo")
                .then(() => setCopied(true));
            }}
          >
            {copied && <p role="status">Demo-Link kopiert.</p>}
          </KFileShare>
        ) : dialog?.kind === "transfers" ? (
          <KTransferList
            items={[
              {
                id: "upload",
                name: "Präsentation.mp4",
                progress: 0.64,
                status: "Wird hochgeladen",
              },
              {
                id: "resume",
                name: "Archiv.zip",
                progress: 0.31,
                status: "Pausiert · 6 Tage verbleibend",
              },
            ]}
            onPause={() => undefined}
            onResume={() => undefined}
            onCancel={() => undefined}
          />
        ) : dialog?.kind === "reference" ? (
          <div className="k-files-reference-agents">
            <p className="k-files-muted">
              Wähle einen Agenten für diese Datei.
            </p>
            {["Persönlicher Assistent", "Recherche-Agent"].map((agent) => (
              <KButton
                variant="ghost"
                key={agent}
                onClick={() => {
                  setNotice(
                    `Demo: ${dialog.node.name} für ${agent} referenziert.`,
                  );
                  setDialog(null);
                }}
              >
                <KIcon name="bot" />
                {agent}
                <KIcon name="chevron-right" />
              </KButton>
            ))}
          </div>
        ) : null}
      </KAdaptiveDialog>
    </div>
  );
}
export default {
  title: "Patterns/Files",
  component: FilesReview,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof FilesReview>;
export const Review: StoryObj<typeof FilesReview> = {
  parameters: { fixtureId: "files-review" },
};
export const Storage: StoryObj<typeof FilesReview> = {
  args: { initialMode: "storage" },
  parameters: { fixtureId: "files-storage" },
};
export const Empty: StoryObj = {
  render: () => (
    <KFileTree
      nodes={[]}
      expandedIds={[]}
      onSelect={() => undefined}
      onExpandedChange={() => undefined}
    />
  ),
};

export const Workspace: StoryObj<typeof FilesReview> = {
  args: { initialMode: "home", showShared: true, appLabel: "Tasks" },
  argTypes: {
    showShared: { control: "boolean" },
    appLabel: { control: "text" },
  },
  parameters: { fixtureId: "files-workspace" },
};
function HomeFixture({ empty = false }: { empty?: boolean }) {
  const [filter, setFilter] = useState<KFilesHomeCategory>("all");
  const [notice, setNotice] = useState("");
  return (
    <>
      <KFilesHome
        files={
          empty
            ? []
            : [
                {
                  id: "welcome",
                  name: "Willkommen.md",
                  parentLabel: "Notizen",
                  updatedLabel: "10. Okt., 14:00",
                  updatedAt: "2026-10-10T14:00:00Z",
                },
                {
                  id: "photo",
                  name: "Entwurf.svg",
                  parentLabel: "Medien",
                  updatedLabel: "09. Okt., 09:30",
                  updatedAt: "2026-10-09T09:30:00Z",
                },
                {
                  id: "code",
                  name: "example.ts",
                  parentLabel: "Notizen",
                  updatedLabel: "08. Okt., 16:15",
                  updatedAt: "2026-10-08T16:15:00Z",
                },
              ]
        }
        filter={filter}
        onFilterChange={setFilter}
        onOpen={(id) => setNotice(`Datei geöffnet: ${id}`)}
        onCreateFile={() => setNotice("Neue Datei erstellen")}
        onCreateFolder={() => setNotice("Neuen Ordner erstellen")}
        onUpload={() => setNotice("Dateien hochladen")}
        onRetry={() => setNotice("Erneut laden")}
      />
      {notice && <p role="status">{notice}</p>}
    </>
  );
}
export const Home: StoryObj = {
  render: () => <HomeFixture />,
  parameters: { fixtureId: "files-home" },
};
export const HomeEmpty: StoryObj = {
  render: () => <HomeFixture empty />,
  parameters: { fixtureId: "files-home-empty" },
};
