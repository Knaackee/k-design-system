import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import { type CSSProperties, useMemo, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useArgs } from "storybook/preview-api";
import { action } from "storybook/actions";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import {
  KMapZoneEditor,
  type KMapPostalArea,
  type KMapZone,
  type KMapZoneUndoAction,
} from "@k-design-system/ui/editors";
import {
  createMapStyle,
  DARK_MAP_TOKENS,
  LIGHT_MAP_TOKENS,
} from "@k-design-system/ui/maps";

import {
  KAdaptiveDialog,
  KButton,
  KIconButton,
  KSnackbar,
  KToastViewport,
} from "@k-design-system/ui";

setWorkerUrl(workerUrl);

const berlinZones: KMapZone[] = [
  {
    id: "zone-berlin-west",
    name: "Westliche Termine",
    color: "#155dfc",
    kind: "polygon",
    settings: {
      travelCost: { kind: "per-kilometer", amount: 0.7, currency: "EUR" },
      surcharge: { amount: 5, currency: "EUR" },
    },
    coordinates: [
      [13.318, 52.49],
      [13.332, 52.49],
      [13.332, 52.5],
      [13.318, 52.5],
    ],
  },
  {
    id: "zone-berlin-center",
    name: "Mitte",
    color: "#00a63e",
    kind: "polygon",
    settings: {
      travelCost: { kind: "flat-rate", amount: 12, currency: "EUR" },
      availability: {
        kind: "recurring",
        rrule: "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYMONTH=10,11,12",
        startDate: "2026-10-19",
        timeZone: "Europe/Berlin",
      },
    },
    coordinates: [
      [13.382, 52.515],
      [13.397, 52.515],
      [13.397, 52.526],
      [13.382, 52.526],
    ],
  },
  {
    id: "zone-berlin-east",
    name: "Östliche Termine",
    color: "#e7000b",
    kind: "polygon",
    coordinates: [
      [13.43, 52.525],
      [13.446, 52.525],
      [13.446, 52.536],
      [13.43, 52.536],
    ],
  },
];

const adjacentZones: KMapZone[] = [
  {
    id: "adjacent-west",
    name: "West",
    color: "#155dfc",
    kind: "polygon",
    coordinates: [
      [13.385, 52.513],
      [13.397, 52.513],
      [13.397, 52.528],
      [13.385, 52.528],
    ],
    settings: {
      travelCost: { kind: "per-kilometer", amount: 0.7, currency: "EUR" },
    },
  },
  {
    id: "adjacent-east",
    name: "Ost",
    color: "#00a63e",
    kind: "polygon",
    coordinates: [
      [13.397, 52.513],
      [13.409, 52.513],
      [13.409, 52.528],
      [13.397, 52.528],
    ],
    settings: { travelCost: { kind: "free" } },
  },
];

const propertyOptions = {
  defaultWorkingHours: Array.from({ length: 7 }, (_, index) => ({
    day: index + 1,
    intervals: index < 5 ? [{ start: "09:00", end: "17:00" }] : [],
  })),
  weekdayOptions: [
    { value: "MO", label: "Montag", shortLabel: "Mo" },
    { value: "TU", label: "Dienstag", shortLabel: "Di" },
    { value: "WE", label: "Mittwoch", shortLabel: "Mi" },
    { value: "TH", label: "Donnerstag", shortLabel: "Do" },
    { value: "FR", label: "Freitag", shortLabel: "Fr" },
    { value: "SA", label: "Samstag", shortLabel: "Sa" },
    { value: "SU", label: "Sonntag", shortLabel: "So" },
  ],
  currency: "EUR",
  timeZone: "Europe/Berlin",
  defaultTravelCost: {
    kind: "per-kilometer",
    amount: 0.7,
    currency: "EUR",
  },
} as const;

const postalAreas: KMapPostalArea[] = [
  {
    id: "10115",
    country: "DE",
    code: "10115",
    label: "Berlin-Mitte",
    sourceLabel: "Storybook-Beispieldaten · keine amtlichen Grenzen",
    sourceVersion: "Fixture 2026-10",
    coordinates: [
      [13.382, 52.526],
      [13.397, 52.526],
      [13.397, 52.538],
      [13.382, 52.538],
    ],
  },
  {
    id: "10117",
    country: "DE",
    code: "10117",
    label: "Berlin-Mitte",
    sourceLabel: "Storybook-Beispieldaten · keine amtlichen Grenzen",
    sourceVersion: "Fixture 2026-10",
    coordinates: [
      [13.397, 52.515],
      [13.412, 52.515],
      [13.412, 52.526],
      [13.397, 52.526],
    ],
  },
  {
    id: "10119",
    country: "DE",
    code: "10119",
    label: "Prenzlauer Berg",
    sourceLabel: "Storybook-Beispieldaten · keine amtlichen Grenzen",
    sourceVersion: "Fixture 2026-10",
    coordinates: [
      [13.397, 52.526],
      [13.412, 52.526],
      [13.412, 52.538],
      [13.397, 52.538],
    ],
  },
];

interface Args {
  showScheduling?: boolean;
  zones: readonly KMapZone[];
  selectedZoneId: string | null;
  compact: boolean;
  fullscreen: boolean;
  startCenter: [number, number];
}

function Example({
  args,
  dark,
  update,
}: {
  args: Args;
  dark: boolean;
  update: (values: Partial<Args>) => void;
}) {
  const [undoAction, setUndoAction] = useState<KMapZoneUndoAction | null>(null);
  const [saved, setSaved] = useState(() => JSON.stringify(args.zones));
  const [pending, setPending] = useState(false);
  const [editorReset, setEditorReset] = useState(0);
  const [confirmExit, setConfirmExit] = useState(false);
  const [notice, setNotice] = useState("");
  const hasChanges = JSON.stringify(args.zones) !== saved;
  const save = () => {
    setSaved(JSON.stringify(args.zones));
    setNotice("Gebiete gespeichert");
    action("onSave")(args.zones);
  };
  const exit = () => {
    action("onExit")();
    setNotice("Zurück zur Verwaltung – Navigation im Storybook-Beispiel");
  };
  const mapStyle = useMemo(
    () => createMapStyle({ tokens: dark ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS }),
    [dark],
  );
  return (
    <div
      style={
        args.fullscreen
          ? ({
              position: "fixed",
              inset: 0,
              overflow: "hidden",
              "--k-map-zone-editor-height": "100dvh",
            } as CSSProperties)
          : args.compact
            ? { width: "100%", maxWidth: 390, minWidth: 0, overflow: "clip" }
            : { width: "calc(100vw - 32px)", maxWidth: "100%", minWidth: 0 }
      }
    >
      {args.fullscreen && (
        <div
          style={{
            position: "absolute",
            zIndex: 2,
            top: "max(env(safe-area-inset-top), var(--k-space-card-padding))",
            left: "var(--k-space-card-padding)",
          }}
        >
          <KIconButton
            icon="arrow-left"
            label="Zurück zur Verwaltung"
            variant="secondary"
            onClick={() => {
              if (hasChanges || pending) setConfirmExit(true);
              else exit();
            }}
          />
        </div>
      )}
      {args.fullscreen && hasChanges && !pending && (
        <div
          style={{
            position: "absolute",
            zIndex: 2,
            top: "max(env(safe-area-inset-top), var(--k-space-card-padding))",
            right: "var(--k-space-card-padding)",
          }}
        >
          <KIconButton
            icon="cloud-upload"
            label="Gebiete speichern"
            variant="secondary"
            onClick={save}
          />
        </div>
      )}
      <KMapZoneEditor
        key={editorReset}
        zones={args.zones}
        selectedZoneId={args.selectedZoneId}
        postalAreas={postalAreas}
        startCenter={args.startCenter}
        defaultRadiusKm={2.5}
        propertyOptions={{
          ...propertyOptions,
          showScheduling: args.showScheduling,
          workingHoursSources: args.zones.map((zone) => ({
            id: zone.id,
            label: zone.name,
            workingHours:
              zone.settings?.workingHours ??
              propertyOptions.defaultWorkingHours,
          })),
          travelCostSources: args.zones.flatMap((zone) =>
            zone.settings?.travelCost
              ? [
                  {
                    id: zone.id,
                    label: zone.name,
                    travelCost: zone.settings.travelCost,
                  },
                ]
              : [],
          ),
        }}
        defaultZoneSettings={{
          travelCost: {
            kind: "per-kilometer",
            amount: 0.7,
            currency: "EUR",
          },
        }}
        labels={{
          sampleData: "Beispieldaten · keine amtlichen Grenzen",
        }}
        mapProps={{
          mapStyle,
          center: [13.397, 52.5205],
          zoom: 13.6,
          fitContent: true,
          fitPadding: 64,
          showZoomControls: !args.fullscreen,
        }}
        onChange={(zones) => {
          action("onChange")(zones);
          update({ zones });
        }}
        onSelect={(selectedZoneId) => {
          action("onSelect")(selectedZoneId);
          update({ selectedZoneId });
        }}
        onPendingChangesChanged={setPending}
        onValidationError={action("onValidationError")}
        onUndoActionChange={setUndoAction}
      />
      {args.fullscreen && (
        <KAdaptiveDialog
          open={confirmExit}
          onOpenChange={setConfirmExit}
          title="Änderungen speichern?"
          actions={
            <>
              <KButton
                variant="secondary"
                onClick={() => setConfirmExit(false)}
              >
                Weiter bearbeiten
              </KButton>
              <KButton
                variant="secondary"
                onClick={() => {
                  update({ zones: JSON.parse(saved) });
                  setEditorReset((value) => value + 1);
                  setPending(false);
                  setConfirmExit(false);
                  exit();
                }}
              >
                Verwerfen
              </KButton>
              <KButton
                disabled={pending}
                onClick={() => {
                  save();
                  setConfirmExit(false);
                  exit();
                }}
              >
                Speichern
              </KButton>
            </>
          }
        >
          {pending
            ? "Übernimm zuerst die Änderungen im Karteneditor oder verwirf sie beim Verlassen."
            : "Deine Änderungen gelten nach dem Speichern direkt für neue Buchungen."}
        </KAdaptiveDialog>
      )}
      <KToastViewport position="bottom-center">
        {notice && (
          <KSnackbar message={notice} onDismiss={() => setNotice("")} />
        )}
        {undoAction && (
          <KSnackbar
            message={undoAction.message}
            onDismiss={() => setUndoAction(null)}
            action={
              <KButton
                variant="ghost"
                onClick={() => {
                  undoAction.undo();
                  setUndoAction(null);
                }}
              >
                {undoAction.label}
              </KButton>
            }
          />
        )}
      </KToastViewport>
    </div>
  );
}

const meta = {
  title: "Maps/Zone Editor",
  parameters: {
    layout: "fullscreen",
    fixtureId: "map-zone-editor",
    docs: {
      description: {
        component:
          "Dreistufiger Gebiets-Editor mit konfigurierbaren Anfahrtskosten, Zuschlag und Verfügbarkeit. Beim Übernehmen gewinnt die bearbeitete Zone; betroffene Zonen werden nach Bestätigung atomar verkleinert oder entfernt und können gemeinsam rückgängig gemacht werden.",
      },
    },
  },
  args: {
    zones: berlinZones,
    selectedZoneId: null,
    compact: false,
    fullscreen: false,
    startCenter: [13.397, 52.5205],
  },
  argTypes: {
    compact: { table: { disable: true } },
    startCenter: { table: { disable: true } },
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
export const Desktop: Story = {
  name: "Drei Einstiege · Desktop",
  parameters: { fixtureId: "map-zone-editor-desktop" },
};
export const Mobile: Story = {
  name: "Drei Einstiege · Mobil",
  args: { compact: true },
  globals: {
    viewport: { value: "zone-editor-mobile", isRotated: false },
    inputMode: "touch",
    windowClass: "compact",
  },
  parameters: {
    fixtureId: "map-zone-editor-mobile",
    viewport: {
      options: {
        "zone-editor-mobile": {
          name: "Zone editor mobile · 390 × 844",
          styles: { width: "390px", height: "844px" },
          type: "mobile",
        },
      },
    },
  },
};
export const Empty: Story = {
  name: "Erste Zone · Leerzustand",
  args: { zones: [], selectedZoneId: null },
  parameters: { fixtureId: "map-zone-editor-empty" },
};
export const EmptyMobile: Story = {
  name: "Erste Zone · Mobil",
  args: { zones: [], selectedZoneId: null, compact: true },
  globals: {
    viewport: { value: "zone-editor-mobile", isRotated: false },
    inputMode: "touch",
    windowClass: "compact",
  },
  parameters: {
    fixtureId: "map-zone-editor-empty-mobile",
    viewport: {
      options: {
        "zone-editor-mobile": {
          name: "Zone editor mobile · 390 × 844",
          styles: { width: "390px", height: "844px" },
          type: "mobile",
        },
      },
    },
  },
};

export const OverlapDesktop: Story = {
  name: "Überlappung und Eigenschaften · Desktop",
  args: {
    zones: adjacentZones,
    selectedZoneId: "adjacent-west",
    startCenter: [13.397, 52.5205],
  },
  parameters: { fixtureId: "map-zone-editor-overlap-desktop" },
};

export const OverlapMobile: Story = {
  name: "Überlappung und Eigenschaften · Mobil",
  args: {
    zones: adjacentZones,
    selectedZoneId: "adjacent-west",
    startCenter: [13.397, 52.5205],
    compact: true,
  },
  globals: {
    viewport: { value: "zone-editor-mobile", isRotated: false },
    inputMode: "touch",
    windowClass: "compact",
  },
  parameters: {
    fixtureId: "map-zone-editor-overlap-mobile",
    viewport: {
      options: {
        "zone-editor-mobile": {
          name: "Zone editor mobile · 390 × 844",
          styles: { width: "390px", height: "844px" },
          type: "mobile",
        },
      },
    },
  },
};

// Consumer navigation/persistence are simulated here; geometry editing remains
// entirely in the delivered KMapZoneEditor, ready for later host integration.
export const FullscreenDesktop: Story = {
  name: "Vollbild · Desktop",
  args: { fullscreen: true, selectedZoneId: null },
  parameters: { fixtureId: "map-zone-editor-fullscreen-desktop" },
};
export const FullscreenMobile: Story = {
  ...Mobile,
  name: "Vollbild · Mobil",
  args: { fullscreen: true, compact: true, selectedZoneId: null },
  parameters: {
    ...Mobile.parameters,
    fixtureId: "map-zone-editor-fullscreen-mobile",
  },
};
export const FullscreenEmpty: Story = {
  ...FullscreenMobile,
  name: "Vollbild · Erste Zone",
  args: { fullscreen: true, compact: true, zones: [], selectedZoneId: null },
  parameters: {
    ...Mobile.parameters,
    fixtureId: "map-zone-editor-fullscreen-empty",
  },
};


export const AreasOnly: Story = {
  name: "Onboarding: Gebiete ohne Zeiten",
  args: { showScheduling: false },
  parameters: { fixtureId: "map-zone-editor-areas-only" },
};
