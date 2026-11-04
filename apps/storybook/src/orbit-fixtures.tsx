import {
  KIcon,
  type KOrbitLevel,
  type KOrbitNode,
  type KOrbitConnection,
} from "@k-design-system/ui";
export const levels: readonly KOrbitLevel[] = [
  { id: "issues", label: "Issues", radius: 160, periodSeconds: 90 },
  {
    id: "agents",
    label: "Agents",
    radius: 58,
    periodSeconds: 60,
    direction: -1,
  },
];

export const spacingLevels: readonly KOrbitLevel[] = [
  { id: "teams", label: "Teams", radius: 180, periodSeconds: 180 },
  { id: "projects", label: "Projects", radius: 100, periodSeconds: 150 },
  { id: "issues", label: "Issues", radius: 50, periodSeconds: 120 },
  ...["#6366f1", "#0ea5e9", "#f59e0b"].map((color, index) => ({
    id: `issues-${index}`,
    label: "Issues",
    radius: 50,
    periodSeconds: 120,
    color,
  })),
  { id: "agents", label: "Agents", radius: 20, periodSeconds: 90 },
];
export const spacingNodes: readonly KOrbitNode[] = [
  {
    id: "workspace",
    label: "Workspace",
    radius: 28,
    content: <KIcon name="orbit" />,
  },
  {
    id: "team",
    label: "Platform team",
    radius: 23,
    parentId: "workspace",
    levelId: "teams",
    content: "PT",
  },
  ...[1, 8, 20].flatMap((count, project) => [
    {
      id: `project-${project}`,
      label: `Project ${project + 1} · ${count} issues`,
      radius: 18,
      parentId: "team",
      levelId: "projects",
      borderColor: ["#6366f1", "#0ea5e9", "#f59e0b"][project],
      content: (
        <KIcon
          name={(["rocket", "code", "palette"] as const)[project]!}
          color={["#6366f1", "#0ea5e9", "#f59e0b"][project]}
        />
      ),
    },
    ...Array.from({ length: count }, (_, issue) => ({
      id: `issue-${project}-${issue}`,
      label: `Issue ${project + 1}.${issue + 1}`,
      radius: 12,
      parentId: `project-${project}`,
      levelId: `issues-${project}`,
      content: <KIcon name="circle-dot" />,
    })),
    {
      id: `agent-${project}`,
      label: `Agent ${project + 1}`,
      radius: 9,
      parentId: `issue-${project}-0`,
      levelId: "agents",
      status: "active" as const,
      content: <KIcon name="bot" />,
    },
  ]),
];

export const data: readonly KOrbitNode[] = [
  {
    id: "team",
    label: "Platform team",
    description: "The shared command center",
    radius: 46,
    backgroundColor: "var(--k-color-surface-raised)",
    borderColor: "var(--k-color-border-default)",
    badge: { content: "3", label: "3 issues", tone: "info" },
    tone: "info",
    appearance: "avatar",
    content: <span aria-hidden="true">PT</span>,
  },
  {
    id: "issue-a",
    parentId: "team",
    levelId: "issues",
    label: "Token parity",
    description: "Align Web and Flutter tokens",
    radius: 22,
    phase: 0.05,
    tone: "warning",
    status: "question",
    statusLabel: "Needs your answer",
    pulse: true,
    appearance: "icon",
    content: <KIcon name="circle-alert" size={24} />,
  },
  {
    id: "issue-b",
    progress: 42,
    parentId: "team",
    levelId: "issues",
    label: "Release readiness",
    description: "Prepare the supported release",
    content: <KIcon name="rocket" />,
    radius: 18,
    phase: 2.2,
    tone: "success",
    status: "active",
  },
  {
    id: "issue-c",
    parentId: "team",
    levelId: "issues",
    label: "Migration guide",
    description: "Document the consumer path",
    content: <KIcon name="file-text" />,
    radius: 16,
    phase: 4.35,
    status: "completed",
  },
  {
    id: "agent-orbit",
    parentId: "issue-a",
    levelId: "agents",
    label: "Orbit agent",
    description: "Works on shared components",
    radius: 10,
    phase: 0.7,
    tone: "info",
    status: "active",
    appearance: "icon",
    content: <KIcon name="bot" size={16} />,
  },
  {
    id: "agent-mina",
    parentId: "issue-b",
    levelId: "agents",
    label: "Mina",
    description: "Product designer",
    radius: 11,
    phase: 4.5,
    tone: "success",
    appearance: "avatar",
    content: <span aria-hidden="true">MK</span>,
  },
];

export const addedNodes: readonly KOrbitNode[] = [
  {
    id: "issue-added",
    parentId: "team",
    levelId: "issues",
    label: "New issue",
    description: "Added from the command center",
    content: <KIcon name="plus" />,
    radius: 17,
    phase: 5.45,
    tone: "warning",
    status: "question",
  },
  {
    id: "agent-added",
    parentId: "issue-added",
    levelId: "agents",
    label: "New agent",
    description: "Assigned with its issue",
    radius: 9,
    phase: 1.8,
    tone: "info",
    status: "active",
    appearance: "icon",
    content: <KIcon name="bot" size={16} />,
  },
];

export const connections: readonly KOrbitConnection[] = [
  {
    id: "team-issue-a",
    sourceId: "team",
    targetId: "issue-a",
    lineStyle: "solid",
  },
  {
    id: "team-issue-b",
    sourceId: "team",
    targetId: "issue-b",
    lineStyle: "solid",
  },
  {
    id: "team-issue-c",
    sourceId: "team",
    targetId: "issue-c",
    lineStyle: "solid",
  },
  { id: "issue-a-agent", sourceId: "issue-a", targetId: "agent-orbit" },
  { id: "issue-b-agent", sourceId: "issue-b", targetId: "agent-mina" },
  {
    id: "agents-communication",
    sourceId: "agent-orbit",
    targetId: "agent-mina",
    lineStyle: "dotted",
  },
];

export const addedConnections: readonly KOrbitConnection[] = [
  { id: "team-issue-added", sourceId: "team", targetId: "issue-added" },
  { id: "issue-added-agent", sourceId: "issue-added", targetId: "agent-added" },
];

export const deepLevels: readonly KOrbitLevel[] = [
  ...levels,
  { id: "subtasks", label: "Subtasks", radius: 28, periodSeconds: 50 },
  {
    id: "signals",
    label: "Signals",
    radius: 13,
    periodSeconds: 45,
    direction: -1,
  },
];

export const deepNodes: readonly KOrbitNode[] = [
  ...data,
  {
    id: "subtask-a",
    parentId: "agent-orbit",
    levelId: "subtasks",
    label: "Verify Web",
    content: <KIcon name="check" />,
    radius: 7,
    phase: 1.2,
    tone: "warning",
    status: "active",
  },
  {
    id: "signal-a",
    parentId: "subtask-a",
    levelId: "signals",
    label: "Typecheck",
    content: <KIcon name="check" />,
    radius: 4,
    phase: 3.1,
    tone: "success",
    status: "completed",
  },
];

export const deepConnections: readonly KOrbitConnection[] = [
  ...connections,
  { id: "agent-subtask", sourceId: "agent-orbit", targetId: "subtask-a" },
  { id: "subtask-signal", sourceId: "subtask-a", targetId: "signal-a" },
];
