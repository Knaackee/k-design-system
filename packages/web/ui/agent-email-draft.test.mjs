import assert from "node:assert/strict";
import test from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KAgentEmailDraft } from "./dist/chat/agent-email-draft.js";

function render(overrides = {}) {
  return renderToStaticMarkup(
    h(KAgentEmailDraft, {
      draftId: "mail-1",
      title: "Review email",
      from: "sender@example.com",
      value: {
        to: "recipient@example.com",
        cc: "copy@example.com",
        bcc: "private@example.com",
        subject: "Project update",
        markdown: "Hello **Mara**",
      },
      onChange: () => assert.fail("Rendering must not change the draft"),
      onSend: () => assert.fail("Rendering must never approve or send"),
      onDiscard: () => assert.fail("Rendering must never discard"),
      onAddAttachment: () =>
        assert.fail("Rendering must not request attachments"),
      onRemoveAttachment: () =>
        assert.fail("Rendering must not remove attachments"),
      attachments: [
        { id: "file-1", name: "Project.pdf", description: "248 KB" },
      ],
      ...overrides,
    }),
  );
}

test("composer always exposes editable fields and preserves the read-only account", () => {
  const html = render();
  for (const text of [
    "sender@example.com",
    "recipient@example.com",
    "copy@example.com",
    "private@example.com",
    "Project update",
    "Project.pdf",
  ])
    assert.ok(html.includes(text), text);
  assert.equal(html.match(/<input\b/g).length, 5);
  assert.match(html, /readOnly=""[^>]*value="sender@example.com"/);
  assert.match(html, /k-agent-email-draft__editor/);
  assert.match(html, /aria-label="Remove Project.pdf"/);
  assert.doesNotMatch(html, /<form|type="submit"|>Edit<|>Preview</);
  assert.doesNotMatch(html, /<button[^>]*disabled/);
});

test("supplied field errors expose labeled inputs and block approval", () => {
  const html = render({
    errors: { to: "Choose a recipient" },
    error: "Review required",
  });
  assert.match(html, /Choose a recipient/);
  assert.match(html, /aria-invalid="true"/);
  assert.match(html, /<label[^>]+>To<\/label>/);
  assert.match(html, /Review required/);
  assert.match(html, /<button[^>]*disabled[^>]*>[\s\S]*?>Send</);
});

for (const status of ["submitting", "sent", "discarded"]) {
  test(`${status} disables approval, field and attachment actions`, () => {
    const html = render({
      status,
      statusLabel: `${status} by host`,
      border: "aurora",
    });
    const buttons = html.match(/<button\b[^>]*>/g);
    assert.ok(buttons.length >= 4);
    assert.ok(buttons.every((button) => button.includes('disabled=""')));
    assert.equal((html.match(/<input[^>]*disabled=""/g) ?? []).length, 4);
    assert.match(html, new RegExp(`${status} by host`));
    assert.doesNotMatch(html, /k-card-fx--aurora/);
    if (status === "submitting") assert.match(html, /aria-busy="true"/);
  });
}

test("pending emphasis is opt-in and labels are host supplied", () => {
  assert.doesNotMatch(render(), /k-card-fx--aurora/);
  const html = render({
    border: "aurora",
    labels: { send: "Freigeben", discard: "Verwerfen" },
  });
  assert.match(html, /k-card-fx--aurora/);
  assert.match(html, /Freigeben/);
  assert.match(html, /Verwerfen/);
});

test("host-owned delivery status can remain outside the locked card", () => {
  for (const status of ["submitting", "sent", "discarded"]) {
    const html = render({ status });
    assert.doesNotMatch(html, /role="status"/);
    assert.match(html, new RegExp(`data-state="${status}"`));
  }
});

test("Cc stays visible while empty Bcc uses an explicit disclosure", () => {
  const html = render({
    value: { to: "", cc: "", subject: "Draft", markdown: "Hello" },
  });
  assert.match(html, /<label[^>]+>Cc<\/label>/);
  assert.match(html, /placeholder="name@example.com"/);
  assert.match(html, />Add Bcc</);
  assert.doesNotMatch(html, /<label[^>]+>Bcc<\/label>/);
});

test("Subject capture is opt-in and never adds recipient microphones", () => {
  assert.doesNotMatch(render(), /data-dictation-state/);
  const html = render({
    subjectDictation: {
      state: "ready",
      label: "Dictate subject",
      onPressed() {},
    },
  });
  assert.equal((html.match(/data-dictation-state="ready"/g) ?? []).length, 1);
  assert.match(html, /aria-label="Dictate subject"/);
});
for (const state of ["recording", "processing"]) {
  for (const target of ["subject", "body"]) {
    test(`${target} ${state} blocks Send but preserves editable Subject`, () => {
      const binding = {
        state,
        label: "Dictate",
        onPressed() {},
        onStart() {},
        onStop() {},
      };
      const html = render(
        target === "subject"
          ? { subjectDictation: binding }
          : { editor: { dictation: binding } },
      );
      assert.match(html, /<button[^>]*disabled[^>]*>[\s\S]*?>Send</);
      assert.doesNotMatch(html, /<input[^>]*disabled/);
      if (target === "subject") assert.match(html, /k-dictation-anchor/);
    });
  }
}
