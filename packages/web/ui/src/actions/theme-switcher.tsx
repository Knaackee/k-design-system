import { useOptionalKHaptics } from "../feedback/haptics.js";
import { useOptionalKSound } from "../feedback/sound.js";
import { KButton } from "../primitives/button.js";
import {
  KAnimatedIcon,
  type KAnimatedIconSpring,
  type KAnimatedIconReducedMotion,
} from "../primitives/animated-icon.js";
import type { KIconName } from "../primitives/icon.js";

export type KThemeMode = "light" | "dark" | "system";
export interface KThemeSwitcherProps {
  /** Consumer owns theme application and persistence. */
  value: KThemeMode;
  onValueChange: (value: KThemeMode) => void;
  label?: string;
  labels?: Partial<Record<KThemeMode, string>>;
  icons?: Partial<Record<KThemeMode, KIconName>>;
  disabled?: boolean;
  spring?: KAnimatedIconSpring;
  reducedMotion?: KAnimatedIconReducedMotion;
}
const modes: KThemeMode[] = ["light", "dark", "system"];
const defaultLabels = { light: "Light", dark: "Dark", system: "System" };
const defaultIcons: Record<KThemeMode, KIconName> = {
  light: "sun",
  dark: "moon",
  system: "monitor",
};

/** Cycles Light → Dark → System; the consumer applies and persists the theme. */
export function KThemeSwitcher({
  value,
  onValueChange,
  label = "Appearance",
  labels,
  icons,
  disabled,
  spring,
  reducedMotion,
}: KThemeSwitcherProps) {
  const names = { ...defaultLabels, ...labels };
  const symbols = { ...defaultIcons, ...icons };
  const sound = useOptionalKSound();
  const haptics = useOptionalKHaptics();
  return (
    <KButton
      aria-label={`${label}: ${names[value]}`}
      title={`${label}: ${names[value]}`}
      variant="ghost"
      className="k-icon-button"
      disabled={disabled}
      onClick={() => {
        void sound?.play("switch");
        haptics?.perform("selection");
        onValueChange(modes[(modes.indexOf(value) + 1) % modes.length]!);
      }}
    >
      <KAnimatedIcon
        name={symbols[value]}
        spring={spring}
        reducedMotion={reducedMotion}
      />
    </KButton>
  );
}
