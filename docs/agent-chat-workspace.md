# Agent chat workspace — visual review slice

Status: draft for joint Storybook/Widgetbook acceptance. No Tasks integration or publication in this slice.

## Intent and references

A full-screen agent conversation replaces the constrained chat popup. Persistent agents are the primary navigation; conversations belong to the selected agent. The avatar appears once, centered above the conversation, with explicit presence/activity text. Message authors remain accessible without repeating profile pictures on every message.

- User reference: [Grok Bot agent list](https://mobbin.com/screens/e73a46b0-dc6f-4c35-ade4-c2f232d9e24d).
- Viewed comparable [Grok Bot roster](https://mobbin.com/screens/a0e1945f-c561-4c0c-8381-567fcb998072).
- User reference: [Dots desktop conversation](https://images.ctfassets.net/kftzwdyauwt9/6FLrjxbFjTxYrhc6wKch43/85e34bf667a7837764568873e39a21b7/introducing-dots-carousel-proposal.png?w=3840&q=90&fm=webp).
- User reference: [Dots mobile avatar header](https://images.macrumors.com/t/thjtpOFtASYmYtSpave2gqRklUo=/1600x0/article-new/2026/09/openai-dots.jpg).
- User reference: [Muse mobile conversations](https://www.fvw.de/news/media/34/Meta-Muse-Screenshot-336014-detailp.jpeg).

## Public composition

- `KAgentChatWorkspace`: externally supplied sidebar, avatar, title, status, actions, conversation and composer. No auth, agents API, model provider or Rive dependency in the component package.
- `KAgentSwitcher`: retain its existing horizontal presentation; add a vertical roster presentation using the same controlled selection and reorder contract.
- Existing conversation/composer primitives: hide repeated visual author metadata while keeping message author semantics.
- Desktop/tablet: persistent left navigation. Compact viewport: full-screen conversation plus a left drawer, not a bottom-sheet conversation. Drawer closes after choosing an agent/conversation.
- Avatar header reduces on short viewports to leave room for reading and typing. All visible status/content originates from the consumer.
- Long press begins sorting; regular touch scroll remains available. Keyboard reordering and announcements remain available.

## Gallery fixtures and boundaries

Matching fixtures: `agent-chat-workspace-fullscreen`, `agent-chat-workspace-needs-input`, `agent-chat-workspace-offline`, `agent-chat-workspace-mobile`. Five sample agents; selected-agent conversations; controlled selection, order and drafts. These are illustrative states, not live Tasks data or real agent execution.

The galleries share the user-owned RiveCharacter V2 asset and its provenance in `apps/widgetbook/assets/rive`. Each gallery injects its own renderer through the avatar slot. The published layout API does not require Rive or a particular character set.

Human review: proportions and character framing; sidebar density; drag and drop; agent/conversation selection; composer and scrolling; compact drawer; keyboard focus; offline and needs-input states; matching Web/Flutter appearance.

Review URLs:

- Web: http://127.0.0.1:6006/?path=/story/patterns-agentchatworkspace--fullscreen
- Flutter: http://127.0.0.1:6007/#/?path=patterns/agentchatworkspace/fullscreen

Technical review found two parity defects, now corrected: Web conversation-specific draft/history state and Flutter vertical roster geometry. Browser inspection additionally corrected the Web Rive state-machine binding, the V2 squircle enum, and Flutter shape-default/color ordering. Targeted component tests, analyzer/typechecks, and manual conversation/drawer checks passed. Visual Human Acceptance remains pending. The Tasks Flutter-parity checklist records this new full-screen direction; no Tasks chat integration was performed.

## Integration after acceptance

Tasks supplies authorized agents, saved ordering, actual sessions, current presence/activity, avatar configuration and chat transport. A conversation is a user-facing object; native execution sessions and handovers must not silently create confusing extra sidebar chats. Existing scopes and authorization remain unchanged.

This slice starts from `ec58862e44ef93c54974522eab1eb3425b7935a2` on `codex/agent-chat-workspace`, preserving earlier local changes and commits. The repository uses `origin/main`; it is an ancestor of this baseline. No reset, merge, push or parent submodule-pointer update is performed here.
