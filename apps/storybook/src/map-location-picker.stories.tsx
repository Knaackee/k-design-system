import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import "@k-design-system/ui/map-location-picker.css";
import { useMemo } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { action } from "storybook/actions";
import { KIcon } from "@k-design-system/ui/primitives/icon";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import {
  KMapLocationPicker,
  type KMapLocation,
} from "@k-design-system/ui/patterns/map-location-picker";
import {
  createMapStyle,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
} from "@k-design-system/ui/maps";
setWorkerUrl(workerUrl);

const addresses: KMapLocation[] = [
  {
    id: "berlin-1",
    label: "Invalidenstraße 44",
    detail: "10115 Berlin · Deutschland",
    position: [13.387, 52.53],
  },
  {
    id: "berlin-2",
    label: "Friedrichstraße 100",
    detail: "10117 Berlin · Deutschland",
    position: [13.388, 52.52],
  },
  {
    id: "berlin-3",
    label: "Torstraße 120",
    detail: "10119 Berlin · Deutschland",
    position: [13.399, 52.529],
  },
];
const search = async (query: string) =>
  addresses.filter((entry) =>
    `${entry.label} ${entry.detail}`
      .toLowerCase()
      .includes(query.toLowerCase()),
  );
type Args = {
  transitionMs: number;
  blur: number;
  bounce: boolean;
  hint: string;
  frameWidth: number;
  locationFailure: boolean;
  customLeading: boolean;
  markerAppearance: "default" | "bare";
};
function Example({ args, dark }: { args: Args; dark: boolean }) {
  const style = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  return (
    <div
      style={{
        width: args.frameWidth || "100%",
        maxWidth: "100%",
        margin: "auto",
      }}
    >
      <KMapLocationPicker
        onPanelOpenChange={action('onPanelOpenChange')}
        mapProps={{
          mapStyle: style,
          center: [13.39, 52.525],
          zoom: 13,
          renderPin:
            args.markerAppearance === "bare"
              ? () => <KIcon name="map-pin" size={44} />
              : undefined,
        }}
        markerAppearance={args.markerAppearance}
        transitionMs={args.transitionMs}
        blur={args.blur}
        bounce={args.bounce}
        hint={args.hint}
        leading={
          args.customLeading ? (
            <span
              role="img"
              aria-label="Beispiel-Logo"
              style={{
                boxSizing: "border-box",
                width: 28,
                height: 28,
                border: "6px solid var(--k-color-brand-primary-accent)",
                borderRadius: 7,
              }}
            />
          ) : undefined
        }
        onSearch={search}
        onReverseGeocode={async (position, signal) => {
          signal.throwIfAborted();
          const nearest = [...addresses].sort(
            (a, b) =>
              Math.hypot(
                a.position[0] - position[0],
                a.position[1] - position[1],
              ) -
              Math.hypot(
                b.position[0] - position[0],
                b.position[1] - position[1],
              ),
          )[0];
          return { ...nearest, position };
        }}
        onLocate={async () => {
          if (args.locationFailure) throw new Error("Fixture: denied");
          return addresses[0];
        }}
        onChange={action("onChange")}
      />
    </div>
  );
}
const meta = {
  title: "Maps/Location Picker",
  parameters: {
    layout: "fullscreen",
    fixtureId: "map-location-picker",
    docs: {
      description: {
        component:
          "KMapLocationPicker als ausgelieferte KDS-Komponente. Suche mit festen Beispieladressen (Berlin, Invalidenstraße, Friedrichstraße, Torstraße); Standort simuliert Invalidenstraße 44 ohne Browserberechtigung. Geocoding und Standortzugriff werden vom Consumer bereitgestellt.",
      },
    },
  },
  args: {
    transitionMs: 700,
    blur: 8,
    bounce: true,
    hint: "Verschiebe den Pin, um deine Position zu präzisieren.",
    frameWidth: 0,
    locationFailure: false,
    customLeading: false,
    markerAppearance: "default",
  },
  argTypes: {
    transitionMs: { control: { type: "range", min: 0, max: 1800, step: 100 } },
    blur: { control: { type: "range", min: 0, max: 16 } },
    bounce: { control: "boolean" },
    hint: { control: "text" },
    frameWidth: { control: false },
    locationFailure: { control: "boolean" },
    customLeading: { control: "boolean" },
    markerAppearance: { control: "radio", options: ["default", "bare"] },
  },
  render: function Render(args, context) {
    return <Example args={args} dark={context.globals.theme === "dark"} />;
  },
} satisfies Meta<Args>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Desktop: Story = {};
export const Mobile: Story = { name: "Mobil", args: { frameWidth: 390 } };
export const CustomLeading: Story = {
  name: "Custom leading",
  args: { customLeading: true },
};
export const BarePin: Story = {
  name: "Bare pin",
  args: { markerAppearance: "bare" },
};
