# Decision 0006 — Transport-neutral Chat and Agent UI contract

> Status: **accepted for implementation**  
> Date: 24 September 2026  
> Scope: public Chat and Agent UI state, rendering and adapter boundaries across
> Web and Flutter
> Human approval: 24 September 2026 — “Ich genehmige den Plan und akzeptiere”

## Context

K Design System needs matching Chat and Agent UI components for Web and Flutter.
The UI must render ordinary conversation, streaming assistant responses, tool
calls, approvals, user questions, workflow progress, sources and artifacts. It
must remain usable with Vercel AI SDK, AG-UI, Flutter AI Toolkit and proprietary
backends without making any of those transports part of the component API.

Vercel AI SDK UI and AI Elements provide a strong Web reference for message
parts, streaming, tools and approval responses. AG-UI provides a transport
protocol for agent events, and a young Dart implementation exists. Flutter AI
Toolkit provides a provider abstraction and function calling, while Flutter
GenUI can render agent-selected widgets from an allowed catalog but remains
experimental. Their state models and maturity differ, so exposing one directly
would make cross-platform parity and future compatibility dependent on an
external implementation.

## Decision

Define an owned, transport-neutral public contract in both UI packages. Web and
Flutter expose equivalent names, states and lifecycle semantics in their native
languages. The contract is controlled: consumers own conversation data and
side effects; components render state and emit typed intent callbacks.

### Message and run model

An agent conversation contains stable-ID messages. Each message contains an
ordered, discriminated list of parts. The initial public part kinds are:

- text/Markdown;
- attachment;
- source/citation;
- tool call;
- approval request;
- question/input request;
- task/progress group;
- artifact reference;
- status/error notice.

Messages and parts remain immutable values. Streaming updates replace the
affected value under the same stable ID. Run state is distinct from message
content and covers idle, submitted, streaming, awaiting input, stopped,
completed and failed states.

The UI may display a concise consumer-provided activity or reasoning summary.
It does not expose or encourage raw private chain-of-thought.

### Tool and human-interaction lifecycle

Tool calls have explicit pending, running, succeeded, failed, cancelled and
approval-required states. A renderer registry maps a tool name to a custom
consumer renderer; an accessible generic renderer is always available.

Approvals and questions are first-class parts rather than special text. An
approval response identifies the exact approval and selected option. A question
supports free text, single choice, multiple choice, confirmation and a
consumer-rendered custom form. Pending parts are actionable once; answered,
rejected, cancelled and expired parts remain visible as immutable history.

The component library never authorizes or executes a side effect. It emits the
consumer's response. The backend remains responsible for validating IDs,
parameters, authorization, idempotency and whether a request is still active.

### Adapter boundary

Core packages contain no model client, transport, persistence or agent runtime.
Adapters translate external event models into the owned contract and translate
typed UI intents back into their host APIs. Vercel AI SDK and AG-UI adapters are
separate follow-up packages or entry points and may depend on their respective
SDKs without adding those dependencies to the core UI packages.

The first implementation establishes tested adapter interfaces and deterministic
adapter fixtures, but it does not ship live Vercel, AG-UI, Firebase or model
connections.

### Rendering and customization

The components compose existing K Design primitives for controls, attachments,
badges, alerts, progress, disclosure and overlays. Content, icons, labels,
formatters, renderers, actions and callbacks are consumer-configurable. Visual
defaults use the tiered token contract from Decision 0005.

Default rich response rendering supports streaming GitHub-flavored Markdown,
links, lists, tables, task lists and fenced code. Web uses `streamdown`, matching
AI Elements' streaming-oriented approach. Flutter uses
`flutter_markdown_plus`, with coalesced streaming updates and a replaceable
renderer boundary. Both sanitize or reject unsafe embedded content and delegate
link activation to the consumer.

### Platform behavior

The information architecture and state behavior are identical. Platform-native
input behavior remains allowed: Web supplies keyboard, pointer, selection and
ARIA semantics; Flutter supplies keyboard, pointer, touch and Semantics. Both
honor reduced motion, text scaling, safe areas, density and minimum hit targets.

## Alternatives considered

- **Expose Vercel AI SDK types directly:** excellent Web ergonomics, but no
  equivalent Flutter contract and an inappropriate dependency for core UI.
- **Expose AG-UI directly:** transport-neutral in intent, but its Dart SDK is
  young and the protocol contains transport concerns that visual components do
  not need.
- **Use Flutter AI Toolkit as the Flutter component:** fast initial delivery,
  but makes Flutter appearance and lifecycle diverge from the owned Web API.
- **Ship only render props with no state vocabulary:** highly flexible, but
  leaves every consumer to rebuild lifecycle semantics and prevents dependable
  cross-platform parity.
- **Bundle live adapters in the first slice:** demonstrates integration sooner,
  but couples component hardening to network, backend and SDK-version work.

## Consequences

- Equivalent model definitions must be maintained in TypeScript and Dart, with
  parity fixtures guarding drift.
- External runtimes require explicit adapters, but the UI can evolve without
  changing model providers.
- Consumers retain responsibility for storage, transport, authorization and
  tool execution.
- Rich Markdown adds one reviewed rendering dependency per platform behind a
  replaceable boundary.
- New part kinds require a public-contract decision and fallback rendering.

Acceptance of this decision authorizes the contract for implementation. It does
not authorize a commit, push, publication, backend integration or live model
credentials.
