import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KAgentSwitcher } from "../dist/chat/agent-switcher.js";
import { moveAgentId } from "../dist/chat/use-agent-switcher-reorder.js";

const items = [
  {
    id: "ada",
    name: "Ada",
    connection: "online",
    activity: "working",
    unread: 2,
  },
  {
    id: "linus",
    name: "Linus",
    connection: "sleeping",
    activity: "idle",
  },
];

test("settings rows expose configured avatars, sibling controls and disabled unpinned handles", () => {
  const html = renderToStaticMarkup(
    h(KAgentSwitcher, {
      variant: "settings",
      orientation: "vertical",
      selectedId: null,
      onSelect() {},
      onReorder() {},
      items: [
        {
          id: "ada",
          name: "Ada",
          avatar: h("span", {}, "Configured avatar"),
          controlContent: h("button", { role: "switch" }, "Pin Ada"),
        },
        { id: "linus", name: "Linus", reorderable: false },
      ],
    }),
  );
  assert.match(html, /Configured avatar/);
  assert.match(
    html,
    /role="switch">Pin Ada<\/button><button[^>]*class="k-agent-switcher__settings-handle"/,
  );
  assert.match(html, /aria-label="Linus:[^"]*"[^>]*disabled=""/);
  assert.doesNotMatch(html, /aria-pressed=/);
});

test("agent switcher exposes selection and independent status semantics", () => {
  const html = renderToStaticMarkup(
    h(KAgentSwitcher, {
      items,
      selectedId: "ada",
      onSelect() {},
      onManage() {},
      labels: {
        connectionSleeping: "Schläft",
        activityIdle: "In Ruhe",
        activityWorking: "Arbeitet",
        connectionPrefix: "Verbindung",
        activityPrefix: "Aktivität",
        unreadMessages: (count) => `${count} ungelesene Nachrichten`,
      },
    }),
  );

  assert.match(
    html,
    /aria-label="Ada, Verbindung: Online, Aktivität: Arbeitet, 2 ungelesene Nachrichten"[^>]*aria-pressed="true"/,
  );
  assert.match(
    html,
    /aria-label="Linus, Verbindung: Schläft, Aktivität: In Ruhe"[^>]*aria-pressed="false"/,
  );
  assert.match(html, /aria-label="Agenten auswählen"/);
  assert.match(html, /data-connection="online"/);
  assert.match(html, /data-activity="working"[^>]*>Arbeitet/);
});

test("agent switcher omits the manage action when no handler is supplied", () => {
  const html = renderToStaticMarkup(
    h(KAgentSwitcher, {
      items,
      selectedId: "linus",
      onSelect() {},
    }),
  );

  assert.doesNotMatch(html, /Agenten auswählen/);
});

test("custom slots render directly and optional indicators stay absent", () => {
  const html = renderToStaticMarkup(
    h(KAgentSwitcher, {
      items: [
        {
          id: "custom",
          name: "Custom agent",
          avatar: h("span", { className: "rive-slot" }, "animated"),
          nameContent: h("strong", {}, "Visual name"),
          statusContent: h("em", {}, "Custom status"),
          badgeContent: "VIP",
          semanticLabel: "Custom agent semantic status",
          connectionColor: "rebeccapurple",
          showName: false,
        },
      ],
      selectedId: null,
      onSelect() {},
    }),
  );

  assert.match(html, /aria-label="Custom agent semantic status"/);
  assert.match(html, /k-agent-switcher__avatar-custom/);
  assert.match(html, /class="rive-slot">animated/);
  assert.match(html, />Custom status</);
  assert.match(html, />VIP</);
  assert.doesNotMatch(html, /k-avatar__fallback/);
  assert.doesNotMatch(html, /k-agent-switcher__connection/);
  assert.doesNotMatch(html, />Visual name</);
  assert.match(html, /--k-agent-connection-color:rebeccapurple/);
});

test("moveAgentId returns complete controlled orders in either direction", () => {
  assert.deepEqual(moveAgentId(["ada", "linus", "mira"], "ada", "mira"), [
    "linus",
    "mira",
    "ada",
  ]);
  assert.deepEqual(moveAgentId(["ada", "linus", "mira"], "mira", "ada"), [
    "mira",
    "ada",
    "linus",
  ]);
  assert.deepEqual(moveAgentId(["ada", "linus"], "missing", "ada"), [
    "ada",
    "linus",
  ]);
});

test("vertical agent switcher exposes its axis and vertical keyboard guidance", () => {
  const html = renderToStaticMarkup(
    h(KAgentSwitcher, {
      items,
      selectedId: "ada",
      onSelect() {},
      onReorder() {},
      orientation: "vertical",
      labels: {
        reorderInstructionVertical: "Alt plus Pfeil hoch oder runter.",
      },
    }),
  );

  assert.match(html, /data-orientation="vertical"/);
  assert.match(html, /Alt plus Pfeil hoch oder runter\./);
  assert.doesNotMatch(html, /Alt plus Left or Right arrow/);
});
