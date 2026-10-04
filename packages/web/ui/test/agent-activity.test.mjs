import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KAgentToolCall } from "../dist/chat/agent-parts.js";
import { KChatConversation } from "../dist/chat/conversation.js";

const tool = (id, state = "succeeded") => ({
  id,
  type: "tool",
  toolName: "search",
  title: "Issues durchsuchen",
  state,
  arguments: { project: "Orbit" },
});
const conversation = (parts, props = {}) =>
  renderToStaticMarkup(
    h(KChatConversation, {
      messages: [{ id: "message", role: "assistant", parts }],
      ...props,
    }),
  );

test("running tools start collapsed and errors remain visible outside the details", () => {
  const html = renderToStaticMarkup(
    h(KAgentToolCall, {
      part: { ...tool("one", "failed"), error: "Permission denied" },
    }),
  );
  assert.match(html, /aria-expanded="false"/);
  assert.match(html, /hidden=""/);
  assert.match(html, /<\/section>.*Permission denied/s);
  assert.match(
    renderToStaticMarkup(h(KAgentToolCall, { part: tool("one", "running") })),
    /aria-expanded="false"/,
  );
});

test("only consecutive tools group, preserving text and human gates in order", () => {
  const html = conversation([
    tool("one"),
    tool("two", "running"),
    {
      id: "question",
      type: "question",
      title: "Welches Projekt?",
      kind: "text",
      state: "pending",
    },
    tool("three"),
    { id: "text", type: "text", text: "Fertig" },
    tool("four"),
  ]);
  assert.equal((html.match(/k-agent-tool-group/g) ?? []).length, 1);
  assert.match(html, /Issues durchsuchen · 2×/);
  assert.ok(
    html.indexOf("Welches Projekt?") > html.indexOf("Issues durchsuchen · 2×"),
  );
});

test("failed tools are not hidden in a group and custom renderers remain untouched", () => {
  const html = conversation([
    tool("one"),
    { ...tool("two", "failed"), error: "Failed" },
  ]);
  assert.doesNotMatch(html, /k-agent-tool-group/);
  const custom = conversation([tool("one"), tool("two")], {
    toolRenderers: { search: (part) => h("p", {}, `custom-${part.id}`) },
  });
  assert.doesNotMatch(custom, /k-agent-tool-group/);
  assert.match(custom, /custom-one/);
  assert.match(custom, /custom-two/);
});
