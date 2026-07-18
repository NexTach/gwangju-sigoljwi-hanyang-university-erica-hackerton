import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const currentDirectory = dirname(fileURLToPath(import.meta.url));
const packageDirectory = resolve(currentDirectory, "..");
const tokens = JSON.parse(
  await readFile(resolve(packageDirectory, "tokens.json"), "utf8"),
);
const outputDirectory = resolve(packageDirectory, "dist");

await mkdir(outputDirectory, { recursive: true });

const toKebabCase = (value) =>
  value
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/[\s_]+/g, "-")
    .toLowerCase();

const flatten = (value, prefix = []) =>
  Object.entries(value).flatMap(([key, child]) => {
    const path = [...prefix, key];
    return child !== null && typeof child === "object" && !Array.isArray(child)
      ? flatten(child, path)
      : [[path, child]];
  });

const foundationGroups = [
  "palette",
  "spacing",
  "radius",
  "typography",
  "size",
  "shadow",
  "motion",
  "breakpoint",
  "layout",
  "zIndex",
];

const foundationVariables = foundationGroups.flatMap((group) =>
  flatten(tokens[group], [group]),
);
const lightVariables = flatten(tokens.semantic.light, ["color"]);
const darkVariables = flatten(tokens.semantic.dark, ["color"]);

const variableLines = (entries) =>
  entries
    .map(
      ([path, value]) =>
        `  --rd-${path.map(toKebabCase).join("-")}: ${String(value)};`,
    )
    .join("\n");

const css = `/* Generated from tokens.json. Do not edit directly. */
:root,
[data-rd-theme='light'] {
${variableLines(foundationVariables)}
${variableLines(lightVariables)}
  color-scheme: light;
}

[data-rd-theme='dark'] {
${variableLines(darkVariables)}
  color-scheme: dark;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-rd-theme='light']) {
${variableLines(darkVariables)}
    color-scheme: dark;
  }
}
`;

const js = `// Generated from tokens.json. Do not edit directly.
export const tokens = ${JSON.stringify(tokens, null, 2)};
export default tokens;
`;

const types = `// Generated from tokens.json. Do not edit directly.
export declare const tokens: ${JSON.stringify(tokens, null, 2)};
export default tokens;
`;

await Promise.all([
  writeFile(resolve(outputDirectory, "tokens.css"), css),
  writeFile(resolve(outputDirectory, "tokens.js"), js),
  writeFile(resolve(outputDirectory, "tokens.d.ts"), types),
]);
