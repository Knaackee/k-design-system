import "maplibre-gl/dist/maplibre-gl.css";
import "@k-design-system/ui/maps.css";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useArgs } from "storybook/preview-api";
import { useEffect, useMemo, useRef, useState } from "react";
import { KMap } from "@k-design-system/ui/patterns/map";
import { KButton } from "@k-design-system/ui/primitives/button";
import {
  createMapStyle,
  readMapTokens,
  MAP_TOKEN_METADATA,
  LIGHT_MAP_TOKENS,
  DARK_MAP_TOKENS,
  DEFAULT_SETTINGS,
  SETTINGS_SCHEMA,
  type MapSettings,
  type MapTokens,
} from "@k-design-system/ui/maps";
import { setWorkerUrl } from "maplibre-gl";
import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
import "./map-playground.css";

setWorkerUrl(workerUrl);
type Args = Record<string, unknown> & {
  zoom: number;
  interactive: boolean;
  showZoomControls: boolean;
  center: [number, number];
};
const defaults: Args = {
  ...DEFAULT_SETTINGS,
  zoom: 14,
  interactive: true,
  showZoomControls: true,
  center: [13.388, 52.517],
};
const tokenArgs = Object.fromEntries(
  MAP_TOKEN_METADATA.map((token) => [token.key, undefined]),
);
const controlValue = (value: MapTokens[keyof MapTokens]) =>
  Array.isArray(value) ? value.join(", ") : value;

function MapPlayground({
  args,
  themeKey,
  update,
}: {
  args: Args;
  themeKey: string;
  update: (values: Record<string, unknown>) => void;
}) {
  const root = useRef<HTMLDivElement>(null);
  const [base, setBase] = useState<MapTokens>(() => readMapTokens());
  const previousBase = useRef(
    args._tokenTheme === "dark" ? DARK_MAP_TOKENS : LIGHT_MAP_TOKENS,
  );
  useEffect(() => {
    if (!root.current) return;
    const next = readMapTokens(root.current);
    const inherited: Record<string, unknown> = {};
    const currentTheme = themeKey.split(":")[0];
    if (args._tokenTheme !== currentTheme) inherited._tokenTheme = currentTheme;
    for (const token of MAP_TOKEN_METADATA) {
      const value = args[token.key];
      if (
        value === undefined ||
        value === controlValue(previousBase.current[token.key])
      ) {
        const resolved = controlValue(next[token.key]);
        if (value !== resolved) inherited[token.key] = resolved;
      }
    }
    previousBase.current = next;
    if (JSON.stringify(next) !== JSON.stringify(base)) setBase(next);
    if (Object.keys(inherited).length) update(inherited);
  }, [themeKey, args, base, update]);
  const tokens = useMemo(() => {
    const result = { ...base };
    for (const token of MAP_TOKEN_METADATA) {
      const value = args[token.key];
      if (value !== undefined && value !== null && value !== "") {
        Object.assign(result, {
          [token.key]:
            token.type === "fontFamily" && typeof value === "string"
              ? value.split(",").map((font) => font.trim())
              : value,
        });
      }
    }
    return result;
  }, [args, base]);
  // Filling inherited controls must not reload an otherwise identical style.
  const styleKey = JSON.stringify([
    tokens,
    ...Object.keys(DEFAULT_SETTINGS).map((key) => args[key]),
  ]);
  const style = useMemo(
    () =>
      createMapStyle({
        tokens,
        settings: Object.fromEntries(
          Object.keys(DEFAULT_SETTINGS).map((key) => [key, args[key]]),
        ) as Partial<MapSettings>,
      }),
    [styleKey],
  );
  return (
    <div ref={root} className="k-map-playground">
      <header className="k-map-playground__header">
        <div>
          <strong>KMap</strong>
          <p>
            KDS-Kartenstil · Optionen und Token-Overrides im Controls-Panel.
          </p>
        </div>
        <KButton
          variant="secondary"
          onClick={() =>
            update({
              ...defaults,
              ...Object.fromEntries(
                MAP_TOKEN_METADATA.map((token) => [
                  token.key,
                  controlValue(base[token.key]),
                ]),
              ),
            })
          }
        >
          Defaults wiederherstellen
        </KButton>
      </header>
      <KMap
        mapStyle={style}
        center={args.center}
        zoom={args.zoom}
        onViewChange={(view) => {
          if (
            view.zoom !== args.zoom ||
            view.center.some(
              (value, index) => Math.abs(value - args.center[index]) > 1e-8,
            )
          )
            update(view);
        }}
        interactive={args.interactive}
        showZoomControls={args.showZoomControls}
      />
      <details className="k-map-playground__tokens">
        <summary>Token-Namen, Vererbung und aktuelle Werte</summary>
        <p>
          Leere Overrides erben den aktuellen KDS-Theme-Wert. Die Kartenschrift
          verwendet vorerst Noto Sans, da die eingebundene Glyphenquelle keine
          Inter-Glyphen bereitstellt.
        </p>
        <div className="k-map-playground__table">
          <table>
            <thead>
              <tr>
                <th>Token / CSS-Variable</th>
                <th>KDS-Default im Theme</th>
                <th>Wirksamer Wert</th>
              </tr>
            </thead>
            <tbody>
              {MAP_TOKEN_METADATA.map((token) => (
                <tr key={token.key}>
                  <td>
                    <code>{token.token}</code>
                    <br />
                    <code>{token.cssVariable}</code>
                  </td>
                  <td>{String(base[token.key])}</td>
                  <td>
                    {String(tokens[token.key])}
                    {args[token.key] !== undefined &&
                    args[token.key] !== controlValue(base[token.key])
                      ? " · Override"
                      : " · geerbt"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </details>
    </div>
  );
}
const meta = {
  title: "Maps/Map",
  parameters: {
    layout: "fullscreen",
    fixtureId: "map-basic",
    controls: { expanded: false },
    docs: {
      description: {
        component:
          "KMap mit KDS-Kartentokens. Globale Theme-Auswahl wird geerbt; Overrides gelten nur für diese Karte. Karte benötigt Internet für OpenFreeMap-Kacheln und Glyphen.",
      },
    },
  },
  args: { ...defaults, ...tokenArgs },
  argTypes: {
    _tokenTheme: { table: { disable: true }, control: false },
    center: { control: "object", table: { category: "Bedienung" } },
    zoom: {
      control: { type: "range", min: 3, max: 19, step: 0.5 },
      table: { category: "Bedienung", defaultValue: { summary: "14" } },
    },
    interactive: { control: "boolean", table: { category: "Bedienung" } },
    showZoomControls: { control: "boolean", table: { category: "Bedienung" } },
    ...Object.fromEntries(
      SETTINGS_SCHEMA.map((setting) => [
        setting.key,
        {
          name: `${setting.label} · ${setting.key}`,
          control:
            setting.type === "toggle"
              ? "boolean"
              : setting.type === "select"
                ? "select"
                : { ...setting },
          options: "options" in setting ? setting.options : undefined,
          table: {
            category: "Kartendetails",
            defaultValue: { summary: String(DEFAULT_SETTINGS[setting.key]) },
          },
        },
      ]),
    ),
    ...Object.fromEntries(
      MAP_TOKEN_METADATA.map((token) => [
        token.key,
        {
          name: token.token,
          description: `${token.description} — ${token.cssVariable}. Leer = KDS-Theme erben.`,
          control:
            token.type === "color"
              ? "color"
              : token.type === "number"
                ? "number"
                : "text",
          table: {
            category: "Karten-Tokens",
            defaultValue: {
              summary: `Hell: ${String(token.defaults.light)} / Dunkel: ${String(token.defaults.dark)}`,
            },
          },
        },
      ]),
    ),
  },
  render: function Render(args, context) {
    const [, updateArgs] = useArgs();
    return (
      <MapPlayground
        args={args as Args}
        themeKey={`${context.globals.theme}:${context.globals.brand}`}
        update={updateArgs}
      />
    );
  },
} satisfies Meta<Args>;
export default meta;
export const Map: StoryObj<typeof meta> = {};
