import type { KOrbitPalette } from "./orbit-draw.js";

export function kOrbitPalette(styles: CSSStyleDeclaration): KOrbitPalette {
  const value = (name: string, fallback: string) =>
    cssValue(styles, name, fallback);
  return {
    nodeSurfaces: {
      neutral: value("--k-color-surface-raised", "white"),
      info: value("--k-color-status-info-background", "white"),
      success: value("--k-color-status-success-background", "white"),
      warning: value("--k-color-status-warning-background", "white"),
      error: value("--k-color-status-error-background", "white"),
    },
    progressWidth: cssNumber(
      styles,
      "--k-component-orbit-progress-line-width",
      cssNumber(styles, "--k-border-width-focus", 2),
    ),
    nodeBorder: value("--k-color-border-default", "gray"),
    surface: value(
      "--k-component-orbit-center-highlight",
      value("--k-color-surface-raised", "white"),
    ),
    track: value(
      "--k-component-orbit-track-color",
      value("--k-color-border-default", "gray"),
    ),
    primary: value(
      "--k-component-orbit-center-base",
      value("--k-color-action-primary-background", "blue"),
    ),
    muted: value(
      "--k-component-orbit-center-rim",
      value("--k-color-text-muted", "gray"),
    ),
    info: value(
      "--k-color-status-info-accent",
      value("--k-color-action-primary-background", "blue"),
    ),
    success: value(
      "--k-color-status-success-accent",
      value("--k-color-action-primary-background", "green"),
    ),
    warning: value(
      "--k-color-status-warning-accent",
      value("--k-color-action-primary-background", "orange"),
    ),
    error: value(
      "--k-color-status-error-accent",
      value("--k-color-action-primary-background", "red"),
    ),
    glow: value(
      "--k-component-orbit-glow-color",
      value("--k-color-action-primary-background", "blue"),
    ),
    shadow: value(
      "--k-component-orbit-center-shadow",
      value("--k-color-text-muted", "gray"),
    ),
    trackWidth: cssNumber(styles, "--k-component-orbit-track-line-width", 1),
    trackOpacity: cssNumber(styles, "--k-component-orbit-track-opacity", 0.45),
    connectionColor: value(
      "--k-component-orbit-connection-color",
      value("--k-color-action-primary-background", "blue"),
    ),
    connectionWidth: cssNumber(
      styles,
      "--k-component-orbit-connection-line-width",
      1,
    ),
    connectionDash: cssNumber(
      styles,
      "--k-component-orbit-connection-dash-length",
      8,
    ),
    connectionGap: cssNumber(
      styles,
      "--k-component-orbit-connection-gap-length",
      6,
    ),
    connectionOpacity: cssNumber(
      styles,
      "--k-component-orbit-connection-opacity",
      0.6,
    ),
    particleSize: cssNumber(
      styles,
      "--k-component-orbit-signal-particle-size",
      8,
    ),
    trailLength: cssNumber(
      styles,
      "--k-component-orbit-signal-trail-length",
      24,
    ),
    pingRadius: cssNumber(styles, "--k-component-orbit-signal-ping-radius", 16),
    glowBlur: cssNumber(styles, "--k-component-orbit-glow-blur", 24),
    glowOpacity: cssNumber(styles, "--k-component-orbit-glow-opacity", 0.3),
    centerRadiusRatio: cssNumber(
      styles,
      "--k-component-orbit-center-radius-ratio",
      0.296,
    ),
    nodeSize: cssNumber(styles, "--k-component-orbit-node-size", 24),
    pulseDuration: cssNumber(
      styles,
      "--k-component-orbit-motion-pulse-duration",
      1800,
    ),
    labelOffset: cssNumber(styles, "--k-component-orbit-node-label-offset", 18),
    labelSize: cssNumber(styles, "--k-component-orbit-node-label-size", 12),
    labelLineHeight: cssNumber(styles, "--k-font-caption-line-height", 16),
  };
}

export function cssNumber(
  styles: CSSStyleDeclaration,
  name: string,
  fallback: number,
): number {
  const value = Number.parseFloat(cssValue(styles, name, String(fallback)));
  return Number.isFinite(value) ? value : fallback;
}

function cssValue(
  styles: CSSStyleDeclaration,
  name: string,
  fallback: string,
  seen = new Set<string>(),
): string {
  if (seen.has(name)) return fallback;
  seen.add(name);
  const raw = styles.getPropertyValue(name).trim();
  const alias = raw.match(/^var\((--[^,)]+)(?:,\s*([^)]+))?\)$/);
  return alias
    ? cssValue(styles, alias[1]!, alias[2]?.trim() || fallback, seen)
    : raw || fallback;
}
