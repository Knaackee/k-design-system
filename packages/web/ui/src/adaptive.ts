/**
 * Adaptive resolution (Decision 0010).
 *
 * Resolves the adaptive token axes from the *available window* and the
 * *primary pointer*, so a gallery viewport and a real device receive the same
 * configuration. Explicit overrides win; presets are overrides, not defaults.
 */

export type KDensity = "dense" | "standard" | "spacious";
export type KTypeScale = "compact" | "standard" | "mobile" | "apple";
export type KInputMode = "pointer" | "touch";
export type KWindowClass =
  "compact" | "medium" | "expanded" | "large" | "extra-large";
/**
 * Motion style (Decision 0011): `apple` calm springs, `expressive`
 * Material Expressive-like springs with bounce, `reduced` short fades
 * without movement (forced by `prefers-reduced-motion: reduce`).
 */
export type KMotionStyle = "apple" | "expressive" | "reduced";
/** Style preset (Decision 0014): structure and rhythm, not colours. */
export type KStyle = "linear" | "apple" | "material";

export interface KAdaptiveConfiguration {
  density: KDensity;
  typeScale: KTypeScale;
  inputMode: KInputMode;
  windowClass: KWindowClass;
  motion: KMotionStyle;
  style: KStyle;
}

export interface KAdaptiveEnvironment {
  /** Available width in CSS px of the region the app renders into. */
  width: number;
  /** True when the primary pointer is coarse (finger). */
  coarsePointer: boolean;
  /** True when the person asked the system to reduce motion. */
  reduceMotion?: boolean;
  /** True on iPhone and iPad: the default style is then `apple`. */
  appleTouch?: boolean;
  /** True on Android: the default style is then `material`. */
  android?: boolean;
}

/** Android phone or tablet. */
export function kIsAndroid(): boolean {
  return (
    typeof navigator !== "undefined" && /Android/.test(navigator.userAgent)
  );
}

/** iPhone or iPad (iPadOS reports a Mac with touch). */
export function kIsAppleTouch(): boolean {
  if (typeof navigator === "undefined") return false;
  return (
    /iPhone|iPad|iPod/.test(navigator.userAgent) ||
    (/Macintosh/.test(navigator.userAgent) && navigator.maxTouchPoints > 1)
  );
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
  // Platform-native default (Decision 0014): Apple devices get the Apple
  // style, Android Material 3 Expressive, desktops the productivity style.
  const style: KStyle =
    overrides.style ??
    (environment.appleTouch
      ? "apple"
      : environment.android
        ? "material"
        : "linear");
  // The Apple style uses the iOS/iPadOS ramp on phones and tablets
  // (Decision 0014); desktops keep the standard ramp.
  const typeScale: KTypeScale =
    overrides.typeScale ??
    (style === "apple" &&
    (windowClass === "compact" || windowClass === "medium")
      ? "apple"
      : windowClass === "compact"
        ? "mobile"
        : "standard");
  // The system setting always wins: an app may pick a motion style, never
  // more motion than the person asked for.
  // Material pairs with expressive springs unless the app chose a style.
  const motion: KMotionStyle = environment.reduceMotion
    ? "reduced"
    : (overrides.motion ?? (style === "material" ? "expressive" : "apple"));
  return {
    density: overrides.density ?? "standard",
    typeScale,
    inputMode,
    windowClass,
    motion,
    style,
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
    "data-motion": configuration.motion,
    "data-style": configuration.style,
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
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
  const update = () => {
    const width =
      element === document.documentElement
        ? window.innerWidth
        : element.getBoundingClientRect().width;
    const configuration = resolveKAdaptive(
      {
        width,
        coarsePointer: coarse.matches,
        reduceMotion: reduce.matches,
        appleTouch: kIsAppleTouch(),
        android: kIsAndroid(),
      },
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
  reduce.addEventListener("change", update);
  return () => {
    observer.disconnect();
    coarse.removeEventListener("change", update);
    reduce.removeEventListener("change", update);
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

/** What moves (Decision 0011). Components pick a role, never a duration. */
export type KMotionRole =
  "feedback" | "control" | "enter" | "exit" | "page" | "attention";

export interface KMotionSpec {
  /** Time until the spring rests, in ms: the duration to animate over. */
  settle: number;
  /** The spring sampled as a CSS `linear()` easing. */
  easing: string;
  /** 1 = full movement, 0 = fade only (reduced). Scale offsets with it. */
  distance: number;
}

/**
 * Resolved motion of a role for script animations (Web Animations API).
 * CSS uses `var(--k-motion-<role>-settle)` and `var(--k-motion-<role>-easing)`.
 */
export function kMotion(
  role: KMotionRole,
  element: Element = document.documentElement,
): KMotionSpec {
  const style = getComputedStyle(element);
  const read = (name: string) =>
    style.getPropertyValue(`--k-motion-${role}-${name}`).trim();
  // Browsers may serialise a duration as `736ms` or `0.736s`.
  const settle = read("settle");
  return {
    settle:
      (Number.parseFloat(settle) || 0) *
      (settle.endsWith("ms") || !settle.endsWith("s") ? 1 : 1000),
    easing: read("easing") || "ease",
    distance: Number.parseFloat(read("distance") || "1"),
  };
}
