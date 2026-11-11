import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  chmodSync,
  cpSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

test("phone runner launches Flutter and collects all reports in a path with spaces", () => {
  const root = mkdtempSync(join(tmpdir(), "k phone gate "));
  try {
    for (const path of ["tooling", "bin", "apps/widgetbook/build"])
      mkdirSync(join(root, path), { recursive: true });
    cpSync(
      new URL("./flutter-phone-gate.mjs", import.meta.url),
      join(root, "tooling/runner.mjs"),
    );
    const fake = join(root, "bin/fake.mjs");
    writeFileSync(
      fake,
      `import { writeFileSync } from "node:fs";
writeFileSync("args.json", JSON.stringify(process.argv.slice(2)));
for (let i = 0; i < 6; i++) writeFileSync("build/phone_gate_report." + i + ".txt", "1 use cases\\n");`,
    );
    const windows = process.platform === "win32";
    const command = join(root, windows ? "bin/flutter.bat" : "bin/flutter");
    writeFileSync(
      command,
      windows
        ? `@"${process.execPath}" "${fake}" %*\r\n`
        : `#!/bin/sh\n"${process.execPath}" "${fake}" "$@"\n`,
    );
    if (!windows) chmodSync(command, 0o755);
    const env = { ...process.env, K_PHONE_GATE_JOBS: "2" };
    const pathKey =
      Object.keys(env).find((key) => key.toLowerCase() === "path") ?? "PATH";
    env[pathKey] = join(root, "bin") + (windows ? ";" : ":") + env[pathKey];
    const output = execFileSync(
      process.execPath,
      [join(root, "tooling/runner.mjs"), "--filter", "alpha|beta"],
      { env, encoding: "utf8" },
    );
    assert.match(output, /6 use cases, 0 overflow/);
    const args = JSON.parse(
      readFileSync(join(root, "apps/widgetbook/args.json"), "utf8"),
    );
    assert.ok(args.includes("--dart-define=PHONE_GATE_FILTER=alpha|beta"));
    assert.equal(args.filter((arg) => arg.startsWith("test/gates/")).length, 6);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
