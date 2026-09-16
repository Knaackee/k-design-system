import { createContext, useContext, type ReactNode } from "react";
import { resolveLocalization, type KLocalizationOptions } from "./data.js";
const Context = createContext<KLocalizationOptions>({});
export interface KLocalizationProviderProps extends KLocalizationOptions {
  children: ReactNode;
}
export function KLocalizationProvider({
  children,
  ...options
}: KLocalizationProviderProps) {
  const parent = useContext(Context);
  const value: KLocalizationOptions = {
    locale: options.locale ?? parent.locale,
    calendarLocale: options.calendarLocale ?? parent.calendarLocale,
    dateFormat: options.dateFormat ?? parent.dateFormat,
    timeFormat: options.timeFormat ?? parent.timeFormat,
    timeZone: options.timeZone ?? parent.timeZone,
    messages: { ...parent.messages, ...options.messages },
    locales: { ...parent.locales, ...options.locales },
  };
  return <Context.Provider value={value}>{children}</Context.Provider>;
}
export function useKLocalization(localeOverride?: string) {
  return resolveLocalization(useContext(Context), localeOverride);
}
