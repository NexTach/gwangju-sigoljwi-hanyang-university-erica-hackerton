import { describe, expect, it } from "vitest";
import {
  distanceToRoadMeters,
  matchYongbongRoadHint,
  yongbongRoadProfiles,
} from "./yongbong-scenario.js";

describe("Describe 용봉동 도로 정본", () => {
  describe("Context 앱과 서버가 사용하는 도로 목록을 확인하는 경우", () => {
    it("It 고정 UUID와 실제 형상을 가진 도로 8개를 제공한다", () => {
      expect(yongbongRoadProfiles).toHaveLength(8);
      expect(
        new Set(yongbongRoadProfiles.map((road) => road.roadSegmentId)).size,
      ).toBe(8);
      expect(
        yongbongRoadProfiles.every(
          (road) => road.roadName.length > 0 && road.geometry.length >= 2,
        ),
      ).toBe(true);
    });
  });

  describe("Context 알려진 ID와 도로 위 좌표를 함께 받은 경우", () => {
    it("It 해당 정본 도로만 신뢰한다", () => {
      const road = yongbongRoadProfiles[2]!;
      const location = road.geometry[1]!;

      expect(
        matchYongbongRoadHint({
          ...location,
          roadSegmentIdHint: road.roadSegmentId,
        })?.roadSegmentId,
      ).toBe(road.roadSegmentId);
      expect(distanceToRoadMeters(location, road)).toBeLessThan(1);
    });
  });

  describe("Context 임의 UUID가 실제 도로 좌표와 함께 들어온 경우", () => {
    it("It 클라이언트가 지정한 ID를 신뢰하지 않는다", () => {
      const location = yongbongRoadProfiles[2]!.geometry[1]!;

      expect(
        matchYongbongRoadHint({
          ...location,
          roadSegmentIdHint: "d189be1f-e2d5-4b90-8cec-360ec343be99",
        }),
      ).toBeNull();
    });
  });

  describe("Context 알려진 ID가 멀리 떨어진 좌표와 함께 들어온 경우", () => {
    it("It 위치가 맞지 않는 힌트를 무시한다", () => {
      const road = yongbongRoadProfiles[2]!;

      expect(
        matchYongbongRoadHint({
          latitude: 35.1603,
          longitude: 126.8537,
          roadSegmentIdHint: road.roadSegmentId,
        }),
      ).toBeNull();
    });
  });
});
