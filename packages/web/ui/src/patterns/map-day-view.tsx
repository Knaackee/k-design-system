import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from "react";
import { KPopover } from "../extended-components.js";
import { KIconButton } from "../actions/icon-button.js";
import { KButton } from "../primitives/button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import {
  KMapDaySheetController,
  type KMapDayPanelState,
  useKMapDaySheet,
} from "./map-day-sheet-controller.js";

export { KMapDaySheetController, type KMapDayPanelState };
export interface KMapDayPanelContext {
  isSheet: boolean;
  expanded: boolean;
  toggleExpanded: () => void;
  selectedItemId: string | null;
  onItemClick: (itemId: string) => void;
}
export interface KMapDayItem {
  id: string;
  /** Minutes from midnight on the consumer's displayed day. */
  start: number;
  end: number;
  expectedStart?: number;
  title: string;
  detail: string;
  /** Human-readable route endpoints, exposed beside the time. */
  routeDescription?: string;
  icon: KIconName;
  kind: "stop" | "travel";
  actions?: readonly { id: string; label: string; icon?: KIconName }[];
}
export interface KMapDayViewProps {
  items: readonly KMapDayItem[];
  currentTime: number;
  title: string;
  dayLabel: string;
  summary?: ReactNode;
  description?: ReactNode;
  footer?: ReactNode;
  /** Receives selection and a callback for consumer-rendered map markers. */
  renderMap: (context: {
    selectedItemId: string | null;
    onItemClick: (itemId: string) => void;
  }) => ReactNode;
  selectedItemId?: string | null;
  defaultSelectedItemId?: string | null;
  panelState?: KMapDayPanelState;
  defaultPanelState?: KMapDayPanelState;
  /** Percentage heights for compact / medium / expanded mobile panels. */
  panelHeights?: readonly [number, number, number];
  panelWidth?: number;
  presentation?: "auto" | "sidebar" | "sheet";
  showCurrentTime?: boolean;
  showForecasts?: boolean;
  formatTime?: (minutes: number) => string;
  labels?: Partial<{
    panel: string;
    resize: string;
    smaller: string;
    larger: string;
    compact: string;
    medium: string;
    expanded: string;
    now: string;
    outside: string;
    expected: string;
    minutes: string;
    later: string;
    earlier: string;
  }>;
  formatForecast?: (item: KMapDayItem) => ReactNode;
  renderItemDetails?: (item: KMapDayItem) => ReactNode;
  /** Product-specific header; return null to omit it on a sidebar. */
  renderPanelHeader?: (context: KMapDayPanelContext) => ReactNode;
  /** Replaces itinerary content, retaining the accessible sheet and scroll area. */
  renderPanelBody?: (context: KMapDayPanelContext) => ReactNode;
  /** Docked sidebars meet the content edges; floating remains the default. */
  panelLayout?: "floating" | "docked";
  onSelectionChange?: (itemId: string) => void;
  onItemClick?: (itemId: string) => void;
  onMapItemClick?: (itemId: string) => void;
  onAction?: (event: { itemId: string; actionId: string }) => void;
  onPanelStateChange?: (state: KMapDayPanelState) => void;
  sheetController?: KMapDaySheetController;
  /** Reports the actual manual or animated sheet position within 0–1. */
  onSheetFractionChanged?: (fraction: number) => void;
  /** Keeps the selected itinerary row in view as the sheet moves. */
  ensureSelectedItemVisible?: boolean;
  className?: string;
  style?: CSSProperties;
}

const time = (minutes: number) =>
  `${Math.floor(minutes / 60)
    .toString()
    .padStart(2, "0")}:${(minutes % 60).toString().padStart(2, "0")}`;
const DEFAULT_PANEL_HEIGHTS = [28, 62, 91] as const;

/** Controlled or uncontrolled map + itinerary composition; no routing or scrolling side effects. */
export function KMapDayView({
  items,
  currentTime,
  title,
  dayLabel,
  summary,
  description,
  footer,
  renderMap,
  selectedItemId,
  defaultSelectedItemId = null,
  panelState,
  defaultPanelState = 1,
  panelHeights = DEFAULT_PANEL_HEIGHTS,
  panelWidth = 404,
  presentation = "auto",
  showCurrentTime = true,
  showForecasts = true,
  formatTime = time,
  labels,
  formatForecast,
  renderItemDetails,
  renderPanelHeader,
  renderPanelBody,
  panelLayout = "floating",
  onSelectionChange,
  onItemClick,
  onMapItemClick,
  onAction,
  onPanelStateChange,
  sheetController,
  onSheetFractionChanged,
  ensureSelectedItemVisible = false,
  className = "",
  style,
}: KMapDayViewProps) {
  const [localSelection, setLocalSelection] = useState(defaultSelectedItemId);
  const [localPanel, setLocalPanel] = useState(defaultPanelState);
  const root = useRef<HTMLDivElement>(null);
  const body = useRef<HTMLDivElement>(null);
  const selected =
    selectedItemId === undefined ? localSelection : selectedItemId;
  const snap = panelState ?? localPanel;
  const current = items.find(
    (item) => currentTime >= item.start && currentTime < item.end,
  );
  const text = {
    panel: "Tagesablauf",
    resize: "Höhe des Tagesablaufs",
    smaller: "Ansicht verkleinern",
    larger: "Ansicht vergrößern",
    compact: "Kompakt",
    medium: "Halb geöffnet",
    expanded: "Vollständig geöffnet",
    now: "Jetzt laut Plan",
    outside: "Außerhalb der geplanten Zeiten",
    expected: "Erwartet",
    minutes: "Min.",
    later: "später",
    earlier: "früher",
    ...labels,
  };
  if (
    !Number.isFinite(panelWidth) ||
    panelWidth < 280 ||
    panelHeights.some(
      (height, i) =>
        !Number.isFinite(height) ||
        height <= 0 ||
        height > 100 ||
        (i > 0 && height <= panelHeights[i - 1]!),
    )
  )
    throw new RangeError(
      "Panel width must be >= 280; panel heights must increase within 0–100.",
    );
  const sheet = useKMapDaySheet({
    root,
    presentation,
    snap,
    heights: panelHeights,
    controller: sheetController,
    onFractionChanged: onSheetFractionChanged,
    onSnapChange: (next) => {
      if (next === snap) return;
      if (panelState === undefined) setLocalPanel(next);
      onPanelStateChange?.(next);
    },
  });
  useEffect(() => {
    if (!ensureSelectedItemVisible || !selected || !sheet.isSheet) return;
    const frame = requestAnimationFrame(() => {
      const row = Array.from(
        body.current?.querySelectorAll<HTMLElement>("[data-item-id]") ?? [],
      ).find((element) => element.dataset.itemId === selected);
      row?.scrollIntoView({ block: "nearest" });
    });
    return () => cancelAnimationFrame(frame);
  }, [ensureSelectedItemVisible, selected, sheet.fraction, sheet.isSheet]);
  const select = (id: string, source: "list" | "map") => {
    if (!items.some((item) => item.id === id)) return;
    if (selectedItemId === undefined) setLocalSelection(id);
    if (selected !== id) onSelectionChange?.(id);
    if (source === "map") onMapItemClick?.(id);
    else onItemClick?.(id);
  };
  const panelContext: KMapDayPanelContext = {
    isSheet: sheet.isSheet,
    expanded: sheet.fraction >= panelHeights[2] / 100 - 0.01,
    toggleExpanded: () => {
      void sheet.snapTo(sheet.fraction >= panelHeights[2] / 100 - 0.01 ? 1 : 2);
    },
    selectedItemId: selected,
    onItemClick: (id) => select(id, "list"),
  };
  const customHeader = renderPanelHeader?.(panelContext);
  return (
    <div
      className={`k-day-map ${className}`}
      ref={root}
      data-presentation={presentation}
      data-panel-layout={panelLayout}
      data-custom-panel={!!renderPanelBody || undefined}
      data-sheet={sheet.isSheet || undefined}
      data-sheet-moving={sheet.moving || undefined}
      style={
        {
          "--k-day-panel-width": `${panelWidth}px`,
          "--k-day-sheet-fraction": `${sheet.fraction * 100}%`,
          ...style,
        } as CSSProperties
      }
    >
      {renderMap({
        selectedItemId: selected,
        onItemClick: (id) => select(id, "map"),
      })}
      <section
        className="k-day-panel"
        data-snap={snap}
        data-sheet-state={sheet.state ?? "free"}
        aria-label={text.panel}
      >
        <div
          className="k-day-panel__handle"
          role="slider"
          tabIndex={0}
          aria-label={text.resize}
          aria-valuemin={0}
          aria-valuemax={2}
          aria-valuenow={snap}
          aria-orientation="vertical"
          aria-valuetext={[text.compact, text.medium, text.expanded][snap]}
          onKeyDown={(event) => {
            if (["ArrowUp", "ArrowDown", "Home", "End"].includes(event.key)) {
              event.preventDefault();
              void sheet.snapTo(
                event.key === "Home"
                  ? 0
                  : event.key === "End"
                    ? 2
                    : ((snap +
                        (event.key === "ArrowUp"
                          ? 1
                          : -1)) as KMapDayPanelState),
              );
            }
          }}
          onPointerDown={(event) => {
            if (!sheet.isSheet) return;
            sheet.startDrag(event.clientY);
            event.currentTarget.setPointerCapture(event.pointerId);
          }}
          onPointerMove={(event) => sheet.dragTo(event.clientY)}
          onPointerUp={() => sheet.finishDrag()}
          onPointerCancel={() => sheet.cancelDrag()}
        >
          <span />
        </div>
        {renderPanelHeader ? (
          customHeader != null && (
            <header className="k-day-panel__custom-header">
              {customHeader}
            </header>
          )
        ) : (
          <header className="k-day-panel__header">
            <div className="k-day-panel__heading">
              <div>
                <span className="k-day-muted">{dayLabel}</span>
                <h2>{title}</h2>
              </div>
              <div className="k-day-panel__sizes">
                <KButton
                  variant="ghost"
                  aria-label={text.smaller}
                  disabled={snap === 0}
                  onClick={() =>
                    void sheet.snapTo((snap - 1) as KMapDayPanelState)
                  }
                >
                  <KIcon name="chevron-down" />
                </KButton>
                <KButton
                  variant="ghost"
                  aria-label={text.larger}
                  disabled={snap === 2}
                  onClick={() =>
                    void sheet.snapTo((snap + 1) as KMapDayPanelState)
                  }
                >
                  <KIcon name="chevron-up" />
                </KButton>
              </div>
            </div>
            {summary && <div className="k-day-panel__summary">{summary}</div>}
            {showCurrentTime && (
              <div className="k-day-now-summary">
                <KIcon name="clock" size={16} />
                <span>
                  <strong>
                    {formatTime(currentTime)} · {text.now}
                  </strong>
                  <br />
                  {current?.title ?? text.outside}
                </span>
              </div>
            )}
          </header>
        )}
        <div ref={body} className="k-day-panel__body">
          {renderPanelBody ? (
            renderPanelBody(panelContext)
          ) : (
            <>
              {description && (
                <div className="k-day-explanation">{description}</div>
              )}
              <ol className="k-day-timeline">
                {items.map((item) => {
                  const active = showCurrentTime && current?.id === item.id;
                  const forecast =
                    showForecasts &&
                    item.expectedStart !== undefined &&
                    item.expectedStart !== item.start;
                  return (
                    <li
                      key={item.id}
                      className={`k-day-entry k-day-entry--${item.kind}`}
                      data-past={item.end <= currentTime && !active}
                      data-selected={selected === item.id}
                      aria-current={active ? "step" : undefined}
                    >
                      <div className="k-day-entry__rail">
                        <span>
                          <KIcon name={item.icon} size={20} />
                        </span>
                      </div>
                      <div
                        className="k-day-entry__main"
                        data-route-info={!!item.routeDescription}
                      >
                        <button
                          data-item-id={item.id}
                          className="k-day-entry__content"
                          aria-pressed={selected === item.id}
                          onClick={() => select(item.id, "list")}
                        >
                          <span className="k-day-entry__top">
                            <strong>{item.title}</strong>
                            <span className="k-day-entry__time">
                              <time>{formatTime(item.start)}</time>
                            </span>
                          </span>
                          <span className="k-day-muted">{item.detail}</span>
                          {forecast && (
                            <span className="k-day-delay">
                              {formatForecast ? (
                                formatForecast(item)
                              ) : (
                                <>
                                  {text.expected}{" "}
                                  {formatTime(item.expectedStart!)} ·{" "}
                                  {Math.abs(item.expectedStart! - item.start)}{" "}
                                  {text.minutes}{" "}
                                  {item.expectedStart! > item.start
                                    ? text.later
                                    : text.earlier}
                                </>
                              )}
                            </span>
                          )}
                        </button>
                        {item.routeDescription && (
                          <span className="k-day-entry__info">
                            <KPopover
                              portal
                              align="end"
                              label="Routendetails"
                              trigger={
                                <KIconButton
                                  icon="info"
                                  label={`Routendetails: ${item.title}`}
                                  variant="ghost"
                                />
                              }
                            >
                              <div className="k-day-route-info">
                                {item.routeDescription}
                              </div>
                            </KPopover>
                          </span>
                        )}
                        {renderItemDetails?.(item)}
                        {item.actions?.length ? (
                          <div className="k-day-entry__actions">
                            {item.actions.map((action) => (
                              <KButton
                                key={action.id}
                                variant="ghost"
                                onClick={() =>
                                  onAction?.({
                                    itemId: item.id,
                                    actionId: action.id,
                                  })
                                }
                              >
                                {action.icon && <KIcon name={action.icon} />}
                                {action.label}
                              </KButton>
                            ))}
                          </div>
                        ) : null}
                      </div>
                      {active && (
                        <div className="k-day-time-line">
                          <span>{formatTime(currentTime)}</span>
                          <i />
                          <small>{text.now}</small>
                        </div>
                      )}
                    </li>
                  );
                })}
              </ol>
            </>
          )}
        </div>
        {footer && <footer className="k-day-panel__footer">{footer}</footer>}
      </section>
    </div>
  );
}
