import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import ts from "typescript";

const source = await readFile(
  new URL("../apps/storybook/src/agent-ui-complete-data.ts", import.meta.url),
  "utf8",
);
const { outputText } = ts.transpileModule(source, {
  compilerOptions: {
    target: ts.ScriptTarget.ES2022,
    module: ts.ModuleKind.ES2022,
  },
});
const { completeMessages, initialCompleteResponses } = await import(
  `data:text/javascript;base64,${Buffer.from(outputText).toString("base64")}`
);
const parts = (state) =>
  completeMessages(state).flatMap((message) => message.parts);
const part = (state, id) => parts(state).find((item) => item.id === id);

test("Complete demo answers only the addressed question and preserves other gates", () => {
  const state = initialCompleteResponses();
  state.questions.checks = { questionId: "checks", optionIds: ["web"] };
  assert.equal(part(state, "checks").state, "answered");
  assert.equal(part(state, "note").state, "pending");
  assert.equal(part(state, "confirmation").state, "pending");
  assert.equal(part(state, "release-approval").state, "pending");
});

test("Complete demo keeps form completion separate from explicit approval", () => {
  const state = initialCompleteResponses();
  state.forms["release-config"] = {
    formId: "release-config",
    action: "submit",
    values: { name: "Preview" },
  };
  assert.equal(part(state, "release-config").state, "answered");
  assert.equal(part(state, "release-approval").state, "pending");
  state.approvals["release-approval"] = {
    approvalId: "release-approval",
    optionId: "reject",
  };
  assert.equal(part(state, "release-approval").state, "rejected");
});

test("Complete demo starts fresh and uses unique message and part identities", () => {
  const first = initialCompleteResponses();
  first.questions.note = { questionId: "note", text: "First demo" };
  assert.equal(part(initialCompleteResponses(), "note").state, "pending");
  const messages = completeMessages(initialCompleteResponses());
  assert.equal(
    new Set(messages.map((message) => message.id)).size,
    messages.length,
  );
  const allParts = messages.flatMap((message) => message.parts);
  assert.equal(new Set(allParts.map((item) => item.id)).size, allParts.length);
});
