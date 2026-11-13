import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import { useMemo, type CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KList, KListItem } from "@k-design-system/ui";
import { KMap } from "@k-design-system/ui/patterns/map";
import {
  createMapStyle,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
} from "@k-design-system/ui/maps";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";

setWorkerUrl(workerUrl);

const meta = {
  title: "Patterns/Map Embedded",
  parameters: { fixtureId: "map-embedded" },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

function EmbeddedMap({ dark }: { dark: boolean }) {
  const mapStyle = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  return (
    <KList
      title="Heute"
      separated={false}
      style={
        {
          width: "var(--k-layout-form-width)",
          maxWidth: "100%",
          "--k-map-height": "calc(var(--k-size-hit-target) * 4)",
          "--k-map-min-height": "0",
        } as CSSProperties
      }
    >
      <KMap
        embedded
        mapStyle={mapStyle}
        center={[13.388, 52.517]}
        label="Route zum nächsten Termin"
        interactive={false}
        showZoomControls={false}
        pins={[
          {
            id: "start",
            label: "Start",
            position: [13.387, 52.53],
            icon: "house",
          },
          {
            id: "customer",
            label: "Anna Müller",
            position: [13.394, 52.525],
            icon: "user",
          },
        ]}
        routes={[
          {
            id: "drive",
            coordinates: [
              [13.387, 52.53],
              [13.391, 52.531],
              [13.395, 52.527],
              [13.394, 52.525],
            ],
          },
        ]}
        fitContent
        fitPadding={24}
        fitDurationMs={0}
      />
      <KListItem
        mediaIcon="calendar"
        title="Anna Müller"
        description="Haarschnitt"
        value="09:00"
      />
      <KListItem
        mediaIcon="circle-check"
        title="Leon Fischer"
        description="Bartpflege"
        value="10:30"
      />
    </KList>
  );
}

export const Review: Story = {
  render: (_, context) => (
    <EmbeddedMap dark={context.globals.theme === "dark"} />
  ),
};
