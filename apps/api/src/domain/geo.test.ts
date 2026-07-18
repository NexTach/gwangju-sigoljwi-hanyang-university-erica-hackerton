import { describe, expect, it } from "vitest";
import { distanceMeters, offsetMidpoint } from "./geo.js";

const origin = { latitude: 35.177235, longitude: 126.899021 };
const destination = { latitude: 35.18155, longitude: 126.89944 };

describe("Describe distanceMeters", () => {
  describe("Context 두 좌표 사이 거리를 계산하는 경우", () => {
    it("It 방향과 무관한 미터 단위 거리를 반환한다", () => {
      const forward = distanceMeters(origin, destination);
      const reverse = distanceMeters(destination, origin);

      expect(distanceMeters(origin, origin)).toBe(0);
      expect(forward).toBeCloseTo(reverse, 8);
      expect(forward).toBeGreaterThan(450);
      expect(forward).toBeLessThan(500);
    });
  });
});

describe("Describe offsetMidpoint", () => {
  describe("Context 직선 경로에서 우회점을 만드는 경우", () => {
    it("It 출발지와 목적지의 단순 중점에서 벗어난 좌표를 반환한다", () => {
      const midpoint = {
        latitude: (origin.latitude + destination.latitude) / 2,
        longitude: (origin.longitude + destination.longitude) / 2,
      };
      const offset = offsetMidpoint(origin, destination, 40);

      expect(distanceMeters(midpoint, offset)).toBeGreaterThan(50);
      expect(
        distanceMeters(origin, offset) + distanceMeters(offset, destination),
      ).toBeGreaterThan(distanceMeters(origin, destination));
    });
  });
});
