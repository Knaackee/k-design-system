import { useState } from "react";
import { KAgentSwitcher, KSwitch } from "@k-design-system/ui";

const agents = [
  { id: "ada", name: "Ada", avatar: "🧭" },
  { id: "linus", name: "Linus", avatar: "🌙" },
  { id: "mira", name: "Mira", avatar: "✨" },
];

export function AgentSwitcherSettingsFixture() {
  const [pins, setPins] = useState(["ada", "linus"]);
  const ordered = [
    ...pins.map((id) => agents.find((agent) => agent.id === id)!),
    ...agents.filter((agent) => !pins.includes(agent.id)),
  ];
  return (
    <div style={{ maxWidth: 480, margin: "auto" }}>
      <KAgentSwitcher
        variant="settings"
        orientation="vertical"
        selectedId={null}
        onSelect={() => {}}
        items={ordered.map((agent) => ({
          ...agent,
          reorderable: pins.includes(agent.id),
          controlContent: (
            <KSwitch
              showLabel={false}
              label={`Pin ${agent.name}`}
              checked={pins.includes(agent.id)}
              onCheckedChange={(enabled) =>
                setPins(
                  enabled
                    ? [...pins, agent.id]
                    : pins.filter((id) => id !== agent.id),
                )
              }
            />
          ),
        }))}
        onReorder={(ids) => setPins(ids.filter((id) => pins.includes(id)))}
      />
    </div>
  );
}
