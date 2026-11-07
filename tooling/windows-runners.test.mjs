import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative, win32 } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { flutterTestCommand } from "./flutter-test-command.mjs";

const checker = fileURLToPath(new URL("./check-ui-rules.mjs", import.meta.url));

test("UI runner resolves its file URL root with default scopes", () => {
  const run = spawnSync(process.execPath, [checker, "--json"], {
    encoding: "utf8",
    windowsHide: true,
  });
  assert.equal(run.error, undefined);
  assert.ok(Array.isArray(JSON.parse(run.stdout)), run.stderr);
});

test("UI runner excludes dependency directories with native path separators", async () => {
  const fixture = await mkdtemp(join(tmpdir(), "k-ui paths-"));
  try {
    await mkdir(join(fixture, "node_modules"));
    await writeFile(join(fixture, "safe.tsx"), "<KText>Safe</KText>");
    await writeFile(
      join(fixture, "node_modules", "ignored.css"),
      ".test { font-size: 1px; transition: all 200ms ease; }",
    );
    const run = spawnSync(process.execPath, [checker, fixture, "--json"], {
      encoding: "utf8",
      windowsHide: true,
    });
    assert.equal(run.status, 0, run.stderr);
    assert.deepEqual(JSON.parse(run.stdout), []);
  } finally {
    assert.match(relative(tmpdir(), fixture), /^k-ui paths-/);
    await rm(fixture, { recursive: true, force: true });
  }
});

test("Windows Flutter invocation preserves shell metacharacters as direct Dart argv", () => {
  const bin = "C:\\SDK path\\flutter\\bin";
  const packages = win32.join(
    win32.dirname(bin),
    "packages/flutter_tools/.dart_tool/package_config.json",
  );
  const dart = win32.join(bin, "cache/dart-sdk/bin/dart.exe"),
    snapshot = win32.join(bin, "cache/flutter_tools.snapshot");
  const files = new Set([
    win32.join(bin, "flutter.bat"),
    packages,
    dart,
    snapshot,
  ]);
  const args = [
    "test",
    '--dart-define=PHONE_GATE_FILTER=a|b & "quoted"',
    "test/gates/phone_gate_0.dart",
  ];
  const run = flutterTestCommand(args, {
    platform: "win32",
    env: { PATH: `C:\\missing;"${bin}"` },
    exists: (path) => files.has(path),
  });
  assert.equal(run.command, dart);
  assert.deepEqual(run.args, [`--packages=${packages}`, snapshot, ...args]);
});

test("Flutter invocation keeps POSIX argv and reports missing Windows SDKs", () => {
  assert.deepEqual(flutterTestCommand(["test"], { platform: "linux" }), {
    command: "flutter",
    args: ["test"],
  });
  assert.throws(
    () =>
      flutterTestCommand(["test"], {
        platform: "win32",
        env: { PATH: "C:\\missing" },
        exists: () => false,
      }),
    /initialized Flutter SDK/,
  );
});
