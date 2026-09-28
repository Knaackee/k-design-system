import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import {
  KContainer,
  KField,
  KStack,
  KText,
  KTextarea,
} from "@k-design-system/ui";

function TextareaFixture() {
  const [value, setValue] = useState(
    "Inspect the roof.\nDocument the findings.",
  );
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Multiline notes</KText>
          <KField
            label="Description"
            required
            helperText="Use Enter for a new line. Up to 240 characters."
          >
            <KTextarea
              name="description"
              value={value}
              onChange={(event) => setValue(event.target.value)}
              maxLength={240}
            />
          </KField>
          <KField
            label="Required notes"
            required
            errorText="Enter a description."
          >
            <KTextarea placeholder="Describe the next steps…" />
          </KField>
          <KField label="Read only">
            <KTextarea
              defaultValue={"Approved scope.\nAwaiting inspection."}
              readOnly
            />
          </KField>
          <KField label="Unavailable">
            <KTextarea defaultValue="Not available." disabled />
          </KField>
        </KStack>
      </KContainer>
    </div>
  );
}

const meta = {
  title: "Forms/Textarea",
  component: TextareaFixture,
  parameters: { fixtureId: "textarea-states" },
} satisfies Meta<typeof TextareaFixture>;
export default meta;
export const States: StoryObj<typeof meta> = { name: "textarea-states" };
