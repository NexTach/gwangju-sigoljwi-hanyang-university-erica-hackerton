import { describe, expect, it } from "vitest";
import { getRoadGrade } from "./DataDisplay";
import { cx } from "./utils";

describe("Describe getRoadGrade", () => {
  describe("Context 점수 경계값을 등급으로 변환하는 경우", () => {
    it("It 미확인 값과 네 개 점수 구간을 구분한다", () => {
      expect([null, 39, 40, 60, 80].map(getRoadGrade)).toEqual([
        "UNKNOWN",
        "POOR",
        "CAUTION",
        "NORMAL",
        "GOOD",
      ]);
    });
  });
});

describe("Describe cx", () => {
  describe("Context 조건부 클래스 이름을 합치는 경우", () => {
    it("It 유효한 문자열만 공백으로 연결한다", () => {
      expect(cx("base", false, null, undefined, "active")).toBe("base active");
    });
  });
});
