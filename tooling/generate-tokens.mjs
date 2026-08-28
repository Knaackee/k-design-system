import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const check = process.argv.includes("--check");

const sourceFiles = {
  foundation: "tokens/foundation.tokens.json",
  semantic: "tokens/semantic.tokens.json",
  orbitLight: "tokens/themes/orbit.light.tokens.json",
  orbitDark: "tokens/themes/orbit.dark.tokens.json",
  referenceLight: "tokens/themes/reference.light.tokens.json",
  referenceDark: "tokens/themes/reference.dark.tokens.json",
};

const outputFiles = {
  css: "packages/web/tokens/src/generated/tokens.css",
  typescript: "packages/web/tokens/src/generated/tokens.ts",
  dart: "packages/flutter/k_design_tokens/lib/src/generated/k_design_tokens.g.dart",
  flat: "dist/tokens.flat.json",
};

const readJson = async (path) =>
  JSON.parse(await readFile(resolve(root, path), "utf8"));

export function flattenTokens(node, prefix = "", output = new Map()) {
  for (const [key, value] of Object.entries(node)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (value && typeof value === "object" && "$value" in value) {
      if (!value.$type) throw new Error(`Token ${path} is missing $type`);
      output.set(path, { type: value.$type, value: value.$value });
    } else if (value && typeof value === "object" && !Array.isArray(value)) {
      flattenTokens(value, path, output);
    } else {
      throw new Error(`Invalid token group at ${path}`);
    }
  }
  return output;
}

export function resolveToken(path, tokens, stack = []) {
  if (stack.includes(path))
    throw new Error(
      `Circular token reference: ${[...stack, path].join(" -> ")}`,
    );
  const token = tokens.get(path);
  if (!token) throw new Error(`Unknown token reference: ${path}`);
  if (typeof token.value === "string") {
    const match = token.value.match(/^\{([^}]+)\}$/);
    if (match) return resolveToken(match[1], tokens, [...stack, path]);
  }
  return token;
}

export function resolvedSemantic(foundation, semantic, overrides) {
  for (const [path, override] of overrides) {
    const contract = semantic.get(path);
    if (!contract) throw new Error(`Unknown theme override: ${path}`);
    if (contract.type !== override.type) {
      throw new Error(
        `Theme override ${path} has type ${override.type}; expected ${contract.type}`,
      );
    }
  }
  const all = new Map([...foundation, ...semantic, ...overrides]);
  return new Map(
    [...semantic.keys()].map((path) => [path, resolveToken(path, all)]),
  );
}

const kebab = (value) =>
  value
    .replace(/\./g, "-")
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .toLowerCase();
const camel = (value) =>
  value.replace(/\.([a-zA-Z0-9])/g, (_, char) => char.toUpperCase());

function cssValue(token) {
  if (token.type === "dimension")
    return `${token.value.value}${token.value.unit}`;
  if (token.type === "duration")
    return `${token.value.value}${token.value.unit}`;
  return String(token.value);
}

function cssBlock(selector, tokens) {
  const lines = [...tokens].map(
    ([path, token]) => `  --k-${kebab(path)}: ${cssValue(token)};`,
  );
  return `${selector} {\n${lines.join("\n")}\n}`;
}

function dartType(token) {
  return {
    color: "Color",
    dimension: "double",
    duration: "Duration",
    fontFamily: "String",
    fontWeight: "FontWeight",
  }[token.type];
}

function dartValue(token) {
  switch (token.type) {
    case "color":
      return `Color(0xFF${token.value.slice(1).toUpperCase()})`;
    case "dimension":
      return `${Number(token.value.value).toFixed(1)}`;
    case "duration":
      return `Duration(${token.value.unit === "ms" ? "milliseconds" : "seconds"}: ${token.value.value})`;
    case "fontFamily":
      return JSON.stringify(String(token.value).split(",")[0].trim());
    case "fontWeight":
      return `FontWeight.w${token.value}`;
    default:
      throw new Error(`Unsupported Dart token type: ${token.type}`);
  }
}

function dartTheme(name, tokens) {
  const values = [...tokens].map(
    ([path, token]) => `    ${camel(path)}: ${dartValue(token)},`,
  );
  return `  static const ${name} = KDesignTokens(\n${values.join("\n")}\n  );`;
}

function generateDart(themes, semantic) {
  const fields = [...semantic].map(
    ([path, token]) => `  final ${dartType(token)} ${camel(path)};`,
  );
  const constructor = [...semantic].map(
    ([path]) => `    required this.${camel(path)},`,
  );
  const copyParameters = [...semantic].map(
    ([path, token]) => `    ${dartType(token)}? ${camel(path)},`,
  );
  const copies = [...semantic].map(
    ([path]) => `      ${camel(path)}: ${camel(path)} ?? this.${camel(path)},`,
  );
  const lerps = [...semantic].map(([path, token]) => {
    const name = camel(path);
    if (token.type === "color")
      return `      ${name}: Color.lerp(${name}, other.${name}, t)!,`;
    if (token.type === "dimension")
      return `      ${name}: lerpDouble(${name}, other.${name}, t)!,`;
    if (token.type === "duration")
      return `      ${name}: t < 0.5 ? ${name} : other.${name},`;
    if (token.type === "fontWeight")
      return `      ${name}: FontWeight.lerp(${name}, other.${name}, t)!,`;
    return `      ${name}: t < 0.5 ? ${name} : other.${name},`;
  });

  return `// GENERATED FILE. DO NOT EDIT.\nimport 'dart:ui' show lerpDouble;\nimport 'package:flutter/material.dart';\n\n@immutable\nclass KDesignTokens extends ThemeExtension<KDesignTokens> {\n  const KDesignTokens({\n${constructor.join("\n")}\n  });\n\n${fields.join("\n")}\n\n${Object.entries(
    themes,
  )
    .map(([name, tokens]) => dartTheme(name, tokens))
    .join(
      "\n\n",
    )}\n\n  @override\n  KDesignTokens copyWith({\n${copyParameters.join("\n")}\n  }) {\n    return KDesignTokens(\n${copies.join("\n")}\n    );\n  }\n\n  @override\n  KDesignTokens lerp(covariant KDesignTokens? other, double t) {\n    if (other == null) return this;\n    return KDesignTokens(\n${lerps.join("\n")}\n    );\n  }\n}\n`;
}

async function emit(path, content) {
  const absolute = resolve(root, path);
  if (check) {
    let current;
    try {
      current = await readFile(absolute, "utf8");
    } catch {
      throw new Error(`Generated output is missing: ${path}`);
    }
    if (current !== content)
      throw new Error(`Generated output is stale: ${path}`);
    return;
  }
  await mkdir(dirname(absolute), { recursive: true });
  await writeFile(absolute, content, "utf8");
}

export async function generate() {
  const sources = Object.fromEntries(
    await Promise.all(
      Object.entries(sourceFiles).map(async ([name, path]) => [
        name,
        await readJson(path),
      ]),
    ),
  );
  const foundation = flattenTokens(sources.foundation);
  const semantic = flattenTokens(sources.semantic);
  const themes = {
    orbitLight: resolvedSemantic(
      foundation,
      semantic,
      flattenTokens(sources.orbitLight),
    ),
    orbitDark: resolvedSemantic(
      foundation,
      semantic,
      flattenTokens(sources.orbitDark),
    ),
    referenceLight: resolvedSemantic(
      foundation,
      semantic,
      flattenTokens(sources.referenceLight),
    ),
    referenceDark: resolvedSemantic(
      foundation,
      semantic,
      flattenTokens(sources.referenceDark),
    ),
  };

  const css = `/* GENERATED FILE. DO NOT EDIT. */\n${cssBlock(':root, [data-brand="orbit"][data-theme="light"]', themes.orbitLight)}\n\n${cssBlock('[data-theme="dark"], [data-brand="orbit"][data-theme="dark"]', themes.orbitDark)}\n\n${cssBlock('[data-brand="reference"][data-theme="light"]', themes.referenceLight)}\n\n${cssBlock('[data-brand="reference"][data-theme="dark"]', themes.referenceDark)}\n`;
  const names = [...semantic.keys()];
  const typescript = `// GENERATED FILE. DO NOT EDIT.\nexport const tokenNames = ${JSON.stringify(names, null, 2)} as const;\nexport type KTokenName = (typeof tokenNames)[number];\nexport const cssVariable = (token: KTokenName): string => \`--k-\${token.replace(/\\./g, "-").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase()}\`;\n`;
  const flat = `${JSON.stringify(
    Object.fromEntries(
      Object.entries(themes).map(([theme, values]) => [
        theme,
        Object.fromEntries(
          [...values].map(([path, token]) => [
            path,
            { type: token.type, value: token.value },
          ]),
        ),
      ]),
    ),
    null,
    2,
  )}\n`;

  await emit(outputFiles.css, css);
  await emit(outputFiles.typescript, typescript);
  await emit(outputFiles.dart, generateDart(themes, semantic));
  await emit(outputFiles.flat, flat);
  console.log(
    check
      ? "Generated token outputs are current."
      : "Generated token outputs updated.",
  );
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  generate().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
