import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import {
  KContainer,
  KDictationAction,
  KDictationState,
  KField,
  KInput,
  KStack,
  KTextarea,
} from "@k-design-system/ui";

function DictationFixture() {
  const [state, setState] = useState(KDictationState.ready);
  const action = (
    <KDictationAction
      state={state}
      label={
        state === KDictationState.recording
          ? "Stop dictation"
          : "Start dictation"
      }
      onPressed={() =>
        setState(
          state === KDictationState.recording
            ? KDictationState.ready
            : KDictationState.recording,
        )
      }
    />
  );
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KField label="Title">
            <KInput
              defaultValue="Inspect the roof"
              dictationState={state}
              dictationOffset={8}
              clearable
              trailingAction={action}
            />
          </KField>
          <KField label="Notes">
            <KTextarea
              dictationState={state}
              dictationOffset={9}
              defaultValue="Describe the next steps"
              placeholder="Describe the next steps…"
              trailingAction={action}
            />
          </KField>
          {Object.values(KDictationState).map((status) => (
            <KField key={status} label={status}>
              <KInput
                dictationState={status}
                dictationOffset={0}
                trailingAction={
                  <KDictationAction
                    state={status}
                    label={`Dictation ${status}`}
                    onPressed={() => undefined}
                  />
                }
              />
            </KField>
          ))}
          {[0, 0.5, 1].map((level) => (
            <KField
              key={level}
              label={`Recording level sample ${level.toFixed(1)}`}
            >
              <KInput
                trailingAction={
                  <KDictationAction
                    state={KDictationState.recording}
                    label="Stop dictation"
                    audioLevel={level}
                    onPressed={() => undefined}
                  />
                }
              />
            </KField>
          ))}
          <KField label="Read only">
            <KInput readOnly trailingAction={action} />
          </KField>
          <KField label="Unavailable">
            <KTextarea disabled trailingAction={action} />
          </KField>
        </KStack>
      </KContainer>
    </div>
  );
}

const meta = {
  title: "Forms/Dictation",
  component: DictationFixture,
  parameters: { fixtureId: "dictation-controls" },
} satisfies Meta<typeof DictationFixture>;
export default meta;
export const Controls: StoryObj<typeof meta> = { name: "dictation-controls" };
