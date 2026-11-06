import { useId, useRef, useState, type ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KFileIcon } from "../primitives/file-icon.js";
import { KContextMenu } from "../actions/context-menu.js";
import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";
import { KInput } from "../forms/input.js";
import { KSelect } from "../forms/selection.js";
export {
  KFilesWorkspace,
  type KFilesWorkspaceProps,
} from "./files-workspace.js";

export interface KFileNode {
  id: string;
  name: string;
  kind: "folder" | "file";
  icon?: KIconName;
  detail?: ReactNode;
  children?: readonly KFileNode[];
}
export interface KFileTreeProps {
  nodes: readonly KFileNode[];
  selectedId?: string;
  expandedIds: readonly string[];
  onSelect: (id: string) => void;
  onExpandedChange: (ids: string[]) => void;
  label?: string;
  emptyContent?: ReactNode;
  actions?: (node: KFileNode) => ReactNode;
  menuActions?: (node: KFileNode) => readonly KMenuAction[];
  showDetails?: boolean;
  onFilesDrop?: (files: File[], folder: KFileNode) => void;
  canDropFiles?: (folder: KFileNode) => boolean;
}
/** Controlled navigation. The consumer owns authority, loading and ordering. */
export function KFileTree({
  nodes,
  selectedId,
  expandedIds,
  onSelect,
  onExpandedChange,
  label = "Dateien",
  emptyContent = "Noch keine Dateien",
  actions,
  menuActions,
  showDetails = false,
  onFilesDrop,
  canDropFiles,
}: KFileTreeProps) {
  const [dropTarget, setDropTarget] = useState<string | null>(null);
  const render = (items: readonly KFileNode[], depth: number): ReactNode =>
    items.map((node) => {
      const expanded = expandedIds.includes(node.id);
      const menu = menuActions?.(node) ?? [];
      const acceptsFiles =
        node.kind === "folder" &&
        !!onFilesDrop &&
        (canDropFiles?.(node) ?? true);
      const row = (
        <div
          className="k-file-tree__row"
          data-selected={selectedId === node.id || undefined}
          data-drop-target={dropTarget === node.id || undefined}
          onDragOver={(event) => {
            if (!event.dataTransfer.types.includes("Files")) return;
            event.preventDefault();
            event.stopPropagation();
            event.dataTransfer.dropEffect = acceptsFiles ? "copy" : "none";
            setDropTarget(acceptsFiles ? node.id : null);
          }}
          onDragLeave={(event) => {
            if (
              !event.currentTarget.contains(event.relatedTarget as Node | null)
            )
              setDropTarget(null);
          }}
          onDrop={(event) => {
            event.preventDefault();
            event.stopPropagation();
            setDropTarget(null);
            const files = Array.from(event.dataTransfer.files);
            if (acceptsFiles && files.length) onFilesDrop?.(files, node);
          }}
          style={{
            paddingInlineStart: `calc(var(--k-space-control-gap) / 2 + ${depth} * 12px)`,
          }}
        >
          {node.kind === "folder" ? (
            <button
              type="button"
              className="k-file-tree__toggle"
              aria-label={`${expanded ? "Einklappen" : "Aufklappen"}: ${node.name}`}
              aria-expanded={expanded}
              onClick={() =>
                onExpandedChange(
                  expanded
                    ? expandedIds.filter((id) => id !== node.id)
                    : [...expandedIds, node.id],
                )
              }
            >
              <KIcon
                name={expanded ? "chevron-down" : "chevron-right"}
                size={16}
              />
            </button>
          ) : (
            <span className="k-file-tree__toggle" aria-hidden="true" />
          )}
          <button
            type="button"
            className="k-file-tree__select"
            aria-current={selectedId === node.id ? "page" : undefined}
            onClick={() => onSelect(node.id)}
          >
            {node.icon ? (
              <KIcon name={node.icon} size={16} />
            ) : (
              <KFileIcon
                name={node.name}
                kind={node.kind}
                expanded={expanded}
              />
            )}
            <span className="k-file-tree__name">{node.name}</span>
            {showDetails && node.detail ? (
              <span className="k-file-tree__detail">{node.detail}</span>
            ) : null}
          </button>
          {actions?.(node)}
          {menu.length > 0 && (
            <span className="k-file-tree__menu">
              <KMenuButton
                overflow
                label={`Aktionen für ${node.name}`}
                actions={menu}
              />
            </span>
          )}
        </div>
      );
      return (
        <li key={node.id}>
          {menu.length ? (
            <KContextMenu label={`Aktionen für ${node.name}`} actions={menu}>
              {row}
            </KContextMenu>
          ) : (
            row
          )}
          {expanded && node.children?.length ? (
            <ul>{render(node.children, depth + 1)}</ul>
          ) : null}
        </li>
      );
    });
  return (
    <nav className="k-file-tree" aria-label={label}>
      {nodes.length ? (
        <ul>{render(nodes, 0)}</ul>
      ) : (
        <div className="k-files-empty">{emptyContent}</div>
      )}
    </nav>
  );
}

export interface KFileTransfer {
  id: string;
  name: string;
  progress: number;
  status: string;
  error?: string;
  canPause?: boolean;
  canResume?: boolean;
  canCancel?: boolean;
}
/** Non-modal transfer surface; progress and lifecycle are owned by the consumer. */
export function KFileTransferPanel({
  items,
  collapsed,
  onCollapsedChange,
  onClose,
  label = "Übertragungen",
  children,
}: {
  items: readonly KFileTransfer[];
  collapsed: boolean;
  onCollapsedChange: (value: boolean) => void;
  onClose: () => void;
  label?: string;
  children?: ReactNode;
}) {
  if (!items.length && !children) return null;
  return (
    <aside className="k-file-transfer-panel" aria-label={label}>
      <header>
        <strong>{label}</strong>
        <KButton
          variant="ghost"
          aria-label={
            collapsed ? "Übertragungen ausklappen" : "Übertragungen einklappen"
          }
          aria-expanded={!collapsed}
          onClick={() => onCollapsedChange(!collapsed)}
        >
          <KIcon name={collapsed ? "chevron-up" : "chevron-down"} />
        </KButton>
        <KButton
          variant="ghost"
          aria-label="Transferanzeige schließen"
          onClick={onClose}
        >
          <KIcon name="x" />
        </KButton>
      </header>
      {children ? (
        <div hidden={collapsed}>{children}</div>
      ) : (
        !collapsed && (
          <ul>
            {items.map((item) => (
              <li key={item.id}>
                <KFileIcon name={item.name} />
                <div>
                  <strong>{item.name}</strong>
                  <span>{item.error ?? item.status}</span>
                  <progress
                    max={1}
                    value={item.progress}
                    aria-label={`${item.name}: ${Math.round(item.progress * 100)} %`}
                  />
                </div>
                <span>
                  {item.progress >= 1 ? (
                    <KIcon name="check" size={16} />
                  ) : (
                    `${Math.round(item.progress * 100)} %`
                  )}
                </span>
              </li>
            ))}
          </ul>
        )
      )}
    </aside>
  );
}
export function KTransferList({
  items,
  onPause,
  onResume,
  onCancel,
  label = "Übertragungen",
}: {
  items: readonly KFileTransfer[];
  onPause?: (id: string) => void;
  onResume?: (id: string) => void;
  onCancel?: (id: string) => void;
  label?: string;
}) {
  return (
    <section className="k-transfer-list" aria-label={label}>
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            <div className="k-transfer-list__identity">
              <KFileIcon name={item.name} />
              <div>
                <strong>{item.name}</strong>
                <span>{item.status}</span>
                <progress
                  max={1}
                  value={Math.max(0, Math.min(1, item.progress))}
                  aria-label={item.name}
                />
              </div>
              {item.progress >= 1 ? <KIcon name="check" size={16} /> : null}
            </div>
            {item.error ? <p role="alert">{item.error}</p> : null}
            <div className="k-transfer-list__actions">
              {onPause && item.canPause !== false ? (
                <KButton variant="ghost" onClick={() => onPause(item.id)}>
                  Pausieren
                </KButton>
              ) : null}
              {onResume && item.canResume !== false ? (
                <KButton variant="ghost" onClick={() => onResume(item.id)}>
                  Fortsetzen
                </KButton>
              ) : null}
              {onCancel && item.canCancel !== false ? (
                <KButton variant="ghost" onClick={() => onCancel(item.id)}>
                  Abbrechen
                </KButton>
              ) : null}
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}

export interface KStorageEntry {
  id: string;
  label: string;
  bytes: number;
  detail?: ReactNode;
}
export function KStorageBreakdown({
  entries,
  formatBytes,
  title = "Speicherverbrauch",
  checkedAt,
  children,
}: {
  entries: readonly KStorageEntry[];
  formatBytes: (bytes: number) => string;
  title?: string;
  checkedAt?: ReactNode;
  children?: ReactNode;
}) {
  const total = entries.reduce((sum, entry) => sum + entry.bytes, 0);
  return (
    <section className="k-storage-breakdown">
      <h2>{title}</h2>
      <p className="k-storage-breakdown__total">{formatBytes(total)}</p>
      {checkedAt ? <p className="k-files-muted">{checkedAt}</p> : null}
      <ul>
        {entries.map((entry) => (
          <li key={entry.id}>
            <div className="k-files-inline">
              <span>{entry.label}</span>
              <strong>{formatBytes(entry.bytes)}</strong>
            </div>
            <progress
              value={entry.bytes}
              max={Math.max(total, 1)}
              aria-label={entry.label}
            />
            {entry.detail}
          </li>
        ))}
      </ul>
      {children}
    </section>
  );
}

export function KFileInfo({
  name,
  properties,
  actions,
}: {
  name: ReactNode;
  properties: readonly { label: string; value: ReactNode }[];
  actions?: ReactNode;
}) {
  return (
    <section className="k-file-info">
      <div className="k-file-info__identity">
        <KIcon name="file-text" size={24} />
        <strong>{name}</strong>
      </div>
      <dl>
        {properties.map((property) => (
          <div key={property.label}>
            <dt>{property.label}</dt>
            <dd>{property.value}</dd>
          </div>
        ))}
      </dl>
      {actions}
    </section>
  );
}

export function KFileShare({
  recipients,
  onInvite,
  onRevoke,
  link,
  onCopyLink,
  children,
}: {
  recipients: readonly {
    id: string;
    name: string;
    permission: string;
    expires?: string;
  }[];
  onInvite?: (email: string, permission: "view" | "edit") => void;
  onRevoke?: (id: string) => void;
  link?: string;
  onCopyLink?: () => void;
  children?: ReactNode;
}) {
  const id = useId();
  const [email, setEmail] = useState("");
  const [permission, setPermission] = useState<"view" | "edit">("view");
  return (
    <section className="k-file-share">
      {onInvite ? (
        <form
          onSubmit={(event) => {
            event.preventDefault();
            onInvite(email.trim(), permission);
            setEmail("");
          }}
        >
          <label htmlFor={`${id}-email`}>Personen einladen</label>
          <KInput
            id={`${id}-email`}
            type="email"
            required
            placeholder="E-Mail-Adresse"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />
          <div className="k-file-share__invite-actions">
            <KSelect
              label="Berechtigung"
              value={permission}
              onValueChange={(value) =>
                setPermission(value === "edit" ? "edit" : "view")
              }
              options={[
                { value: "view", label: "Kann ansehen" },
                { value: "edit", label: "Kann bearbeiten" },
              ]}
            />
            <KButton type="submit" disabled={!email.trim()}>
              Einladen
            </KButton>
          </div>
        </form>
      ) : null}
      <div className="k-file-share__section">
        <h3>Personen mit Zugriff</h3>
        <ul>
          {recipients.map((recipient) => (
            <li key={recipient.id}>
              <KIcon name="user-round" size={20} />
              <div className="k-file-share__person">
                <strong>{recipient.name}</strong>
                <p className="k-files-muted">{recipient.permission}</p>
                {recipient.expires && (
                  <p className="k-files-muted">{recipient.expires}</p>
                )}
              </div>
              {onRevoke ? (
                <KButton variant="ghost" onClick={() => onRevoke(recipient.id)}>
                  Entfernen
                </KButton>
              ) : null}
            </li>
          ))}
        </ul>
        {!recipients.length && (
          <p className="k-files-muted">Noch keine Personen eingeladen.</p>
        )}
      </div>
      {link ? (
        <div className="k-file-share__section">
          <h3>Linkzugriff</h3>
          <p className="k-files-muted">
            Jeder mit dem Link kann ansehen und herunterladen. Bearbeiten
            erfordert eine Anmeldung und Freigabe.
          </p>
          <KButton variant="secondary" onClick={onCopyLink}>
            <KIcon name="link" />
            Link kopieren
          </KButton>
        </div>
      ) : null}
      {children}
    </section>
  );
}

export function KMediaPlayer({
  src,
  kind,
  label,
  onError,
  fallback,
}: {
  src: string;
  kind: "audio" | "video";
  label: string;
  onError?: () => void;
  fallback?: ReactNode;
}) {
  const media = useRef<HTMLMediaElement | null>(null);
  const [playing, setPlaying] = useState(false),
    [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0),
    [muted, setMuted] = useState(false),
    [failed, setFailed] = useState(false);
  const time = (value: number) =>
    `${Math.floor(value / 60)}:${String(Math.floor(value % 60)).padStart(2, "0")}`;
  const events = {
    onTimeUpdate: () => setPosition(media.current?.currentTime ?? 0),
    onLoadedMetadata: () => {
      setFailed(false);
      setDuration(
        Number.isFinite(media.current?.duration) ? media.current!.duration : 0,
      );
    },
    onPlay: () => setPlaying(true),
    onPause: () => setPlaying(false),
    onError: () => {
      setFailed(true);
      onError?.();
    },
  };
  return (
    <figure className="k-media-player" aria-label={label}>
      {kind === "video" ? (
        <video
          ref={(element) => {
            media.current = element;
          }}
          src={src}
          preload="metadata"
          playsInline
          {...events}
        />
      ) : (
        <>
          <audio
            ref={(element) => {
              media.current = element;
            }}
            src={src}
            preload="metadata"
            {...events}
          />
          <div className="k-media-player__preview">
            <KIcon name="file-volume" size={48} />
          </div>
        </>
      )}
      {failed ? (
        <p role="alert">Dieses Format kann hier nicht abgespielt werden.</p>
      ) : null}
      <div className="k-media-player__controls">
        <KButton
          variant="ghost"
          aria-label={playing ? "Pausieren" : "Abspielen"}
          disabled={failed}
          onClick={() => {
            if (playing) media.current?.pause();
            else
              void media.current?.play().catch(() => {
                setFailed(true);
                onError?.();
              });
          }}
        >
          <KIcon name={playing ? "pause" : "play"} />
        </KButton>
        <span>{time(position)}</span>
        <input
          type="range"
          aria-label="Wiedergabeposition"
          min={0}
          max={duration || 1}
          step={0.1}
          value={Math.min(position, duration || 1)}
          disabled={!duration}
          onChange={(event) => {
            if (media.current)
              media.current.currentTime = Number(event.target.value);
            setPosition(Number(event.target.value));
          }}
        />
        <span>{time(duration)}</span>
        <KButton
          variant="ghost"
          aria-label={muted ? "Ton einschalten" : "Stummschalten"}
          onClick={() => {
            if (media.current) media.current.muted = !muted;
            setMuted(!muted);
          }}
        >
          <KIcon name={muted ? "volume-x" : "volume-2"} />
        </KButton>
      </div>
      <figcaption>{label}</figcaption>
      {fallback}
    </figure>
  );
}

export {
  KFilesHome,
  kFilesHomeCategory,
  type KFilesHomeEntry,
  type KFilesHomeProps,
  type KFilesHomeCategory,
} from "./files-home.js";
