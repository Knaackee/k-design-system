import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import {
  KSoundController,
  type KSoundControllerOptions,
} from "./sound-controller.js";
export { KSoundController } from "./sound-controller.js";
export type {
  KSoundControllerOptions,
  KSoundPlayer,
} from "./sound-controller.js";
export { kSoundSources, type KSoundCue } from "./sound-cues.js";

const SoundContext = createContext<KSoundController | null>(null);
export interface KSoundProviderProps extends KSoundControllerOptions {
  children: ReactNode;
}
export function KSoundProvider({
  children,
  enabled = false,
  volume = 0.25,
  ...options
}: KSoundProviderProps) {
  const [controller] = useState(
    () => new KSoundController({ ...options, enabled, volume }),
  );
  useEffect(() => {
    controller.setEnabled(enabled);
  }, [controller, enabled]);
  useEffect(() => {
    controller.setVolume(volume);
  }, [controller, volume]);
  useEffect(() => {
    const unlock = () => {
      void controller.unlock();
    };
    const visibility = () => controller.setActive(!document.hidden);
    visibility();
    document.addEventListener("pointerdown", unlock, { passive: true });
    document.addEventListener("keydown", unlock);
    document.addEventListener("visibilitychange", visibility);
    return () => {
      document.removeEventListener("pointerdown", unlock);
      document.removeEventListener("keydown", unlock);
      document.removeEventListener("visibilitychange", visibility);
      controller.dispose();
    };
  }, [controller]);
  return (
    <SoundContext.Provider value={controller}>{children}</SoundContext.Provider>
  );
}
export function useOptionalKSound(): KSoundController | null {
  return useContext(SoundContext);
}
export function useKSound(): KSoundController {
  const controller = useContext(SoundContext);
  if (!controller) throw new Error("useKSound requires KSoundProvider");
  return controller;
}
export interface KSoundToggleProps {
  enabled: boolean;
  onEnabledChange: (enabled: boolean) => void;
  labelEnable?: string;
  labelDisable?: string;
  disabled?: boolean;
}
/** An ordinary public icon button; persistence is owned by the consumer. */
export function KSoundToggle({
  enabled,
  onEnabledChange,
  labelEnable = "Enable sounds",
  labelDisable = "Mute sounds",
  disabled,
}: KSoundToggleProps) {
  return (
    <KIconButton
      icon={enabled ? "volume-2" : "volume-off"}
      label={enabled ? labelDisable : labelEnable}
      aria-pressed={enabled}
      disabled={disabled}
      onClick={() => onEnabledChange(!enabled)}
    />
  );
}
