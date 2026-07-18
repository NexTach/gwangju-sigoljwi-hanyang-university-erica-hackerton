import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const packageDirectory = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const tokens = JSON.parse(
  await readFile(resolve(packageDirectory, "tokens.json"), "utf8"),
);

const hexToRgb = (hex) => {
  const normalized = hex.replace("#", "");
  return [
    Number.parseInt(normalized.slice(0, 2), 16),
    Number.parseInt(normalized.slice(2, 4), 16),
    Number.parseInt(normalized.slice(4, 6), 16),
  ];
};

const luminance = (hex) => {
  const [red, green, blue] = hexToRgb(hex).map((channel) => {
    const value = channel / 255;
    return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
};

const contrast = (foreground, background) => {
  const values = [luminance(foreground), luminance(background)].sort(
    (a, b) => b - a,
  );
  return (values[0] + 0.05) / (values[1] + 0.05);
};

test("uses a four-point spacing grid", () => {
  for (const [name, value] of Object.entries(tokens.spacing)) {
    const number = Number.parseInt(value, 10);
    assert.equal(
      number % tokens.meta.baseGrid,
      0,
      `${name} (${value}) is off-grid`,
    );
  }
});

test("interactive controls meet the 44px minimum target", () => {
  assert.ok(Number.parseInt(tokens.size.touchTarget, 10) >= 44);
  assert.ok(Number.parseInt(tokens.size.buttonMedium, 10) >= 44);
  assert.ok(Number.parseInt(tokens.size.buttonLarge, 10) >= 44);
});

test("primary text meets WCAG AA in both themes", () => {
  assert.ok(
    contrast(
      tokens.semantic.light.contentPrimary,
      tokens.semantic.light.surface,
    ) >= 4.5,
  );
  assert.ok(
    contrast(
      tokens.semantic.dark.contentPrimary,
      tokens.semantic.dark.surface,
    ) >= 4.5,
  );
});

test("primary action supports readable inverse text", () => {
  assert.ok(
    contrast(
      tokens.semantic.light.contentInverse,
      tokens.semantic.light.actionPrimary,
    ) >= 4.5,
  );
});

test("semantic themes expose the same contract", () => {
  assert.deepEqual(
    Object.keys(tokens.semantic.light).sort(),
    Object.keys(tokens.semantic.dark).sort(),
  );
});

test("Flutter palette and spacing stay aligned with the shared source", async () => {
  const dartSource = await readFile(
    resolve(
      packageDirectory,
      "..",
      "road_dna_design",
      "lib",
      "src",
      "rd_tokens.dart",
    ),
    "utf8",
  );

  for (const [name, value] of Object.entries(tokens.palette)) {
    const expected = `0xFF${value.slice(1).toUpperCase()}`;
    const match = dartSource.match(
      new RegExp(`static const ${name} = Color\\((0x[0-9A-F]+)\\);`),
    );
    assert.ok(match, `Flutter palette is missing ${name}`);
    assert.equal(match[1], expected, `Flutter palette differs for ${name}`);
  }

  for (const [name, value] of Object.entries(tokens.spacing)) {
    const expected = `${Number.parseInt(value, 10)}.0`;
    assert.match(
      dartSource,
      new RegExp(`static const x${name} = ${expected.replace(".", "\\.")};`),
      `Flutter spacing differs for ${name}`,
    );
  }
});
