import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import {
  KBrowserPermissionRequest,
  KBrowserPermissionList,
} from "./dist/patterns/browser-permissions.js";

const props = {
  agent: "Nova",
  title: "Search hotels",
  description: "Send travel dates",
  host: "stay.example",
  origin: "https://stay.example",
  path: "/search",
  action: "Search hotels",
  onDecision() {},
  onTakeOver() {},
  onAllowWebsite() {},
  onWebsiteConfirmationChange() {},
};
const render = (extra) =>
  renderToStaticMarkup(
    createElement(KBrowserPermissionRequest, { ...props, ...extra }),
  );
test("manual and invalid requests cannot render approval actions", () => {
  for (const state of ["manual", "blocked", "expired"]) {
    const html = render({ state, websiteConfirmationOpen: true });
    assert.doesNotMatch(
      html,
      /Allow once|Remember permission|Confirm website permission/,
    );
    assert.match(html, /Take over browser/);
    assert.match(html, /stay\.example/);
  }
});
test("broad permission needs a separate confirmation and exact origin", () => {
  assert.doesNotMatch(render(), /Confirm website permission/);
  const html = render({ websiteConfirmationOpen: true });
  assert.match(html, /Confirm website permission/);
  assert.match(html, /https:\/\/stay\.example/);
  assert.match(
    html,
    /Purchases, payments and messages still require your manual action/,
  );
});
test("empty management describes the next decision without granting anything", () => {
  const html = renderToStaticMarkup(
    createElement(KBrowserPermissionList, {
      agent: "Nova",
      rules: [],
      onDecisionChange() {},
      onRevoke() {},
      onReset() {},
    }),
  );
  assert.match(html, /No browser permissions yet/);
  assert.doesNotMatch(html, /<select|<button/);
});
