---
title: "Cross-platform Chat and Agent UI"
date: 2026-09-24
---

# Cross-platform Chat and Agent UI

## Objective

Deliver an enterprise-grade, externally configurable Chat and Agent UI for Web
and Flutter with matching behavior and visual language. It must support normal
chat, streaming responses, attachments, tool calls, approvals, questions,
workflow progress, sources and artifacts while remaining independent of the
consumer's model provider, agent runtime, persistence and navigation.

Mode: Regular. The user selected Regular on 24 September 2026.

Status: approved on 24 September 2026. The user explicitly approved this Plan
and accepted Decision 0006, then authorized direct implementation.

## Scope

This Plan delivers core UI and stable adapter contracts. It does not connect a
live model or ship provider-specific adapters.

Allowed paths:

- `packages/web/ui/src/chat/` and the equivalent Flutter `src/chat/`: public
  models, controlled components, render registries and interaction behavior;
- existing package export barrels and package dependency manifests;
- platform-neutral token source, generator outputs and token tests only for
  evidenced Chat/Agent component roles not already covered by semantic tokens;
- focused Web and Flutter component tests;
- matching Storybook and Widgetbook fixtures and their deterministic demo
  controllers;
- component documentation, this Plan, its index and proposed Decision 0006.

No backend endpoint, API key, LLM/provider client, persistent conversation
store, authentication, arbitrary agent-generated widget execution, live
Vercel/AG-UI adapter, visual baseline update, commit, push or publication is in
scope. Existing components are changed only when a defect prevents their reuse.

## Governing decisions

- [Decision 0006](../decisions/0006-transport-neutral-agent-ui-contract.md)
  owns the state and adapter boundary.
- [Decision 0005](../decisions/0005-tiered-design-token-contract.md) owns visual
  customization and token cascade.
- [Decision 0001](../decisions/0001-adaptive-foundation.md) owns adaptive input,
  window and accessibility behavior.
- [Decision 0003](../decisions/0003-unified-density-composition.md) owns density
  and composition spacing.

## Public component set

The exact native-language signatures may differ, but Web and Flutter expose the
same concepts and states:

1. **`KChatConversation`** — scrollable controlled timeline, empty state,
   incremental history loading, stable scroll anchoring, unread/new-content
   affordance and scroll-to-latest action.
2. **`KChatMessage` / `KChatMessagePart` renderers** — user, assistant and system
   presentation; streamed Markdown; attachments; sources; status/error parts;
   timestamps, identity and consumer actions.
3. **`KChatComposer`** — multiline prompt, submit/stop states, attachments,
   configurable leading/trailing tools, keyboard shortcuts and validation.
4. **`KAgentToolCall`** — generic stateful fallback plus registry-based custom
   renderer, arguments/result disclosure and retry/open callbacks supplied by
   the consumer.
5. **`KAgentApproval`** — exact action summary, typed options, optional reason,
   single-response lifecycle and resolved history.
6. **`KAgentQuestion`** — confirmation, single choice, multiple choice, free
   text and consumer-rendered custom input.
7. **`KAgentTaskGroup`** — collapsible ordered progress with pending, active,
   completed, failed and skipped steps.
8. **`KAgentSources` and `KAgentArtifact`** — citations and product-owned
   artifact references with configurable activation and preview renderers.
9. **`KAgentActivity`** — concise activity/reasoning summary with accessible
   disclosure; no raw private chain-of-thought contract.
10. **Adapter interfaces** — translate a host snapshot/event into controlled
    conversation state and translate UI intents back to the host.

Every component supports external labels, icons, content builders/renderers,
formatters, accessible names and lifecycle callbacks. Core models never carry
React nodes or Flutter widgets; renderer registries keep serializable state
separate from presentation.

## Implementation waves

### 1. Contract, tokens and deterministic state

- Add equivalent TypeScript and Dart immutable models with stable message,
  part, run, tool, approval and question IDs.
- Add exhaustive state transitions and adapter interfaces without transport
  dependencies.
- Add only evidenced component tokens for message surfaces, composer geometry,
  tool/approval status accents and streaming feedback.
- Add parity fixtures serialized as JSON where both platforms can consume the
  same semantic data.

### 2. Conversation, message and composer foundation

- Implement the controlled timeline with lazy history loading, bottom anchoring
  and no forced scrolling while a user reads earlier content.
- Implement user/assistant/system messages, attachments and status/error parts
  by composing existing components.
- Add streaming Markdown and code blocks with selection, copy, safe link events
  and reduced-motion behavior.
- Implement the prompt composer, submit/stop behavior, attachments and full
  keyboard/touch semantics.

### 3. Tools and human-in-the-loop interactions

- Implement generic and registered tool renderers for every lifecycle state.
- Implement approvals whose controls disappear after one accepted response and
  whose resolved decision remains visible.
- Implement question types, validation, submit/cancel events and custom-form
  renderer slots.
- Ensure pending interactions survive unrelated message updates and cannot
  answer stale or resolved requests in the UI.

### 4. Agent progress, sources and artifacts

- Implement task/progress groups, activity summaries, citations and artifact
  references.
- Reuse Disclosure, Progress, Badge, Alert, Attachment, Button and existing
  overlay primitives instead of recreating their behavior.
- Provide safe fallbacks for unknown part types, unknown tools and unavailable
  artifact renderers.

### 5. Galleries and parity hardening

- Add matching Storybook and Widgetbook fixtures: `chat-empty`, `chat-basic`,
  `chat-streaming`, `chat-long-history`, `chat-attachments`, `agent-tools`,
  `agent-approval`, `agent-question`, `agent-tasks`, `agent-sources-artifacts`
  and `agent-error-recovery`.
- Add deterministic gallery controls that move through states without network
  access or secrets.
- Compare compact portrait, medium and large layouts under Light/Dark,
  Orbit/Reference, Dense/Standard/Spacious and increased text scale.
- Correct parity defects without updating unrelated accepted visuals.

## Interaction and accessibility requirements

- New streamed content follows the viewport only while the user is already at
  the latest content; otherwise a reachable new-content action appears.
- Focus remains stable during streaming and after tool-state replacement.
- Approval and question actions are keyboard and touch accessible, announce
  state changes and cannot be submitted twice.
- Tool arguments, results, code and long URLs wrap or scroll within their own
  bounded region without widening the conversation.
- Composer shortcuts do not conflict with multiline input or IME composition.
- Text selection, copy, link activation and attachment activation are explicit
  consumer events on both platforms.
- Reduced motion disables decorative streaming and transition effects without
  delaying content.
- Default touch targets, focus rings, contrast and semantic labels meet the
  repository's existing accessibility contract.

## Tests and observable evidence

Targeted development checks:

- Web package build/typecheck and focused interaction tests for timeline,
  composer, tool, approval and question behavior;
- Flutter analyze plus focused widget tests for the same state matrix, touch,
  keyboard, semantics and scroll anchoring;
- model parity tests against the shared JSON fixtures;
- Markdown safety tests, incomplete-stream fixtures and long code/table cases;
- token generation/audit checks after any token addition;
- Storybook/Widgetbook hot-reload review after each wave.

Final integrated verification:

```text
pnpm install --frozen-lockfile
dart pub get
pnpm verify
git diff --check
```

The final report lists public APIs, dependencies, token additions, parity
fixtures, tested state transitions, gallery links and any documented platform
deviation. Passing automation does not constitute Human visual acceptance.

## Risks and controls

- **Provider coupling:** provider types remain in later adapters, never core UI.
- **State explosion:** discriminated parts and exhaustive state tests make every
  state explicit; unknown parts retain a safe fallback.
- **Streaming jank:** stable IDs, coalesced updates and long-response fixtures
  guard rebuild and scroll behavior; renderers remain replaceable.
- **Approval theater:** UI responses refer to exact request IDs and options;
  documentation states that backend authorization and execution gates are
  mandatory.
- **Generated UI risk:** arbitrary schemas are deferred; only registered
  renderers receive typed, validated data.
- **Token growth:** reuse semantic roles first and require a consumer-visible
  need for every Chat/Agent component token.
- **Oversized first delivery:** waves are separately reviewable, but the public
  model contract is established once before visual component work.

## Definition of done

All scoped components and shared fixtures exist on both platforms; controlled
state and adapter contracts are documented; the complete tool/approval/question
state matrix is tested; final verification passes; both galleries are available
for side-by-side Human visual and interaction review.

Human acceptance, commit authorization, provider-adapter work, push and
publication remain separate gates.
