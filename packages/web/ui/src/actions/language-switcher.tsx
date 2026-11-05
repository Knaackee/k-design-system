import { useOptionalKHaptics } from "../feedback/haptics.js";
import { useOptionalKSound } from "../feedback/sound.js";
import type { ReactNode } from "react";
import { KMenuButton } from "./menu-button.js";
import { KIcon } from "../primitives/icon.js";

export interface KLanguageOption {
  /** BCP 47 language tag. */
  value: string;
  /** Native language name, e.g. Deutsch or Français. */
  label: string;
  /** Optional decorative flag; never the only language identifier. */
  flag?: ReactNode;
}

export interface KLanguageSwitcherProps {
  value: string;
  onValueChange: (value: string) => void;
  languages: readonly KLanguageOption[];
  label?: string;
  disabled?: boolean;
}

/** The host owns translations, locale application and preference persistence. */
export function KLanguageSwitcher({
  value,
  onValueChange,
  languages,
  label = "Language",
  disabled,
}: KLanguageSwitcherProps) {
  const sound = useOptionalKSound();
  const haptics = useOptionalKHaptics();
  return (
    <KMenuButton
      label={`${label}: ${languages.find((language) => language.value === value)?.label ?? value}`}
      disabled={disabled}
      overflow
      align="end"
      triggerContent={<KIcon name="languages" strokeWidth={1.5} />}
      actions={languages.map((language) => ({
        id: language.value,
        label: language.label,
        iconContent: language.flag,
        checked: language.value === value,
        onSelect: () => {
          if (language.value !== value) {
            void sound?.play("tap");
            haptics?.perform("selection");
          }
          onValueChange(language.value);
        },
      }))}
    />
  );
}
