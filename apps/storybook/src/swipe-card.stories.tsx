import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import {
  KButton,
  KCard,
  KList,
  KListItem,
  KStack,
  KText,
  type KCardBorder,
  type KSwipeAction,
} from "@k-design-system/ui";

// Decision 0016: swipe actions on list rows and KCard border effects.
// Widgetbook twins: lib/swipe_card_fixtures.dart (same fixture ids).

export default {
  title: "Data display/Swipe and card effects",
  parameters: { layout: "padded" },
} satisfies Meta;

const people = [
  ["Mara Feld", "Moved the appointment to Thursday 14:00"],
  ["Jonas Kühn", "Question about invoice 2026-118"],
  ["Lea Brandt", "New booking: cut & blow-dry"],
  ["Tom Seidel", "Thanks, see you next week!"],
] as const;

export function SwipeListFixture() {
  const [rows, setRows] = useState(people.map(([name]) => name));
  const [log, setLog] = useState("Swipe a row, or hover it with a pointer.");
  const actions = (name: string): [KSwipeAction[], KSwipeAction[]] => [
    [
      {
        id: "read",
        label: "Read",
        icon: "mail-open",
        tone: "info",
        onSelect: () => setLog(`Marked ${name} as read`),
      },
    ],
    [
      {
        id: "flag",
        label: "Flag",
        icon: "flag",
        tone: "warning",
        onSelect: () => setLog(`Flagged ${name}`),
      },
      {
        id: "delete",
        label: "Delete",
        icon: "trash",
        tone: "destructive",
        fullSwipe: true,
        onSelect: () => {
          setRows((all) => all.filter((row) => row !== name));
          setLog(`Deleted ${name}`);
        },
      },
    ],
  ];
  return (
    <KStack gap="action" style={{ maxWidth: 420 }}>
      <KList>
        {people
          .filter(([name]) => rows.includes(name))
          .map(([name, text]) => {
            const [leading, trailing] = actions(name);
            return (
              <KListItem
                key={name}
                title={name}
                description={text}
                onClick={() => setLog(`Opened ${name}`)}
                leadingActions={leading}
                trailingActions={trailing}
              />
            );
          })}
      </KList>
      <KText variant="bodySmall" role="status">
        {log}
      </KText>
      <KButton
        variant="secondary"
        onClick={() => setRows(people.map(([name]) => name))}
      >
        Reset list
      </KButton>
    </KStack>
  );
}

export const SwipeList: StoryObj = {
  name: "list-swipe",
  parameters: { fixtureId: "list-swipe" },
  render: () => <SwipeListFixture />,
};

const effects: { border: KCardBorder; title: string; text: string }[] = [
  {
    border: "pulse",
    title: "Waiting for you",
    text: "A question or approval needs input.",
  },
  {
    border: "spin",
    title: "Agent working",
    text: "A process runs until its result arrives.",
  },
  {
    border: "aurora",
    title: "AI input active",
    text: "Composer while the agent responds.",
  },
  {
    border: "flame",
    title: "Urgent",
    text: "A deadline or critical error. Use sparingly.",
  },
  {
    border: "dashed",
    title: "Drop here",
    text: "Drop zone while dragging a file.",
  },
  { border: "shimmer", title: "Loading", text: "Content arrives in a moment." },
  {
    border: "success",
    title: "Saved",
    text: "One pulse after a successful action.",
  },
];

export function CardBordersFixture() {
  return (
    <div
      style={{
        display: "grid",
        gap: 24,
        gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))",
      }}
    >
      {effects.map((effect) => (
        <KCard
          key={effect.border}
          border={effect.border}
          title={effect.title}
          description={effect.border}
        >
          <KText variant="bodySmall">{effect.text}</KText>
        </KCard>
      ))}
    </div>
  );
}

export const CardBorders: StoryObj = {
  name: "card-borders",
  parameters: { fixtureId: "card-borders" },
  render: () => <CardBordersFixture />,
};

export function CardHeaderFixture() {
  return (
    <div style={{ maxWidth: 360 }}>
      <KCard
        title="Rocky"
        description="Agent · working for 4 min"
        menu={[
          { id: "edit", label: "Edit", icon: "pencil" },
          { id: "duplicate", label: "Duplicate", icon: "copy" },
          {
            id: "delete",
            label: "Delete",
            icon: "trash",
            destructive: true,
            separatorBefore: true,
          },
        ]}
        actions={
          <>
            <KButton>Open</KButton>
            <KButton variant="secondary">Pause</KButton>
          </>
        }
      >
        <KText variant="bodySmall">
          Groups the feedback entries from the sheet by theme.
        </KText>
      </KCard>
    </div>
  );
}

export const CardHeader: StoryObj = {
  name: "card-header",
  parameters: { fixtureId: "card-header" },
  render: () => <CardHeaderFixture />,
};

/** Playground: border effect, colour and speed are props. */
export const CardBorderPlayground: StoryObj<{
  border: KCardBorder;
  borderColor: string;
  borderDuration: number;
}> = {
  name: "card-border-playground",
  args: { border: "spin", borderColor: "", borderDuration: 0 },
  argTypes: {
    border: {
      control: "select",
      options: [
        "none",
        "pulse",
        "spin",
        "aurora",
        "flame",
        "dashed",
        "shimmer",
        "success",
      ],
    },
    borderColor: { control: "color" },
    borderDuration: {
      control: { type: "range", min: 0, max: 8000, step: 100 },
    },
  },
  render: ({ border, borderColor, borderDuration }) => (
    <div style={{ maxWidth: 360 }}>
      <KCard
        key={`${border}-${borderDuration}`}
        border={border}
        borderColor={borderColor || undefined}
        borderDuration={borderDuration || undefined}
        title="Configurable border"
        description="Effect, colour and duration are props; defaults come from component.cardBorder tokens."
      />
    </div>
  ),
};
