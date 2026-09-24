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

const variantFiles = {
  typeScaleCompact: [
    "tokens/modes/type-scale.compact.tokens.json",
    '[data-type-scale="compact"]',
  ],
  typeScaleStandard: [
    "tokens/modes/type-scale.standard.tokens.json",
    '[data-type-scale="standard"]',
  ],
  densityDense: [
    "tokens/modes/density.dense.tokens.json",
    '[data-density="dense"]',
  ],
  densityStandard: [
    "tokens/modes/density.standard.tokens.json",
    '[data-density="standard"]',
  ],
  densitySpacious: [
    "tokens/modes/density.spacious.tokens.json",
    '[data-density="spacious"]',
  ],
  inputModePointer: [
    "tokens/modes/input-mode.pointer.tokens.json",
    '[data-input-mode="pointer"]',
  ],
  inputModeTouch: [
    "tokens/modes/input-mode.touch.tokens.json",
    '[data-input-mode="touch"]',
  ],
  windowCompact: [
    "tokens/modes/window.compact.tokens.json",
    '[data-window-class="compact"]',
  ],
  windowMedium: [
    "tokens/modes/window.medium.tokens.json",
    '[data-window-class="medium"]',
  ],
  windowExpanded: [
    "tokens/modes/window.expanded.tokens.json",
    '[data-window-class="expanded"]',
  ],
  windowLarge: [
    "tokens/modes/window.large.tokens.json",
    '[data-window-class="large"]',
  ],
  windowExtraLarge: [
    "tokens/modes/window.extra-large.tokens.json",
    '[data-window-class="extra-large"]',
  ],
};

const outputFiles = {
  css: "packages/web/tokens/src/generated/tokens.css",
  typescript: "packages/web/tokens/src/generated/tokens.ts",
  dart: "packages/flutter/k_design_tokens/lib/src/generated/k_design_tokens.g.dart",
  flat: "dist/tokens.flat.json",
};

const readJson = async (path) => {
  const source = await readFile(resolve(root, path), "utf8");
  try {
    return JSON.parse(source);
  } catch (cause) {
    throw new Error(`Invalid token JSON: ${path}`, { cause });
  }
};

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

export function resolvedVariant(foundation, semantic, overrides) {
  const resolved = resolvedSemantic(foundation, semantic, overrides);
  return new Map(
    [...overrides.keys()].map((path) => [path, resolved.get(path)]),
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
  if (token.type === "shadow") {
    return shadowLayers(token.value)
      .map(
        (shadow) =>
          `${cssDimension(shadow.offsetX)} ${cssDimension(shadow.offsetY)} ${cssDimension(shadow.blur)} ${cssDimension(shadow.spread)} ${shadow.color}`,
      )
      .join(", ");
  }
  return String(token.value);
}

function tokenReference(token) {
  if (typeof token?.value !== "string") return null;
  return token.value.match(/^\{([^}]+)\}$/)?.[1] ?? null;
}

function cssTokenValue(path, token, sourceTokens, overrides = new Map()) {
  const reference = tokenReference(sourceTokens.get(path));
  if (path.startsWith("component.") && reference && !overrides.has(path)) {
    return `var(--k-${kebab(reference)})`;
  }
  return cssValue(token);
}

const shadowLayers = (value) => (Array.isArray(value) ? value : [value]);
const cssDimension = (value) => `${value.value}${value.unit}`;

function cssBlock(selector, tokens, sourceTokens = tokens, overrides) {
  const lines = [...tokens].map(
    ([path, token]) =>
      `  --k-${kebab(path)}: ${cssTokenValue(path, token, sourceTokens, overrides)};`,
  );
  return `${selector} {\n${lines.join("\n")}\n}`;
}

function dartType(token) {
  return {
    color: "Color",
    dimension: "double",
    number: "double",
    duration: "Duration",
    fontFamily: "String",
    fontWeight: "FontWeight",
    shadow: "List<BoxShadow>",
  }[token.type];
}

function dartColor(value) {
  const hex = value.slice(1).toUpperCase();
  const argb =
    hex.length === 8 ? `${hex.slice(6)}${hex.slice(0, 6)}` : `FF${hex}`;
  return `Color(0x${argb})`;
}

function dartValue(token) {
  switch (token.type) {
    case "color": {
      return dartColor(token.value);
    }
    case "dimension":
      return `${Number(token.value.value).toFixed(1)}`;
    case "number":
      return `${Number(token.value).toFixed(2)}`;
    case "duration":
      return `Duration(${token.value.unit === "ms" ? "milliseconds" : "seconds"}: ${token.value.value})`;
    case "fontFamily":
      return JSON.stringify(
        `packages/k_design_tokens/${String(token.value).split(",")[0].trim()}`,
      );
    case "fontWeight":
      return `FontWeight.w${token.value}`;
    case "shadow":
      return `<BoxShadow>[${shadowLayers(token.value)
        .map(
          (shadow) =>
            `BoxShadow(color: ${dartColor(shadow.color)}, offset: Offset(${Number(shadow.offsetX.value).toFixed(1)}, ${Number(shadow.offsetY.value).toFixed(1)}), blurRadius: ${Number(shadow.blur.value).toFixed(1)}, spreadRadius: ${Number(shadow.spread.value).toFixed(1)})`,
        )
        .join(", ")}]`;
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

function generateDart(themes, semantic, variants) {
  const fields = [...semantic].map(
    ([path, token]) => `  final ${dartType(token)} ${camel(path)};`,
  );
  const constructor = [...semantic].map(
    ([path]) => `    required this.${camel(path)},`,
  );
  const copyParameters = [...semantic].map(
    ([path, token]) => `    ${dartType(token)}? ${camel(path)},`,
  );
  const copies = [...semantic].map(([path, token]) => {
    const name = camel(path);
    const reference = path.startsWith("component.")
      ? tokenReference(token)
      : null;
    const dependency =
      reference && semantic.has(reference) ? camel(reference) : null;
    return dependency
      ? `      ${name}: ${name} ?? ${dependency} ?? this.${name},`
      : `      ${name}: ${name} ?? this.${name},`;
  });
  const lerps = [...semantic].map(([path, token]) => {
    const name = camel(path);
    if (token.type === "color")
      return `      ${name}: Color.lerp(${name}, other.${name}, t)!,`;
    if (token.type === "dimension" || token.type === "number")
      return `      ${name}: lerpDouble(${name}, other.${name}, t)!,`;
    if (token.type === "duration")
      return `      ${name}: t < 0.5 ? ${name} : other.${name},`;
    if (token.type === "fontWeight")
      return `      ${name}: FontWeight.lerp(${name}, other.${name}, t)!,`;
    if (token.type === "shadow")
      return `      ${name}: BoxShadow.lerpList(${name}, other.${name}, t)!,`;
    return `      ${name}: t < 0.5 ? ${name} : other.${name},`;
  });

  const variantFields = Object.entries(variants).flatMap(([variant, tokens]) =>
    [...tokens].map(
      ([path, token]) =>
        `  static const ${camel(`${variant}.${path}`)} = ${dartValue(token)};`,
    ),
  );

  return `// GENERATED FILE. DO NOT EDIT.\nimport 'dart:ui' show lerpDouble;\nimport 'package:flutter/material.dart';\n\nabstract final class KDesignTokenVariants {\n${variantFields.join("\n")}\n}\n\n@immutable\nclass KDesignTokens extends ThemeExtension<KDesignTokens> {\n  const KDesignTokens({\n${constructor.join("\n")}\n  });\n\n${fields.join("\n")}\n\n${Object.entries(
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
  const variantSources = Object.fromEntries(
    await Promise.all(
      Object.entries(variantFiles).map(async ([name, [path]]) => [
        name,
        await readJson(path),
      ]),
    ),
  );
  const foundation = flattenTokens(sources.foundation);
  const semantic = flattenTokens(sources.semantic);
  const themeOverrides = {
    orbitLight: flattenTokens(sources.orbitLight),
    orbitDark: flattenTokens(sources.orbitDark),
    referenceLight: flattenTokens(sources.referenceLight),
    referenceDark: flattenTokens(sources.referenceDark),
  };
  const themes = {
    orbitLight: resolvedSemantic(
      foundation,
      semantic,
      themeOverrides.orbitLight,
    ),
    orbitDark: resolvedSemantic(foundation, semantic, themeOverrides.orbitDark),
    referenceLight: resolvedSemantic(
      foundation,
      semantic,
      themeOverrides.referenceLight,
    ),
    referenceDark: resolvedSemantic(
      foundation,
      semantic,
      themeOverrides.referenceDark,
    ),
  };
  const variants = Object.fromEntries(
    Object.entries(variantSources).map(([name, source]) => [
      name,
      resolvedVariant(foundation, semantic, flattenTokens(source)),
    ]),
  );

  const variantCss = Object.entries(variants)
    .map(([name, tokens]) => cssBlock(variantFiles[name][1], tokens))
    .join("\n\n");
  const themeCss = `${cssBlock(':root, [data-brand="orbit"][data-theme="light"]', themes.orbitLight, semantic, themeOverrides.orbitLight)}\n\n${cssBlock('[data-theme="dark"], [data-brand="orbit"][data-theme="dark"]', themes.orbitDark, semantic, themeOverrides.orbitDark)}\n\n${cssBlock('[data-brand="reference"][data-theme="light"]', themes.referenceLight, semantic, themeOverrides.referenceLight)}\n\n${cssBlock('[data-brand="reference"][data-theme="dark"]', themes.referenceDark, semantic, themeOverrides.referenceDark)}`;
  const css = `/* GENERATED FILE. DO NOT EDIT. */\n@layer k-design-theme, k-design-mode;\n\n@layer k-design-theme {\n${themeCss}\n}\n\n@layer k-design-mode {\n${variantCss}\n}\n`;
  const names = [...semantic.keys()];
  const typescript = `// GENERATED FILE. DO NOT EDIT.\nexport const tokenNames = ${JSON.stringify(names, null, 2)} as const;\nexport type KTokenName = (typeof tokenNames)[number];\nexport const cssVariable = (token: KTokenName): string => \`--k-\${token.replace(/\\./g, "-").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase()}\`;\n`;
  const flat = `${JSON.stringify(
    {
      ...Object.fromEntries(
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
      variants: Object.fromEntries(
        Object.entries(variants).map(([variant, values]) => [
          variant,
          Object.fromEntries(
            [...values].map(([path, token]) => [
              path,
              { type: token.type, value: token.value },
            ]),
          ),
        ]),
      ),
    },
    null,
    2,
  )}\n`;

  await emit(outputFiles.css, css);
  await emit(outputFiles.typescript, typescript);
  await emit(outputFiles.dart, generateDart(themes, semantic, variants));
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
