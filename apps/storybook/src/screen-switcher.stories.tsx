import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KScreenSwitcher,
  KButton,
  KText,
  KIcon,
  type KScreenSwitcherMode,
} from "@k-design-system/ui";
import "./screen-switcher-demo.css";
function TestScreen({
  index,
  onShowStack,
}: {
  index: number;
  onShowStack: () => void;
}) {
  return (
    <div className="screen-switcher-demo__content">
      <KButton fullWidth onClick={onShowStack}>
        Geöffnete Screens
      </KButton>
      <div className="screen-switcher-demo__image">
        <KIcon name="mountain" size={48} />
      </div>
      <div>
        <KText>Projekt {index + 1} · Übersicht</KText>
        <KText>
          Dieser vollständige Test-Screen wird als Karte im Stapel dargestellt.
          Der Inhalt kommt von außen.
        </KText>
      </div>
      {Array.from({ length: 5 }, (_, row) => (
        <div className="screen-switcher-demo__section" key={row}>
          <KText>
            {row + 1}. Arbeitspaket · Projekt {index + 1}
          </KText>
          <KText>Konzept, Gestaltung und Umsetzung im Team abstimmen.</KText>
        </div>
      ))}
    </div>
  );
}
function Demo() {
  const [state, setState] = useState<{
    activeId: string | null;
    mode: KScreenSwitcherMode;
  }>({ activeId: "screen-1", mode: "screen" });
  return (
    <div className="screen-switcher-demo">
      <KScreenSwitcher
        {...state}
        showOverviewButton={false}
        onStateChange={setState}
        label="Entwürfe"
        overviewLabel="Geöffnete Screens"
        minimizeLabel="Stapel anzeigen"
        items={Array.from({ length: 8 }, (_, index) => ({
          id: `screen-${index + 1}`,
          title: `Entwurf ${index + 1}`,
          closable: false,
          content: (
            <TestScreen
              index={index}
              onShowStack={() =>
                setState((previous) => ({ ...previous, mode: "overview" }))
              }
            />
          ),
        }))}
      />
    </div>
  );
}
export default {
  title: "Navigation/ScreenSwitcher",
  component: Demo,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof Demo>;
export const Workspace: StoryObj<typeof Demo> = {
  parameters: { fixtureId: "screen-switcher-workspace" },
};
