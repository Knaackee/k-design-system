import { kLocaleCatalog } from "../generated/locales.js";
import type { KDateFormat, KTimeFormat } from "../pickers/date-values.js";
export type KMessageKey = keyof typeof kLocaleCatalog.en.messages;
export type KMessages = Record<KMessageKey, string>;
export interface KLocaleData {
  name: string;
  messages: KMessages;
  months: readonly string[];
  weekdays: readonly string[];
  firstDay: number;
}
export type KLocaleCatalog = Record<string, KLocaleData>;
export interface KLocalizationOptions {
  locale?: string;
  calendarLocale?: string;
  messages?: Partial<KMessages>;
  locales?: KLocaleCatalog;
  dateFormat?: KDateFormat;
  timeFormat?: KTimeFormat;
  timeZone?: string;
}
export const kSupportedLocales = Object.entries(kLocaleCatalog).map(
  ([code, data]) => ({ code, name: data.name }),
);
export { kLocaleCatalog };
export function resolveLocale(
  tag: string,
  custom: KLocaleCatalog = {},
): KLocaleData {
  const catalog: KLocaleCatalog = { ...kLocaleCatalog, ...custom };
  const normalized = tag.replaceAll("_", "-").toLowerCase();
  const match = (key: string) =>
    Object.keys(catalog).find((k) => k.toLowerCase() === key);
  return catalog[match(normalized) ?? match(normalized.split("-")[0]) ?? "en"];
}
export function resolveLocalization(
  options: KLocalizationOptions = {},
  localeOverride?: string,
) {
  const locale = localeOverride ?? options.locale ?? "en";
  const calendarLocale = localeOverride ?? options.calendarLocale ?? locale;
  const data = resolveLocale(locale, options.locales);
  const calendar = resolveLocale(calendarLocale, options.locales);
  return {
    locale,
    calendarLocale,
    calendar,
    messages: {
      ...kLocaleCatalog.en.messages,
      ...data.messages,
      ...options.messages,
    } as KMessages,
    dateFormat: options.dateFormat ?? ("iso" as KDateFormat),
    timeFormat: options.timeFormat ?? ("h24" as KTimeFormat),
    timeZone: options.timeZone ?? "UTC",
  };
}
