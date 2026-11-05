#!/usr/bin/env node
// Flutter phone gate runner (Decision 0010).
//
// Runs the six shard entry files apps/widgetbook/test/gates/phone_gate_<n>.dart
// in one `flutter test` call. Flutter starts one test process per file and
// runs `-j` of them in parallel. Shards exist because a single test process
// accumulates memory over 400+ use cases × 16 configurations (about 5 GB);
// one shard peaks around 1.2 GB. Parallelism follows the CPU count and the
// memory of the machine (K_PHONE_GATE_JOBS overrides it).
//
// Merges the shard reports into apps/widgetbook/build/phone_gate_report.txt
// and fails when a shard found an overflow or did not finish.
//
// Usage: node tooling/flutter-phone-gate.mjs [--filter a|b]
import { spawnSync } from "node:child_process";
import { readFile, rm, writeFile } from "node:fs/promises";
import { availableParallelism, totalmem } from "node:os";
import { join, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const app = join(root, "apps/widgetbook");
const args = process.argv.slice(2);
const filter = args.includes("--filter")
  ? args[args.indexOf("--filter") + 1]
  : "";
const shards = 6;
const perShardBytes = 2 * 1024 ** 3; // peak plus headroom
const jobs = Number(
  process.env.K_PHONE_GATE_JOBS ??
    Math.max(
      1,
      Math.min(
        availableParallelism(),
        Math.floor(totalmem() / perShardBytes) - 1,
        shards,
      ),
    ),
);

for (let index = 0; index < shards; index++)
  await rm(join(app, `build/phone_gate_report.${index}.txt`), { force: true });
const started = Date.now();
const run = spawnSync(
  "flutter",
  [
    "test",
    `--concurrency=${jobs}`,
    ...(filter ? [`--dart-define=PHONE_GATE_FILTER=${filter}`] : []),
    ...Array.from(
      { length: shards },
      (_, index) => `test/gates/phone_gate_${index}.dart`,
    ),
  ],
  { cwd: app, stdio: ["ignore", "ignore", "inherit"] },
);

const lines = { OVERFLOW: [], skipped: [], NOTE: [] };
let useCases = 0;
let failedShards = 0;
for (let index = 0; index < shards; index++) {
  const text = await readFile(
    join(app, `build/phone_gate_report.${index}.txt`),
    "utf8",
  ).catch(() => "");
  if (!text) {
    failedShards++;
    console.error(`Shard ${index + 1}/${shards} did not finish.`);
    continue;
  }
  const [header, ...rest] = text.trim().split("\n");
  useCases += Number(header.match(/(\d+) use cases/)?.[1] ?? 0);
  for (const line of rest) {
    const kind = line.trim().split(/\s+/)[0];
    if (kind in lines) lines[kind].push(line);
  }
}

const count = (kind) =>
  new Set(lines[kind].map((line) => line.trim().split(/\s+/)[1])).size;
const minutes = ((Date.now() - started) / 60000).toFixed(1);
const summary = [
  `Phone gate: ${useCases} use cases, ${lines.OVERFLOW.length} overflow(s), ` +
    `${count("skipped")} use cases skipped (not verified), ` +
    `${count("NOTE")} with non-layout errors (layout checked)` +
    (failedShards ? `, ${failedShards} shard(s) did not finish` : "") +
    ` — ${shards} shards, ${jobs} parallel, ${minutes} min.`,
  ...lines.OVERFLOW.sort(),
  ...lines.skipped.sort(),
  ...lines.NOTE.sort(),
].join("\n");
await writeFile(join(app, "build/phone_gate_report.txt"), summary + "\n");
console.log(
  summary
    .split("\n")
    .slice(0, 1 + lines.OVERFLOW.length)
    .join("\n"),
);
process.exitCode =
  lines.OVERFLOW.length || failedShards || run.status !== 0 ? 1 : 0;
