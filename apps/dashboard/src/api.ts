import type {
  DashboardOverviewResponse,
  MovementType,
  NearbyRoadsResponse,
  PriorityRoadsResponse,
  RoadDetailResponse,
} from "@road-dna/contracts";
import {
  demoDetail,
  demoNearby,
  demoOverview,
  demoPriorities,
} from "./demo-data";

const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL ?? "").replace(/\/$/, "");
const demoMode = import.meta.env.VITE_DEMO_MODE === "true";

interface ApiErrorPayload {
  code?: string;
  message?: string;
}

async function get<T>(path: string): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    const payload = (await response
      .json()
      .catch(() => ({}))) as ApiErrorPayload;
    throw new Error(
      payload.message ?? `API 요청에 실패했어요 (${response.status})`,
    );
  }
  return response.json() as Promise<T>;
}

const movementQuery = (movementType?: MovementType): string =>
  movementType ? `movementType=${movementType}` : "";

export async function getOverview(
  movementType?: MovementType,
): Promise<DashboardOverviewResponse> {
  if (demoMode) return demoOverview;
  const query = movementQuery(movementType);
  return get(`/api/v1/dashboard/overview${query ? `?${query}` : ""}`);
}

export async function getPriorities(
  movementType?: MovementType,
): Promise<PriorityRoadsResponse> {
  if (demoMode) return demoPriorities(movementType);
  const query = new URLSearchParams({ limit: "20" });
  if (movementType) query.set("movementType", movementType);
  return get(`/api/v1/dashboard/priorities?${query}`);
}

export async function getNearbyRoads(
  movementType?: MovementType,
): Promise<NearbyRoadsResponse> {
  if (demoMode) return demoNearby(movementType);
  const types: MovementType[] = movementType
    ? [movementType]
    : ["WHEELCHAIR", "STROLLER", "WALKING"];
  const responses = await Promise.all(
    types.map((type) =>
      get<NearbyRoadsResponse>(
        "/api/v1/roads/nearby?" +
          new URLSearchParams({
            latitude: "35.15995",
            longitude: "126.85315",
            movementType: type,
            radius: "2000",
          }),
      ),
    ),
  );
  return { roads: responses.flatMap((response) => response.roads) };
}

export async function getRoadDetail(
  roadSegmentId: string,
): Promise<RoadDetailResponse> {
  if (demoMode) return demoDetail(roadSegmentId);
  return get(`/api/v1/roads/${encodeURIComponent(roadSegmentId)}`);
}

export const isDemoMode = demoMode;
