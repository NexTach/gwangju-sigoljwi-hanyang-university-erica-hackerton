import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { describe, it } from "node:test";
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

describe("Describe 디자인 토큰 불변식", () => {
  describe("Context 간격과 터치 크기를 검증하는 경우", () => {
    it("It 기본 그리드와 최소 터치 영역을 지킨다", () => {
      for (const [name, value] of Object.entries(tokens.spacing)) {
        const number = Number.parseInt(value, 10);
        assert.equal(
          number % tokens.meta.baseGrid,
          0,
          `${name} (${value}) is off-grid`,
        );
      }
      assert.ok(Number.parseInt(tokens.size.touchTarget, 10) >= 44);
      assert.ok(Number.parseInt(tokens.size.buttonMedium, 10) >= 44);
      assert.ok(Number.parseInt(tokens.size.buttonLarge, 10) >= 44);
    });
  });

  describe("Context 라이트·다크 의미 색상을 검증하는 경우", () => {
    it("It 같은 키 계약과 WCAG AA 텍스트 대비를 유지한다", () => {
      assert.deepEqual(
        Object.keys(tokens.semantic.light).sort(),
        Object.keys(tokens.semantic.dark).sort(),
      );
      for (const theme of Object.values(tokens.semantic)) {
        assert.ok(contrast(theme.contentPrimary, theme.surface) >= 4.5);
        assert.ok(contrast(theme.contentTertiary, theme.surface) >= 4.5);
        assert.ok(contrast(theme.contentTertiary, theme.surfaceSubtle) >= 4.5);
      }
      assert.ok(
        contrast(
          tokens.semantic.light.contentInverse,
          tokens.semantic.light.actionPrimary,
        ) >= 4.5,
      );
    });
  });
});
