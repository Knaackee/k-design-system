import { useMemo, useRef, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KOrbit,
  KOrbitController,
  KSlider,
  KSurface,
  KText,
  type KOrbitNode,
  type KOrbitSignalStyle,
} from "@k-design-system/ui";
import "./orbit.stories.css";
import { OrbitDemoDetails } from "./orbit-demo-details";
import {
  levels,
  data,
  addedNodes,
  addedConnections,
  connections,
  deepLevels,
  deepNodes,
  deepConnections,
} from "./orbit-fixtures";

type Filter = "all" | "active" | "questions";
type LabelVisibility = "interaction" | "always" | "hidden";

function includeMatchesAndAncestors(
  nodes: readonly KOrbitNode[],
  filter: Filter,
) {
  if (filter === "all") return nodes;
  const byId = new Map(nodes.map((node) => [node.id, node]));
  const visible = new Set<string>();
  for (const node of nodes) {
    const matches =
      filter === "active"
        ? node.status === "active"
        : node.status === "question";
    if (!matches) continue;
    let current: KOrbitNode | undefined = node;
    while (current) {
      visible.add(current.id);
      current = current.parentId ? byId.get(current.parentId) : undefined;
    }
  }
  return nodes.filter(({ id }) => visible.has(id));
}

function OrbitFixture({
  communication = false,
  deep = false,
  freeze = false,
}: {
  communication?: boolean;
  deep?: boolean;
  freeze?: boolean;
}) {
  const controller = useMemo(() => new KOrbitController(), []);
  const [filter, setFilter] = useState<Filter>("all");
  const [labelVisibility, setLabelVisibility] =
    useState<LabelVisibility>("interaction");
  const [pinned, setPinned] = useState<string | null>(null);
  const [selected, setSelected] = useState<string | null>(null);
  const [details, setDetails] = useState<KOrbitNode | null>(null);
  const [showAdded, setShowAdded] = useState(false);
  const [statuses, setStatuses] = useState<
    Record<string, NonNullable<KOrbitNode["status"]>>
  >({});
  const [minZoom, setMinZoom] = useState(0.65);
  const [maxZoom, setMaxZoom] = useState(deep ? 5 : 2.2);
  const [maxAngularSpeed, setMaxAngularSpeed] = useState(12);
  const [nodeOptions, setNodeOptions] = useState<
    Record<string, Partial<KOrbitNode>>
  >({});
  const [speed, setSpeed] = useState(1);
  const [paused, setPaused] = useState(false);
  const [duration, setDuration] = useState(1800);
  const [signalStyle, setSignalStyle] = useState<KOrbitSignalStyle>("trail");
  const sequence = useRef(1);
  const [events, setEvents] = useState<string[]>(["Ready"]);
  const sourceNodes = deep ? deepNodes : data;
  const sourceConnections = deep ? deepConnections : connections;
  const allNodes = [...sourceNodes, ...(showAdded ? addedNodes : [])].map(
    (node) => {
      const status = statuses[node.id] ?? node.status;
      return {
        ...node,
        status,
        pulse: status === "question",
        statusLabel: status === "question" ? "Needs your answer" : undefined,
        ...nodeOptions[node.id],
      };
    },
  );
  const nodes = includeMatchesAndAncestors(allNodes, filter);
  const visibleIds = new Set(nodes.map(({ id }) => id));
  const allConnections = [
    ...sourceConnections,
    ...(showAdded ? addedConnections : []),
  ];
  const visibleConnections = allConnections.filter(
    ({ sourceId, targetId }) =>
      visibleIds.has(sourceId) && visibleIds.has(targetId),
  );
  const selectedNode = allNodes.find(({ id }) => id === selected) ?? null;
  const log = (event: string) =>
    setEvents((current) => [event, ...current].slice(0, 6));
  const triggerConnection = (connectionId: string) => {
    const id = `demo-signal-${sequence.current++}`;
    log(
      `${id}: ${controller.triggerSignal({
        id,
        connectionId,
        durationMs: duration,
        style: signalStyle,
      })}`,
    );
  };
  const triggerSelectedNode = () => {
    if (!selected) return;
    const id = `node-ping-${sequence.current++}`;
    log(
      `${id}: ${controller.triggerSignal({
        id,
        nodeId: selected,
        durationMs: duration,
      })}`,
    );
  };
  const toggleSelectedStatus = (status: NonNullable<KOrbitNode["status"]>) => {
    if (!selectedNode) return;
    const next = selectedNode.status === status ? "idle" : status;
    setStatuses((current) => ({ ...current, [selectedNode.id]: next }));
    log(`${selectedNode.label}: ${next}`);
  };

  return (
    <section className="k-orbit-demo">
      <KOrbit
        className="k-orbit-demo__scene"
        levels={deep ? deepLevels : levels}
        nodes={nodes}
        defaultView={{ yaw: 0, pitch: 0, zoom: 1.15, offset: { x: 0, y: 0 } }}
        zoomBounds={[minZoom, maxZoom]}
        connections={visibleConnections}
        controller={controller}
        selectedId={selected}
        pinnedId={pinned}
        onPinnedChange={setPinned}
        onSelectionChange={setSelected}
        onNodeActivate={(node) => setDetails(node)}
        labelVisibility={labelVisibility}
        motionSpeed={speed}
        maxAngularSpeed={maxAngularSpeed}
        paused={paused}
        onPausedChange={setPaused}
        onMotionSpeedChange={setSpeed}
        signalStyle={signalStyle}
        elapsedSeconds={freeze ? 0 : undefined}
        showControls
        onSignalEnd={(id, reason) => log(`${id}: ${reason}`)}
      />
      <KSurface className="k-orbit-demo__panel" radius="card" border="default">
        <KText variant="heading3">
          {deep
            ? "Deep hierarchy"
            : communication
              ? "Communication"
              : "Team command center"}
        </KText>
        <KText variant="bodySmall">
          {deep
            ? "Team → issues → agents → subtasks → signals."
            : "Team → issues → agents. Filtered results keep their ancestor path."}
        </KText>
        <label className="k-orbit-demo__field">
          <KText variant="bodySmall">Configure node</KText>
          <select
            aria-label="Configure node"
            value={selected ?? ""}
            onChange={(event) => setSelected(event.target.value || null)}
          >
            <option value="">Choose a node…</option>
            {nodes.map((node) => (
              <option key={node.id} value={node.id}>
                {node.label}
              </option>
            ))}
          </select>
        </label>
        {selectedNode && (
          <>
            <KText variant="bodySmall">
              Progress: {selectedNode.progress ?? 0}%
            </KText>
            <KSlider
              label="Node progress"
              min={0}
              max={100}
              step={1}
              value={selectedNode.progress ?? 0}
              onValueChange={(progress) =>
                setNodeOptions((current) => ({
                  ...current,
                  [selectedNode.id]: { ...current[selectedNode.id], progress },
                }))
              }
            />
            <KText variant="bodySmall">
              Radius: {selectedNode.radius ?? 10} world units
            </KText>
            <KSlider
              label="Selected node radius"
              min={2}
              max={80}
              step={1}
              value={selectedNode.radius ?? 10}
              onValueChange={(radius) =>
                setNodeOptions((current) => ({
                  ...current,
                  [selectedNode.id]: { ...current[selectedNode.id], radius },
                }))
              }
              valueLabel={(value) => `${value} world units`}
            />
            {selectedNode.levelId && (
              <label className="k-orbit-demo__field">
                <KText variant="bodySmall">Orbit duration (seconds)</KText>
                <KSlider
                  label="Selected node orbit duration"
                  min={10}
                  max={180}
                  step={5}
                  value={
                    selectedNode.periodSeconds ??
                    (deep ? deepLevels : levels).find(
                      (level) => level.id === selectedNode.levelId,
                    )?.periodSeconds ??
                    60
                  }
                  onValueChange={(periodSeconds) =>
                    setNodeOptions((current) => ({
                      ...current,
                      [selectedNode.id]: {
                        ...current[selectedNode.id],
                        periodSeconds,
                      },
                    }))
                  }
                  valueLabel={(value) => `${value}s`}
                />
              </label>
            )}
            <KButton
              variant="secondary"
              onClick={() =>
                setNodeOptions((current) => ({
                  ...current,
                  [selectedNode.id]: {
                    ...current[selectedNode.id],
                    pulse: !selectedNode.pulse,
                  },
                }))
              }
            >
              Toggle pulse
            </KButton>
            <KButton
              variant="secondary"
              onClick={() =>
                setNodeOptions((current) => ({
                  ...current,
                  [selectedNode.id]: {
                    ...current[selectedNode.id],
                    badge:
                      selectedNode.badge === null
                        ? { content: "99+", label: "99+ updates", tone: "info" }
                        : null,
                  },
                }))
              }
            >
              Toggle custom badge
            </KButton>
          </>
        )}
        {pinned && (
          <KButton variant="secondary" onClick={() => setPinned(null)}>
            Stop following: {allNodes.find((node) => node.id === pinned)?.label}
          </KButton>
        )}
        <div className="k-orbit-demo__actions" aria-label="Node filter">
          {(["all", "active", "questions"] as const).map((value) => (
            <KButton
              key={value}
              variant={filter === value ? "primary" : "secondary"}
              onClick={() => setFilter(value)}
            >
              {value === "all"
                ? "All"
                : value === "active"
                  ? "Active"
                  : "Questions"}
            </KButton>
          ))}
        </div>
        <div className="k-orbit-demo__actions" aria-label="Label visibility">
          {(["interaction", "always", "hidden"] as const).map((value) => (
            <KButton
              key={value}
              variant={labelVisibility === value ? "primary" : "secondary"}
              onClick={() => setLabelVisibility(value)}
            >
              Labels: {value}
            </KButton>
          ))}
        </div>
        <div className="k-orbit-demo__actions">
          <KButton onClick={() => setShowAdded((value) => !value)}>
            {showAdded ? "Remove issue + agent" : "Add issue + agent"}
          </KButton>
          <KButton
            variant="secondary"
            disabled={!selectedNode}
            onClick={() => setDetails(selectedNode)}
          >
            Open details
          </KButton>
        </div>
        <div className="k-orbit-demo__actions">
          <KButton
            variant="secondary"
            disabled={!selectedNode}
            onClick={() => toggleSelectedStatus("question")}
          >
            Toggle question
          </KButton>
          <KButton
            variant="secondary"
            disabled={!selectedNode}
            onClick={() => toggleSelectedStatus("active")}
          >
            Toggle active
          </KButton>
          <KButton
            variant="secondary"
            disabled={!selectedNode}
            onClick={triggerSelectedNode}
          >
            Ping selected
          </KButton>
        </div>
        <div className="k-orbit-demo__actions">
          <KButton onClick={() => triggerConnection("team-issue-a")}>
            Trigger event
          </KButton>
        </div>
        {communication && (
          <>
            <label className="k-orbit-demo__field">
              <KText variant="bodySmall">Signal style</KText>
              <select
                aria-label="Signal style"
                value={signalStyle}
                onChange={(event) =>
                  setSignalStyle(event.target.value as KOrbitSignalStyle)
                }
              >
                <option value="point">Travelling point</option>
                <option value="trail">Travelling trail</option>
                <option value="pings">Endpoint pings</option>
              </select>
            </label>
            <KSlider
              label="Signal duration"
              value={duration}
              min={400}
              max={2400}
              step={200}
              onValueChange={setDuration}
              valueLabel={(value) => `${value} milliseconds`}
            />
            <KButton
              variant="secondary"
              onClick={() =>
                visibleConnections
                  .slice(0, 5)
                  .forEach(({ id }) => triggerConnection(id))
              }
            >
              Burst
            </KButton>
          </>
        )}
        <label className="k-orbit-demo__field">
          <KText variant="bodySmall">Minimum zoom: {minZoom.toFixed(2)}×</KText>
          <KSlider
            label="Minimum zoom"
            min={0.1}
            max={1}
            step={0.05}
            value={minZoom}
            onValueChange={setMinZoom}
          />
        </label>
        <label className="k-orbit-demo__field">
          <KText variant="bodySmall">Maximum zoom: {maxZoom.toFixed(1)}×</KText>
          <KSlider
            label="Maximum zoom"
            min={1}
            max={10}
            step={0.1}
            value={maxZoom}
            onValueChange={setMaxZoom}
          />
        </label>
        <KSlider
          label="Maximum angular speed"
          min={0}
          max={30}
          step={1}
          value={maxAngularSpeed}
          onValueChange={setMaxAngularSpeed}
          valueLabel={(value) => `${value}°/s`}
        />
        <KText variant="heading4">Event log</KText>
        <ol className="k-orbit-demo__log" aria-live="polite">
          {events.map((event, index) => (
            <li key={`${event}-${index}`}>{event}</li>
          ))}
        </ol>
      </KSurface>
      <OrbitDemoDetails
        node={details}
        pinnedId={pinned}
        onClose={() => setDetails(null)}
        onPin={(id) => {
          setPinned(id);
          setDetails(null);
        }}
      />
    </section>
  );
}

const meta = {
  title: "Data display/Orbit",
  component: OrbitFixture,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof OrbitFixture>;
export default meta;
type Story = StoryObj<typeof meta>;

export const TeamProjects: Story = {
  name: "orbit-team-projects",
  parameters: { fixtureId: "orbit-team-projects" },
};
export const Communication: Story = {
  name: "orbit-communication",
  args: { communication: true },
  parameters: { fixtureId: "orbit-communication" },
};
export const Deterministic: Story = {
  name: "orbit-deterministic",
  args: { freeze: true },
  parameters: { fixtureId: "orbit-deterministic" },
};
export const DeepHierarchy: Story = {
  name: "orbit-deep-hierarchy",
  args: { deep: true },
  parameters: { fixtureId: "orbit-deep-hierarchy" },
};
