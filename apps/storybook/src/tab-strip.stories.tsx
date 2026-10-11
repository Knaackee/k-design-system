import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KTabStrip } from "@k-design-system/ui/patterns/tab-strip";
import { KFileIcon } from "@k-design-system/ui/primitives/file-icon";
function Review() {
  const [names, setNames] = useState([
    "Willkommen.md",
    "Projektplan.md",
    "index.ts",
    "styles.css",
    "package.json",
    "Notizen.txt",
    "Recherche.md",
    "Entwurf.svg",
    "Präsentation.mp4",
  ]);
  const [active, setActive] = useState(names[0]);
  const close = (id: string) => {
    setNames((items) => items.filter((item) => item !== id));
    if (active === id) setActive(names.find((item) => item !== id) ?? "");
  };
  return (
    <div style={{ width: "100vw", minWidth: 0 }}>
      <KTabStrip
        items={names.map((name) => ({
          id: name,
          label: name,
          icon: <KFileIcon name={name} />,
        }))}
        selectedId={active}
        onSelect={setActive}
        onClose={close}
        onReorder={setNames}
        menuActions={(item) => [
          { id: "close", label: "Schließen", onSelect: () => close(item.id) },
          {
            id: "others",
            label: "Andere schließen",
            onSelect: () => {
              setNames([item.id]);
              setActive(item.id);
            },
          },
        ]}
      />
    </div>
  );
}
export default {
  title: "Patterns/Tab Strip",
  component: Review,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof Review>;
export const Overflow: StoryObj<typeof Review> = {};
