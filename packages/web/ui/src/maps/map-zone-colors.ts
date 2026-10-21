export const mapZonePalette = [
  { name: "red", label: "Rot", light: "#e7000b", dark: "#ff6467" },
  { name: "orange", label: "Orange", light: "#f54900", dark: "#ff8904" },
  { name: "amber", label: "Bernstein", light: "#e17100", dark: "#ffb900" },
  { name: "yellow", label: "Gelb", light: "#d08700", dark: "#fdc700" },
  { name: "lime", label: "Limette", light: "#5ea500", dark: "#9ae600" },
  { name: "green", label: "Grün", light: "#00a63e", dark: "#05df72" },
  { name: "emerald", label: "Smaragd", light: "#009966", dark: "#00d492" },
  { name: "teal", label: "Türkis", light: "#009689", dark: "#00d5be" },
  { name: "cyan", label: "Cyan", light: "#0092b8", dark: "#00d3f2" },
  { name: "sky", label: "Himmelblau", light: "#0084d1", dark: "#00bcff" },
  { name: "blue", label: "Blau", light: "#155dfc", dark: "#51a2ff" },
  { name: "indigo", label: "Indigo", light: "#4f39f6", dark: "#7c86ff" },
  { name: "violet", label: "Violett", light: "#7f22fe", dark: "#a684ff" },
  { name: "purple", label: "Lila", light: "#9810fa", dark: "#c27aff" },
  { name: "fuchsia", label: "Fuchsia", light: "#c800de", dark: "#ed6aff" },
  { name: "pink", label: "Pink", light: "#e60076", dark: "#fb64b6" },
  { name: "rose", label: "Rosé", light: "#ec003f", dark: "#ff637e" },
  { name: "slate", label: "Schiefer", light: "#45556c", dark: "#90a1b9" },
  { name: "gray", label: "Grau", light: "#4a5565", dark: "#99a1af" },
  { name: "zinc", label: "Zink", light: "#52525c", dark: "#9f9fa9" },
  { name: "neutral", label: "Neutral", light: "#525252", dark: "#a1a1a1" },
  { name: "stone", label: "Stein", light: "#57534d", dark: "#a6a09b" },
] as const;

export const defaultMapZoneColor = mapZonePalette[10].light;

export function resolveMapZoneColor(value: string, dark: boolean) {
  const family = mapZonePalette.find(
    (entry) => entry.light === value.toLowerCase(),
  );
  return family ? (dark ? family.dark : family.light) : value;
}

export function mapZoneCssColor(value: string) {
  const family = mapZonePalette.find(
    (entry) => entry.light === value.toLowerCase(),
  );
  return family ? `light-dark(${family.light}, ${family.dark})` : value;
}

export function mapZoneForeground(background: string) {
  const channels = [1, 3, 5].map((index) => {
    const value = Number.parseInt(background.slice(index, index + 2), 16) / 255;
    return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  const luminance =
    0.2126 * (channels[0] ?? 0) +
    0.7152 * (channels[1] ?? 0) +
    0.0722 * (channels[2] ?? 0);
  return (luminance + 0.05) / 0.05 >= 1.05 / (luminance + 0.05)
    ? "#000000"
    : "#ffffff";
}
