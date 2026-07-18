import { describe, expect, it } from "vitest";
import { demoNearby, demoPriorities } from "./demo-data";
import { gradeLabel, movementLabel } from "./types";

describe("dashboard presentation contracts", () => {
  it("keeps movement filters and road labels explicit", () => {
    expect(movementLabel.WHEELCHAIR).toBe("휠체어");
    expect(gradeLabel.UNKNOWN).toBe("데이터 없음");
  });

  it("never leaks another movement type into filtered demo data", () => {
    expect(
      demoNearby("STROLLER").roads.every(
        (road) => road.movementType === "STROLLER",
      ),
    ).toBe(true);
    expect(
      demoPriorities("WALKING").roads.every(
        (road) => road.movementType === "WALKING",
      ),
    ).toBe(true);
  });
});
