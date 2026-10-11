import { KIcon, type KIconName, type KIconProps } from "../primitives/icon.js";

export type KWeatherCondition =
  | "clear"
  | "partly_cloudy"
  | "cloudy"
  | "fog"
  | "drizzle"
  | "rain"
  | "snow"
  | "thunderstorm";

/** Stable semantic names shared with Flutter; weather providers remain host-owned. */
export function kWeatherIconName(
  condition: KWeatherCondition,
  period: "day" | "night" = "day",
): KIconName {
  switch (condition) {
    case "clear":
      return period === "night" ? "moon" : "sun";
    case "partly_cloudy":
      return period === "night" ? "cloud-moon" : "cloud-sun";
    case "cloudy":
      return "cloud";
    case "fog":
      return "cloud-fog";
    case "drizzle":
      return "cloud-drizzle";
    case "rain":
      return "cloud-rain";
    case "snow":
      return "cloud-snow";
    case "thunderstorm":
      return "cloud-lightning";
  }
}

export interface KWeatherIconProps extends Omit<KIconProps, "name"> {
  condition: KWeatherCondition;
  period?: "day" | "night";
}

export function KWeatherIcon({
  condition,
  period = "day",
  size = 24,
  ...props
}: KWeatherIconProps) {
  return (
    <KIcon {...props} size={size} name={kWeatherIconName(condition, period)} />
  );
}
