import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KPresentationMap,
  KWeatherIcon,
  type KWeatherCondition,
} from "@k-design-system/ui";

const conditions: KWeatherCondition[] = [
  "clear",
  "partly_cloudy",
  "cloudy",
  "fog",
  "drizzle",
  "rain",
  "snow",
  "thunderstorm",
];
function Review() {
  return (
    <div
      style={{
        maxWidth: 720,
        margin: "auto",
        padding: "var(--k-space-control-gap)",
      }}
    >
      <h2>Wetter-Symbole</h2>
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: "var(--k-space-control-gap)",
        }}
      >
        {conditions.map((condition) => (
          <div key={condition}>
            <KWeatherIcon
              condition={condition}
              period="day"
              size={32}
              label={condition}
            />
            <KWeatherIcon
              condition={condition}
              period="night"
              size={32}
              label={`${condition}, night`}
            />
            <p>{condition}</p>
          </div>
        ))}
      </div>
      <KPresentationMap
        title="Brandenburger Tor"
        latitude={52.5163}
        longitude={13.3777}
        description="Die Karte wird erst nach Aktivierung geladen."
        loadLabel="Karte laden"
        openLabel="Karte öffnen"
        onOpen={() =>
          window.open(
            "https://www.openstreetmap.org/?mlat=52.5163&mlon=13.3777#map=16/52.5163/13.3777",
            "_blank",
            "noopener,noreferrer",
          )
        }
      />
    </div>
  );
}
const meta = {
  title: "Patterns/Chat Presentations/Data",
  component: Review,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof Review>;
export default meta;
export const ReviewData: StoryObj<typeof meta> = {};
