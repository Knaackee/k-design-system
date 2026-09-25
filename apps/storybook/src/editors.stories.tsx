import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  CodeEditorFixture,
  CodeEditorMobileFixture,
  EditorCollaborationFixture,
  MarkdownEditorFixture,
  MarkdownEditorMobileFixture,
} from "./editor-fixture.js";

const mobileGlobals = {
  viewport: { value: "editor-mobile", isRotated: false },
  inputMode: "touch",
  windowClass: "compact",
  density: "standard",
};

const mobileParameters = {
  layout: "fullscreen",
  viewport: {
    options: {
      "editor-mobile": {
        name: "Mobile · 375 × 812",
        styles: { width: "375px", height: "812px" },
        type: "mobile",
      },
    },
  },
};

const meta = {
  title: "Forms/Editors",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Markdown: Story = {
  name: "markdown-editor",
  render: () => <MarkdownEditorFixture />,
  parameters: { fixtureId: "markdown-editor" },
};

export const Code: Story = {
  name: "code-editor",
  render: () => <CodeEditorFixture />,
  parameters: { fixtureId: "code-editor" },
};

export const MarkdownMobile: Story = {
  name: "markdown-editor-mobile",
  render: () => <MarkdownEditorMobileFixture />,
  globals: mobileGlobals,
  parameters: { ...mobileParameters, fixtureId: "markdown-editor-mobile" },
};

export const CodeMobile: Story = {
  name: "code-editor-mobile",
  render: () => <CodeEditorMobileFixture />,
  globals: mobileGlobals,
  parameters: { ...mobileParameters, fixtureId: "code-editor-mobile" },
};

export const Collaboration: Story = {
  name: "editor-collaboration",
  render: () => <EditorCollaborationFixture />,
  parameters: { fixtureId: "editor-collaboration" },
};
