import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import {
  KHapticController,
  type KHapticControllerOptions,
} from "./haptics-controller.js";
export {
  KHapticController,
  kHapticPatterns,
  type KHapticControllerOptions,
  type KHapticCue,
} from "./haptics-controller.js";

const HapticsContext = createContext<KHapticController | null>(null);
export interface KHapticsProviderProps extends KHapticControllerOptions {
  children: ReactNode;
}
export function KHapticsProvider({
  children,
  enabled = false,
  ...options
}: KHapticsProviderProps) {
  const [controller] = useState(
    () => new KHapticController({ ...options, enabled }),
  );
  useEffect(() => {
    controller.setEnabled(enabled);
  }, [controller, enabled]);
  useEffect(() => {
    const visibility = () => controller.setActive(!document.hidden);
    visibility();
    document.addEventListener("visibilitychange", visibility);
    return () => document.removeEventListener("visibilitychange", visibility);
  }, [controller]);
  return (
    <HapticsContext.Provider value={controller}>
      {children}
    </HapticsContext.Provider>
  );
}
export function useOptionalKHaptics(): KHapticController | null {
  return useContext(HapticsContext);
}
export function useKHaptics(): KHapticController {
  const controller = useContext(HapticsContext);
  if (!controller) throw new Error("useKHaptics requires KHapticsProvider");
  return controller;
}
