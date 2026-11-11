import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KAgentQuestion } from "../dist/chat/agent-parts.js";
import { KAgentSingleChoice } from "../dist/chat/ask-tools.js";

const question = {
  id: "question",
  type: "question",
  statusLabel: "Deine Antwort wird benötigt",
  title: "Welche Daten soll ich verwenden?",
  description: "Wähle eine Datenquelle.",
  kind: "single-choice",
  state: "pending",
  options: [
    {
      id: "current",
      label: "Aktuelle Daten",
      description: "Aus der Verbindung",
    },
    { id: "file", label: "Hochgeladene Datei" },
  ],
  submitLabel: "Antwort senden",
};
const render = (part = question, props = {}) =>
  renderToStaticMarkup(h(KAgentQuestion, { part, ...props }));

test("question choices are named by their question and described by their context", () => {
  const html = render();
  const titleId = html.match(/<strong id="([^"]+)">Welche Daten/)?.[1];
  const descriptionId = html.match(/<p id="([^"]+)">Wähle eine/)?.[1];
  assert.ok(titleId);
  assert.ok(descriptionId);
  assert.ok(
    html.includes(
      `role="radiogroup" aria-labelledby="${titleId}" aria-describedby="${descriptionId}"`,
    ),
  );
  assert.equal((html.match(/type="radio"/g) ?? []).length, 2);
  assert.match(html, /Deine Antwort wird benötigt/);
  assert.match(html, /disabled=""[^>]*>.*Antwort senden/s);
});

test("answered questions show their answer without editable choices or submit", () => {
  const html = render({
    ...question,
    state: "answered",
    answerSummary: "Aktuelle Daten",
  });
  assert.match(html, /Aktuelle Daten/);
  assert.doesNotMatch(
    html,
    /<input|<button|role="radiogroup"|Deine Antwort wird benötigt/,
  );
});

test("text questions retain the consumer input and multiple choice retains checkbox semantics", () => {
  const text = render(
    { ...question, kind: "text", options: [] },
    {
      inputRenderer: () => h("textarea", { "aria-label": "Eigene Antwort" }),
    },
  );
  assert.match(text, /aria-label="Eigene Antwort"/);
  assert.doesNotMatch(text, /role="radiogroup"/);
  const multiple = render({ ...question, kind: "multiple-choice" });
  assert.equal((multiple.match(/type="checkbox"/g) ?? []).length, 2);
  assert.match(multiple, /role="group"/);
});

test("single choice forwards the optional border only while awaiting an answer", () => {
  const defaultHtml = renderToStaticMarkup(
    h(KAgentSingleChoice, { part: question }),
  );
  assert.doesNotMatch(defaultHtml, /data-border=/);
  const pendingHtml = renderToStaticMarkup(
    h(KAgentSingleChoice, { part: question, border: "aurora" }),
  );
  assert.match(pendingHtml, /k-card-fx--aurora/);
  const answeredHtml = renderToStaticMarkup(
    h(KAgentSingleChoice, {
      part: { ...question, state: "answered", answerSummary: "Current data" },
      border: "aurora",
    }),
  );
  assert.doesNotMatch(answeredHtml, /data-border=/);
});
