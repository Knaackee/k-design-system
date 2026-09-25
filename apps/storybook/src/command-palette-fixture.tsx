import { useState } from "react";
import {
  KButton,
  KCommandPalette,
  KKbd,
  KKbdGroup,
  KText,
  type KCommandPaletteItem,
} from "@k-design-system/ui";

const commands: readonly KCommandPaletteItem[] = [
  {
    id: "new",
    label: "Create new…",
    description: "Start with a new item",
    icon: "plus",
    group: "Actions",
    priority: 20,
    children: [
      {
        id: "new-issue",
        label: "Issue",
        icon: "circle-check",
        shortcut: ["N", "I"],
      },
      {
        id: "new-project",
        label: "Project",
        icon: "folder",
        shortcut: ["N", "P"],
      },
      {
        id: "new-document",
        label: "Document",
        icon: "file-text",
        shortcut: ["N", "D"],
      },
    ],
  },
  {
    id: "search",
    label: "Search workspace",
    description: "Find issues, projects and documents",
    keywords: ["find", "lookup"],
    icon: "search",
    shortcut: ["⌘", "F"],
    group: "Actions",
    priority: 10,
  },
  {
    id: "inbox",
    label: "Open inbox",
    description: "Review unread notifications",
    icon: "mail",
    shortcut: ["G", "I"],
    group: "Navigation",
  },
  {
    id: "projects",
    label: "Open projects",
    icon: "folder",
    shortcut: ["G", "P"],
    group: "Navigation",
  },
  {
    id: "settings",
    label: "Open settings",
    icon: "settings",
    shortcut: ["⌘", ","],
    group: "Navigation",
  },
  {
    id: "theme",
    label: "Change appearance…",
    description: "Choose a color theme",
    icon: "eye",
    group: "Preferences",
    children: [
      {
        id: "theme-system",
        label: "Use system appearance",
        icon: "sliders-horizontal",
      },
      { id: "theme-light", label: "Light appearance", icon: "eye" },
      { id: "theme-dark", label: "Dark appearance", icon: "eye-off" },
    ],
  },
  {
    id: "disabled",
    label: "Unavailable command",
    description: "Disabled items remain discoverable",
    icon: "lock",
    group: "Preferences",
    disabled: true,
  },
];

export function CommandPaletteFixture() {
  const [open, setOpen] = useState(true);
  const [result, setResult] = useState("No command selected");
  return (
    <div className="k-primitive-fixture">
      <KText variant="heading4">Command palette</KText>
      <KText>Run an action with search, touch or keyboard navigation.</KText>
      <KButton onClick={() => setOpen(true)}>
        Open commands&nbsp;
        <KKbdGroup>
          <KKbd>Ctrl</KKbd>
          <span>+</span>
          <KKbd>K</KKbd>
        </KKbdGroup>
      </KButton>
      <KText role="status">{result}</KText>
      <KCommandPalette
        open={open}
        onOpenChange={setOpen}
        items={commands}
        onCommand={async (item) => {
          await Promise.resolve();
          setResult(`${item.label} selected`);
        }}
      />
    </div>
  );
}
