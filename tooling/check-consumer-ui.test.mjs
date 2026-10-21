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
