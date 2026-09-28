import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KDialog,
  KGantt,
  KInput,
  KSurface,
  KText,
  applyKGanttProposal,
  kGanttAddDays,
  summarizeKGanttTasks,
  type KGanttLink,
  type KGanttTask,
} from "@k-design-system/ui";
import fixture from "../../../fixtures/gantt-reference.json";

const initial = fixture.tasks as KGanttTask[];
function GanttReference({
  scale = "weeks",
  start = fixture.window.start,
  end = fixture.window.end,
}: {
  scale?: "days" | "weeks" | "months";
  start?: string;
  end?: string;
}) {
  const [tasks, setTasks] = useState<readonly KGanttTask[]>(initial);
  const [selected, setSelected] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(
    initial.filter((task) => task.type === "summary").map((task) => task.id),
  );
  const [editing, setEditing] = useState<KGanttTask | null>(null);
  const reject = false;
  const [message, setMessage] = useState(
    "Select a task to inspect its dates and progress.",
  );
  const [error, setError] = useState("");
  const records = summarizeKGanttTasks(tasks);
  const open = (id: string) => {
    setEditing(records.find((task) => task.id === id) ?? null);
    setError("");
  };
  const propose = (next: KGanttTask) => {
    const result = applyKGanttProposal(tasks, next, !reject);
    if (result === tasks) {
      setMessage("Change declined. Original values retained.");
      return false;
    }
    setTasks(result);
    setSelected(next.id);
    setMessage(
      `${next.text}: ${next.start}${next.end ? ` – ${kGanttAddDays(next.end, -1)}` : ""} · ${next.progress}%. Saved in this demo.`,
    );
    return true;
  };
  const locked = editing?.readOnly || editing?.type === "summary";
  return (
    <KSurface radius="card" className="k-gantt-demo">
      <KGantt
        tasks={tasks}
        links={fixture.links as KGanttLink[]}
        start={start}
        end={end}
        scale={scale}
        selectedId={selected}
        onSelect={setSelected}
        expanded={expanded}
        onExpandedChange={setExpanded}
        onOpen={open}
        onPropose={propose}
      />
      <span
        style={{
          position: "absolute",
          width: 1,
          height: 1,
          overflow: "hidden",
          clipPath: "inset(50%)",
          whiteSpace: "nowrap",
        }}
        role="status"
      >
        {message}
      </span>
      <KDialog
        open={editing !== null}
        onOpenChange={(value) => {
          if (!value) setEditing(null);
        }}
        title={editing?.text ?? "Task details"}
      >
        {editing && (
          <form
            className="k-gantt-form"
            onSubmit={(event) => {
              event.preventDefault();
              if (propose(editing)) setEditing(null);
              else
                setError(
                  "Change declined or invalid. Check dates and demo permissions.",
                );
            }}
          >
            <label>
              <KText variant="bodySmall">Start date</KText>
              <KInput
                type="date"
                required
                disabled={locked}
                value={editing.start}
                onChange={(event) =>
                  setEditing({ ...editing, start: event.target.value })
                }
              />
            </label>
            {editing.end && (
              <label>
                <KText variant="bodySmall">Last day included</KText>
                <KInput
                  type="date"
                  required
                  disabled={locked}
                  min={editing.start}
                  value={kGanttAddDays(editing.end, -1)}
                  onChange={(event) => {
                    if (event.target.value)
                      setEditing({
                        ...editing,
                        end: kGanttAddDays(event.target.value, 1),
                      });
                  }}
                />
              </label>
            )}
            <label>
              <KText variant="bodySmall">Progress (%)</KText>
              <KInput
                type="number"
                min={0}
                max={100}
                required
                disabled={locked}
                value={editing.progress}
                onChange={(event) =>
                  setEditing({
                    ...editing,
                    progress: Number(event.target.value),
                  })
                }
              />
            </label>
            {editing.type === "summary" && (
              <KText variant="caption">
                Summary dates and progress follow the child tasks.
              </KText>
            )}
            {error && (
              <KText variant="bodySmall" role="alert">
                {error}
              </KText>
            )}
            <div className="k-gantt-toolbar">
              <KButton variant="ghost" onClick={() => setEditing(null)}>
                Close
              </KButton>
              <KButton type="submit" disabled={locked}>
                Save changes
              </KButton>
            </div>
          </form>
        )}
      </KDialog>
    </KSurface>
  );
}
const meta = {
  title: "Data display/Gantt",
  component: GanttReference,
  parameters: { layout: "fullscreen", fixtureId: "gantt-reference" },
  args: {
    scale: "weeks",
    start: fixture.window.start,
    end: fixture.window.end,
  },
} satisfies Meta<typeof GanttReference>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Reference: Story = { name: "gantt-reference" };
