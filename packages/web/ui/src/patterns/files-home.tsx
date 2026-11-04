import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { KFileIcon } from "../primitives/file-icon.js";

export type KFilesHomeCategory = "all" | "documents" | "images" | "other";
const labels: Record<KFilesHomeCategory, string> = {
  all: "Alle",
  documents: "Dokumente",
  images: "Bilder",
  other: "Weitere",
};
export function kFilesHomeCategory(
  name: string,
): Exclude<KFilesHomeCategory, "all"> {
  const extension = name.split(".").at(-1)?.toLowerCase();
  if (
    ["png", "jpg", "jpeg", "gif", "webp", "svg", "avif", "heic"].includes(
      extension ?? "",
    )
  )
    return "images";
  if (
    [
      "md",
      "txt",
      "pdf",
      "doc",
      "docx",
      "odt",
      "rtf",
      "csv",
      "xlsx",
      "xls",
      "pptx",
    ].includes(extension ?? "")
  )
    return "documents";
  return "other";
}
export interface KFilesHomeEntry {
  id: string;
  name: string;
  parentLabel: string;
  updatedLabel: string;
  /** ISO date/time used by the semantic time element. */
  updatedAt?: string;
  category?: Exclude<KFilesHomeCategory, "all">;
}
export interface KFilesHomeProps {
  files: readonly KFilesHomeEntry[];
  loading?: boolean;
  error?: string;
  filter: KFilesHomeCategory;
  onFilterChange: (filter: KFilesHomeCategory) => void;
  onOpen: (id: string) => void;
  onCreateFile: () => void;
  onCreateFolder: () => void;
  onUpload: () => void;
  onRetry: () => void;
  title?: string;
  description?: string;
  recentDescription?: string;
}
/** Presentation only: consumers own ordering, timestamps, loading and actions. */
export function KFilesHome({
  files,
  loading = false,
  error,
  filter,
  onFilterChange,
  onOpen,
  onCreateFile,
  onCreateFolder,
  onUpload,
  onRetry,
  title = "Dein Platz für Ideen.",
  description = "Alles, was du festhältst. Alles, was dein Assistent für dich erstellt.",
  recentDescription = "Deine letzten 50 Dateien · auch aus Unterordnern",
}: KFilesHomeProps) {
  const categories = (["all", "documents", "images", "other"] as const).filter(
    (key) =>
      key === "all" ||
      files.some(
        (file) => (file.category ?? kFilesHomeCategory(file.name)) === key,
      ),
  );
  const activeFilter = categories.includes(filter) ? filter : "all";
  const visible = files.filter(
    (file) =>
      activeFilter === "all" ||
      (file.category ?? kFilesHomeCategory(file.name)) === activeFilter,
  );
  const actions = [
    {
      title: "Neue Datei",
      description: "Gedanken festhalten",
      icon: "file-plus" as const,
      onClick: onCreateFile,
    },
    {
      title: "Neuer Ordner",
      description: "Platz für ein neues Thema",
      icon: "folder-plus" as const,
      onClick: onCreateFolder,
    },
    {
      title: "Hochladen",
      description: "Dateien von deinem Gerät",
      icon: "upload" as const,
      onClick: onUpload,
    },
  ];
  return (
    <section className="k-files-home" aria-label="Dateiübersicht">
      <div className="k-files-home-intro">
        <h2>{title}</h2>
        <p>{description}</p>
      </div>
      <div className="k-files-home-actions">
        {actions.map((action) => (
          <KButton
            key={action.title}
            fullWidth
            variant="secondary"
            className="k-files-home-action"
            onClick={action.onClick}
          >
            <span className="k-files-home-action-content">
              <span className="k-files-home-action-icon">
                <KIcon name={action.icon} size={24} />
              </span>
              <span>
                <strong>{action.title}</strong>
                <small>{action.description}</small>
              </span>
              <KIcon name="arrow-up-right" size={16} />
            </span>
          </KButton>
        ))}
      </div>
      <div className="k-files-home-section">
        <h2>Zuletzt geändert</h2>
        <span>{recentDescription}</span>
      </div>
      {files.length > 0 && (
        <div className="k-files-home-filters" aria-label="Dateityp">
          {categories.map((key) => (
            <KButton
              key={key}
              variant={activeFilter === key ? "secondary" : "ghost"}
              aria-pressed={activeFilter === key}
              onClick={() => onFilterChange(key)}
            >
              {labels[key]}
            </KButton>
          ))}
        </div>
      )}
      {error ? (
        <div className="k-files-home-empty" role="alert">
          <KIcon name="cloud-off" size={32} />
          <h3>Dateien gerade nicht erreichbar</h3>
          <p>Deine Dateien bleiben erhalten. Versuche es noch einmal.</p>
          <KButton variant="secondary" onClick={onRetry}>
            Erneut versuchen
          </KButton>
        </div>
      ) : loading && files.length === 0 ? (
        <p role="status" className="k-files-home-loading">
          Deine Dateien werden geladen …
        </p>
      ) : visible.length > 0 ? (
        <ul className="k-files-home-list">
          {visible.map((file) => (
            <li key={file.id}>
              <KButton
                fullWidth
                variant="ghost"
                className="k-files-home-row"
                onClick={() => onOpen(file.id)}
              >
                <span className="k-files-home-row-content">
                  <span className="k-files-home-file-icon">
                    <KFileIcon name={file.name} />
                  </span>
                  <span className="k-files-home-filename">
                    <strong>{file.name}</strong>
                    <small>{file.parentLabel}</small>
                  </span>
                  <time dateTime={file.updatedAt}>{file.updatedLabel}</time>
                  <KIcon name="arrow-up-right" size={16} />
                </span>
              </KButton>
            </li>
          ))}
        </ul>
      ) : (
        <div className="k-files-home-empty">
          <span className="k-files-home-empty-icon">
            <KIcon name="files" size={32} />
          </span>
          <h3>Hier beginnt deine Sammlung.</h3>
          <p>
            Erstelle deine erste Datei oder lade etwas hoch.
            <br />
            Auch die Dateien deines Assistenten findest du hier.
          </p>
          <KButton variant="secondary" onClick={onCreateFile}>
            Erste Datei erstellen
          </KButton>
        </div>
      )}
    </section>
  );
}
