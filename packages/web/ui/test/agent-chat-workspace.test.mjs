import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KAgentChatWorkspace } from "../dist/chat/agent-chat-workspace.js";

test("agent chat workspace exposes consumer slots and mobile agents trigger", () => {
  const html = renderToStaticMarkup(
    h(KAgentChatWorkspace, {
      sidebar: h("nav", { "aria-label": "Roster" }, "Roster"),
      avatar: h("span", { className: "hero-avatar" }, "Avatar"),
      title: "Ada",
      contentMaxWidth: 920,
      rightSidebar: h("p", {}, "Context"),
      rightSidebarOpen: false,
      status: h("span", { role: "status" }, "Bereit"),
      actions: h("button", {}, "Mehr"),
      composer: h("form", { "aria-label": "Composer" }),
      labels: { agents: "Agenten", closeAgents: "Agenten schließen" },
      children: h("article", {}, "Conversation"),
    }),
  );

  assert.match(html, /class="k-agent-chat-workspace"/);
  assert.match(html, /aria-haspopup="dialog"/);
  assert.match(html, /aria-expanded="false"/);
  assert.match(html, /class="hero-avatar"/);
  assert.match(html, /<h1 class="k-visually-hidden">Ada<\/h1>/);
  assert.match(html, /role="status">Bereit/);
  assert.match(html, /Conversation/);
  assert.match(html, /aria-label="Composer"/);
  assert.match(html, /--k-agent-chat-workspace-content-max-width:920px/);
  assert.match(html, /data-right-sidebar-open="false"/);
});

test("agent chat workspace CSS keeps the responsive shell contract", async () => {
  const css = await readFile(
    new URL("../src/chat/agent-chat-workspace.css", import.meta.url),
    "utf8",
  );

  assert.match(css, /@media \(min-width: 768px\)/);
  assert.match(
    css,
    /--k-agent-chat-workspace-sidebar-width: var\(--k-layout-panel-width\)/,
  );
  assert.match(css, /--k-agent-chat-workspace-avatar-mobile-size: calc/);
  assert.match(css, /--k-agent-chat-workspace-avatar-desktop-size: calc/);
  assert.match(css, /var\(--k-agent-chat-workspace-sidebar-width\)/);
  assert.match(css, /var\(--k-agent-chat-workspace-avatar-mobile-size\)/);
  assert.match(css, /var\(--k-agent-chat-workspace-avatar-desktop-size\)/);
  assert.match(css, /@media \(max-height: 620px\)/);
});

test("floating identity exposes size and motion controls without duplicating conversation", () => {
  const html = renderToStaticMarkup(
    h(KAgentChatWorkspace, {
      sidebar: "Agents",
      avatar: "Avatar",
      title: "Ada",
      composer: "Composer",
      children: "Unique conversation",
      avatarSizeMobile: 88,
      avatarSizeDesktop: 112,
      avatarSizeCompact: 48,
      avatarBackdropBlur: 6,
      avatarTransitionDuration: 0,
      showTitle: true,
      conversationEmpty: true,
      avatarSizeEmpty: 260,
      debugAvatarBounds: true,
    }),
  );
  assert.match(html, /data-show-title="true"/);
  assert.match(html, /data-conversation-empty="true"/);
  assert.match(html, /data-debug-avatar-bounds="true"/);
  assert.match(html, /--k-agent-chat-workspace-avatar-empty-size:260px/);
  assert.match(html, /--k-agent-chat-workspace-avatar-mobile-size:88px/);
  assert.match(html, /--k-agent-chat-workspace-avatar-transition:0ms/);
  assert.equal(html.split("Unique conversation").length, 2);
  assert.match(html, /k-agent-chat-workspace__stage/);
});

test("workspace avatar information is optional and has a keyboard-accessible label", () => {
  const html = renderToStaticMarkup(
    h(KAgentChatWorkspace, {
      sidebar: null,
      avatar: h("span", {}, "Avatar"),
      title: "Ada",
      avatarLabel: "Ada",
      avatarPopover: h("p", {}, "Private account data"),
      avatarPopoverLabel: "Ada: Zugang und Kontingente",
      composer: null,
      children: null,
    }),
  );
  assert.match(html, /class="k-agent-chat-workspace__avatar-label"/);
  assert.match(html, /aria-label="Ada: Zugang und Kontingente"/);
  assert.match(html, /aria-expanded="false"/);
  assert.doesNotMatch(html, /Private account data/);
});
