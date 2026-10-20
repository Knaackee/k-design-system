import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import { useMemo } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useArgs } from "storybook/preview-api";
import { action } from "storybook/actions";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import {
  KMap,
  type KMapProps,
  type KMapPin,
  type KMapRoute,
} from "@k-design-system/ui/patterns/map";
import {
  createMapStyle,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
} from "@k-design-system/ui/maps";

setWorkerUrl(workerUrl);
const pins: KMapPin[] = [
  {
    id: "start",
    label: "Start · Invalidenstraße",
    position: [13.387, 52.53],
    icon: "house",
  },
  {
    id: "customer",
    label: "Kundentermin · Mitte",
    position: [13.394, 52.525],
    icon: "user",
  },
  {
    id: "end",
    label: "Ziel · Friedrichstraße",
    position: [13.388, 52.52],
    icon: "flag",
  },
];
// Illustrative geometry only; the host supplies actual routing-server results.
const routes: KMapRoute[] = [
  {
    id: "drive",
    coordinates: [
      [13.387, 52.53],
      [13.391, 52.531],
      [13.395, 52.527],
      [13.394, 52.525],
    ],
  },
  {
    id: "walk",
    coordinates: [
      [13.394, 52.525],
      [13.39, 52.523],
      [13.388, 52.52],
    ],
    dashed: true,
  },
];
const logo = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" fill="#f7fee7"/><path d="M18 14v36m28-36L18 32l28 18" fill="none" stroke="#4d7c0f" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/></svg>')}`;
type Args = Omit<KMapProps, "mapStyle"> & {
  moveAccepted: boolean;
  moveDelayMs: number;
};
function Example({
  args,
  dark,
  update,
}: {
  args: Args;
  dark: boolean;
  update: (args: Partial<Args>) => void;
}) {
  const style = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  return (
    <KMap
      {...args}
      mapStyle={style}
      onPinClick={action("onPinClick")}
      onSelectionChange={(id) => {
        update({ selectedPinId: id });
        action("onSelectionChange")(id);
      }}
      onPinDragStart={action("onPinDragStart")}
      onPinDrag={action("onPinDrag")}
      onPinDragEnd={action("onPinDragEnd")}
      onPinMove={async (event) => {
        action("onPinMove")(event);
        if (args.moveDelayMs)
          await new Promise((resolve) => setTimeout(resolve, args.moveDelayMs));
        if (!args.moveAccepted) return false;
        update({
          pins: args.pins?.map((pin) =>
            pin.id === event.id ? { ...pin, position: event.position } : pin,
          ),
        });
        return true;
      }}
    />
  );
}
const meta = {
  title: "Maps/Map Overlays",
  parameters: {
    layout: "fullscreen",
    fixtureId: "map-overlays",
    docs: {
      description: {
        component:
          "KMap: kontrollierbare Pins und übergebene Routengeometrie. Koordinaten: [Längengrad, Breitengrad]. Keine Routenberechnung. CSS --k-map-route-color überschreibt den geerbten Markenakzent; Pinfarbe und Größe auch je Pin konfigurierbar.",
      },
    },
  },
  args: {
    center: [13.391, 52.525] as [number, number],
    zoom: 14,
    pins,
    routes: [],
    selectedPinId: null,
    selectedRouteId: null,
    fitContent: true,
    fitPadding: 80,
    interactive: true,
    showZoomControls: true,
    pinDrag: {
      activation: "drag",
      longPressMs: 400,
      scale: 1.15,
      durationMs: 160,
    },
    moveAccepted: true,
    moveDelayMs: 0,
  },
  argTypes: {
    pins: { control: "object" },
    routes: { control: "object" },
    pinDrag: {
      control: "object",
      description:
        "Öffentliche KMap-Optionen: activation, longPressMs, scale und durationMs. Je Pin über drag überschreibbar.",
    },
    moveAccepted: {
      control: "boolean",
      table: { category: "Host-Antwort simulieren" },
    },
    moveDelayMs: {
      control: { type: "range", min: 0, max: 2000, step: 100 },
      table: { category: "Host-Antwort simulieren" },
    },
    selectedPinId: {
      control: "select",
      options: [null, "start", "customer", "end"],
    },
    selectedRouteId: { control: "select", options: [null, "drive", "walk"] },
    fitContent: { control: "boolean" },
    fitPadding: { control: { type: "range", min: 0, max: 150 } },
    interactive: { control: "boolean" },
    showZoomControls: { control: "boolean" },
  },
  render: function Render(args, context) {
    const [, update] = useArgs<Args>();
    return (
      <Example
        args={args}
        dark={context.globals.theme === "dark"}
        update={update}
      />
    );
  },
} satisfies Meta<Args>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Pins: Story = {};
export const CustomPins: Story = {
  name: "Consumer-Inhalte",
  args: {
    pins: pins.map((pin) => ({ ...pin, size: 56 })),
    renderPin: (pin, { selected }) => (
      <svg viewBox="0 0 56 56" width="100%" height="100%" aria-hidden="true">
        <circle
          cx="28"
          cy="28"
          r="24"
          fill="var(--k-color-surface-raised)"
          stroke="currentColor"
          strokeWidth={selected ? 5 : 2}
        />
        <text
          x="28"
          y="34"
          textAnchor="middle"
          fill="currentColor"
          fontSize="18"
          fontFamily="var(--k-font-family)"
          fontWeight="700"
        >
          {pin.id === "start" ? "AB" : pin.id === "customer" ? "CD" : "EF"}
        </text>
      </svg>
    ),
  },
  parameters: {
    docs: {
      description: {
        story:
          "Freier renderPin-Slot: hier ein Consumer-SVG, alternativ z. B. eine vom Consumer geladene Rive-Komponente. Auswahlzustand wird übergeben. Nur visuelle Inhalte, keine verschachtelten Buttons. KMap übernimmt den zugänglichen Button, Fokus und Drag-Verhalten.",
      },
    },
  },
};
export const LogoPins: Story = {
  name: "Logo-Pins",
  args: {
    pins: pins.map((pin, index) => ({
      ...pin,
      imageUrl: logo,
      size: 48,
      shape: (["circle", "square", "pin"] as const)[index],
    })),
  },
};
export const Routes: Story = { name: "Routen", args: { pins: [], routes } };
export const PinsAndRoute: Story = { name: "Pins mit Route", args: { routes } };
export const TrafficSegments: Story = {
  name: "Verkehr · Routensegmente",
  args: {
    routes: [
      {
        ...routes[0],
        width: 7,
        segments: [
          { id: "clear", startIndex: 0, endIndex: 1, traffic: "free" },
          { id: "slow", startIndex: 1, endIndex: 2, traffic: "slow" },
          { id: "jam", startIndex: 2, endIndex: 3, traffic: "congested" },
        ],
      },
      routes[1],
    ],
  },
};
export const DraggablePins: Story = {
  name: "Pins verschieben",
  args: {
    pins: pins.map((pin) => ({ ...pin, draggable: true })),
    fitContent: false,
  },
  parameters: {
    docs: {
      description: {
        story:
          "Pins ziehen oder fokussieren und mit Pfeiltasten verschieben (Shift: größerer Schritt). onPinMove meldet die neue Position; der Host übernimmt sie kontrolliert. Eine Route wird dadurch nicht automatisch neu berechnet.",
      },
    },
  },
};
export const LongPressPins: Story = {
  name: "Pins · Long Press",
  args: {
    pins: pins.map((pin) => ({ ...pin, draggable: true })),
    fitContent: false,
    pinDrag: {
      activation: "longPress",
      longPressMs: 400,
      scale: 1.2,
      durationMs: 180,
    },
    moveDelayMs: 600,
  },
};
