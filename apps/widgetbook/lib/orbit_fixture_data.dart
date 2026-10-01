import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const orbitLevels = [
  KOrbitLevel(id: 'issues', label: 'Issues', radius: 160, periodSeconds: 90),
  KOrbitLevel(
    id: 'agents',
    label: 'Agents',
    radius: 58,
    periodSeconds: 60,
    clockwise: false,
  ),
];

const orbitDeepLevels = [
  ...orbitLevels,
  KOrbitLevel(id: 'subtasks', label: 'Subtasks', radius: 28, periodSeconds: 50),
  KOrbitLevel(
    id: 'signals',
    label: 'Signals',
    radius: 13,
    periodSeconds: 45,
    clockwise: false,
  ),
];

List<KOrbitNode> orbitNodes(KDesignTokens tokens) => [
  KOrbitNode(
    id: 'team',
    label: 'Platform team',
    description: 'The shared command center',
    radius: 46,
    backgroundColor: tokens.colorSurfaceRaised,
    borderColor: tokens.colorBorderDefault,
    badge: const KOrbitBadge(
      content: Text('3'),
      label: '3 issues',
      tone: KOrbitTone.info,
    ),
    tone: KOrbitTone.info,
    appearance: KOrbitNodeAppearance.avatar,
    content: const Text('PT'),
  ),
  const KOrbitNode(
    id: 'issue-a',
    parentId: 'team',
    levelId: 'issues',
    label: 'Token parity',
    description: 'Align Web and Flutter tokens',
    radius: 22,
    phase: .05,
    tone: KOrbitTone.warning,
    status: KOrbitStatus.question,
    statusLabel: 'Needs your answer',
    pulse: true,
    appearance: KOrbitNodeAppearance.icon,
    content: KIcon(KIconName.circleAlert, size: 22),
  ),
  const KOrbitNode(
    id: 'issue-b',
    parentId: 'team',
    levelId: 'issues',
    label: 'Release readiness',
    description: 'Prepare the supported release',
    radius: 18,
    progress: 42,
    phase: 2.2,
    tone: KOrbitTone.success,
    status: KOrbitStatus.active,
    content: KIcon(KIconName.rocket),
  ),
  const KOrbitNode(
    id: 'issue-c',
    parentId: 'team',
    levelId: 'issues',
    label: 'Migration guide',
    description: 'Document the consumer path',
    radius: 16,
    phase: 4.35,
    status: KOrbitStatus.completed,
    content: KIcon(KIconName.fileText),
  ),
  const KOrbitNode(
    id: 'agent-orbit',
    parentId: 'issue-a',
    levelId: 'agents',
    label: 'Orbit agent',
    description: 'Works on shared components',
    radius: 10,
    phase: .7,
    tone: KOrbitTone.info,
    status: KOrbitStatus.active,
    appearance: KOrbitNodeAppearance.icon,
    content: KIcon(KIconName.bot, size: 16),
  ),
  const KOrbitNode(
    id: 'agent-mina',
    parentId: 'issue-b',
    levelId: 'agents',
    label: 'Mina',
    description: 'Product designer',
    radius: 11,
    phase: 4.5,
    tone: KOrbitTone.success,
    appearance: KOrbitNodeAppearance.avatar,
    content: Text('MK'),
  ),
];

const orbitAddedNodes = [
  KOrbitNode(
    id: 'issue-added',
    parentId: 'team',
    levelId: 'issues',
    label: 'New issue',
    description: 'Added from the command center',
    radius: 17,
    phase: 5.45,
    tone: KOrbitTone.warning,
    status: KOrbitStatus.question,
    content: KIcon(KIconName.plus),
  ),
  KOrbitNode(
    id: 'agent-added',
    parentId: 'issue-added',
    levelId: 'agents',
    label: 'New agent',
    description: 'Assigned with its issue',
    radius: 9,
    phase: 1.8,
    tone: KOrbitTone.info,
    status: KOrbitStatus.active,
    appearance: KOrbitNodeAppearance.icon,
    content: KIcon(KIconName.bot, size: 14),
  ),
];

const orbitDeepExtraNodes = [
  KOrbitNode(
    id: 'subtask-a',
    parentId: 'agent-orbit',
    levelId: 'subtasks',
    label: 'Verify Web',
    radius: 7,
    phase: 1.2,
    tone: KOrbitTone.warning,
    status: KOrbitStatus.active,
    content: KIcon(KIconName.check),
  ),
  KOrbitNode(
    id: 'signal-a',
    parentId: 'subtask-a',
    levelId: 'signals',
    label: 'Typecheck',
    radius: 4,
    phase: 3.1,
    tone: KOrbitTone.success,
    status: KOrbitStatus.completed,
    content: KIcon(KIconName.check),
  ),
];

const orbitConnections = [
  KOrbitConnection(
    id: 'team-issue-a',
    sourceId: 'team',
    targetId: 'issue-a',
    lineStyle: KOrbitLineStyle.solid,
  ),
  KOrbitConnection(
    id: 'team-issue-b',
    sourceId: 'team',
    targetId: 'issue-b',
    lineStyle: KOrbitLineStyle.solid,
  ),
  KOrbitConnection(
    id: 'team-issue-c',
    sourceId: 'team',
    targetId: 'issue-c',
    lineStyle: KOrbitLineStyle.solid,
  ),
  KOrbitConnection(
    id: 'issue-a-agent',
    sourceId: 'issue-a',
    targetId: 'agent-orbit',
  ),
  KOrbitConnection(
    id: 'issue-b-agent',
    sourceId: 'issue-b',
    targetId: 'agent-mina',
  ),
  KOrbitConnection(
    id: 'agents-communication',
    sourceId: 'agent-orbit',
    targetId: 'agent-mina',
    lineStyle: KOrbitLineStyle.dotted,
  ),
];

const orbitAddedConnections = [
  KOrbitConnection(
    id: 'team-issue-added',
    sourceId: 'team',
    targetId: 'issue-added',
  ),
  KOrbitConnection(
    id: 'issue-added-agent',
    sourceId: 'issue-added',
    targetId: 'agent-added',
  ),
];

const orbitDeepConnections = [
  ...orbitConnections,
  KOrbitConnection(
    id: 'agent-subtask',
    sourceId: 'agent-orbit',
    targetId: 'subtask-a',
  ),
  KOrbitConnection(
    id: 'subtask-signal',
    sourceId: 'subtask-a',
    targetId: 'signal-a',
  ),
];

const orbitSpacingLevels = [
  KOrbitLevel(id: 'teams', label: 'Teams', radius: 180, periodSeconds: 180),
  KOrbitLevel(
    id: 'projects',
    label: 'Projects',
    radius: 100,
    periodSeconds: 150,
  ),
  KOrbitLevel(id: 'issues', label: 'Issues', radius: 50, periodSeconds: 120),
  KOrbitLevel(
    id: 'issues-0',
    label: 'Issues',
    radius: 50,
    periodSeconds: 120,
    color: Color(0xff6366f1),
  ),
  KOrbitLevel(
    id: 'issues-1',
    label: 'Issues',
    radius: 50,
    periodSeconds: 120,
    color: Color(0xff0ea5e9),
  ),
  KOrbitLevel(
    id: 'issues-2',
    label: 'Issues',
    radius: 50,
    periodSeconds: 120,
    color: Color(0xfff59e0b),
  ),
  KOrbitLevel(id: 'agents', label: 'Agents', radius: 20, periodSeconds: 90),
];
final orbitSpacingNodes = <KOrbitNode>[
  const KOrbitNode(
    id: 'workspace',
    label: 'Workspace',
    radius: 28,
    content: KIcon(KIconName.orbit),
  ),
  const KOrbitNode(
    id: 'team',
    label: 'Platform team',
    radius: 23,
    parentId: 'workspace',
    levelId: 'teams',
    content: Text('PT'),
  ),
  for (var project = 0; project < 3; project++) ...[
    KOrbitNode(
      id: 'project-$project',
      label: 'Project ${project + 1} · ${[1, 8, 20][project]} issues',
      radius: 18,
      parentId: 'team',
      levelId: 'projects',
      borderColor: const [
        Color(0xff6366f1),
        Color(0xff0ea5e9),
        Color(0xfff59e0b),
      ][project],
      content: KIcon(
        const [KIconName.rocket, KIconName.code, KIconName.palette][project],
        color: const [
          Color(0xff6366f1),
          Color(0xff0ea5e9),
          Color(0xfff59e0b),
        ][project],
      ),
    ),
    for (var issue = 0; issue < [1, 8, 20][project]; issue++)
      KOrbitNode(
        id: 'issue-$project-$issue',
        label: 'Issue ${project + 1}.${issue + 1}',
        radius: 12,
        parentId: 'project-$project',
        levelId: 'issues-$project',
        content: const KIcon(KIconName.circleDot),
      ),
    KOrbitNode(
      id: 'agent-$project',
      label: 'Agent ${project + 1}',
      radius: 9,
      parentId: 'issue-$project-0',
      levelId: 'agents',
      status: KOrbitStatus.active,
      content: const KIcon(KIconName.bot),
    ),
  ],
];
