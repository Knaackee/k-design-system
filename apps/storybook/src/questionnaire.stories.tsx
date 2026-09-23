import type { Meta, StoryObj } from "@storybook/react-vite";
import { QuestionnaireFixture } from "./extended-component-fixtures.js";
export default {
  title: "Patterns/Questionnaire",
  component: QuestionnaireFixture,
} satisfies Meta<typeof QuestionnaireFixture>;
export const Steps: StoryObj<typeof QuestionnaireFixture> = {
  name: "questionnaire-steps",
  parameters: { fixtureId: "questionnaire-steps" },
};
