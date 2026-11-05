import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { KInput } from "../forms/input.js";
import { KSurface } from "../primitives/surface.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { kIconNames } from "../generated/icons.js";
import { kEmojiCatalog } from "../generated/emoji.js";
import {
  SymbolPickerPopover,
  type KSymbolPickerAnchorProps,
} from "./symbol-picker-popover.js";

export interface KSymbolItem {
  id: string;
  label: string;
  category: string;
  keywords?: readonly string[];
  disabled?: boolean;
}
export interface KEmojiItem extends KSymbolItem {
  value: string;
  svg: string;
  tones?: readonly { value: string; svg: string }[];
}
export interface KIconItem extends KSymbolItem {
  name: KIconName;
}
export interface KSymbolPickerLabels {
  search: string;
  searchPlaceholder?: string;
  clearSearch?: string;
  all: string;
  recent: string;
  empty: string;
  /** @deprecated The descriptive footer has been removed. */
  hint: string;
  skinTone: string;
  tones: readonly string[];
}
const defaults: KSymbolPickerLabels = {
  search: "Search",
  all: "All",
  recent: "Recent",
  empty: "No matches",
  hint: "Choose a symbol",
  skinTone: "Skin tone",
  tones: ["Default", "Light", "Medium light", "Medium", "Medium dark", "Dark"],
};
export interface KSymbolPickerProps<
  T extends KSymbolItem,
> extends KSymbolPickerAnchorProps {
  items?: readonly T[];
  value?: string | null;
  onSelect: (item: T) => void;
  recentIds?: readonly string[];
  labels?: Partial<KSymbolPickerLabels>;
  categoryLabels?: Readonly<Record<string, string>>;
  renderItem?: (item: T) => ReactNode;
  disabled?: boolean;
  /** Escape requests dismissal; the consumer owns the surrounding overlay. */
  onDismiss?: () => void;
  width?: number | string;
  height?: number;
}
export const kDefaultIconItems: readonly KIconItem[] = kIconNames.map(
  (name) => ({
    id: name,
    name,
    label: name.replaceAll("-", " "),
    category: "Lucide",
  }),
);
export { kEmojiCatalog };

function Picker<T extends KSymbolItem>({
  items,
  value,
  onSelect,
  recentIds = [],
  labels,
  categoryLabels = {},
  renderItem,
  disabled = false,
  onDismiss,
  width = 352,
  height = 420,
  accessory,
}: KSymbolPickerProps<T> & {
  items: readonly T[];
  renderItem: (item: T) => ReactNode;
  accessory?: ReactNode;
}) {
  const text = { ...defaults, ...labels };
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("");
  const [focusedId, setFocusedId] = useState<string | null>(null);
  const grid = useRef<HTMLDivElement>(null);
  const categories = useMemo(
    () => [...new Set(items.map((item) => item.category))],
    [items],
  );
  const visible = useMemo(() => {
    const q = query.trim().toLocaleLowerCase();
    const source =
      !q && category === "__recent"
        ? recentIds.flatMap((id) => items.find((item) => item.id === id) ?? [])
        : items;
    return source.filter((item) =>
      q
        ? [item.label, ...(item.keywords ?? [])].some((word) =>
            word.toLocaleLowerCase().includes(q),
          )
        : !category || category === "__recent" || item.category === category,
    );
  }, [items, query, category, recentIds]);
  const tabs = [
    ["", text.all],
    ...(recentIds.length ? [["__recent", text.recent]] : []),
    ...categories.map((c) => [c, categoryLabels[c] ?? c]),
  ];
  return (
    <KSurface
      className="k-symbol-picker"
      style={{ width, maxWidth: "100%", height }}
      onKeyDown={(e) => {
        if (e.key === "Escape") {
          e.stopPropagation();
          onDismiss?.();
        }
      }}
    >
      <div className="k-symbol-search">
        <KInput
          aria-label={text.search}
          placeholder={text.searchPlaceholder ?? text.search}
          clearLabel={text.clearSearch}
          value={query}
          disabled={disabled}
          onChange={(e) => {
            setQuery(e.target.value);
          }}
          clearable
          onClear={() => setQuery("")}
        />
      </div>
      <div className="k-symbol-categories" aria-label={text.all}>
        {tabs.map(([id, label]) => (
          <button
            type="button"
            key={id}
            disabled={disabled}
            aria-pressed={category === id}
            aria-label={label}
            title={label}
            onClick={() => {
              setCategory(id);
              setQuery("");
              grid.current?.scrollTo(0, 0);
            }}
          >
            {id === "" ? (
              <KIcon name="search" />
            ) : id === "__recent" ? (
              <KIcon name="clock" />
            ) : (
              renderItem(items.find((item) => item.category === id)!)
            )}
          </button>
        ))}
      </div>
      <div
        className="k-symbol-grid"
        ref={grid}
        onKeyDown={(e) => {
          const buttons = [
            ...e.currentTarget.querySelectorAll<HTMLButtonElement>(
              "button:not(:disabled)",
            ),
          ];
          const index = buttons.indexOf(e.target as HTMLButtonElement);
          if (index < 0) return;
          const columns = Math.max(
            1,
            Math.floor(e.currentTarget.clientWidth / 44),
          );
          const next =
            e.key === "Home"
              ? 0
              : e.key === "End"
                ? buttons.length - 1
                : index +
                  ({
                    ArrowRight: 1,
                    ArrowLeft: -1,
                    ArrowDown: columns,
                    ArrowUp: -columns,
                  }[e.key] ?? 0);
          if (
            [
              "Home",
              "End",
              "ArrowRight",
              "ArrowLeft",
              "ArrowUp",
              "ArrowDown",
            ].includes(e.key)
          ) {
            e.preventDefault();
            buttons[Math.max(0, Math.min(buttons.length - 1, next))]?.focus();
          }
        }}
      >
        {visible.map((item) => (
          <button
            type="button"
            key={item.id}
            title={item.label}
            aria-label={item.label}
            aria-pressed={value === item.id}
            tabIndex={
              item.id ===
              (visible.some((i) => i.id === focusedId && !i.disabled)
                ? focusedId
                : visible.find((i) => !i.disabled)?.id)
                ? 0
                : -1
            }
            disabled={disabled || item.disabled}
            onFocus={() => {
              setFocusedId(item.id);
            }}
            onClick={() => onSelect(item)}
          >
            {renderItem(item)}
          </button>
        ))}
        {!visible.length && (
          <span className="k-symbol-empty" role="status">
            {text.empty}
          </span>
        )}
      </div>
      {accessory && <div className="k-symbol-footer">{accessory}</div>}
    </KSurface>
  );
}
export function KIconPicker(props: KSymbolPickerProps<KIconItem>) {
  return (
    <SymbolPickerPopover
      {...props}
      label={props.triggerLabel ?? "Choose icon"}
      icon="star"
    >
      {(close) => (
        <Picker
          {...props}
          items={props.items ?? kDefaultIconItems}
          onDismiss={() => {
            close();
            props.onDismiss?.();
          }}
          onSelect={(item) => {
            props.onSelect(item);
            close();
          }}
          renderItem={
            props.renderItem ?? ((item) => <KIcon name={item.name} size={20} />)
          }
        />
      )}
    </SymbolPickerPopover>
  );
}
export interface KEmojiPickerProps extends KSymbolPickerProps<KEmojiItem> {
  skinTone?: number;
  onSkinToneChange?: (tone: number) => void;
  showSkinTonePicker?: boolean;
}

const skinToneHand = kEmojiCatalog.find((item) => item.id === "270b")!;

function SkinToneControl({
  tone,
  labels,
  disabled,
  onChange,
}: {
  tone: number;
  labels: KSymbolPickerLabels;
  disabled?: boolean;
  onChange: (tone: number) => void;
}) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    if (!open) return;
    const dismiss = (event: PointerEvent) => {
      if (!root.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener("pointerdown", dismiss);
    return () => document.removeEventListener("pointerdown", dismiss);
  }, [open]);
  const hand = (index: number) =>
    skinToneHand.tones?.[index - 1] ?? skinToneHand;
  const image = (index: number) => (
    <img
      src={`data:image/svg+xml,${encodeURIComponent(hand(index).svg)}`}
      width={24}
      height={24}
      draggable={false}
      alt=""
    />
  );
  return (
    <div
      className="k-emoji-tone-control"
      ref={root}
      onKeyDown={(event) => {
        if (event.key === "Escape" && open) {
          event.stopPropagation();
          setOpen(false);
          trigger.current?.focus();
        }
      }}
    >
      <button
        ref={trigger}
        type="button"
        className="k-emoji-tone-trigger"
        aria-label={`${labels.skinTone}: ${labels.tones[tone]}`}
        aria-haspopup="menu"
        aria-expanded={open}
        title={labels.skinTone}
        disabled={disabled}
        onClick={() => setOpen(!open)}
      >
        {image(tone)}
      </button>
      {open && (
        <div
          className="k-emoji-tone-menu"
          role="menu"
          aria-label={labels.skinTone}
        >
          {labels.tones.map((label, index) => (
            <button
              type="button"
              role="menuitemradio"
              key={index}
              aria-label={label}
              aria-checked={tone === index}
              title={label}
              onClick={() => {
                onChange(index);
                setOpen(false);
                trigger.current?.focus();
              }}
            >
              {image(index)}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export function KEmojiPicker({
  skinTone,
  onSkinToneChange,
  showSkinTonePicker = true,
  ...props
}: KEmojiPickerProps) {
  const [localTone, setTone] = useState(0);
  const tone = Math.max(0, Math.min(5, skinTone ?? localTone));
  const resolve = (item: KEmojiItem) =>
    tone && item.tones?.[tone - 1]
      ? { ...item, ...item.tones[tone - 1] }
      : item;
  const text = { ...defaults, ...props.labels };
  return (
    <SymbolPickerPopover
      {...props}
      label={props.triggerLabel ?? "Choose emoji"}
      icon="heart"
    >
      {(close) => (
        <Picker
          {...props}
          items={props.items ?? kEmojiCatalog}
          onSelect={(item) => {
            props.onSelect(resolve(item));
            close();
          }}
          onDismiss={() => {
            close();
            props.onDismiss?.();
          }}
          renderItem={(item) =>
            props.renderItem ? (
              props.renderItem(resolve(item))
            ) : (
              // ~1,900 SVG emoji: decode only the ones near the visible part
              // of the grid. Eager decoding blocked a phone's main thread
              // (76 s on a software-rendered phone emulation).
              <img
                width={24}
                height={24}
                alt=""
                draggable={false}
                loading="lazy"
                decoding="async"
                src={`data:image/svg+xml,${encodeURIComponent(resolve(item).svg)}`}
              />
            )
          }
          accessory={
            showSkinTonePicker && (
              <SkinToneControl
                tone={tone}
                labels={text}
                disabled={props.disabled}
                onChange={(next) => {
                  if (skinTone === undefined) setTone(next);
                  onSkinToneChange?.(next);
                }}
              />
            )
          }
        />
      )}
    </SymbolPickerPopover>
  );
}
