import { existsSync } from "node:fs";
import { win32 } from "node:path";

/** Use direct SDK argv on Windows: .bat requires a shell and can expose a console. */
export function flutterTestCommand(
  args,
  { platform = process.platform, env = process.env, exists = existsSync } = {},
) {
  if (platform !== "win32") return { command: "flutter", args };
  for (const directory of (env.PATH ?? env.Path ?? "").split(";")) {
    if (!directory) continue;
    const bin = directory.replace(/^"|"$/g, "");
    if (!exists(win32.join(bin, "flutter.bat"))) continue;
    const sdk = win32.dirname(bin);
    const dart = win32.join(bin, "cache/dart-sdk/bin/dart.exe");
    const snapshot = win32.join(bin, "cache/flutter_tools.snapshot");
    const packages = win32.join(
      sdk,
      "packages/flutter_tools/.dart_tool/package_config.json",
    );
    if ([dart, snapshot, packages].every(exists)) {
      return {
        command: dart,
        args: [`--packages=${packages}`, snapshot, ...args],
      };
    }
  }
  throw new Error(
    "No initialized Flutter SDK found on PATH for the phone gate.",
  );
}
