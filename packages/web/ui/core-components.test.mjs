import assert from "node:assert/strict";
import test from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KList, KListItem } from "./dist/data-display/list.js";
import { KSegmentedControl } from "./dist/navigation/segmented-control.js";
import { KPageHeader } from "./dist/navigation/page-header.js";
import { KAppShell } from "./dist/navigation/app-shell.js";
import { KBarChart } from "./dist/charts/cartesian-chart.js";

test("compact plots reserve no axis gutters only when both axes are hidden", () => {
  const render = (compact, ticks) =>
    renderToStaticMarkup(
      h(KBarChart, {
        compact,
        label: "Bookings",
        series: [
          {
            id: "bookings",
            label: "Bookings",
            points: [{ id: "peak", x: 0, y: 5 }],
          },
        ],
        xAxis: { min: -0.5, max: 0.5, ticks, format: String },
        yAxis: { min: 0, max: 5, ticks, format: String },
      }),
    );
  assert.match(render(true, []), /data-axis-free="true"/);
  assert.doesNotMatch(render(false, []), /data-axis-free/);
  assert.doesNotMatch(render(true, [0]), /data-axis-free/);
});

test("controlled shell rail retains toggle and custom navigation; phones retain tabs", () => {
  const previous = globalThis.window;
  const render = (width, mode) => {
    globalThis.window = { innerWidth: width };
    return renderToStaticMarkup(
      h(KAppShell, {
        destinations: [
          { id: "home", label: "Home", icon: "house" },
          { id: "jobs", label: "Jobs", icon: "calendar" },
        ],
        selectedId: "home",
        onSelectedChange: () => {},
        sidebarMode: mode,
        onSidebarModeChange: () => {},
        sidebarHeader: h("span", null, "Toggle slot"),
        sidebarContent: h("span", null, "Custom destinations"),
        sidebarFooter: h("span", null, "Account slot"),
        children: h("main", null, "Page"),
      }),
    );
  };
  try {
    const rail = render(1200, "rail");
    assert.match(rail, /data-layout="rail"/);
    for (const text of ["Toggle slot", "Custom destinations", "Account slot"])
      assert.ok(rail.includes(text));
    assert.match(render(700, "expanded"), /data-layout="sidebar"/);
    const phone = render(393, "rail");
    assert.match(phone, /data-layout="tab-bar"/);
    assert.doesNotMatch(phone, /Toggle slot|Custom destinations|Account slot/);
  } finally {
    if (previous === undefined) delete globalThis.window;
    else globalThis.window = previous;
  }
});

test("list: rows are list items; buttons and links get a chevron", () => {
  const html = renderToStaticMarkup(
    h(
      KList,
      null,
      h(KListItem, { title: "Account", onClick: () => {} }),
      h(KListItem, { title: "Help", href: "/help" }),
      h(KListItem, { title: "Version", trailing: "1.0" }),
    ),
  );
  assert.equal(html.match(/<li class="k-list__row">/g).length, 3);
  assert.match(html, /<button class="k-list-item"[^>]*type="button"/);
  assert.match(html, /<a[^>]*href="\/help"/);
  assert.equal(html.match(/k-list-item__chevron/g).length, 2);
  assert.match(html, /k-list-item__trailing">1.0</);
});

test("list: disabled link loses its href", () => {
  const html = renderToStaticMarkup(
    h(KListItem, { title: "Billing", href: "/billing", disabled: true }),
  );
  assert.doesNotMatch(html, /href=/);
  assert.match(html, /aria-disabled="true"/);
});

test("segmented control is a radio group with one tab stop", () => {
  const html = renderToStaticMarkup(
    h(KSegmentedControl, {
      label: "Period",
      value: "week",
      onValueChange: () => {},
      segments: [
        { value: "day", label: "Day" },
        { value: "week", label: "Week" },
        { value: "month", label: "Month" },
      ],
    }),
  );
  assert.match(html, /role="radiogroup"[^>]*aria-label="Period"/);
  assert.equal(html.match(/role="radio"/g).length, 3);
  assert.equal(html.match(/aria-checked="true"/g).length, 1);
  assert.equal(html.match(/tabindex="0"/g).length, 1);
  assert.match(html, /--k-segment-index:1/);
  assert.match(html, /data-stackable="true"/);
});

test("segmented control reports more than five segments", () => {
  const errors = [];
  const original = console.error;
  console.error = (message) => errors.push(message);
  try {
    renderToStaticMarkup(
      h(KSegmentedControl, {
        label: "Too many",
        value: "0",
        onValueChange: () => {},
        segments: Array.from({ length: 6 }, (_, i) => ({
          value: String(i),
          label: String(i),
        })),
      }),
    );
  } finally {
    console.error = original;
  }
  assert.match(String(errors[0]), /2 to 5 segments/);
});

test("page header: one h1, back chevron with destination, actions", () => {
  const html = renderToStaticMarkup(
    h(KPageHeader, {
      title: "Portfolio",
      subtitle: "3 buildings",
      backLabel: "Back to Portfolios",
      actions: h("button", null, "Add"),
    }),
  );
  assert.equal(html.match(/<h1/g).length, 1);
  assert.match(html, /aria-label="Back to Portfolios"/);
  assert.match(html, /data-back="true"[^>]*data-actions="true"/);
  assert.match(html, /k-page-header__actions"><button>Add</);
});

test("app shell renders a tab bar without a window (server)", () => {
  const html = renderToStaticMarkup(
    h(
      KAppShell,
      {
        selectedId: "home",
        onSelectedChange: () => {},
        destinations: [
          { id: "home", label: "Home", icon: "house" },
          { id: "search", label: "Search", icon: "search" },
        ],
      },
      h("main", null, "Content"),
    ),
  );
  assert.match(html, /data-layout="tab-bar"/);
  assert.match(html, /k-mobile-app-bar/);
  assert.doesNotMatch(html, /k-sidebar/);
  assert.match(html, /<main>Content<\/main>/);
  assert.match(html, /class="k-mobile-app-bar__label">Search</);
});

test("app shell icon-only tabs retain accessible names and use larger icons", () => {
  const html = renderToStaticMarkup(
    h(KAppShell, {
      selectedId: "home",
      onSelectedChange: () => {},
      tabBarLabelVisibility: "never",
      destinations: [
        { id: "home", label: "Home", icon: "house" },
        { id: "search", label: "Search", icon: "search" },
      ],
    }),
  );
  assert.match(html, /aria-current="page" aria-label="Home"/);
  assert.match(html, /aria-label="Search"/);
  assert.doesNotMatch(html, /k-mobile-app-bar__label/);
  assert.equal(html.match(/width:32px;height:32px/g).length, 2);
});

test("app shell custom expanded body preserves rail and phone destinations", () => {
  const previous = globalThis.window;
  const render = (width) => {
    globalThis.window = { innerWidth: width };
    return renderToStaticMarkup(
      h(
        KAppShell,
        {
          selectedId: "home",
          onSelectedChange: () => {},
          destinations: [
            { id: "home", label: "Home", icon: "house" },
            { id: "jobs", label: "Jobs", icon: "repeat" },
          ],
          sidebarContent: h("div", null, "Home and agents"),
          sidebarFooter: h("div", null, "Footer actions"),
        },
        h("main", null, "Content"),
      ),
    );
  };
  try {
    const desktop = render(1000);
    assert.match(desktop, /Home and agents/);
    assert.match(desktop, /Footer actions/);
    assert.doesNotMatch(desktop, />Jobs</);
    const rail = render(700);
    assert.doesNotMatch(rail, /Home and agents|Footer actions/);
    assert.match(rail, /Jobs/);
    const phone = render(393);
    assert.doesNotMatch(phone, /Home and agents|Footer actions/);
    assert.match(phone, /k-mobile-app-bar/);
    assert.match(phone, /Jobs/);
  } finally {
    if (previous === undefined) delete globalThis.window;
    else globalThis.window = previous;
  }
});
