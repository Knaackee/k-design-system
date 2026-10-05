import { useState } from "react";
import {
  KAgentQuestion,
  KDictationAction,
  KDictationState,
  KInput,
} from "@k-design-system/ui";

export function AgentQuestionDictationFixture() {
  const [state, setState] = useState(KDictationState.ready);
  const action = (
    <KDictationAction
      state={state}
      label={state === KDictationState.recording ? "Stop dictation" : "Start dictation"}
      onPressed={() =>
        setState((current) =>
          current === KDictationState.recording
            ? KDictationState.ready
            : KDictationState.recording,
        )
      }
    />
  );
  return (
    <div className="k-primitive-fixture">
      <KAgentQuestion
        part={{
          id: "agent-ui-text-question-dictation",
          type: "question",
          title: "What should the agent remember?",
          description: "The host owns recording and transcription.",
          kind: "text",
          state: "pending",
          placeholder: "Speak or type a note…",
          submitLabel: "Save note",
        }}
        inputRenderer={({ value, onChange }) => (
          <KInput
            value={value}
            placeholder="Speak or type a note…"
            onChange={(event) => onChange(event.target.value)}
            dictationState={state}
            trailingAction={action}
          />
        )}
      />
    </div>
  );
}
