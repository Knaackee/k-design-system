import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { KChatComposer, KDictationState, KStack } from "@k-design-system/ui";

function ComposerFixture({ mobile = false }: { mobile?: boolean }) {
  const [voiceActive, setVoiceActive] = useState(false);
  const [value, setValue] = useState("Check both platforms");
  return (
    <div style={{ maxWidth: mobile ? 360 : 800 }}>
      <KStack align="stretch" gap="section">
        <KChatComposer
          value={value}
          onValueChange={setValue}
          onSubmit={() => undefined}
          onAttach={() => undefined}
          voiceActive={voiceActive}
          onVoiceInput={() => setVoiceActive((active) => !active)}
        />
        <KChatComposer
          value="Recording"
          onValueChange={() => undefined}
          onSubmit={() => undefined}
          onAttach={() => undefined}
          voiceActive
          voiceAudioLevel={0.5}
          onVoiceInput={() => undefined}
        />
        <KChatComposer
          value="Unavailable"
          disabled
          onValueChange={() => undefined}
          onSubmit={() => undefined}
          onVoiceInput={() => undefined}
        />
        <KChatComposer
          value=""
          runState="streaming"
          onValueChange={() => undefined}
          onSubmit={() => undefined}
          onStop={() => undefined}
          onVoiceInput={() => undefined}
        />
        {[
          KDictationState.processing,
          KDictationState.unavailable,
          KDictationState.error,
        ].map((state) => (
          <KChatComposer
            key={state}
            value={state}
            voiceState={state}
            onValueChange={() => undefined}
            onSubmit={() => undefined}
            onVoiceInput={() => undefined}
          />
        ))}
        <KChatComposer
          value="Voice omitted"
          onValueChange={() => undefined}
          onSubmit={() => undefined}
        />
      </KStack>
    </div>
  );
}

const meta = {
  title: "Patterns/ChatComposer",
  component: ComposerFixture,
} satisfies Meta<typeof ComposerFixture>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Controls: Story = {
  name: "chat-composer-controls",
  parameters: { fixtureId: "chat-composer-controls" },
};
export const Mobile: Story = {
  name: "chat-composer-mobile",
  args: { mobile: true },
  parameters: { fixtureId: "chat-composer-mobile" },
};
