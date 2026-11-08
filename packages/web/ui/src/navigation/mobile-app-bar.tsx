import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import { LiquidGlass } from "apple-liquid-glass-webgl";

export type KGlassQuality = "auto" | "liquid" | "frosted" | "solid";
export type KResolvedGlassQuality = Exclude<KGlassQuality, "auto">;
export type KMobileAppBarVariant =
  | "floating-glass"
  | "fixed"
  | "fixed-line"
  | "action"
  | "floating-dock"
  | "labeled"
  | "collapsible"
  | "contextual";
export type KMobileAppBarLabelVisibility = "never" | "selected" | "always";

export interface KMobileAppBarItem {
  id: string;
  label: string;
  icon: ReactNode;
  selectedIcon?: ReactNode;
  badge?: ReactNode;
  disabled?: boolean;
}

export interface KMobileAppBarItemState {
  selected: boolean;
}

export interface KMobileAppBarProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "onChange"
> {
  items: readonly KMobileAppBarItem[];
  selectedId: string;
  onSelectionChange: (id: string) => void;
  primaryAction?: ReactNode;
  variant?: KMobileAppBarVariant;
  labelVisibility?: KMobileAppBarLabelVisibility;
  collapsed?: boolean;
  contextualContent?: ReactNode;
  quality?: KGlassQuality;
  visibility?: "portrait-mobile" | "always";
  label?: string;
  renderItem?: (
    item: KMobileAppBarItem,
    state: KMobileAppBarItemState,
  ) => ReactNode;
  onResolvedQualityChange?: (quality: KResolvedGlassQuality) => void;
}

function prefersReducedEffects() {
  return (
    window.matchMedia("(prefers-reduced-motion: reduce)").matches ||
    window.matchMedia("(prefers-reduced-transparency: reduce)").matches
  );
}

function canUseLiquidGlass() {
  const navigatorWithHints = navigator as Navigator & {
    deviceMemory?: number;
    connection?: { saveData?: boolean };
  };
  return (
    LiquidGlass.isSupported() &&
    !prefersReducedEffects() &&
    (navigator.hardwareConcurrency === 0 ||
      navigator.hardwareConcurrency >= 4) &&
    (navigatorWithHints.deviceMemory === undefined ||
      navigatorWithHints.deviceMemory >= 4) &&
    !navigatorWithHints.connection?.saveData
  );
}

function resolveQuality(quality: KGlassQuality): KResolvedGlassQuality {
  if (quality === "auto") return canUseLiquidGlass() ? "liquid" : "frosted";
  if (quality === "liquid" && !LiquidGlass.isSupported()) return "frosted";
  return quality;
}

export function KMobileAppBar({
  items,
  selectedId,
  onSelectionChange,
  primaryAction,
  variant = "floating-glass",
  labelVisibility,
  collapsed = false,
  contextualContent,
  quality = "auto",
  visibility = "portrait-mobile",
  label = "Primary navigation",
  renderItem,
  onResolvedQualityChange,
  className,
  ...props
}: KMobileAppBarProps) {
  const surfaceRef = useRef<HTMLDivElement>(null);
  const [resolvedQuality, setResolvedQuality] = useState<KResolvedGlassQuality>(
    () => (quality === "solid" ? "solid" : "frosted"),
  );

  useEffect(() => {
    const update = () => setResolvedQuality(resolveQuality(quality));
    update();
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    const reducedTransparency = window.matchMedia(
      "(prefers-reduced-transparency: reduce)",
    );
    reducedMotion.addEventListener("change", update);
    reducedTransparency.addEventListener("change", update);
    return () => {
      reducedMotion.removeEventListener("change", update);
      reducedTransparency.removeEventListener("change", update);
    };
  }, [quality]);

  useEffect(() => {
    onResolvedQualityChange?.(resolvedQuality);
  }, [onResolvedQualityChange, resolvedQuality]);

  useEffect(() => {
    if (resolvedQuality !== "liquid" || !surfaceRef.current) return;
    const glass = new LiquidGlass(surfaceRef.current, {
      shape: "pill",
      tint: 0.52,
      tintTone: "dark",
      frost: 0.28,
      maxDpr: 2,
      fallback: "css",
      respectReducedTransparency: true,
      material: { refraction: 62, dispersion: 1.1, rim: 0.2 },
    });
    return () => glass.destroy();
  }, [resolvedQuality]);

  const splitIndex = useMemo(() => Math.ceil(items.length / 2), [items.length]);
  const groups = primaryAction
    ? [items.slice(0, splitIndex), items.slice(splitIndex)]
    : [items, []];

  const renderDestination = (item: KMobileAppBarItem) => {
    const selected = item.id === selectedId;
    const resolvedLabelVisibility =
      labelVisibility ?? (variant === "labeled" ? "always" : "never");
    const showLabel =
      resolvedLabelVisibility === "always" ||
      (resolvedLabelVisibility === "selected" && selected);
    return (
      <button
        aria-current={selected ? "page" : undefined}
        aria-label={item.label}
        className="k-mobile-app-bar__destination"
        data-selected={selected || undefined}
        disabled={item.disabled}
        key={item.id}
        onClick={() => onSelectionChange(item.id)}
        type="button"
      >
        {renderItem ? (
          renderItem(item, { selected })
        ) : (
          <>
            <span aria-hidden="true" className="k-mobile-app-bar__icon">
              {selected ? (item.selectedIcon ?? item.icon) : item.icon}
            </span>
            {item.badge !== undefined && (
              <span className="k-mobile-app-bar__badge">{item.badge}</span>
            )}
            {showLabel && (
              <span className="k-mobile-app-bar__label">{item.label}</span>
            )}
          </>
        )}
      </button>
    );
  };

  return (
    <nav
      aria-label={label}
      className={["k-mobile-app-bar", className].filter(Boolean).join(" ")}
      data-visibility={visibility}
      data-variant={variant}
      data-label-visibility={labelVisibility}
      data-collapsed={collapsed || undefined}
      {...props}
    >
      <div
        className="k-mobile-app-bar__surface"
        data-quality={resolvedQuality}
        ref={surfaceRef}
      >
        {variant === "contextual" ? (
          <div className="k-mobile-app-bar__contextual">
            {contextualContent}
          </div>
        ) : (
          <>
            <div className="k-mobile-app-bar__group">
              {groups[0].map(renderDestination)}
            </div>
            {primaryAction && (
              <div className="k-mobile-app-bar__primary">{primaryAction}</div>
            )}
            {groups[1].length > 0 && (
              <div className="k-mobile-app-bar__group">
                {groups[1].map(renderDestination)}
              </div>
            )}
          </>
        )}
      </div>
    </nav>
  );
}
