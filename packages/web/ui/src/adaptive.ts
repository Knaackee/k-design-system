/**
 * Adaptive resolution (Decision 0010).
 *
 * Resolves the adaptive token axes from the *available window* and the
 * *primary pointer*, so a gallery viewport and a real device receive the same
 * configuration. Explicit overrides win; presets are overrides, not defaults.
 */

export type KDensity = "dense" | "standard" | "spacious";
export type KTypeScale = "compact" | "standard" | "mobile";
export type KInputMode = "pointer" | "touch";
export type KWindowClass =
  "compact" | "medium" | "expanded" | "large" | "extra-large";

export interface KAdaptiveConfiguration {
  density: KDensity;
  typeScale: KTypeScale;
  inputMode: KInputMode;
  windowClass: KWindowClass;
}

export interface KAdaptiveEnvironment {
  /** Available width in CSS px of the region the app renders into. */
  width: number;
  /** True when the primary pointer is coarse (finger). */
  coarsePointer: boolean;
}

export type KAdaptiveOverrides = Partial<KAdaptiveConfiguration>;

export function kWindowClassForWidth(width: number): KWindowClass {
  if (width < 600) return "compact";
  if (width < 840) return "medium";
  if (width < 1200) return "expanded";
  if (width < 1600) return "large";
  return "extra-large";
}

export function resolveKAdaptive(
  environment: KAdaptiveEnvironment,
  overrides: KAdaptiveOverrides = {},
): KAdaptiveConfiguration {
  const windowClass =
    overrides.windowClass ?? kWindowClassForWidth(environment.width);
  const inputMode =
    overrides.inputMode ?? (environment.coarsePointer ? "touch" : "pointer");
  // Parity rule: the type ramp follows the window class only. Tablet and
  // desktop share one ramp; mobile Web and the mobile app share another.
  // Input mode changes hit targets, never typography.
  const typeScale =
    overrides.typeScale ?? (windowClass === "compact" ? "mobile" : "standard");
  return {
    density: overrides.density ?? "standard",
    typeScale,
    inputMode,
    windowClass,
  };
}

/** Named overrides. Prefer the resolver; use these to pin a product context. */
export const kAdaptivePresets = {
  dashboard: { density: "dense", typeScale: "compact", inputMode: "pointer" },
  desktopApp: { density: "standard", typeScale: "standard" },
  mobileApp: { density: "standard", typeScale: "mobile", inputMode: "touch" },
  marketing: { density: "spacious", typeScale: "standard" },
} as const satisfies Record<string, KAdaptiveOverrides>;

export function kAdaptiveAttributes(
  configuration: KAdaptiveConfiguration,
): Record<string, string> {
  return {
    "data-density": configuration.density,
    "data-type-scale": configuration.typeScale,
    "data-input-mode": configuration.inputMode,
    "data-window-class": configuration.windowClass,
  };
}

/**
 * Keeps `element`'s adaptive data attributes in sync with its width and the
 * primary pointer. Returns a disposer. Width is observed on the element itself
 * (not the device), so embedded apps and gallery frames resolve correctly.
 */
export function applyKAdaptive(
  element: HTMLElement = document.documentElement,
  overrides: KAdaptiveOverrides = {},
  onChange?: (configuration: KAdaptiveConfiguration) => void,
): () => void {
  const coarse = window.matchMedia("(pointer: coarse)");
  const update = () => {
    const width =
      element === document.documentElement
        ? window.innerWidth
        : element.getBoundingClientRect().width;
    const configuration = resolveKAdaptive(
      { width, coarsePointer: coarse.matches },
      overrides,
    );
    for (const [name, value] of Object.entries(
      kAdaptiveAttributes(configuration),
    ))
      if (element.getAttribute(name) !== value)
        element.setAttribute(name, value);
    onChange?.(configuration);
  };
  update();
  const observer = new ResizeObserver(update);
  observer.observe(element);
  coarse.addEventListener("change", update);
  return () => {
    observer.disconnect();
    coarse.removeEventListener("change", update);
  };
}

/** Text scale from which rows stack instead of placing controls side by side. */
export const kLargeTextScale = 1.3;

/**
 * Applies an accessibility text scale (e.g. from a user setting) the way
 * Flutter receives the system text scale: sets `--k-text-scale` (capped per
 * role by the components) and `data-text-large` from 1.3x so layouts stack.
 */
export function setKTextScale(
  element: HTMLElement = document.documentElement,
  scale = 1,
): void {
  element.style.setProperty("--k-text-scale", String(scale));
  element.toggleAttribute("data-text-large", scale >= kLargeTextScale);
}
