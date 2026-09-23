import type { Meta, StoryObj } from "@storybook/react-vite";
import { OtpFixture } from "./extended-component-fixtures.js";
export default {
  title: "Forms/InputOTP",
  component: OtpFixture,
} satisfies Meta<typeof OtpFixture>;
export const Code: StoryObj<typeof OtpFixture> = {
  name: "input-otp-code",
  parameters: { fixtureId: "input-otp-code" },
};
