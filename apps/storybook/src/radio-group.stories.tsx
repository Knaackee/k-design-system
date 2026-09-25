import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KRadioGroup } from "@k-design-system/ui";

function RadioFixture() {
  const [value, setValue] = useState<string | null>("all");
  return (
    <div style={{ padding: "var(--k-space-card-padding)" }}>
      <KRadioGroup
        label="Notifications"
        value={value}
        onValueChange={setValue}
        items={[
          { value: "all", label: "All updates" },
          { value: "important", label: "Important updates only" },
          { value: "none", label: "No updates" },
          {
            value: "managed",
            label: "Managed by administrator",
            disabled: true,
          },
        ]}
      />
    </div>
  );
}
export default {
  title: "Forms/RadioGroup",
  component: RadioFixture,
  parameters: { fixtureId: "radio-group-options" },
} satisfies Meta<typeof RadioFixture>;
export const Options: StoryObj<typeof RadioFixture> = {
  name: "radio-group-options",
};
