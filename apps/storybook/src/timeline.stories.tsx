import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KDialog,
  KInput,
  KSelect,
  KSurface,
  KText,
} from "@k-design-system/ui";
import fixture from "../../../fixtures/timeline-reference.json";
import { TimelineCanvas } from "./timeline/timeline-canvas";
import {
  addDays,
  applyProposal,
  localDate,
  type TimelineItem,
} from "./timeline/timeline-model";

function TimelineReference() {
  const [items, setItems] = useState<readonly TimelineItem[]>(fixture.items);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [window, setWindow] = useState(fixture.window);
  const reject = false;
  const [message, setMessage] = useState(
    "Select an item to inspect or edit its dates.",
  );
  const [editing, setEditing] = useState<TimelineItem | null>(null);
  const [error, setError] = useState("");
  const format = (date: string) =>
    new Intl.DateTimeFormat("en", { month: "short", day: "numeric" }).format(
      localDate(date),
    );
  const propose = (next: TimelineItem) => {
    const result = applyProposal(
      items,
      next,
      fixture.groups.map((group) => group.id),
      !reject,
    );
    if (result === items) {
      setMessage(
        reject
          ? "Change declined. Original dates retained."
          : "This change is not allowed.",
      );
      return false;
    }
    setItems(result);
    setSelectedId(next.id);
    setMessage(
      `${next.label}: ${format(next.start)}${next.end ? ` – ${format(addDays(next.end, -1))}` : ""}. Change saved in this demo.`,
    );
    return true;
  };
  return (
    <KSurface radius="card" className="k-timeline-demo">
      <TimelineCanvas
        items={items}
        groups={fixture.groups}
        selectedId={selectedId}
        onSelect={setSelectedId}
        onItemOpen={(id) => {
          const item = items.find((entry) => entry.id === id);
          if (item) {
            setSelectedId(id);
            setError("");
            setEditing({ ...item });
          }
        }}
        onPropose={propose}
        window={window}
        onWindowChange={setWindow}
        today={fixture.today}
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
        onOpenChange={(open) => {
          if (!open) setEditing(null);
        }}
        title={editing?.label ?? "Item details"}
      >
        {editing && (
          <form
            className="k-timeline-demo__editor"
            onSubmit={(event) => {
              event.preventDefault();
              if (propose(editing)) setEditing(null);
              else
                setError(
                  reject
                    ? "Change declined by the demo. Turn off ‘Decline changes’ to save."
                    : "End date must not be before the start date.",
                );
            }}
          >
            <label className="k-timeline-demo__field">
              <KText variant="bodySmall">Start date</KText>
              <KInput
                type="date"
                required
                disabled={editing.readOnly}
                value={editing.start}
                onChange={(event) =>
                  setEditing({ ...editing, start: event.target.value })
                }
              />
            </label>
            {editing.end && (
              <label className="k-timeline-demo__field">
                <KText variant="bodySmall">Last day included</KText>
                <KInput
                  type="date"
                  required
                  disabled={editing.readOnly}
                  min={editing.start}
                  value={addDays(editing.end, -1)}
                  onChange={(event) => {
                    if (event.target.value)
                      setEditing({
                        ...editing,
                        end: addDays(event.target.value, 1),
                      });
                  }}
                />
              </label>
            )}
            <KSelect
              label="Group"
              value={editing.group}
              disabled={editing.readOnly}
              onValueChange={(group) => setEditing({ ...editing, group })}
              options={fixture.groups.map((group) => ({
                value: group.id,
                label: group.label,
              }))}
            />
            {error && (
              <KText variant="bodySmall" role="alert">
                {error}
              </KText>
            )}
            <div className="k-timeline-demo__navigation">
              <KButton variant="ghost" onClick={() => setEditing(null)}>
                Cancel
              </KButton>
              <KButton type="submit" disabled={editing.readOnly}>
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
  title: "Data display/Timeline",
  component: TimelineReference,
  parameters: { layout: "fullscreen", fixtureId: "timeline-reference" },
} satisfies Meta<typeof TimelineReference>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Reference: Story = { name: "timeline-reference" };
