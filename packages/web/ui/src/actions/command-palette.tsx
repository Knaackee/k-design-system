import { Command } from "cmdk";
import { useEffect, useMemo, useState, type ReactNode } from "react";
import { KDialog } from "../overlays/overlay.js";
import { KIcon, type KIconName } from "../primitives/icon.js";

export interface KCommandPaletteItem {
  id: string;
  label: string;
  description?: string;
  keywords?: readonly string[];
  icon?: KIconName;
  shortcut?: readonly string[];
  group?: string;
  disabled?: boolean;
  priority?: number;
  closeOnInvoke?: boolean;
  children?: readonly KCommandPaletteItem[];
  metadata?: unknown;
}

export interface KCommandPaletteLabels {
  title: string;
  searchPlaceholder: string;
  empty: string;
  loading: string;
  back: string;
  close: string;
  navigate: string;
  select: string;
}

export interface KCommandPaletteProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  items: readonly KCommandPaletteItem[];
  onCommand: (item: KCommandPaletteItem) => void | Promise<void>;
  query?: string;
  defaultQuery?: string;
  onQueryChange?: (query: string) => void;
  activeItemId?: string;
  onActiveItemChange?: (id: string) => void;
  onPageChange?: (path: readonly KCommandPaletteItem[]) => void;
  labels?: Partial<KCommandPaletteLabels>;
  loading?: boolean;
  shouldFilter?: boolean;
  loop?: boolean;
  enableGlobalShortcut?: boolean;
  renderItemContent?: (item: KCommandPaletteItem) => ReactNode;
  footer?: ReactNode;
  className?: string;
}

const defaultLabels: KCommandPaletteLabels = {
  title: "Commands",
  searchPlaceholder: "Search commands…",
  empty: "No commands found",
  loading: "Loading commands…",
  back: "Back",
  close: "Close command palette",
  navigate: "Navigate",
  select: "Select",
};

export function KCommandPalette({
  open,
  onOpenChange,
  items,
  onCommand,
  query,
  defaultQuery = "",
  onQueryChange,
  activeItemId,
  onActiveItemChange,
  onPageChange,
  labels: labelOverrides,
  loading = false,
  shouldFilter = true,
  loop = true,
  enableGlobalShortcut = true,
  renderItemContent,
  footer,
  className,
}: KCommandPaletteProps) {
  const labels = { ...defaultLabels, ...labelOverrides };
  const [localQuery, setLocalQuery] = useState(defaultQuery);
  const [localActive, setLocalActive] = useState("");
  const [pages, setPages] = useState<KCommandPaletteItem[]>([]);
  const [executing, setExecuting] = useState<string>();
  const currentQuery = query ?? localQuery;
  const currentActive = activeItemId ?? localActive;
  const currentItems = pages.at(-1)?.children ?? items;

  const groups = useMemo(() => {
    const grouped = new Map<string, KCommandPaletteItem[]>();
    [...currentItems]
      .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0))
      .forEach((item) => {
        const group = item.group ?? "";
        grouped.set(group, [...(grouped.get(group) ?? []), item]);
      });
    return [...grouped.entries()];
  }, [currentItems]);

  useEffect(() => {
    if (!enableGlobalShortcut) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() === "k" && (event.metaKey || event.ctrlKey)) {
        event.preventDefault();
        onOpenChange(!open);
      }
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [enableGlobalShortcut, onOpenChange, open]);

  useEffect(() => {
    if (!open) {
      setPages([]);
      setExecuting(undefined);
      if (query === undefined) setLocalQuery(defaultQuery);
    }
  }, [defaultQuery, open, query]);

  const updateQuery = (value: string) => {
    if (query === undefined) setLocalQuery(value);
    onQueryChange?.(value);
  };

  const updatePages = (next: KCommandPaletteItem[]) => {
    setPages(next);
    updateQuery("");
    onPageChange?.(next);
  };

  const invoke = async (item: KCommandPaletteItem) => {
    if (item.disabled || executing) return;
    if (item.children?.length) {
      updatePages([...pages, item]);
      return;
    }
    setExecuting(item.id);
    try {
      await onCommand(item);
      if (item.closeOnInvoke !== false) onOpenChange(false);
    } finally {
      setExecuting(undefined);
    }
  };

  return (
    <KDialog
      open={open}
      onOpenChange={onOpenChange}
      title={pages.at(-1)?.label ?? labels.title}
      closeLabel={labels.close}
      contentInset={false}
      className={["k-command-palette-dialog", className]
        .filter(Boolean)
        .join(" ")}
    >
      <Command
        className="k-command-palette"
        value={currentActive}
        onValueChange={(value) => {
          if (activeItemId === undefined) setLocalActive(value);
          onActiveItemChange?.(value);
        }}
        shouldFilter={shouldFilter}
        loop={loop}
        onKeyDown={(event) => {
          if (
            pages.length &&
            (event.key === "Escape" ||
              (event.key === "Backspace" && !currentQuery))
          ) {
            event.preventDefault();
            event.stopPropagation();
            updatePages(pages.slice(0, -1));
          }
        }}
      >
        <div className="k-command-palette__search">
          {pages.length ? (
            <button
              type="button"
              className="k-command-palette__back"
              aria-label={labels.back}
              onClick={() => updatePages(pages.slice(0, -1))}
            >
              <KIcon name="arrow-left" />
            </button>
          ) : (
            <KIcon name="search" className="k-command-palette__search-icon" />
          )}
          <Command.Input
            autoFocus
            value={currentQuery}
            onValueChange={updateQuery}
            placeholder={labels.searchPlaceholder}
            aria-label={labels.searchPlaceholder}
          />
          {loading ? <span className="k-command-palette__spinner" /> : null}
        </div>
        <Command.List className="k-command-palette__list">
          {loading ? (
            <Command.Loading className="k-command-palette__state">
              {labels.loading}
            </Command.Loading>
          ) : null}
          <Command.Empty className="k-command-palette__state">
            {labels.empty}
          </Command.Empty>
          {!loading
            ? groups.map(([group, groupItems]) => (
                <Command.Group
                  key={group || "default"}
                  heading={group || undefined}
                >
                  {groupItems.map((item) => (
                    <Command.Item
                      key={item.id}
                      value={item.id}
                      keywords={[
                        item.label,
                        item.description ?? "",
                        ...(item.keywords ?? []),
                      ]}
                      disabled={item.disabled}
                      onSelect={() => void invoke(item)}
                      className="k-command-palette__item"
                    >
                      {renderItemContent ? (
                        renderItemContent(item)
                      ) : (
                        <>
                          <span className="k-command-palette__item-icon">
                            {item.icon ? <KIcon name={item.icon} /> : null}
                          </span>
                          <span className="k-command-palette__item-copy">
                            <span className="k-command-palette__item-label">
                              {item.label}
                            </span>
                            {item.description ? (
                              <span className="k-command-palette__item-description">
                                {item.description}
                              </span>
                            ) : null}
                          </span>
                          {executing === item.id ? (
                            <span className="k-command-palette__spinner" />
                          ) : item.children?.length ? (
                            <KIcon name="chevron-right" />
                          ) : item.shortcut?.length ? (
                            <span
                              className="k-command-palette__shortcut"
                              aria-hidden="true"
                            >
                              {item.shortcut.map((key) => (
                                <kbd key={key}>{key}</kbd>
                              ))}
                            </span>
                          ) : null}
                        </>
                      )}
                    </Command.Item>
                  ))}
                </Command.Group>
              ))
            : null}
        </Command.List>
        <footer className="k-command-palette__footer">
          {footer ?? (
            <>
              <span>
                <kbd>↑</kbd>
                <kbd>↓</kbd> {labels.navigate}
              </span>
              <span>
                <kbd>↵</kbd> {labels.select}
              </span>
            </>
          )}
        </footer>
      </Command>
    </KDialog>
  );
}
