import {
  useEffect,
  useId,
  useRef,
  useState,
  type ReactNode,
  type CSSProperties,
} from "react";
import { KChatBubble, type KChatBubbleProps } from "../chat/chat-bubble.js";
import { FabAttention, type KFabAttention } from "./fab-attention.js";

export interface KFabItem {
  id: string;
  label: string;
  content: ReactNode;
  onSelect: () => void;
  disabled?: boolean;
}

export interface KFabProps extends Omit<KChatBubbleProps, "onClick"> {
  items: readonly KFabItem[];
  /** Press opens the actions; longPress reserves a short press for onPress. */
  activation?: "press" | "longPress";
  onPress?: () => void;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  /** Space between bubbles, including the trigger, in pixels. Default: 8. */
  itemGap?: number;
  attention?: readonly KFabAttention[];
  /** Total pulse duration, at least attentionHoldMs + 600 ms. Default: 1800. */
  attentionShowMs?: number;
  /** Delay after the pulse before another notice peeks. Default: 7000. */
  attentionPauseMs?: number;
  /** Fraction of the bubble height revealed, from 0 to 1. Default: 0.5. */
  attentionPeekFraction?: number;
  /** Time spent at the highest point, in milliseconds. Default: 324. */
  attentionHoldMs?: number;
  onAttentionSelect?: (notice: KFabAttention) => void;
}

/** Generic floating action group. The consumer owns its placement and content. */
export function KFab({
  items,
  activation = "press",
  onPress,
  open: controlledOpen,
  onOpenChange,
  visible = true,
  disabled,
  loading,
  itemGap = 8,
  attention = [],
  attentionShowMs = 1800,
  attentionPauseMs = 7000,
  attentionPeekFraction = 0.5,
  attentionHoldMs = 324,
  onAttentionSelect,
  ...bubble
}: KFabProps) {
  const [localOpen, setLocalOpen] = useState(false);
  const open =
    visible &&
    !disabled &&
    !loading &&
    items.length > 0 &&
    (controlledOpen ?? localOpen);
  const root = useRef<HTMLSpanElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const origin = useRef<{ x: number; y: number } | undefined>(undefined);
  const consumed = useRef(false);
  const pointerType = useRef("");
  const keyboardOpen = useRef(false);
  const [availableHeight, setAvailableHeight] = useState<number>();
  const [scrollable, setScrollable] = useState(false);
  const id = useId();
  const change = (next: boolean) => {
    setLocalOpen(next);
    onOpenChange?.(next);
  };
  const cancel = () => {
    clearTimeout(timer.current);
    timer.current = undefined;
  };
  useEffect(() => cancel, []);
  useEffect(() => {
    if (!visible || disabled || loading) cancel();
  }, [visible, disabled, loading]);
  useEffect(() => {
    if (!open) return;
    const measure = () => {
      const height = Math.max(
        0,
        (root.current?.getBoundingClientRect().top ?? 0) - 24,
      );
      setAvailableHeight(height);
      const actions =
        root.current?.querySelector<HTMLElement>(".k-fab__actions");
      setScrollable((actions?.scrollHeight ?? 0) > height);
    };
    measure();
    window.addEventListener("resize", measure);
    if (keyboardOpen.current) {
      root.current
        ?.querySelector<HTMLButtonElement>(
          ".k-fab__actions button:not(:disabled)",
        )
        ?.focus();
      keyboardOpen.current = false;
    }
    const outside = (event: PointerEvent) => {
      if (!root.current?.contains(event.target as Node)) change(false);
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        change(false);
        trigger.current?.focus();
      }
    };
    document.addEventListener("pointerdown", outside);
    document.addEventListener("keydown", escape);
    return () => {
      document.removeEventListener("pointerdown", outside);
      document.removeEventListener("keydown", escape);
      window.removeEventListener("resize", measure);
    };
  });
  return (
    <span
      ref={root}
      className="k-fab"
      style={
        {
          "--k-fab-item-gap": `${Number.isFinite(itemGap) ? Math.max(0, itemGap) : 8}px`,
        } as CSSProperties
      }
    >
      {!open && visible && !disabled && !loading && attention.length > 0 && (
        <FabAttention
          key={JSON.stringify(
            attention
              .filter((notice) =>
                items.some(
                  (item) => item.id === notice.itemId && !item.disabled,
                ),
              )
              .map((notice) => [notice.id, notice.itemId]),
          )}
          notices={attention}
          items={items}
          size={bubble.size}
          showMs={attentionShowMs}
          pauseMs={attentionPauseMs}
          peekFraction={attentionPeekFraction}
          holdMs={attentionHoldMs}
          onSelect={(notice) => {
            trigger.current?.focus();
            onAttentionSelect?.(notice);
          }}
        />
      )}
      <span
        id={id}
        className="k-fab__actions"
        data-open={open}
        aria-hidden={!open}
        inert={!open}
        style={{
          maxHeight: availableHeight,
          overflowY: scrollable ? "auto" : "visible",
        }}
        role="group"
        aria-label={bubble.label}
      >
        {items.map((item) => (
          <KChatBubble
            key={item.id}
            visible={open}
            label={item.label}
            title={item.label}
            size={bubble.size}
            disabled={item.disabled}
            className={
              attention.some((notice) => notice.itemId === item.id)
                ? "k-fab__marked"
                : undefined
            }
            onClick={() => {
              change(false);
              trigger.current?.focus();
              item.onSelect();
            }}
          >
            {item.content}
          </KChatBubble>
        ))}
      </span>
      <KChatBubble
        {...bubble}
        className={["k-fab__trigger", bubble.className]
          .filter(Boolean)
          .join(" ")}
        ref={trigger}
        visible={visible}
        disabled={disabled}
        loading={loading}
        aria-expanded={open}
        aria-controls={open ? id : undefined}
        onPointerDown={(event) => {
          bubble.onPointerDown?.(event);
          cancel();
          consumed.current = false;
          pointerType.current = event.pointerType;
          if (
            event.defaultPrevented ||
            event.button !== 0 ||
            !event.isPrimary ||
            disabled ||
            loading
          )
            return;
          origin.current = { x: event.clientX, y: event.clientY };
          if (activation === "longPress" && items.length)
            timer.current = setTimeout(() => {
              consumed.current = true;
              change(!open);
            }, 500);
        }}
        onPointerMove={(event) => {
          bubble.onPointerMove?.(event);
          const start = origin.current;
          if (
            start &&
            Math.hypot(event.clientX - start.x, event.clientY - start.y) > 10
          ) {
            cancel();
            consumed.current = true;
          }
        }}
        onPointerUp={(event) => {
          cancel();
          bubble.onPointerUp?.(event);
        }}
        onPointerCancel={(event) => {
          cancel();
          consumed.current = true;
          bubble.onPointerCancel?.(event);
        }}
        onPointerLeave={(event) => {
          cancel();
          bubble.onPointerLeave?.(event);
        }}
        onContextMenu={(event) => {
          event.preventDefault();
          cancel();
          // Touch browsers may emit contextmenu after our long-press timer.
          if (pointerType.current === "touch" && consumed.current) return;
          if (!disabled && !loading && items.length) change(!open);
        }}
        onKeyDown={(event) => {
          bubble.onKeyDown?.(event);
          if (
            items.length &&
            (event.key === "ArrowUp" || (event.shiftKey && event.key === "F10"))
          ) {
            event.preventDefault();
            keyboardOpen.current = true;
            change(true);
          }
        }}
        onClick={(event) => {
          if (consumed.current && event.detail !== 0) {
            consumed.current = false;
            return;
          }
          if (activation === "press" && items.length) change(!open);
          else {
            change(false);
            onPress?.();
          }
        }}
      />
    </span>
  );
}
