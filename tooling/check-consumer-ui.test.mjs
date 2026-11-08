import test from "node:test";
import assert from "node:assert/strict";
import { findings } from "./check-consumer-ui.mjs";

test("flags native controls on both platforms including typed dropdowns", () => {
  assert.equal(
    findings('<input type="checkbox" /><select />', ".tsx").length,
    2,
  );
  assert.equal(
    findings("Checkbox(value: true); DropdownButton<String>()", ".dart").length,
    2,
  );
});
test("accepts K components and structural layout", () => {
  assert.deepEqual(
    findings('<div><KCheckbox /><KStack gap="section" /></div>', ".tsx"),
    [],
  );
  assert.deepEqual(
    findings("Column(children: [KCheckbox(), KRadioGroup()])", ".dart"),
    [],
  );
});
test("reports raw spacing and upstream imports with line numbers", () => {
  assert.deepEqual(findings("\n.card { padding: 16px; }", ".css"), [
    { rule: "raw-spacing", line: 2 },
  ]);
  assert.equal(
    findings('import { Checkbox } from "@mui/material";', ".tsx")[0].rule,
    "upstream-import",
  );
});
test("reports appearance set in app code (Decision 0015)", () => {
  const rules = (source, ext) => findings(source, ext).map((f) => f.rule);
  assert.deepEqual(rules("KIcon(KIconName.house, strokeWidth: 2)", ".dart"), [
    "icon-stroke",
  ]);
  assert.deepEqual(rules('<KIcon name="house" strokeWidth={2} />', ".tsx"), [
    "icon-stroke",
  ]);
  assert.deepEqual(
    rules("KAdaptiveOverrides(density: KDensity.dense)", ".dart"),
    ["appearance-override"],
  );
  assert.deepEqual(rules('<div data-density="dense" />', ".tsx"), [
    "appearance-override",
  ]);
  assert.deepEqual(
    rules(
      "KCard(child: Row(children: [Text('A'), KIcon(KIconName.chevronRight)]))",
      ".dart",
    ),
    ["hand-built-row"],
  );
  assert.deepEqual(
    rules(
      '<KCard><span>A</span><KIcon name="chevron-right" /></KCard>',
      ".tsx",
    ),
    ["hand-built-row"],
  );
  assert.deepEqual(
    rules("Scaffold(body: SingleChildScrollView(child: x))", ".dart"),
    ["bare-page"],
  );
  assert.deepEqual(rules("Scaffold(body: KPage(children: [x]))", ".dart"), []);
});

test("reports split rows and hand-built steps (Decision 0015)", () => {
  const rules = (source, ext) => findings(source, ext).map((f) => f.rule);
  assert.deepEqual(
    rules(
      "KListItem(title: 'Theme', trailing: KIconButton(label: 'x', icon: i))",
      ".dart",
    ),
    ["split-row"],
  );
  assert.deepEqual(
    rules('<KListItem title="Theme" trailing={<KSwitch checked />} />', ".tsx"),
    ["split-row"],
  );
  assert.deepEqual(
    rules("KListItem(title: 'Theme', menu: options, value: 'Dark')", ".dart"),
    [],
  );
  assert.deepEqual(rules("KProgressDots(count: 3, activeIndex: 0)", ".dart"), [
    "hand-built-steps",
  ]);
  assert.deepEqual(
    rules("<KProgressDots count={3} activeIndex={0} />", ".tsx"),
    ["hand-built-steps"],
  );
});

test("reports navigation buttons placed in page content (Decision 0015)", () => {
  const rules = (source, ext) => findings(source, ext).map((f) => f.rule);
  assert.deepEqual(
    rules(
      "KIconButton(label: 'Verlauf', icon: KIconName.menu, onPressed: f)",
      ".dart",
    ),
    ["content-nav-button"],
  );
  assert.deepEqual(
    rules(
      "KPageHeader(title: 'Chat', leading: KIconButton(label: 'Verlauf', icon: KIconName.menu, onPressed: f))",
      ".dart",
    ),
    [],
  );
  assert.deepEqual(
    rules('<KIconButton label="Verlauf" icon="menu" />', ".tsx"),
    ["content-nav-button"],
  );
  assert.deepEqual(
    rules(
      '<KPageHeader title="Chat" leading={<KIconButton label="Verlauf" icon="menu" />} />',
      ".tsx",
    ),
    [],
  );
});

test("refresh-button", () => {
  const rules = (source, ext) => findings(source, ext).map((f) => f.rule);
  assert.deepEqual(
    rules(
      "KIconButton(label: 'Aktualisieren', icon: KIconName.refreshCw, onPressed: f)",
      ".dart",
    ),
    ["refresh-button"],
  );
  assert.deepEqual(
    rules('<KIconButton label="Aktualisieren" icon="refresh-cw" />', ".tsx"),
    ["refresh-button"],
  );
  assert.deepEqual(rules("KPage(onRefresh: load, children: [])", ".dart"), []);
});

test("safe-area-shell", () => {
  const rules = (source, ext) => findings(source, ext).map((f) => f.rule);
  assert.deepEqual(
    rules("SafeArea(child: KAppShell(destinations: d))", ".dart"),
    ["safe-area-shell"],
  );
  assert.deepEqual(rules("KAppShell(destinations: d)", ".dart"), []);
});
