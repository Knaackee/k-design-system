import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import "@k-design-system/ui/map-day-view.css";
import { useMemo } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useArgs } from "storybook/preview-api";
import { action } from "storybook/actions";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import { KMap } from "@k-design-system/ui/patterns/map";
import {
  KMapDayView,
  KMapDaySheetController,
  type KMapDayPanelState,
} from "@k-design-system/ui/patterns/map-day-view";
import { KIcon } from "@k-design-system/ui/primitives/icon";
import { KButton, KInline, KList, KListItem, KText } from "@k-design-system/ui";
import {
  createMapStyle,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
} from "@k-design-system/ui/maps";
import { dayEntries, dayTime } from "./map-day-data";
import "./map-day.css";
setWorkerUrl(workerUrl);

type Args = {
  customPanel?: boolean;
  now: number;
  delay: number;
  title: string;
  dayLabel: string;
  selectedItemId: string;
  panelState: KMapDayPanelState;
  panelWidth: number;
  compactHeight: number;
  mediumHeight: number;
  expandedHeight: number;
  showCurrentTime: boolean;
  showForecasts: boolean;
  showActions: boolean;
  presentation: "auto" | "sheet" | "sidebar";
  frameWidth: number;
};
function DayExample({
  args,
  theme,
  update,
}: {
  args: Args;
  theme: string;
  update: (values: Partial<Args>) => void;
}) {
  const mapStyle = useMemo(
    () =>
      createMapStyle({
        tokens: theme === "dark" ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS,
      }),
    [theme],
  );
  const sheetController = useMemo(() => new KMapDaySheetController(), []);
  const focusSheet = (source: "list" | "map", id: string) => {
    void sheetController.animateTo(0.45);
    action(source === "list" ? "onItemClick" : "onMapItemClick")(id);
  };
  const items = dayEntries.map((entry) => ({
    ...entry,
    expectedStart:
      entry.start > args.now && entry.kind === "stop"
        ? entry.start + args.delay
        : undefined,
    actions:
      args.showActions && ["anna", "leo"].includes(entry.id)
        ? [{ id: "details", label: "Details", icon: "arrow-right" as const }]
        : undefined,
  }));
  return (
    <div
      style={{
        width: args.frameWidth ? `${args.frameWidth}px` : "100%",
        maxWidth: args.frameWidth ? undefined : "100%",
      }}
    >
      <KMapDayView
        items={items}
        currentTime={args.now}
        title={args.title}
        dayLabel={args.dayLabel}
        selectedItemId={args.selectedItemId}
        panelState={args.panelState}
        panelHeights={[
          args.compactHeight,
          args.mediumHeight,
          args.expandedHeight,
        ]}
        panelWidth={args.panelWidth}
        presentation={args.presentation}
        panelLayout={args.customPanel ? "docked" : "floating"}
        renderPanelHeader={
          args.customPanel
            ? ({ isSheet, expanded, toggleExpanded }) =>
                isSheet ? (
                  <KInline gap="control">
                    <KText variant="heading5">{args.dayLabel}</KText>
                    <KButton variant="secondary" onClick={toggleExpanded}>
                      {expanded ? "Karte zeigen" : "Ganzer Tag"}
                    </KButton>
                  </KInline>
                ) : null
            : undefined
        }
        renderPanelBody={
          args.customPanel
            ? ({ selectedItemId, onItemClick }) => (
                <KList title="Tagesablauf">
                  {items.map((item) => (
                    <KListItem
                      key={item.id}
                      title={item.title}
                      description={item.detail}
                      selected={selectedItemId === item.id}
                      onClick={() => onItemClick(item.id)}
                      disclosure={false}
                    />
                  ))}
                </KList>
              )
            : undefined
        }
        showCurrentTime={args.showCurrentTime}
        showForecasts={args.showForecasts}
        sheetController={sheetController}
        ensureSelectedItemVisible
        summary={
          <>
            <span>2 Kunden</span>
            <span>1 privater Termin</span>
            <span>09:00 – 12:35</span>
          </>
        }
        description="Planposition, kein Live-Standort. Die Prognose verändert keine bestätigten Zeiten."
        footer={
          <>
            <KIcon name="house" />
            <span>
              Tagesende <strong>{dayTime(755 + args.delay)}</strong> · geplant
              12:35
            </span>
          </>
        }
        onSelectionChange={(id) => {
          update({ selectedItemId: id });
          action("onSelectionChange")(id);
        }}
        onItemClick={(id) => focusSheet("list", id)}
        onMapItemClick={(id) => focusSheet("map", id)}
        onSheetFractionChanged={action("onSheetFractionChanged")}
        onPanelStateChange={(state) => {
          update({ panelState: state });
          action("onPanelStateChange")(state);
        }}
        onAction={action("onAction")}
        renderMap={({ selectedItemId }) => {
          const selected = items.find((item) => item.id === selectedItemId);
          return (
            <KMap
              mapStyle={mapStyle}
              center={selected?.center ?? [13.399, 52.535]}
              zoom={13.5}
              cameraTransitionMs={350}
              label="Karte deines Tages"
              onViewChange={action("onMapViewChange")}
            />
          );
        }}
      />
    </div>
  );
}
const meta = {
  title: "Maps/Day view",
  parameters: { layout: "fullscreen" },
  args: {
    now: 560,
    delay: 5,
    title: "Dein Tag unterwegs",
    dayLabel: "Dienstag, 20. Oktober",
    selectedItemId: "drive-1",
    panelState: 1,
    panelWidth: 404,
    compactHeight: 28,
    mediumHeight: 62,
    expandedHeight: 91,
    showCurrentTime: true,
    showForecasts: true,
    showActions: true,
    presentation: "auto",
    frameWidth: 0,
  },
  argTypes: {
    now: {
      name: "Aktuelle Zeit · Minuten ab Mitternacht",
      control: { type: "range", min: 535, max: 760, step: 1 },
    },
    delay: {
      name: "Erwartete Verspätung in Minuten",
      control: { type: "range", min: 0, max: 60, step: 5 },
    },
    selectedItemId: {
      control: "select",
      options: dayEntries.map((item) => item.id),
    },
    panelState: { control: "inline-radio", options: [0, 1, 2] },
    panelWidth: { control: { type: "range", min: 280, max: 460, step: 4 } },
    compactHeight: { control: { type: "range", min: 20, max: 40, step: 1 } },
    mediumHeight: { control: { type: "range", min: 45, max: 70, step: 1 } },
    expandedHeight: { control: { type: "range", min: 75, max: 98, step: 1 } },
    presentation: {
      control: "inline-radio",
      options: ["auto", "sidebar", "sheet"],
    },
    frameWidth: { table: { disable: true } },
  },
  render: function Render(args, context) {
    const [, update] = useArgs();
    return (
      <DayExample
        args={args}
        theme={String(context.globals.theme)}
        update={update}
      />
    );
  },
} satisfies Meta<Args>;
export default meta;
export const Day: StoryObj<typeof meta> = {};
export const Tablet: StoryObj<typeof meta> = {
  args: { frameWidth: 1024, presentation: "sidebar" },
  name: "Tablet · rechte Seitenleiste",
};
export const Mobile: StoryObj<typeof meta> = {
  args: { frameWidth: 390, presentation: "sheet" },
  name: "Mobil · Bottom-Sheet",
};
export const CustomDockedPanel: StoryObj<typeof meta> = {
  args: { customPanel: true, frameWidth: 1024, presentation: "sidebar" },
  name: "Custom panel · docked sidebar",
};
export const CustomSheetPanel: StoryObj<typeof meta> = {
  args: { customPanel: true, frameWidth: 390, presentation: "sheet" },
  name: "Custom panel · accessible sheet",
};
